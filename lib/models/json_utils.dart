/// Conversores tolerantes usados pelos models.
///
/// O DRF serializa `DecimalField` como string (`"45.00"`) e datas em ISO-8601;
/// estas funções normalizam tudo para tipos Dart sem quebrar quando um campo
/// vem nulo ou com um tipo inesperado.
class Json {
  const Json._();

  static int asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static int? asIntOrNull(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double asDouble(Object? value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static double? asDoubleOrNull(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String asString(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value is String ? value : '$value';
  }

  static String? asStringOrNull(Object? value) {
    if (value == null) return null;
    final text = value is String ? value : '$value';
    return text.isEmpty ? null : text;
  }

  static bool asBool(Object? value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  static DateTime? asDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  static List<String> asStringList(Object? value) {
    if (value is List) return value.map((item) => '$item').toList();
    return const [];
  }

  static List<Map<String, dynamic>> asMapList(Object? value) {
    if (value is List) return value.whereType<Map<String, dynamic>>().toList();
    return const [];
  }

  static Map<String, dynamic> asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((key, item) => MapEntry('$key', item));
    return const {};
  }

  /// Data no formato `AAAA-MM-DD` aceito pela API.
  static String? dateOnly(DateTime? value) {
    if (value == null) return null;
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
