import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/google_sign_in_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/widgets.dart';
import 'google_button_stub.dart'
    if (dart.library.js_interop) 'google_button_web.dart';

/// Botão "Continuar com o Google", usado no login e no cadastro.
///
/// Some por completo quando o client ID não está configurado: melhor não
/// oferecer do que oferecer um botão que só devolve erro.
///
/// O login em si acontece sempre pelo stream de tokens do serviço, mesmo no
/// celular, onde o `authenticate()` também devolve a conta. Uma entrada só
/// evita o cadastro em duplicidade que apareceria se os dois caminhos
/// chamassem a API.
class GoogleSignInButton extends ConsumerStatefulWidget {
  const GoogleSignInButton({
    super.key,
    required this.onSignedIn,
    this.preferredBranchId,
  });

  /// Chamado depois que o backend confirma a sessão. Recebe `true` quando a
  /// conta acabou de ser criada.
  final void Function(bool isNewAccount) onSignedIn;

  /// Filial escolhida no cadastro, quando houver.
  final int? preferredBranchId;

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  final GoogleSignInService _google = GoogleSignInService.instance;

  late final Future<void> _initialization;
  StreamSubscription<String>? _subscription;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    // Sem client ID o widget nem aparece: acordar o plugin seria trabalho
    // jogado fora (e quebraria os testes de widget, que não têm plataforma).
    _initialization = _google.isEnabled ? _start() : Future<void>.value();
  }

  Future<void> _start() async {
    await _google.ensureInitialized();
    // Só depois de inicializar: antes disso o stream do plugin não existe.
    _subscription = _google.idTokens.listen(_authenticate);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _authenticate(String idToken) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);

    final outcome =
        await ref.read(authControllerProvider.notifier).signInWithGoogle(
              idToken: idToken,
              preferredBranchId: widget.preferredBranchId,
            );

    if (!mounted) return;
    setState(() => _isBusy = false);
    if (outcome.succeeded) widget.onSignedIn(outcome.isNewAccount);
  }

  Future<void> _openGoogle() async {
    setState(() => _isBusy = true);
    try {
      // O token não vem daqui: chega pelo stream, em `_authenticate`.
      final iniciou = await _google.startSignIn();
      if (!mounted || iniciou) return;
      setState(() => _isBusy = false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      ref.read(authControllerProvider.notifier).reportGoogleFailure(
            'Não foi possível abrir a conta Google. Tente novamente.',
          );
      debugPrint('[GoogleSignIn] falha ao iniciar o fluxo: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_google.isEnabled) return const SizedBox.shrink();

    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppSkeleton(height: 48);
        }
        if (snapshot.hasError) {
          // Configuração incompleta (client ID errado, por exemplo). Esconder
          // é melhor do que mostrar um botão que não vai funcionar.
          debugPrint('[GoogleSignIn] inicialização falhou: ${snapshot.error}');
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _OuSeparator(),
            const SizedBox(height: AppSpacing.md),
            if (_isBusy)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (_google.supportsOwnButton)
              AppButton.outline(
                label: 'Continuar com o Google',
                icon: Icons.g_mobiledata_rounded,
                onPressed: _openGoogle,
              )
            else
              // Na web, o clique precisa ser no botão do próprio Google.
              Center(child: buildGoogleRenderedButton(minimumWidth: 320)),
          ],
        );
      },
    );
  }
}

class _OuSeparator extends StatelessWidget {
  const _OuSeparator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget linha() => Expanded(
          child: Divider(color: theme.dividerColor, height: 1),
        );

    return Row(
      children: [
        linha(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text('ou', style: theme.textTheme.bodySmall),
        ),
        linha(),
      ],
    );
  }
}
