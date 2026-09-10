import '../core/network/api_client.dart';
import '../core/network/paginated.dart';
import '../models/client.dart';
import '../models/json_utils.dart';

class ClientRepository {
  const ClientRepository(this._api);

  final ApiClient _api;

  Future<Paginated<Client>> list({
    int page = 1,
    int pageSize = 20,
    String? search,
    int? branchId,
    String ordering = 'user__first_name',
  }) async {
    final data = await _api.get(
      '/clients/',
      query: {
        'page': page,
        'page_size': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
        if (branchId != null) 'preferred_branch': branchId,
        'ordering': ordering,
      },
    );
    return Paginated.fromResponse<Client>(data, Client.fromJson);
  }

  Future<Client> detail(int id) async {
    final data = await _api.get('/clients/$id/');
    return Client.fromJson(Json.asMap(data));
  }

  Future<Client> me() async {
    final data = await _api.get('/clients/me/');
    return Client.fromJson(Json.asMap(data));
  }

  Future<Client> updateMe(Map<String, dynamic> payload) async {
    final data = await _api.patch('/clients/me/', data: payload);
    return Client.fromJson(Json.asMap(data));
  }

  /// Cadastro de cliente pelo balcão (OWNER/BARBER).
  Future<Client> create({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    int? preferredBranchId,
    DateTime? birthDate,
    String notes = '',
  }) async {
    final data = await _api.post(
      '/clients/',
      data: {
        'user': {
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'email': email.trim().toLowerCase(),
          'phone': phone.replaceAll(RegExp(r'\D'), ''),
        },
        if (preferredBranchId != null) 'preferred_branch': preferredBranchId,
        if (birthDate != null) 'birth_date': Json.dateOnly(birthDate),
        if (notes.isNotEmpty) 'notes': notes,
      },
    );
    return Client.fromJson(Json.asMap(data));
  }

  Future<Client> update(int id, Map<String, dynamic> payload) async {
    final data = await _api.patch('/clients/$id/', data: payload);
    return Client.fromJson(Json.asMap(data));
  }
}
