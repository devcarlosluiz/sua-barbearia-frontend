import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/barber.dart';
import '../models/branch.dart';
import '../models/service.dart';
import 'auth_provider.dart';
import 'core_providers.dart';

/// Filiais visíveis ao usuário.
///
/// Sem sessão (tela de cadastro) usa o endpoint público; autenticado usa a
/// listagem completa, que já respeita as permissões do papel.
final branchesProvider = FutureProvider<List<Branch>>((ref) async {
  final repository = ref.watch(catalogRepositoryProvider);
  final isAuthenticated = ref.watch(authControllerProvider).isAuthenticated;
  return isAuthenticated ? repository.branches() : repository.publicBranches();
});

final branchDetailProvider = FutureProvider.family<Branch, int>((ref, id) {
  return ref.watch(catalogRepositoryProvider).branch(id);
});

final serviceCategoriesProvider = FutureProvider<List<ServiceCategory>>((ref) {
  return ref.watch(catalogRepositoryProvider).serviceCategories();
});

/// Parâmetros de filtro do catálogo de serviços/barbeiros.
class CatalogFilter {
  const CatalogFilter(
      {this.branchId, this.serviceId, this.barberId, this.search});

  final int? branchId;
  final int? serviceId;
  final int? barberId;
  final String? search;

  @override
  bool operator ==(Object other) =>
      other is CatalogFilter &&
      other.branchId == branchId &&
      other.serviceId == serviceId &&
      other.barberId == barberId &&
      other.search == search;

  @override
  int get hashCode => Object.hash(branchId, serviceId, barberId, search);
}

final servicesProvider =
    FutureProvider.family<List<Service>, CatalogFilter>((ref, filter) {
  return ref.watch(catalogRepositoryProvider).services(
        branchId: filter.branchId,
        barberId: filter.barberId,
        search: filter.search,
      );
});

/// Todos os serviços (inclusive inativos) — usado na gestão do proprietário.
final allServicesProvider = FutureProvider<List<Service>>((ref) {
  return ref.watch(catalogRepositoryProvider).services(onlyActive: false);
});

final barbersProvider =
    FutureProvider.family<List<Barber>, CatalogFilter>((ref, filter) {
  return ref.watch(catalogRepositoryProvider).barbers(
        branchId: filter.branchId,
        serviceId: filter.serviceId,
        search: filter.search,
      );
});

final allBarbersProvider = FutureProvider<List<Barber>>((ref) {
  return ref.watch(catalogRepositoryProvider).barbers(onlyActive: false);
});

final barberDetailProvider = FutureProvider.family<Barber, int>((ref, id) {
  return ref.watch(catalogRepositoryProvider).barber(id);
});

final barberServicesProvider =
    FutureProvider.family<List<BarberService>, int>((ref, barberId) {
  return ref.watch(catalogRepositoryProvider).barberServices(barberId);
});

final workingHoursProvider =
    FutureProvider.family<List<WorkingHour>, int>((ref, barberId) {
  return ref.watch(catalogRepositoryProvider).workingHours(barberId: barberId);
});

final timeOffsProvider =
    FutureProvider.family<List<TimeOff>, int?>((ref, barberId) {
  return ref.watch(catalogRepositoryProvider).timeOffs(barberId: barberId);
});
