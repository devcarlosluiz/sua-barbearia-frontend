/// Exceção única que a camada de UI consome.
///
/// O [code] é o código estável devolvido pelo backend (ex.: `SLOT_NOT_AVAILABLE`)
/// e o [message] já vem pronto para exibição ao usuário.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.code = 'ERROR',
    this.statusCode,
    this.fieldErrors = const {},
  });

  final String message;
  final String code;
  final int? statusCode;

  /// Erros por campo, no formato `{"email": ["Já existe uma conta..."]}`.
  final Map<String, List<String>> fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isNetworkError => code == 'NETWORK_ERROR' || code == 'TIMEOUT';
  bool get hasFieldErrors => fieldErrors.isNotEmpty;

  /// Primeira mensagem de erro de um campo específico, se houver.
  String? errorFor(String field) {
    final errors = fieldErrors[field];
    if (errors == null || errors.isEmpty) return null;
    return errors.first;
  }

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}
