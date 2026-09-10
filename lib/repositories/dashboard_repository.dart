import '../core/network/api_client.dart';
import '../models/dashboard.dart';
import '../models/json_utils.dart';

class DashboardRepository {
  const DashboardRepository(this._api);

  final ApiClient _api;

  Future<OwnerDashboard> owner({
    String period = '30d',
    DateTime? startDate,
    DateTime? endDate,
    int? branchId,
    int? barberId,
    int? serviceId,
  }) async {
    final data = await _api.get(
      '/dashboard/owner/',
      query: {
        if (startDate == null && endDate == null) 'period': period,
        if (startDate != null) 'start_date': Json.dateOnly(startDate),
        if (endDate != null) 'end_date': Json.dateOnly(endDate),
        if (branchId != null) 'branch': branchId,
        if (barberId != null) 'barber': barberId,
        if (serviceId != null) 'service': serviceId,
      },
    );
    return OwnerDashboard.fromJson(Json.asMap(data));
  }

  Future<BarberDashboard> barber({String period = '30d'}) async {
    final data =
        await _api.get('/dashboard/barber/', query: {'period': period});
    return BarberDashboard.fromJson(Json.asMap(data));
  }

  Future<ClientDashboard> client() async {
    final data = await _api.get('/dashboard/client/');
    return ClientDashboard.fromJson(Json.asMap(data));
  }
}
