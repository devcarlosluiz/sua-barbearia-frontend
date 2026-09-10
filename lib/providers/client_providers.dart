import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/paginated.dart';
import '../models/client.dart';
import 'core_providers.dart';

class ClientFilter {
  const ClientFilter({this.page = 1, this.search, this.branchId});

  final int page;
  final String? search;
  final int? branchId;

  ClientFilter copyWith({
    int? page,
    String? search,
    int? branchId,
    bool clearBranch = false,
  }) {
    return ClientFilter(
      page: page ?? this.page,
      search: search ?? this.search,
      branchId: clearBranch ? null : (branchId ?? this.branchId),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ClientFilter &&
      other.page == page &&
      other.search == search &&
      other.branchId == branchId;

  @override
  int get hashCode => Object.hash(page, search, branchId);
}

final clientFilterProvider =
    StateProvider<ClientFilter>((ref) => const ClientFilter());

final clientsProvider = FutureProvider<Paginated<Client>>((ref) {
  final filter = ref.watch(clientFilterProvider);
  return ref.watch(clientRepositoryProvider).list(
        page: filter.page,
        search: filter.search,
        branchId: filter.branchId,
      );
});

final clientDetailProvider = FutureProvider.family<Client, int>((ref, id) {
  return ref.watch(clientRepositoryProvider).detail(id);
});

/// Perfil do cliente autenticado.
final myClientProfileProvider = FutureProvider<Client>((ref) {
  return ref.watch(clientRepositoryProvider).me();
});
