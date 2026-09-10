/// Página de resultados devolvida pelas listagens da API.
class Paginated<T> {
  const Paginated({
    required this.results,
    required this.count,
    required this.currentPage,
    required this.totalPages,
    this.next,
    this.previous,
  });

  final List<T> results;
  final int count;
  final int currentPage;
  final int totalPages;
  final String? next;
  final String? previous;

  bool get hasNext => next != null;
  bool get hasPrevious => previous != null;
  bool get isEmpty => results.isEmpty;
  bool get isNotEmpty => results.isNotEmpty;

  static Paginated<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final rawResults = (json['results'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(itemFromJson)
        .toList();

    return Paginated<T>(
      results: rawResults,
      count: (json['count'] as num?)?.toInt() ?? rawResults.length,
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
    );
  }

  /// Constrói uma página a partir de uma resposta que pode vir paginada
  /// (`{count, results}`) ou como lista simples (endpoints sem paginação).
  static Paginated<T> fromResponse<T>(
    dynamic data,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    if (data is Map<String, dynamic>) {
      return fromJson<T>(data, itemFromJson);
    }
    final items = (data as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(itemFromJson)
        .toList();
    return Paginated<T>(
      results: items,
      count: items.length,
      currentPage: 1,
      totalPages: 1,
    );
  }

  Paginated<T> copyWithResults(List<T> newResults) => Paginated<T>(
        results: newResults,
        count: count,
        currentPage: currentPage,
        totalPages: totalPages,
        next: next,
        previous: previous,
      );
}
