import 'package:sua_barbearia/core/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regressão de um incidente real: o build web era compilado com
/// `localhost:8000` fixo e quebrava ao ser aberto pelo navegador do emulador
/// Android (`10.0.2.2:8080`), onde `localhost` é o próprio emulador.
void main() {
  String resolve({
    String fromEnv = '',
    bool isWeb = true,
    String origin = 'http://localhost:8080/',
    TargetPlatform platform = TargetPlatform.android,
  }) {
    return AppConfig.resolveApiBaseUrl(
      fromEnv: fromEnv,
      isWeb: isWeb,
      origin: Uri.parse(origin),
      platform: platform,
    );
  }

  group('web: o host vem da página', () {
    test('servido em localhost aponta para localhost', () {
      expect(resolve(origin: 'http://localhost:8080/#/login'),
          'http://localhost:8000');
    });

    test('servido no alias do emulador aponta para o alias', () {
      // É este o caso que estava quebrado.
      expect(resolve(origin: 'http://10.0.2.2:8080/#/login'),
          'http://10.0.2.2:8000');
    });

    test('servido por IP da rede local aponta para o mesmo IP', () {
      expect(resolve(origin: 'http://192.168.0.42:8080/'),
          'http://192.168.0.42:8000');
    });

    test('servido em 127.0.0.1 não vira localhost', () {
      expect(
          resolve(origin: 'http://127.0.0.1:8080/'), 'http://127.0.0.1:8000');
    });

    test('origem sem host cai no padrão', () {
      expect(resolve(origin: 'about:blank'), 'http://localhost:8000');
    });
  });

  group('nativo: o padrão depende da plataforma', () {
    test('Android usa o alias do host do emulador', () {
      expect(
        resolve(isWeb: false, platform: TargetPlatform.android),
        'http://10.0.2.2:8000',
      );
    });

    test('iOS e desktop usam localhost', () {
      expect(
        resolve(isWeb: false, platform: TargetPlatform.iOS),
        'http://localhost:8000',
      );
      expect(
        resolve(isWeb: false, platform: TargetPlatform.macOS),
        'http://localhost:8000',
      );
    });
  });

  group('API_BASE_URL explícita', () {
    test('vence a resolução automática na web', () {
      expect(
        resolve(
          fromEnv: 'https://api.suabarbearia.com.br',
          origin: 'http://10.0.2.2:8080/',
        ),
        'https://api.suabarbearia.com.br',
      );
    });

    test('vence a resolução automática no nativo', () {
      expect(
        resolve(
          fromEnv: 'https://api.suabarbearia.com.br',
          isWeb: false,
          platform: TargetPlatform.android,
        ),
        'https://api.suabarbearia.com.br',
      );
    });
  });

  test('apiUrl acrescenta o prefixo versionado', () {
    expect(AppConfig.apiUrl, endsWith('/api/v1'));
  });
}
