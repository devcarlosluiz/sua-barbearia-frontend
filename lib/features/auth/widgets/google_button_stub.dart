import 'package:flutter/widgets.dart';

/// Versão não-web: no Android e no iOS quem abre o fluxo é o nosso próprio
/// botão, então aqui não há nada a desenhar.
///
/// Este arquivo existe para o import condicional em `google_sign_in_button`:
/// `google_sign_in_web` só compila na web, e importá-lo direto quebraria o
/// build do celular.
Widget buildGoogleRenderedButton({double? minimumWidth}) =>
    const SizedBox.shrink();
