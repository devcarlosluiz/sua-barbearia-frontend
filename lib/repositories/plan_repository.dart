import '../core/network/api_client.dart';
import '../core/network/paginated.dart';
import '../models/json_utils.dart';
import '../models/plan.dart';

/// Planos mensais e assinaturas.
class PlanRepository {
  const PlanRepository(this._api);

  final ApiClient _api;

  // ------------------------------------------------------------------
  // Planos
  // ------------------------------------------------------------------
  Future<List<Plan>> plans({bool? isActive, String? search}) async {
    final data = await _api.get(
      '/plans/',
      query: {
        if (isActive != null) 'is_active': isActive,
        if (search != null && search.isNotEmpty) 'search': search,
        'page_size': 100,
      },
    );
    return Paginated.fromResponse<Plan>(data, Plan.fromJson).results;
  }

  /// Detalhe completo. A listagem não traz `pays_barber_commission`, então o
  /// formulário de edição precisa buscar isto — o mesmo cuidado dos barbeiros.
  Future<Plan> plan(int id) async {
    final data = await _api.get('/plans/$id/');
    return Plan.fromJson(Json.asMap(data));
  }

  Future<Plan> createPlan(Map<String, dynamic> payload) async {
    final data = await _api.post('/plans/', data: payload);
    return Plan.fromJson(Json.asMap(data));
  }

  Future<Plan> updatePlan(int id, Map<String, dynamic> payload) async {
    final data = await _api.patch('/plans/$id/', data: payload);
    return Plan.fromJson(Json.asMap(data));
  }

  Future<void> deletePlan(int id) => _api.delete('/plans/$id/');

  Future<List<Subscription>> planSubscribers(int planId) async {
    final data = await _api.get('/plans/$planId/subscribers/');
    return Json.asMapList(data).map(Subscription.fromJson).toList();
  }

  // ------------------------------------------------------------------
  // Assinaturas
  // ------------------------------------------------------------------
  Future<List<Subscription>> subscriptions(
      {String? status, int? planId}) async {
    final data = await _api.get(
      '/subscriptions/',
      query: {
        if (status != null) 'status': status,
        if (planId != null) 'plan': planId,
        'page_size': 100,
      },
    );
    return Paginated.fromResponse<Subscription>(data, Subscription.fromJson)
        .results;
  }

  /// Assinatura viva do cliente logado. Devolve `null` quando não há nenhuma.
  Future<Subscription?> mySubscription() async {
    final data = await _api.get('/subscriptions/me/');
    final map = Json.asMap(data);
    return map.isEmpty ? null : Subscription.fromJson(map);
  }

  Future<Subscription> subscribe({
    required int planId,
    required BillingType billingType,
    int? branchId,
  }) async {
    final data = await _api.post(
      '/subscriptions/subscribe/',
      data: {
        'plan': planId,
        'billing_type': billingType.wire,
        if (branchId != null) 'branch': branchId,
      },
    );
    return Subscription.fromJson(Json.asMap(data));
  }

  Future<Subscription> cancel(int id, {bool immediate = false}) async {
    final data = await _api.post(
      '/subscriptions/$id/cancel/',
      data: {'immediate': immediate},
    );
    return Subscription.fromJson(Json.asMap(data));
  }

  /// Reemite o QR do PIX quando o anterior expirou.
  Future<SubscriptionInvoice> renewPix(int subscriptionId) async {
    final data = await _api.post('/subscriptions/$subscriptionId/renew-pix/');
    return SubscriptionInvoice.fromJson(Json.asMap(data));
  }

  // ------------------------------------------------------------------
  // Faturas
  // ------------------------------------------------------------------
  Future<Paginated<SubscriptionInvoice>> invoices({
    int page = 1,
    String? status,
    int? subscriptionId,
  }) async {
    final data = await _api.get(
      '/subscription-invoices/',
      query: {
        'page': page,
        if (status != null) 'status': status,
        if (subscriptionId != null) 'subscription': subscriptionId,
      },
    );
    return Paginated.fromResponse<SubscriptionInvoice>(
      data,
      SubscriptionInvoice.fromJson,
    );
  }

  /// Confirmação manual no caixa (OWNER).
  Future<SubscriptionInvoice> confirmInvoice(int id, {String? notes}) async {
    final data = await _api.post(
      '/subscription-invoices/$id/confirm/',
      data: {if (notes != null && notes.isNotEmpty) 'notes': notes},
    );
    return SubscriptionInvoice.fromJson(Json.asMap(data));
  }
}
