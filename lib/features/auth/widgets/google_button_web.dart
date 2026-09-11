import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

/// Botão oficial do Google, desenhado pelo próprio Google Identity Services.
///
/// Na web o fluxo não pode ser iniciado por um botão nosso: o navegador só
/// abre a escolha de conta a partir do elemento que o Google renderiza. Por
/// isso aqui a aparência é a deles — o que ainda ajuda, porque é o visual que
/// as pessoas reconhecem.
Widget buildGoogleRenderedButton({double? minimumWidth}) {
  return google_web.renderButton(
    configuration: google_web.GSIButtonConfiguration(
      theme: google_web.GSIButtonTheme.filledBlack,
      size: google_web.GSIButtonSize.large,
      text: google_web.GSIButtonText.continueWith,
      shape: google_web.GSIButtonShape.rectangular,
      logoAlignment: google_web.GSIButtonLogoAlignment.center,
      minimumWidth: minimumWidth,
      locale: 'pt-BR',
    ),
  );
}
