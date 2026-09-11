import 'package:flutter/foundation.dart';

/// Configuração de ambiente do aplicativo.
///
/// A URL da API é injetada em tempo de compilação:
/// `flutter run --dart-define=API_BASE_URL=https://api.suabarbearia.com.br`
class AppConfig {
  const AppConfig._();

  static const String appName = 'Sua Barbearia';
  static const String apiVersion = 'v1';

  /// Base da API. O padrão cobre o ambiente Docker local.
  ///
  /// No emulador Android, `localhost` aponta para o próprio emulador; por isso
  /// o padrão nativo é `10.0.2.2`, que é o host da máquina.
  ///
  /// Na web o host é derivado da própria página em vez de fixado. Sem isso um
  /// build feito para `localhost` quebra ao ser aberto de qualquer outro
  /// endereço — pelo navegador do emulador (`10.0.2.2:8080`) ou por outro
  /// aparelho na rede local — porque `localhost` passa a apontar para o
  /// dispositivo, não para a máquina que roda o backend.
  ///
  /// Em produção a URL é sempre explícita:
  /// `flutter build web --dart-define=API_BASE_URL=https://api.suabarbearia.com.br`
  static String get apiBaseUrl => resolveApiBaseUrl(
        fromEnv: const String.fromEnvironment('API_BASE_URL'),
        isWeb: kIsWeb,
        origin: Uri.base,
        platform: defaultTargetPlatform,
      );

  /// Resolução pura da base da API — extraída para poder ser testada.
  ///
  /// `Uri.base` e `kIsWeb` não são controláveis dentro de um teste, então a
  /// decisão vive aqui e recebe tudo por parâmetro.
  @visibleForTesting
  static String resolveApiBaseUrl({
    required String fromEnv,
    required bool isWeb,
    required Uri origin,
    required TargetPlatform platform,
  }) {
    if (fromEnv.isNotEmpty) return fromEnv;

    if (isWeb) {
      // O backend de desenvolvimento é HTTP puro na 8000.
      final host = origin.host;
      return host.isEmpty ? 'http://localhost:8000' : 'http://$host:8000';
    }
    return platform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://localhost:8000';
  }

  static String get apiUrl => '$apiBaseUrl/api/$apiVersion';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Registra as requisições no console.
  ///
  /// Ligado por padrão em desenvolvimento. Em builds de release pode ser
  /// habilitado sob demanda para diagnosticar um ambiente específico:
  /// `flutter build web --dart-define=ENABLE_NETWORK_LOGS=true`
  static bool get enableNetworkLogs =>
      kDebugMode ||
      const String.fromEnvironment('ENABLE_NETWORK_LOGS') == 'true';

  static const int defaultPageSize = 20;

  /// Client ID **web** do "Entrar com o Google", criado no Google Cloud.
  ///
  /// É o mesmo valor nas três plataformas, e não por descuido: na web ele é o
  /// client ID do próprio app; no Android e no iOS ele vai como
  /// `serverClientId`, que é o que faz o Google emitir um ID token com `aud`
  /// apontando para o nosso backend. Sem ele, o app nativo recebe um token que
  /// o backend recusa — ou nenhum token.
  ///
  /// `flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=123-abc.apps.googleusercontent.com`
  static const String googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  /// Client ID do iOS, quando houver build para iPhone. Opcional: sem ele o
  /// plugin cai para o valor do `Info.plist`/`GoogleService-Info.plist`.
  static const String googleIosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  /// Sem client ID configurado, o botão do Google simplesmente não aparece —
  /// o backend responderia 503 e o login por e-mail continua funcionando.
  static bool get isGoogleSignInEnabled => googleWebClientId.isNotEmpty;
}
