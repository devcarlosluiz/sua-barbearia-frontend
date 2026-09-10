import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// O armazenamento seguro não existe neste contexto.
///
/// Na Web o `flutter_secure_storage` usa AES-GCM via Web Crypto, que só existe
/// em *secure context* — HTTPS ou `localhost`. Servido por HTTP em um IP da
/// rede (`http://192.168.x.x:8080`), o pacote lança `UnsupportedError` e não há
/// onde guardar o token.
///
/// Isto **não** é silenciado: sem token, o login até é aceito pelo servidor,
/// mas a requisição seguinte sai sem `Authorization` e volta 401 — que a UI
/// mostrava como "e-mail ou senha incorretos", mandando o usuário conferir uma
/// senha que estava certa.
class SecureStorageUnavailable implements Exception {
  const SecureStorageUnavailable(this.cause);

  final Object cause;

  @override
  String toString() => 'SecureStorageUnavailable: $cause';
}

/// Armazenamento seguro dos tokens JWT.
///
/// Regra do projeto: tokens **nunca** vão para SharedPreferences.
/// No Android usamos EncryptedSharedPreferences; no iOS, o Keychain; na Web,
/// AES-GCM via Web Crypto.
///
/// As falhas são tratadas em dois níveis:
///
/// * **Store corrompido** (ex.: chave AES inválida no `localStorage` fazendo o
///   Web Crypto lançar `OperationError`) — tratado como "sem sessão"; o store
///   é limpo e o app segue como anônimo.
/// * **Store indisponível** (`UnsupportedError`) — propagado como
///   [SecureStorageUnavailable]. Aqui não há o que limpar nem como seguir: o
///   ambiente simplesmente não permite guardar credenciais.
class SecureStorage {
  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              // A partir da v10 o Android já usa cifras próprias por padrão
              // (a Jetpack Security foi descontinuada pelo Google), então não
              // há mais o parâmetro `encryptedSharedPreferences`.
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  static const String _accessKey = 'sua_barbearia.access_token';
  static const String _refreshKey = 'sua_barbearia.refresh_token';
  static const String _roleKey = 'sua_barbearia.user_role';

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await _write(_accessKey, access);
    await _write(_refreshKey, refresh);
  }

  Future<void> saveAccessToken(String access) => _write(_accessKey, access);

  Future<String?> readAccessToken() => _read(_accessKey);

  Future<String?> readRefreshToken() => _read(_refreshKey);

  Future<void> saveRole(String role) => _write(_roleKey, role);

  Future<String?> readRole() => _read(_roleKey);

  Future<bool> get hasSession async =>
      (await readAccessToken())?.isNotEmpty ?? false;

  Future<void> clear() async {
    try {
      await _storage.deleteAll();
    } catch (error, stackTrace) {
      debugPrint('[SecureStorage] falha ao limpar a sessão: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } on UnsupportedError catch (error) {
      // Ambiente sem armazenamento seguro: não há sessão nem o que limpar.
      debugPrint('[SecureStorage] indisponível ao ler "$key": $error');
      return null;
    } catch (error, stackTrace) {
      // Store corrompido: descarta a sessão e segue como anônimo.
      debugPrint('[SecureStorage] falha ao ler "$key": $error');
      debugPrintStack(stackTrace: stackTrace);
      await clear();
      return null;
    }
  }

  Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } on UnsupportedError catch (error) {
      // Propaga: engolir aqui produz um login que "dá certo" e falha na
      // requisição seguinte com um 401 que parece senha errada.
      debugPrint('[SecureStorage] indisponível ao gravar "$key": $error');
      throw SecureStorageUnavailable(error);
    } catch (error, stackTrace) {
      // Falha pontual de escrita não pode abortar o login desta sessão.
      debugPrint('[SecureStorage] falha ao gravar "$key": $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
