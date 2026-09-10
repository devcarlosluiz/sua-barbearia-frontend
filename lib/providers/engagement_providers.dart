import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/appointment.dart';
import '../models/loyalty.dart';
import '../models/notification.dart';
import '../models/review.dart';
import 'core_providers.dart';

// ---------------------------------------------------------------------------
// Notificações
// ---------------------------------------------------------------------------
final notificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  final page = await ref.watch(engagementRepositoryProvider).notifications();
  return page.results;
});

final unreadNotificationsProvider = FutureProvider<int>((ref) {
  return ref.watch(engagementRepositoryProvider).unreadCount();
});

// ---------------------------------------------------------------------------
// Fidelidade
// ---------------------------------------------------------------------------
final myLoyaltyProvider = FutureProvider<LoyaltySummary>((ref) {
  return ref.watch(engagementRepositoryProvider).myLoyalty();
});

final loyaltyRewardsProvider = FutureProvider<List<LoyaltyReward>>((ref) {
  return ref.watch(engagementRepositoryProvider).rewards();
});

final allLoyaltyRewardsProvider = FutureProvider<List<LoyaltyReward>>((ref) {
  return ref.watch(engagementRepositoryProvider).rewards(onlyActive: false);
});

// ---------------------------------------------------------------------------
// Avaliações
// ---------------------------------------------------------------------------
final reviewsProvider =
    FutureProvider.family<List<Review>, int?>((ref, barberId) async {
  final page = await ref
      .watch(engagementRepositoryProvider)
      .reviews(barberId: barberId, pageSize: 50);
  return page.results;
});

final reviewSummaryProvider =
    FutureProvider.family<ReviewSummary, int?>((ref, barberId) {
  return ref
      .watch(engagementRepositoryProvider)
      .reviewSummary(barberId: barberId);
});

/// Atendimentos concluídos que o cliente ainda não avaliou.
final pendingReviewsProvider = FutureProvider<List<Appointment>>((ref) {
  return ref.watch(engagementRepositoryProvider).pendingReviews();
});
