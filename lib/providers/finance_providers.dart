import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/paginated.dart';
import '../models/finance.dart';
import 'core_providers.dart';
import 'dashboard_providers.dart';

class FinanceFilter {
  const FinanceFilter({
    this.page = 1,
    this.period = DashboardPeriod.month,
    this.startDate,
    this.endDate,
    this.branchId,
    this.type,
    this.category,
    this.search,
  });

  final int page;
  final DashboardPeriod period;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? branchId;
  final String? type;
  final String? category;
  final String? search;

  bool get isCustom => period == DashboardPeriod.custom;

  FinanceFilter copyWith({
    int? page,
    DashboardPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    int? branchId,
    String? type,
    String? category,
    String? search,
    bool clearBranch = false,
    bool clearType = false,
    bool clearCategory = false,
  }) {
    return FinanceFilter(
      page: page ?? this.page,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      branchId: clearBranch ? null : (branchId ?? this.branchId),
      type: clearType ? null : (type ?? this.type),
      category: clearCategory ? null : (category ?? this.category),
      search: search ?? this.search,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FinanceFilter &&
      other.page == page &&
      other.period == period &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.branchId == branchId &&
      other.type == type &&
      other.category == category &&
      other.search == search;

  @override
  int get hashCode => Object.hash(
        page,
        period,
        startDate,
        endDate,
        branchId,
        type,
        category,
        search,
      );
}

final financeFilterProvider =
    StateProvider<FinanceFilter>((ref) => const FinanceFilter());

final cashFlowSummaryProvider = FutureProvider<CashFlowSummary>((ref) {
  final filter = ref.watch(financeFilterProvider);
  return ref.watch(financeRepositoryProvider).summary(
        period: filter.period.value,
        startDate: filter.isCustom ? filter.startDate : null,
        endDate: filter.isCustom ? filter.endDate : null,
        branchId: filter.branchId,
      );
});

final transactionsProvider =
    FutureProvider<Paginated<FinanceTransaction>>((ref) {
  final filter = ref.watch(financeFilterProvider);
  return ref.watch(financeRepositoryProvider).transactions(
        page: filter.page,
        type: filter.type,
        category: filter.category,
        branchId: filter.branchId,
        search: filter.search,
      );
});

/// Filtros da tela de comissões.
class CommissionFilter {
  const CommissionFilter(
      {this.page = 1, this.barberId, this.status = 'PENDING'});

  final int page;
  final int? barberId;
  final String? status;

  CommissionFilter copyWith(
      {int? page, int? barberId, String? status, bool clearStatus = false}) {
    return CommissionFilter(
      page: page ?? this.page,
      barberId: barberId ?? this.barberId,
      status: clearStatus ? null : (status ?? this.status),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CommissionFilter &&
      other.page == page &&
      other.barberId == barberId &&
      other.status == status;

  @override
  int get hashCode => Object.hash(page, barberId, status);
}

final commissionFilterProvider =
    StateProvider<CommissionFilter>((ref) => const CommissionFilter());

final commissionsProvider = FutureProvider<Paginated<Commission>>((ref) {
  final filter = ref.watch(commissionFilterProvider);
  return ref.watch(financeRepositoryProvider).commissions(
        page: filter.page,
        barberId: filter.barberId,
        status: filter.status,
      );
});

final financeChoicesProvider =
    FutureProvider<Map<String, List<Map<String, String>>>>((ref) {
  return ref.watch(financeRepositoryProvider).choices();
});
