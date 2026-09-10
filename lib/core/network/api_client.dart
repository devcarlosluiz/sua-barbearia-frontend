import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../errors/api_exception.dart';
import '../errors/error_messages.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';

/// Cliente HTTP único do aplicativo.
///
/// Responsabilidades: base URL, headers, JWT, refresh automático, timeouts,
/// logs em desenvolvimento e conversão do envelope da API
/// (`{success, data, message, errors, code}`) em objetos Dart ou [ApiException].
class ApiClient {
  ApiClient(
      {required SecureStorage storage, required VoidCallback onSessionExpired})
      : _storage = storage,
        _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiUrl,
            connectTimeout: AppConfig.connectTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            // Tratamos os status de erro no nosso conversor.
            validateStatus: (status) => status != null && status < 500,
          ),
        ) {
    _dio.interceptors.add(
      AuthInterceptor(
        storage: _storage,
        dio: _dio,
        onSessionExpired: onSessionExpired,
      ),
    );

    if (AppConfig.enableNetworkLogs) {
      _dio.interceptors.add(
        LogInterceptor(
          request: false,
          requestHeader: false,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (object) => debugPrint('[API] $object'),
        ),
      );
    }
  }

  final Dio _dio;
  final SecureStorage _storage;

  Dio get raw => _dio;

  // ------------------------------------------------------------------
  // Verbos
  // ------------------------------------------------------------------
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
  }) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: _clean(query)));

  Future<dynamic> post(String path, {Object? data}) =>
      _send(() => _dio.post<dynamic>(path, data: data));

  Future<dynamic> patch(String path, {Object? data}) =>
      _send(() => _dio.patch<dynamic>(path, data: data));

  Future<dynamic> put(String path, {Object? data}) =>
      _send(() => _dio.put<dynamic>(path, data: data));

  Future<dynamic> delete(String path, {Object? data}) =>
      _send(() => _dio.delete<dynamic>(path, data: data));

  Future<dynamic> upload(String path, FormData form,
          {String method = 'POST'}) =>
      _send(
        () => _dio.request<dynamic>(
          path,
          data: form,
          options: Options(
            method: method,
            headers: {'Content-Type': 'multipart/form-data'},
          ),
        ),
      );

  // ------------------------------------------------------------------
  // Núcleo
  // ------------------------------------------------------------------
  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return _unwrap(response);
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  /// Extrai `data` do envelope e converte respostas de erro em [ApiException].
  dynamic _unwrap(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    final body = response.data;

    if (status == 204 || body == null || body == '') {
      if (status >= 400) {
        throw ApiException(
          message: ErrorMessages.forCode('ERROR'),
          statusCode: status,
        );
      }
      return null;
    }

    if (body is! Map<String, dynamic>) {
      if (status >= 400) {
        throw ApiException(
          message: ErrorMessages.forCode('ERROR'),
          statusCode: status,
        );
      }
      return body;
    }

    final success = body['success'];
    if (status >= 400 || success == false) {
      throw _fromEnvelope(body, status);
    }
    return body.containsKey('data') ? body['data'] : body;
  }

  ApiException _fromEnvelope(Map<String, dynamic> body, int status) {
    final code = (body['code'] as String?) ?? _codeForStatus(status);
    final serverMessage = body['message'] as String?;
    return ApiException(
      message: ErrorMessages.forCode(code, fallback: serverMessage),
      code: code,
      statusCode: status,
      fieldErrors: _parseFieldErrors(body['errors']),
    );
  }

  ApiException _toApiException(DioException error) {
    final response = error.response;
    if (response != null && response.data is Map<String, dynamic>) {
      return _fromEnvelope(
        response.data as Map<String, dynamic>,
        response.statusCode ?? 0,
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: ErrorMessages.forCode('TIMEOUT'),
          code: 'TIMEOUT',
        );
      case DioExceptionType.cancel:
        return ApiException(
          message: ErrorMessages.forCode('CANCELLED'),
          code: 'CANCELLED',
        );
      case DioExceptionType.badResponse:
        final status = response?.statusCode ?? 0;
        return ApiException(
          message: ErrorMessages.forCode(_codeForStatus(status)),
          code: _codeForStatus(status),
          statusCode: status,
        );
      default:
        // `DioExceptionType.unknown` embrulha qualquer exceção lançada dentro
        // do pipeline (inclusive nos interceptors). Sem registrar a causa
        // original, tudo vira "sem conexão" e o diagnóstico fica impossível.
        if (AppConfig.enableNetworkLogs) {
          debugPrint(
            '[API] Falha não-HTTP em ${error.requestOptions.method} '
            '${error.requestOptions.path} (${error.type}): ${error.error}',
          );
          debugPrint('${error.stackTrace}');
        }
        return ApiException(
          message: ErrorMessages.forCode('NETWORK_ERROR'),
          code: 'NETWORK_ERROR',
        );
    }
  }

  static String _codeForStatus(int status) {
    switch (status) {
      case 400:
        return 'VALIDATION_ERROR';
      case 401:
        return 'UNAUTHENTICATED';
      case 403:
        return 'PERMISSION_DENIED';
      case 404:
        return 'NOT_FOUND';
      case 405:
        return 'METHOD_NOT_ALLOWED';
      case 409:
        return 'CONFLICT';
      case 429:
        return 'THROTTLED';
      default:
        return status >= 500 ? 'INTERNAL_ERROR' : 'ERROR';
    }
  }

  static Map<String, List<String>> _parseFieldErrors(Object? raw) {
    if (raw is! Map) return const {};
    final result = <String, List<String>>{};
    raw.forEach((key, value) {
      if (value is List) {
        result['$key'] = value.map((item) => '$item').toList();
      } else if (value is String) {
        result['$key'] = [value];
      }
    });
    return result;
  }

  static Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    final cleaned = <String, dynamic>{};
    query.forEach((key, value) {
      if (value != null && value != '') cleaned[key] = value;
    });
    return cleaned;
  }

  Future<void> clearSession() => _storage.clear();
}
