import '../core/network/api_client.dart';
import '../core/network/paginated.dart';
import '../models/appointment.dart';
import '../models/json_utils.dart';
import '../models/loyalty.dart';
import '../models/notification.dart';
import '../models/review.dart';

/// Fidelidade, avaliações e notificações — o relacionamento com o cliente.
class EngagementRepository {
  const EngagementRepository(this._api);

  final ApiClient _api;

  // ------------------------------------------------------------------
  // Fidelidade
  // ------------------------------------------------------------------
  Future<LoyaltySummary> myLoyalty() async {
    final data = await _api.get('/loyalty/accounts/me/');
    return LoyaltySummary.fromJson(Json.asMap(data));
  }

  Future<List<LoyaltyReward>> rewards({bool onlyActive = true}) async {
    final data = await _api.get(
      '/loyalty/rewards/',
      query: {if (onlyActive) 'is_active': 'true', 'page_size': 100},
    );
    return Paginated.fromResponse<LoyaltyReward>(data, LoyaltyReward.fromJson)
        .results;
  }

  Future<LoyaltyReward> saveReward(Map<String, dynamic> payload,
      {int? id}) async {
    final data = id == null
        ? await _api.post('/loyalty/rewards/', data: payload)
        : await _api.patch('/loyalty/rewards/$id/', data: payload);
    return LoyaltyReward.fromJson(Json.asMap(data));
  }

  Future<LoyaltyTransaction> redeem(int rewardId, {int? clientId}) async {
    final data = await _api.post(
      '/loyalty/rewards/redeem/',
      data: {
        'reward_id': rewardId,
        if (clientId != null) 'client_id': clientId
      },
    );
    return LoyaltyTransaction.fromJson(Json.asMap(data));
  }

  Future<LoyaltyTransaction> adjustPoints({
    required int clientId,
    required int points,
    required String description,
  }) async {
    final data = await _api.post(
      '/loyalty/rewards/adjust/',
      data: {
        'client_id': clientId,
        'points': points,
        'description': description,
      },
    );
    return LoyaltyTransaction.fromJson(Json.asMap(data));
  }

  Future<Paginated<LoyaltyAccount>> loyaltyAccounts({
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await _api.get(
      '/loyalty/accounts/',
      query: {'page': page, 'page_size': pageSize},
    );
    return Paginated.fromResponse<LoyaltyAccount>(
        data, LoyaltyAccount.fromJson);
  }

  // ------------------------------------------------------------------
  // Avaliações
  // ------------------------------------------------------------------
  Future<Paginated<Review>> reviews({
    int page = 1,
    int pageSize = 20,
    int? barberId,
    int? branchId,
    int? rating,
  }) async {
    final data = await _api.get(
      '/reviews/',
      query: {
        'page': page,
        'page_size': pageSize,
        if (barberId != null) 'barber': barberId,
        if (branchId != null) 'branch': branchId,
        if (rating != null) 'rating': rating,
      },
    );
    return Paginated.fromResponse<Review>(data, Review.fromJson);
  }

  Future<Review> createReview({
    required int appointmentId,
    required int rating,
    String comment = '',
  }) async {
    final data = await _api.post(
      '/reviews/',
      data: {
        'appointment': appointmentId,
        'rating': rating,
        if (comment.isNotEmpty) 'comment': comment,
      },
    );
    return Review.fromJson(Json.asMap(data));
  }

  Future<Review> replyReview(int reviewId, String reply) async {
    final data =
        await _api.post('/reviews/$reviewId/reply/', data: {'reply': reply});
    return Review.fromJson(Json.asMap(data));
  }

  Future<ReviewSummary> reviewSummary({int? barberId, int? branchId}) async {
    final data = await _api.get(
      '/reviews/summary/',
      query: {
        if (barberId != null) 'barber': barberId,
        if (branchId != null) 'branch': branchId,
      },
    );
    return ReviewSummary.fromJson(Json.asMap(data));
  }

  /// Atendimentos concluídos que o cliente ainda não avaliou.
  Future<List<Appointment>> pendingReviews() async {
    final data = await _api.get('/reviews/pending/');
    return Json.asMapList(data).map(Appointment.fromJson).toList();
  }

  // ------------------------------------------------------------------
  // Notificações
  // ------------------------------------------------------------------
  Future<Paginated<AppNotification>> notifications({
    int page = 1,
    int pageSize = 20,
    bool unreadOnly = false,
  }) async {
    final data = await _api.get(
      '/notifications/',
      query: {
        'page': page,
        'page_size': pageSize,
        if (unreadOnly) 'unread': 'true',
      },
    );
    return Paginated.fromResponse<AppNotification>(
        data, AppNotification.fromJson);
  }

  Future<int> unreadCount() async {
    final data = Json.asMap(await _api.get('/notifications/unread-count/'));
    return Json.asInt(data['unread_count']);
  }

  Future<int> markRead({List<int>? ids}) async {
    final data = Json.asMap(
      await _api.post(
        '/notifications/mark-read/',
        data: {if (ids != null && ids.isNotEmpty) 'ids': ids},
      ),
    );
    return Json.asInt(data['updated']);
  }

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String deviceName = '',
  }) =>
      _api.post(
        '/device-tokens/',
        data: {
          'token': token,
          'platform': platform,
          if (deviceName.isNotEmpty) 'device_name': deviceName,
        },
      );
}
