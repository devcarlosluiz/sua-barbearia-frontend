import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard.dart';
import 'core_providers.dart';

/// Períodos disponíveis nos filtros dos dashboards.
enum DashboardPeriod {
  today('today', 'Hoje'),
  week('7d', '7 dias'),
  month('30d', '30 dias'),
  thisMonth('this_month', 'Este mês'),
  lastMonth('last_month', 'Mês anterior'),
  custom('custom', 'Personalizado');

  const DashboardPeriod(this.value, this.label);

  final String value;
  final String label;
}

class DashboardFilter {
  const DashboardFilter({
    this.period = DashboardPeriod.month,
    this.startDate,
    this.endDate,
    this.branchId,
    this.barberId,
    this.serviceId,
  });

  final DashboardPeriod period;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? branchId;
  final int? barberId;
  final int? serviceId;

  bool get isCustom => period == DashboardPeriod.custom;

  DashboardFilter copyWith({
    DashboardPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    int? branchId,
    int? barberId,
    int? serviceId,
    bool clearBranch = false,
    bool clearBarber = false,
    bool clearService = false,
    bool clearDates = false,
  }) {
    return DashboardFilter(
      period: period ?? this.period,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      branchId: clearBranch ? null : (branchId ?? this.branchId),
      barberId: clearBarber ? null : (barberId ?? this.barberId),
      serviceId: clearService ? null : (serviceId ?? this.serviceId),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DashboardFilter &&
      other.period == period &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.branchId == branchId &&
      other.barberId == barberId &&
      other.serviceId == serviceId;

  @override
  int get hashCode =>
      Object.hash(period, startDate, endDate, branchId, barberId, serviceId);
}

final dashboardFilterProvider =
    StateProvider<DashboardFilter>((ref) => const DashboardFilter());

final ownerDashboardProvider = FutureProvider<OwnerDashboard>((ref) {
  final filter = ref.watch(dashboardFilterProvider);
  return ref.watch(dashboardRepositoryProvider).owner(
        period: filter.period.value,
        startDate: filter.isCustom ? filter.startDate : null,
        endDate: filter.isCustom ? filter.endDate : null,
        branchId: filter.branchId,
        barberId: filter.barberId,
        serviceId: filter.serviceId,
      );
});

final barberDashboardProvider = FutureProvider<BarberDashboard>((ref) {
  final filter = ref.watch(dashboardFilterProvider);
  return ref
      .watch(dashboardRepositoryProvider)
      .barber(period: filter.period.value);
});

final clientDashboardProvider = FutureProvider<ClientDashboard>((ref) {
  return ref.watch(dashboardRepositoryProvider).client();
});
