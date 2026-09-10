import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/appointment.dart';
import 'core_providers.dart';

/// Data selecionada na agenda (barbeiro/proprietário).
final agendaDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Filial selecionada nos filtros de agenda/relatórios (null = todas).
final selectedBranchFilterProvider = StateProvider<int?>((ref) => null);

/// Agenda do dia, respeitando os filtros ativos.
final agendaProvider = FutureProvider<DayAgenda>((ref) {
  final date = ref.watch(agendaDateProvider);
  final branchId = ref.watch(selectedBranchFilterProvider);
  return ref.watch(appointmentRepositoryProvider).agenda(
        date: date,
        branchId: branchId,
      );
});

/// Próximos agendamentos do usuário autenticado.
final upcomingAppointmentsProvider = FutureProvider<List<Appointment>>((ref) {
  return ref.watch(appointmentRepositoryProvider).upcoming();
});

/// Histórico de atendimentos concluídos.
final appointmentHistoryProvider = FutureProvider<List<Appointment>>((ref) {
  return ref.watch(appointmentRepositoryProvider).history();
});

final appointmentDetailProvider =
    FutureProvider.family<Appointment, int>((ref, id) {
  return ref.watch(appointmentRepositoryProvider).detail(id);
});

/// Filtros da listagem de agendamentos do painel.
class AppointmentQuery {
  const AppointmentQuery({
    this.page = 1,
    this.statuses = const [],
    this.branchId,
    this.barberId,
    this.dateFrom,
    this.dateTo,
    this.search,
  });

  final int page;
  final List<String> statuses;
  final int? branchId;
  final int? barberId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? search;

  AppointmentQuery copyWith({
    int? page,
    List<String>? statuses,
    int? branchId,
    int? barberId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    bool clearBranch = false,
    bool clearBarber = false,
    bool clearDates = false,
  }) {
    return AppointmentQuery(
      page: page ?? this.page,
      statuses: statuses ?? this.statuses,
      branchId: clearBranch ? null : (branchId ?? this.branchId),
      barberId: clearBarber ? null : (barberId ?? this.barberId),
      dateFrom: clearDates ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDates ? null : (dateTo ?? this.dateTo),
      search: search ?? this.search,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppointmentQuery &&
      other.page == page &&
      other.branchId == branchId &&
      other.barberId == barberId &&
      other.dateFrom == dateFrom &&
      other.dateTo == dateTo &&
      other.search == search &&
      other.statuses.join(',') == statuses.join(',');

  @override
  int get hashCode => Object.hash(
        page,
        branchId,
        barberId,
        dateFrom,
        dateTo,
        search,
        statuses.join(','),
      );
}

final appointmentQueryProvider =
    StateProvider<AppointmentQuery>((ref) => const AppointmentQuery());

final appointmentListProvider = FutureProvider((ref) {
  final query = ref.watch(appointmentQueryProvider);
  return ref.watch(appointmentRepositoryProvider).list(
        page: query.page,
        statuses: query.statuses,
        branchId: query.branchId,
        barberId: query.barberId,
        dateFrom: query.dateFrom,
        dateTo: query.dateTo,
        search: query.search,
      );
});

/// Invalida tudo que depende de agendamentos após uma alteração.
void invalidateAppointmentData(WidgetRef ref) {
  ref.invalidate(agendaProvider);
  ref.invalidate(upcomingAppointmentsProvider);
  ref.invalidate(appointmentListProvider);
  ref.invalidate(appointmentHistoryProvider);
}
