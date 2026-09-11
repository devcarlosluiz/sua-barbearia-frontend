import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';

/// Ponte com o "Entrar com o Google".
///
/// O app nunca cria sessão sozinho a partir do que o Google devolve: o único
/// dado aproveitado é o **ID token**, que vai para `POST /auth/google/` e só
/// vira sessão depois que o backend confere a assinatura do Google.
///
/// As duas plataformas seguem caminhos diferentes, e a diferença é do plugin,
/// não nossa:
///
/// * no Android e no iOS, [startSignIn] abre a folha de contas do sistema;
/// * na web, `authenticate()` não existe — quem inicia o fluxo é o botão
///   desenhado pelo próprio Google (`renderButton`, em
///   `GoogleSignInButton`).
///
/// Nos dois casos o resultado chega pelo mesmo lugar, [idTokens], e é por isso
/// que [startSignIn] não devolve o token: ter uma só entrada evita tratar o
/// login duas vezes no celular, onde o retorno da chamada e o evento do stream
/// falam da mesma conta.
class GoogleSignInService {
  GoogleSignInService._();

  static final GoogleSignInService instance = GoogleSignInService._();

  Future<void>? _initialization;

  bool get isEnabled => AppConfig.isGoogleSignInEnabled;

  /// `true` onde o app pode abrir o fluxo por conta própria (Android e iOS).
  /// Na web é `false`: lá o clique tem que ser no botão do Google.
  bool get supportsOwnButton =>
      !kIsWeb && GoogleSignIn.instance.supportsAuthenticate();

  /// Inicializa o SDK uma única vez por execução.
  Future<void> ensureInitialized() {
    return _initialization ??= GoogleSignIn.instance.initialize(
      // Na web o client ID identifica o próprio app; no celular, o
      // `serverClientId` é o que coloca o nosso backend no `aud` do token.
      clientId: kIsWeb
          ? AppConfig.googleWebClientId
          : (AppConfig.googleIosClientId.isEmpty
              ? null
              : AppConfig.googleIosClientId),
      serverClientId: kIsWeb ? null : AppConfig.googleWebClientId,
    );
  }

  /// ID tokens de cada login concluído com sucesso.
  ///
  /// Eventos sem `idToken` são descartados: acontecem quando o Google devolve
  /// só permissão de acesso, que não serve para autenticar ninguém aqui.
  Stream<String> get idTokens {
    return GoogleSignIn.instance.authenticationEvents
        .where((event) => event is GoogleSignInAuthenticationEventSignIn)
        .cast<GoogleSignInAuthenticationEventSignIn>()
        .map((event) => event.user.authentication.idToken)
        .where((token) => token != null && token.isNotEmpty)
        .cast<String>();
  }

  /// Abre a escolha de conta no celular. Na web não é chamado.
  ///
  /// Devolve `false` quando a pessoa desiste — desistir não é erro e não deve
  /// virar mensagem vermelha na tela.
  Future<bool> startSignIn() async {
    await ensureInitialized();
    try {
      await GoogleSignIn.instance.authenticate();
      return true;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return false;
      rethrow;
    }
  }

  /// Desconecta a conta Google do dispositivo.
  ///
  /// Sem isso, o próximo login entraria direto na última conta usada, sem
  /// perguntar — o que surpreende quem sai justamente para trocar de conta.
  Future<void> signOut() async {
    if (_initialization == null) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (error) {
      // Sair do app não pode falhar por causa do Google.
      debugPrint('[GoogleSignIn] falha ao encerrar a sessão: $error');
    }
  }
}
