import 'dart:async';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/secure_storage.dart';

/// Injeta o access token e renova a sessão quando ele expira.
///
/// Fluxo em caso de 401:
/// ```
/// 401 -> POST /auth/refresh/ -> novo access -> refaz a requisição original
///        (se o refresh falhar: limpa a sessão e dispara onSessionExpired)
/// ```
/// Requisições concorrentes que recebem 401 aguardam o mesmo refresh —
/// nunca disparamos vários refreshes em paralelo.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.storage,
    required this.dio,
    required this.onSessionExpired,
  });

  final SecureStorage storage;
  final Dio dio;
  final void Function() onSessionExpired;

  Completer<String?>? _refreshCompleter;

  /// Rotas que não devem receber o header Authorization.
  static const List<String> _publicPaths = [
    '/auth/login/',
    '/auth/register/',
    '/auth/refresh/',
    '/auth/forgot-password/',
    '/auth/reset-password/',
  ];

  bool _isPublic(String path) =>
      _publicPaths.any((public) => path.endsWith(public));

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublic(options.path)) {
      final token = await storage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra['__retried'] == true;

    if (!isUnauthorized ||
        alreadyRetried ||
        _isPublic(err.requestOptions.path)) {
      return handler.next(err);
    }

    final newToken = await _refreshAccessToken();
    if (newToken == null) {
      await storage.clear();
      onSessionExpired();
      return handler.next(err);
    }

    try {
      final options = err.requestOptions;
      options.headers['Authorization'] = 'Bearer $newToken';
      options.extra['__retried'] = true;

      final response = await dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }

  /// Renova o access token. Chamadas concorrentes compartilham o mesmo futuro.
  Future<String?> _refreshAccessToken() {
    final pending = _refreshCompleter;
    if (pending != null) return pending.future;

    final completer = Completer<String?>();
    _refreshCompleter = completer;

    unawaited(
      _performRefresh().then((token) {
        _refreshCompleter = null;
        completer.complete(token);
      }).catchError((_) {
        _refreshCompleter = null;
        completer.complete(null);
      }),
    );

    return completer.future;
  }

  Future<String?> _performRefresh() async {
    final refresh = await storage.readRefreshToken();
    if (refresh == null || refresh.isEmpty) return null;

    // Cliente isolado: não passa por este interceptor e evita recursão.
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    try {
      final response = await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh/',
        data: {'refresh': refresh},
      );

      final body = response.data;
      final payload = body?['data'] as Map<String, dynamic>?;
      final access = payload?['access'] as String?;
      if (access == null || access.isEmpty) return null;

      // O backend rotaciona o refresh token; guardamos o novo quando vier.
      final rotatedRefresh = payload?['refresh'] as String?;
      if (rotatedRefresh != null && rotatedRefresh.isNotEmpty) {
        await storage.saveTokens(access: access, refresh: rotatedRefresh);
      } else {
        await storage.saveAccessToken(access);
      }
      return access;
    } on DioException {
      return null;
    }
  }
}
