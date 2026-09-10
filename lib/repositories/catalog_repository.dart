import '../core/network/api_client.dart';
import '../core/network/paginated.dart';
import '../models/barber.dart';
import '../models/branch.dart';
import '../models/json_utils.dart';
import '../models/service.dart';

/// Filiais, serviços e barbeiros — o catálogo usado no fluxo de agendamento
/// e nas telas de gestão do proprietário.
class CatalogRepository {
  const CatalogRepository(this._api);

  final ApiClient _api;

  // ------------------------------------------------------------------
  // Filiais
  // ------------------------------------------------------------------
  Future<List<Branch>> branches(
      {bool onlyActive = true, String? search}) async {
    final data = await _api.get(
      '/branches/',
      query: {
        if (onlyActive) 'is_active': 'true',
        if (search != null && search.isNotEmpty) 'search': search,
        'page_size': 100,
      },
    );
    return Paginated.fromResponse<Branch>(data, Branch.fromJson).results;
  }

  /// Filiais ativas sem exigir autenticação (usado na tela de cadastro).
  Future<List<Branch>> publicBranches() async {
    final data = await _api.get('/branches/public/');
    return Json.asMapList(data).map(Branch.fromJson).toList();
  }

  Future<Branch> branch(int id) async {
    final data = await _api.get('/branches/$id/');
    return Branch.fromJson(Json.asMap(data));
  }

  Future<Branch> createBranch(Map<String, dynamic> payload) async {
    final data = await _api.post('/branches/', data: payload);
    return Branch.fromJson(Json.asMap(data));
  }

  Future<Branch> updateBranch(int id, Map<String, dynamic> payload) async {
    final data = await _api.patch('/branches/$id/', data: payload);
    return Branch.fromJson(Json.asMap(data));
  }

  Future<void> deleteBranch(int id) => _api.delete('/branches/$id/');

  Future<List<OpeningHour>> openingHours(int branchId) async {
    final data = await _api.get('/branches/$branchId/opening-hours/');
    return Json.asMapList(data).map(OpeningHour.fromJson).toList();
  }

  // ------------------------------------------------------------------
  // Serviços
  // ------------------------------------------------------------------
  Future<List<Service>> services({
    int? branchId,
    int? barberId,
    bool onlyActive = true,
    String? search,
  }) async {
    final data = await _api.get(
      '/services/',
      query: {
        if (branchId != null) 'branch': branchId,
        if (barberId != null) 'barber': barberId,
        if (onlyActive) 'is_active': 'true',
        if (search != null && search.isNotEmpty) 'search': search,
        'page_size': 100,
      },
    );
    return Paginated.fromResponse<Service>(data, Service.fromJson).results;
  }

  Future<Service> createService(Map<String, dynamic> payload) async {
    final data = await _api.post('/services/', data: payload);
    return Service.fromJson(Json.asMap(data));
  }

  Future<Service> updateService(int id, Map<String, dynamic> payload) async {
    final data = await _api.patch('/services/$id/', data: payload);
    return Service.fromJson(Json.asMap(data));
  }

  Future<void> deleteService(int id) => _api.delete('/services/$id/');

  Future<List<ServiceCategory>> serviceCategories() async {
    final data =
        await _api.get('/service-categories/', query: {'page_size': 100});
    return Paginated.fromResponse<ServiceCategory>(
            data, ServiceCategory.fromJson)
        .results;
  }

  // ------------------------------------------------------------------
  // Barbeiros
  // ------------------------------------------------------------------
  Future<List<Barber>> barbers({
    int? branchId,
    int? serviceId,
    bool onlyActive = true,
    String? search,
  }) async {
    final data = await _api.get(
      '/barbers/',
      query: {
        if (branchId != null) 'branch': branchId,
        if (serviceId != null) 'service': serviceId,
        if (onlyActive) 'is_active': 'true',
        if (search != null && search.isNotEmpty) 'search': search,
        'page_size': 100,
      },
    );
    return Paginated.fromResponse<Barber>(data, Barber.fromJson).results;
  }

  Future<Barber> barber(int id) async {
    final data = await _api.get('/barbers/$id/');
    return Barber.fromJson(Json.asMap(data));
  }

  Future<List<BarberService>> barberServices(int barberId) async {
    final data = await _api.get('/barbers/$barberId/services/');
    return Json.asMapList(data).map(BarberService.fromJson).toList();
  }

  Future<Barber> createBarber(Map<String, dynamic> payload) async {
    final data = await _api.post('/barbers/', data: payload);
    return Barber.fromJson(Json.asMap(data));
  }

  Future<Barber> updateBarber(int id, Map<String, dynamic> payload) async {
    final data = await _api.patch('/barbers/$id/', data: payload);
    return Barber.fromJson(Json.asMap(data));
  }

  Future<void> deleteBarber(int id) => _api.delete('/barbers/$id/');

  // ------------------------------------------------------------------
  // Jornada e ausências
  // ------------------------------------------------------------------
  Future<List<WorkingHour>> workingHours({int? barberId, int? branchId}) async {
    final data = await _api.get(
      '/working-hours/',
      query: {
        if (barberId != null) 'barber': barberId,
        if (branchId != null) 'branch': branchId,
      },
    );
    return Paginated.fromResponse<WorkingHour>(data, WorkingHour.fromJson)
        .results;
  }

  Future<WorkingHour> saveWorkingHour(Map<String, dynamic> payload,
      {int? id}) async {
    final data = id == null
        ? await _api.post('/working-hours/', data: payload)
        : await _api.patch('/working-hours/$id/', data: payload);
    return WorkingHour.fromJson(Json.asMap(data));
  }

  Future<void> deleteWorkingHour(int id) => _api.delete('/working-hours/$id/');

  Future<List<TimeOff>> timeOffs({int? barberId}) async {
    final data = await _api.get(
      '/time-offs/',
      query: {if (barberId != null) 'barber': barberId},
    );
    return Paginated.fromResponse<TimeOff>(data, TimeOff.fromJson).results;
  }

  Future<TimeOff> createTimeOff(Map<String, dynamic> payload) async {
    final data = await _api.post('/time-offs/', data: payload);
    return TimeOff.fromJson(Json.asMap(data));
  }

  Future<void> deleteTimeOff(int id) => _api.delete('/time-offs/$id/');
}
