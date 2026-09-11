import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/api_exception.dart';
import '../core/services/google_sign_in_service.dart';
import '../core/storage/secure_storage.dart';
import '../models/barber.dart';
import '../models/client.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import 'core_providers.dart';

enum AuthStatus { unknown, authenticating, authenticated, unauthenticated }

@immutable
class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.client,
    this.barber,
    this.errorMessage,
    this.sessionExpired = false,
  });

  final AuthStatus status;
  final User? user;
  final Client? client;
  final Barber? barber;
  final String? errorMessage;
  final bool sessionExpired;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.authenticating;
  bool get isUnknown => status == AuthStatus.unknown;

  UserRole get role => user?.role ?? UserRole.unknown;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    Client? client,
    Barber? barber,
    String? errorMessage,
    bool clearError = false,
    bool? sessionExpired,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      client: client ?? this.client,
      barber: barber ?? this.barber,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      sessionExpired: sessionExpired ?? this.sessionExpired,
    );
  }

  static const AuthState signedOut =
      AuthState(status: AuthStatus.unauthenticated);
}

/// Resultado do login com o Google, para a tela escolher a mensagem certa.
@immutable
class GoogleSignInOutcome {
  const GoogleSignInOutcome({
    required this.succeeded,
    this.isNewAccount = false,
  });

  final bool succeeded;
  final bool isNewAccount;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository, this._ref) : super(const AuthState()) {
    // Reage a falhas de renovação de token vindas do interceptor.
    _ref.listen<int>(sessionExpiredProvider, (previous, next) {
      if (previous != null && next > previous) {
        _handleSessionExpired();
      }
    });
    restoreSession();
  }

  final AuthRepository _repository;
  final Ref _ref;

  /// Recupera a sessão salva no armazenamento seguro ao abrir o app.
  Future<void> restoreSession() async {
    // Este método decide se o app sai do splash. Qualquer exceção não tratada
    // aqui deixaria o estado em `unknown` para sempre e travaria a abertura —
    // por isso o catch é abrangente e o fallback é sempre "deslogado".
    try {
      if (!await _repository.hasSession()) {
        state = AuthState.signedOut;
        return;
      }

      final current = await _repository.me();
      state = AuthState(
        status: AuthStatus.authenticated,
        user: current.user,
        client: current.client,
        barber: current.barber,
      );
    } catch (error, stackTrace) {
      debugPrint('[Auth] falha ao restaurar a sessão: $error');
      debugPrintStack(stackTrace: stackTrace);
      try {
        await _repository.logout();
      } catch (_) {
        // Ignorado: o objetivo é apenas garantir o estado deslogado.
      }
      state = AuthState.signedOut;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.authenticating, clearError: true);
    try {
      await _repository.login(email: email, password: password);
      final current = await _repository.me();
      state = AuthState(
        status: AuthStatus.authenticated,
        user: current.user,
        client: current.client,
        barber: current.barber,
      );
      return true;
    } on SecureStorageUnavailable {
      // As credenciais foram aceitas; o que falhou foi guardar a sessão.
      // Culpar a senha aqui manda o usuário procurar um problema que não existe.
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Não é possível manter a sessão com segurança neste '
            'endereço. Acesse o app por HTTPS ou por localhost.',
      );
      return false;
    } on ApiException catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: error.statusCode == 401
            ? 'E-mail ou senha incorretos.'
            : error.message,
      );
      return false;
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirm,
    int? preferredBranchId,
  }) async {
    state = state.copyWith(status: AuthStatus.authenticating, clearError: true);
    try {
      await _repository.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
        passwordConfirm: passwordConfirm,
        preferredBranchId: preferredBranchId,
      );
      final current = await _repository.me();
      state = AuthState(
        status: AuthStatus.authenticated,
        user: current.user,
        client: current.client,
        barber: current.barber,
      );
      return true;
    } on SecureStorageUnavailable {
      // A conta foi criada; o que falhou foi guardar a sessão.
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Conta criada, mas não é possível manter a sessão com '
            'segurança neste endereço. Acesse por HTTPS ou por localhost e '
            'entre com os seus dados.',
      );
      return false;
    } on ApiException catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: _firstFieldError(error) ?? error.message,
      );
      return false;
    }
  }

  /// Troca o ID token do Google por uma sessão nossa.
  ///
  /// O token não é inspecionado aqui: quem confere a assinatura, o `aud` e o
  /// e-mail verificado é o backend. Para o app, isto é apenas mais um login.
  Future<GoogleSignInOutcome> signInWithGoogle({
    required String idToken,
    int? preferredBranchId,
  }) async {
    state = state.copyWith(status: AuthStatus.authenticating, clearError: true);
    try {
      final session = await _repository.loginWithGoogle(
        idToken: idToken,
        preferredBranchId: preferredBranchId,
      );
      final current = await _repository.me();
      state = AuthState(
        status: AuthStatus.authenticated,
        user: current.user,
        client: current.client,
        barber: current.barber,
      );
      return GoogleSignInOutcome(
        succeeded: true,
        isNewAccount: session.isNewAccount,
      );
    } on SecureStorageUnavailable {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Não é possível manter a sessão com segurança neste '
            'endereço. Acesse o app por HTTPS ou por localhost.',
      );
      return const GoogleSignInOutcome(succeeded: false);
    } on ApiException catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: error.message,
      );
      return const GoogleSignInOutcome(succeeded: false);
    }
  }

  /// Mensagem de falha vinda do próprio Google (fora do fluxo da nossa API).
  void reportGoogleFailure(String message) {
    state = AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: message,
    );
  }

  Future<void> refreshProfile() async {
    if (!state.isAuthenticated) return;
    try {
      final current = await _repository.me();
      state = state.copyWith(
        user: current.user,
        client: current.client,
        barber: current.barber,
      );
    } on ApiException {
      // Mantém o estado atual: um erro de rede não deve derrubar a sessão.
    }
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    try {
      final current = await _repository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      state = state.copyWith(
        user: current.user,
        client: current.client,
        barber: current.barber,
        clearError: true,
      );
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(errorMessage: error.message);
      return false;
    }
  }

  /// Envia a foto de perfil e atualiza o estado com o usuário já salvo.
  ///
  /// A foto aparece no cabeçalho, na barra lateral e nos cartões: atualizar o
  /// estado aqui faz todos eles trocarem de uma vez, sem recarregar a tela.
  Future<void> uploadAvatar({
    required Uint8List bytes,
    required String filename,
  }) async {
    final current =
        await _repository.uploadAvatar(bytes: bytes, filename: filename);
    state = state.copyWith(
      user: current.user,
      client: current.client,
      barber: current.barber,
      clearError: true,
    );
  }

  Future<void> removeAvatar() async {
    await _repository.removeAvatar();
    final current = await _repository.me();
    state = AuthState(
      status: AuthStatus.authenticated,
      user: current.user,
      client: current.client,
      barber: current.barber,
    );
  }

  Future<void> logout() async {
    // Encerrar também no Google: sem isso, o próximo login entraria direto na
    // mesma conta, sem chance de trocar.
    await GoogleSignInService.instance.signOut();
    await _repository.logout();
    state = AuthState.signedOut;
  }

  void clearError() => state = state.copyWith(clearError: true);

  void _handleSessionExpired() {
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      sessionExpired: true,
      errorMessage: 'Sua sessão expirou. Entre novamente.',
    );
  }

  static String? _firstFieldError(ApiException error) {
    if (!error.hasFieldErrors) return null;
    final first = error.fieldErrors.values.first;
    return first.isEmpty ? null : first.first;
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider), ref);
});

/// Usuário autenticado (null quando não há sessão).
final currentUserProvider = Provider<User?>(
  (ref) => ref.watch(authControllerProvider).user,
);

final currentRoleProvider = Provider<UserRole>(
  (ref) => ref.watch(authControllerProvider).role,
);

final currentClientProvider = Provider<Client?>(
  (ref) => ref.watch(authControllerProvider).client,
);

final currentBarberProvider = Provider<Barber?>(
  (ref) => ref.watch(authControllerProvider).barber,
);
