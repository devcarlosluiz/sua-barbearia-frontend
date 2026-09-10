import '../core/network/api_client.dart';
import '../core/network/paginated.dart';
import '../models/appointment.dart';
import '../models/json_utils.dart';

class AppointmentRepository {
  const AppointmentRepository(this._api);

  final ApiClient _api;

  /// Horários livres para a combinação filial + barbeiro + serviço + data.
  Future<AvailableSlots> availableSlots({
    required int branchId,
    required int barberId,
    required int serviceId,
    required DateTime date,
  }) async {
    final data = await _api.get(
      '/appointments/available-slots/',
      query: {
        'branch_id': branchId,
        'barber_id': barberId,
        'service_id': serviceId,
        'date': Json.dateOnly(date),
      },
    );
    return AvailableSlots.fromJson(Json.asMap(data));
  }

  Future<Appointment> create({
    required int branchId,
    required int barberId,
    required int serviceId,
    required DateTime date,
    required String startTime,
    int? clientId,
    String notes = '',
  }) async {
    final data = await _api.post(
      '/appointments/',
      data: {
        'branch_id': branchId,
        'barber_id': barberId,
        'service_id': serviceId,
        'date': Json.dateOnly(date),
        'start_time': startTime,
        if (clientId != null) 'client_id': clientId,
        if (notes.isNotEmpty) 'notes': notes,
      },
    );
    return Appointment.fromJson(Json.asMap(data));
  }

  Future<Paginated<Appointment>> list({
    int page = 1,
    int pageSize = 20,
    List<String>? statuses,
    DateTime? date,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? branchId,
    int? barberId,
    int? clientId,
    bool? upcoming,
    String? search,
    String ordering = '-date',
  }) async {
    final data = await _api.get(
      '/appointments/',
      query: {
        'page': page,
        'page_size': pageSize,
        if (statuses != null && statuses.isNotEmpty) 'status': statuses,
        if (date != null) 'date': Json.dateOnly(date),
        if (dateFrom != null) 'date_from': Json.dateOnly(dateFrom),
        if (dateTo != null) 'date_to': Json.dateOnly(dateTo),
        if (branchId != null) 'branch': branchId,
        if (barberId != null) 'barber': barberId,
        if (clientId != null) 'client': clientId,
        if (upcoming != null) 'upcoming': upcoming,
        if (search != null && search.isNotEmpty) 'search': search,
        'ordering': ordering,
      },
    );
    return Paginated.fromResponse<Appointment>(data, Appointment.fromJson);
  }

  Future<Appointment> detail(int id) async {
    final data = await _api.get('/appointments/$id/');
    return Appointment.fromJson(Json.asMap(data));
  }

  Future<DayAgenda> agenda(
      {DateTime? date, int? branchId, int? barberId}) async {
    final data = await _api.get(
      '/appointments/agenda/',
      query: {
        if (date != null) 'date': Json.dateOnly(date),
        if (branchId != null) 'branch_id': branchId,
        if (barberId != null) 'barber_id': barberId,
      },
    );
    return DayAgenda.fromJson(Json.asMap(data));
  }

  Future<List<Appointment>> upcoming() async {
    final data = await _api.get('/appointments/upcoming/');
    return Json.asMapList(data).map(Appointment.fromJson).toList();
  }

  Future<List<Appointment>> history() async {
    final data = await _api.get('/appointments/history/');
    return Json.asMapList(data).map(Appointment.fromJson).toList();
  }

  Future<Appointment> cancel(int id, {String reason = ''}) async {
    final data = await _api.post(
      '/appointments/$id/cancel/',
      data: {if (reason.isNotEmpty) 'reason': reason},
    );
    return Appointment.fromJson(Json.asMap(data));
  }

  /// Apaga o agendamento. Só o proprietário pode, e só antes de concluir.
  ///
  /// Diferente de [cancel]: cancelar guarda o registro com o motivo, excluir
  /// some com ele. Não devolve o agendamento — ele deixou de existir.
  Future<void> delete(int id) => _api.delete('/appointments/$id/');

  Future<Appointment> reschedule(
    int id, {
    required DateTime date,
    required String startTime,
    int? barberId,
    String reason = '',
  }) async {
    final data = await _api.post(
      '/appointments/$id/reschedule/',
      data: {
        'date': Json.dateOnly(date),
        'start_time': startTime,
        if (barberId != null) 'barber_id': barberId,
        if (reason.isNotEmpty) 'reason': reason,
      },
    );
    return Appointment.fromJson(Json.asMap(data));
  }

  Future<Appointment> confirm(int id) => _changeStatus(id, 'CONFIRMED');

  Future<Appointment> arrive(int id) async {
    final data = await _api.post('/appointments/$id/arrive/');
    return Appointment.fromJson(Json.asMap(data));
  }

  Future<Appointment> start(int id) async {
    final data = await _api.post('/appointments/$id/start/');
    return Appointment.fromJson(Json.asMap(data));
  }

  Future<Appointment> noShow(int id) async {
    final data = await _api.post('/appointments/$id/no-show/');
    return Appointment.fromJson(Json.asMap(data));
  }

  Future<Appointment> complete(
    int id, {
    required String paymentMethod,
    double? amount,
    double discountAmount = 0,
    String notes = '',
  }) async {
    final data = await _api.post(
      '/appointments/$id/complete/',
      data: {
        'payment_method': paymentMethod,
        if (amount != null) 'amount': amount.toStringAsFixed(2),
        'discount_amount': discountAmount.toStringAsFixed(2),
        if (notes.isNotEmpty) 'notes': notes,
      },
    );
    return Appointment.fromJson(Json.asMap(data));
  }

  Future<Appointment> _changeStatus(int id, String status,
      {String reason = ''}) async {
    final data = await _api.post(
      '/appointments/$id/status/',
      data: {'status': status, if (reason.isNotEmpty) 'reason': reason},
    );
    return Appointment.fromJson(Json.asMap(data));
  }
}
