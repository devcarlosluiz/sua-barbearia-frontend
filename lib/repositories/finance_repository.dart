import '../core/network/api_client.dart';
import '../core/network/paginated.dart';
import '../models/finance.dart';
import '../models/json_utils.dart';
import '../models/payment.dart';

class FinanceRepository {
  const FinanceRepository(this._api);

  final ApiClient _api;

  // ------------------------------------------------------------------
  // Lançamentos
  // ------------------------------------------------------------------
  Future<Paginated<FinanceTransaction>> transactions({
    int page = 1,
    int pageSize = 20,
    String? type,
    String? category,
    int? branchId,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
  }) async {
    final data = await _api.get(
      '/finance/transactions/',
      query: {
        'page': page,
        'page_size': pageSize,
        if (type != null) 'type': type,
        if (category != null) 'category': category,
        if (branchId != null) 'branch': branchId,
        if (startDate != null) 'start_date': Json.dateOnly(startDate),
        if (endDate != null) 'end_date': Json.dateOnly(endDate),
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return Paginated.fromResponse<FinanceTransaction>(
      data,
      FinanceTransaction.fromJson,
    );
  }

  Future<FinanceTransaction> createTransaction({
    required int branchId,
    required String type,
    required String category,
    required String description,
    required double amount,
    required DateTime date,
    int? barberId,
    String notes = '',
  }) async {
    final data = await _api.post(
      '/finance/transactions/',
      data: {
        'branch': branchId,
        'type': type,
        'category': category,
        'description': description,
        'amount': amount.toStringAsFixed(2),
        'date': Json.dateOnly(date),
        if (barberId != null) 'barber': barberId,
        if (notes.isNotEmpty) 'notes': notes,
      },
    );
    return FinanceTransaction.fromJson(Json.asMap(data));
  }

  Future<void> deleteTransaction(int id) =>
      _api.delete('/finance/transactions/$id/');

  Future<CashFlowSummary> summary({
    String period = '30d',
    DateTime? startDate,
    DateTime? endDate,
    int? branchId,
  }) async {
    final data = await _api.get(
      '/finance/transactions/summary/',
      query: {
        if (startDate == null && endDate == null) 'period': period,
        if (startDate != null) 'start_date': Json.dateOnly(startDate),
        if (endDate != null) 'end_date': Json.dateOnly(endDate),
        if (branchId != null) 'branch': branchId,
      },
    );
    return CashFlowSummary.fromJson(Json.asMap(data));
  }

  Future<Map<String, List<Map<String, String>>>> choices() async {
    final data = Json.asMap(await _api.get('/finance/choices/'));
    Map<String, String> asChoice(Map<String, dynamic> item) => {
          'value': Json.asString(item['value']),
          'label': Json.asString(item['label']),
        };
    return {
      'types': Json.asMapList(data['types']).map(asChoice).toList(),
      'categories': Json.asMapList(data['categories']).map(asChoice).toList(),
      'commission_statuses':
          Json.asMapList(data['commission_statuses']).map(asChoice).toList(),
    };
  }

  // ------------------------------------------------------------------
  // Comissões
  // ------------------------------------------------------------------
  Future<Paginated<Commission>> commissions({
    int page = 1,
    int pageSize = 20,
    int? barberId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final data = await _api.get(
      '/finance/commissions/',
      query: {
        'page': page,
        'page_size': pageSize,
        if (barberId != null) 'barber': barberId,
        if (status != null) 'status': status,
        if (startDate != null) 'start_date': Json.dateOnly(startDate),
        if (endDate != null) 'end_date': Json.dateOnly(endDate),
      },
    );
    return Paginated.fromResponse<Commission>(data, Commission.fromJson);
  }

  Future<Map<String, dynamic>> commissionSummary({
    String period = '30d',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final data = await _api.get(
      '/finance/commissions/summary/',
      query: {
        if (startDate == null && endDate == null) 'period': period,
        if (startDate != null) 'start_date': Json.dateOnly(startDate),
        if (endDate != null) 'end_date': Json.dateOnly(endDate),
      },
    );
    return Json.asMap(data);
  }

  Future<Map<String, dynamic>> payCommissions(List<int> ids) async {
    final data = await _api.post(
      '/finance/commissions/pay/',
      data: {'commission_ids': ids},
    );
    return Json.asMap(data);
  }

  // ------------------------------------------------------------------
  // Pagamentos
  // ------------------------------------------------------------------
  Future<Paginated<Payment>> payments({
    int page = 1,
    int pageSize = 20,
    int? branchId,
    String? method,
    String? status,
  }) async {
    final data = await _api.get(
      '/payments/',
      query: {
        'page': page,
        'page_size': pageSize,
        if (branchId != null) 'branch': branchId,
        if (method != null) 'method': method,
        if (status != null) 'status': status,
      },
    );
    return Paginated.fromResponse<Payment>(data, Payment.fromJson);
  }

  Future<Payment> refund(int paymentId, {String reason = ''}) async {
    final data = await _api.post(
      '/payments/$paymentId/refund/',
      data: {if (reason.isNotEmpty) 'reason': reason},
    );
    return Payment.fromJson(Json.asMap(data));
  }
}
