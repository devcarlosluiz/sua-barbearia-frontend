import 'package:sua_barbearia/core/errors/api_exception.dart';
import 'package:sua_barbearia/core/storage/secure_storage.dart';
import 'package:sua_barbearia/models/user.dart';
import 'package:sua_barbearia/providers/auth_provider.dart';
import 'package:sua_barbearia/providers/core_providers.dart';
import 'package:sua_barbearia/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const _owner = User(
  id: 1,
  uuid: 'uuid-owner',
  name: 'Carlos Proprietário',
  firstName: 'Carlos',
  lastName: 'Proprietário',
  email: 'owner@suabarbearia.com',
  phone: '41999990000',
  role: UserRole.owner,
);

const _session = AuthSession(
  access: 'access-token',
  refresh: 'refresh-token',
  user: _owner,
);

/// Cria o container com o repositório mockado e aguarda o `restoreSession`
/// disparado no construtor do controller.
Future<ProviderContainer> buildContainer(MockAuthRepository repository) async {
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  container.read(authControllerProvider);
  await Future<void>.delayed(Duration.zero);
  return container;
}

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    when(() => repository.hasSession()).thenAnswer((_) async => false);
  });

  group('restauração de sessão', () {
    test('sem token salvo o usuário fica deslogado', () async {
      final container = await buildContainer(repository);
      final state = container.read(authControllerProvider);

      expect(state.status, AuthStatus.unauthenticated);
      expect(state.isAuthenticated, isFalse);
      verifyNever(() => repository.me());
    });

    test('com token salvo carrega o perfil', () async {
      when(() => repository.hasSession()).thenAnswer((_) async => true);
      when(() => repository.me())
          .thenAnswer((_) async => const CurrentUser(user: _owner));

      final container = await buildContainer(repository);
      final state = container.read(authControllerProvider);

      expect(state.isAuthenticated, isTrue);
      expect(state.user?.email, 'owner@suabarbearia.com');
      expect(state.role, UserRole.owner);
    });

    test('token inválido derruba a sessão e limpa o armazenamento', () async {
      when(() => repository.hasSession()).thenAnswer((_) async => true);
      when(() => repository.me()).thenThrow(
        const ApiException(message: 'expirado', statusCode: 401),
      );
      when(() => repository.logout()).thenAnswer((_) async {});

      final container = await buildContainer(repository);

      expect(container.read(authControllerProvider).isAuthenticated, isFalse);
      verify(() => repository.logout()).called(1);
    });
  });

  group('login', () {
    test('autentica e carrega o perfil', () async {
      when(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _session);
      when(() => repository.me())
          .thenAnswer((_) async => const CurrentUser(user: _owner));

      final container = await buildContainer(repository);
      final success = await container
          .read(authControllerProvider.notifier)
          .login(
              email: 'owner@suabarbearia.com', password: 'SuaBarbearia@2026');

      expect(success, isTrue);
      expect(container.read(authControllerProvider).isAuthenticated, isTrue);
      expect(container.read(currentUserProvider)?.role, UserRole.owner);
    });

    test('credenciais inválidas produzem mensagem amigável', () async {
      when(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const ApiException(
          message: 'Nenhuma conta encontrada',
          code: 'UNAUTHENTICATED',
          statusCode: 401,
        ),
      );

      final container = await buildContainer(repository);
      final success = await container
          .read(authControllerProvider.notifier)
          .login(email: 'owner@suabarbearia.com', password: 'errada');

      final state = container.read(authControllerProvider);
      expect(success, isFalse);
      expect(state.isAuthenticated, isFalse);
      expect(state.errorMessage, 'E-mail ou senha incorretos.');
    });

    test('erro de rede mantém a mensagem do cliente HTTP', () async {
      when(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const ApiException(message: 'Sem conexão', code: 'NETWORK_ERROR'),
      );

      final container = await buildContainer(repository);
      await container
          .read(authControllerProvider.notifier)
          .login(email: 'a@b.com', password: '12345678');

      expect(
          container.read(authControllerProvider).errorMessage, 'Sem conexão');
    });
  });

  group('sessão que não pode ser guardada', () {
    // Regressão: acessar o app por HTTP em um IP da rede (ex.: pelo celular)
    // deixa o navegador fora de *secure context*. O login era aceito, o token
    // não era gravado e o `me()` voltava 401 — exibido como "senha incorreta",
    // mandando o usuário conferir uma credencial que estava certa.
    test('não culpa a senha quando o armazenamento é indisponível', () async {
      when(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const SecureStorageUnavailable('sem secure context'));

      final container = await buildContainer(repository);
      final success = await container
          .read(authControllerProvider.notifier)
          .login(
              email: 'owner@suabarbearia.com', password: 'SuaBarbearia@2026');

      final state = container.read(authControllerProvider);
      expect(success, isFalse);
      expect(state.errorMessage, isNot(contains('senha incorretos')));
      expect(state.errorMessage, contains('HTTPS'));
      // E o perfil nem chega a ser buscado.
      verifyNever(() => repository.me());
    });

    test('credencial errada continua sendo reportada como tal', () async {
      when(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const ApiException(message: 'nope', statusCode: 401));

      final container = await buildContainer(repository);
      await container
          .read(authControllerProvider.notifier)
          .login(email: 'a@b.com', password: 'errada');

      expect(container.read(authControllerProvider).errorMessage,
          'E-mail ou senha incorretos.');
    });
  });

  group('logout', () {
    test('limpa o estado de autenticação', () async {
      when(() => repository.hasSession()).thenAnswer((_) async => true);
      when(() => repository.me())
          .thenAnswer((_) async => const CurrentUser(user: _owner));
      when(() => repository.logout()).thenAnswer((_) async {});

      final container = await buildContainer(repository);
      expect(container.read(authControllerProvider).isAuthenticated, isTrue);

      await container.read(authControllerProvider.notifier).logout();

      expect(container.read(authControllerProvider).isAuthenticated, isFalse);
      expect(container.read(currentUserProvider), isNull);
    });
  });

  group('sessão expirada', () {
    test('o sinal do interceptor desloga o usuário', () async {
      when(() => repository.hasSession()).thenAnswer((_) async => true);
      when(() => repository.me())
          .thenAnswer((_) async => const CurrentUser(user: _owner));

      final container = await buildContainer(repository);
      expect(container.read(authControllerProvider).isAuthenticated, isTrue);

      // Simula a falha de refresh disparada pelo AuthInterceptor.
      container.read(sessionExpiredProvider.notifier).state++;
      await Future<void>.delayed(Duration.zero);

      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.sessionExpired, isTrue);
      expect(state.errorMessage, contains('sessão expirou'));
    });
  });
}
