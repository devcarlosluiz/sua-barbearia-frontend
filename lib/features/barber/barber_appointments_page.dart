import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/paginated.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/appointment.dart';
import '../../providers/appointment_providers.dart';
import '../../widgets/widgets.dart';
import '../shared/appointment_card.dart';
import '../shared/attendance_actions.dart';

/// Histórico e busca de atendimentos do barbeiro.
class BarberAppointmentsPage extends ConsumerWidget {
  const BarberAppointmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(appointmentQueryProvider);
    final appointments = ref.watch(appointmentListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: Column(
            children: [
              AppSearchField(
                hint: 'Buscar por cliente ou serviço',
                onSearch: (value) => ref
                    .read(appointmentQueryProvider.notifier)
                    .update((state) => state.copyWith(search: value, page: 1)),
              ),
              const SizedBox(height: AppSpacing.xs),
              _StatusFilterBar(
                selected: query.statuses,
                onChanged: (statuses) => ref
                    .read(appointmentQueryProvider.notifier)
                    .update(
                        (state) => state.copyWith(statuses: statuses, page: 1)),
              ),
            ],
          ),
        ),
        Expanded(
          child: AsyncView<Paginated<Appointment>>(
            value: appointments,
            onRetry: () => ref.invalidate(appointmentListProvider),
            emptyMessage: 'Nenhum atendimento encontrado com estes filtros.',
            isEmpty: (page) => page.isEmpty,
            builder: (page) => ListView(
              padding: Responsive.pagePadding(context),
              children: [
                ...page.results.map(
                  (appointment) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppointmentCard(
                      appointment: appointment,
                      showBarber: false,
                      actions: [AttendanceActions(appointment: appointment)],
                    ),
                  ),
                ),
                AppPagination(
                  currentPage: page.currentPage,
                  totalPages: page.totalPages,
                  totalCount: page.count,
                  onPageChanged: (value) => ref
                      .read(appointmentQueryProvider.notifier)
                      .update((state) => state.copyWith(page: value)),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Filtro por status em forma de chips.
class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({required this.selected, required this.onChanged});

  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('Todos'),
            selected: selected.isEmpty,
            onSelected: (_) => onChanged(const []),
          ),
          const SizedBox(width: AppSpacing.xxs),
          ...AppointmentStatus.values.map(
            (status) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xxs),
              child: FilterChip(
                label: Text(status.label),
                selected: selected.contains(status.value),
                onSelected: (isSelected) {
                  final updated = [...selected];
                  if (isSelected) {
                    updated.add(status.value);
                  } else {
                    updated.remove(status.value);
                  }
                  onChanged(updated);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
