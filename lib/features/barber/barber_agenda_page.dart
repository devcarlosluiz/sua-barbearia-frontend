import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/appointment.dart';
import '../../providers/appointment_providers.dart';
import '../../widgets/widgets.dart';
import '../shared/appointment_card.dart';
import '../shared/attendance_actions.dart';

/// Agenda diária do barbeiro, com as ações de atendimento.
class BarberAgendaPage extends ConsumerWidget {
  const BarberAgendaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(agendaDateProvider);
    final agenda = ref.watch(agendaProvider);

    return Column(
      children: [
        DaySelector(
          date: date,
          onChanged: (value) =>
              ref.read(agendaDateProvider.notifier).state = value,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(agendaProvider),
            child: AsyncView<DayAgenda>(
              value: agenda,
              onRetry: () => ref.invalidate(agendaProvider),
              emptyMessage: 'Nenhum atendimento marcado para este dia.',
              isEmpty: (data) => data.appointments.isEmpty,
              emptyIcon: Icons.event_available_outlined,
              builder: (data) => ListView(
                padding: Responsive.pagePadding(context),
                children: [
                  _AgendaSummary(appointments: data.appointments),
                  const SizedBox(height: AppSpacing.md),
                  ...data.appointments.map(
                    (appointment) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppointmentCard(
                        appointment: appointment,
                        showBarber: false,
                        showDate: false,
                        actions: [AttendanceActions(appointment: appointment)],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Seletor de dia com navegação rápida (anterior / hoje / próximo).
class DaySelector extends StatelessWidget {
  const DaySelector({super.key, required this.date, required this.onChanged});

  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Dia anterior',
            onPressed: () => onChanged(date.subtract(const Duration(days: 1))),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(today.year - 1),
                  lastDate: DateTime(today.year + 2),
                  locale: const Locale('pt', 'BR'),
                );
                if (picked != null) onChanged(picked);
              },
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Column(
                  children: [
                    Text(
                      Formatters.friendlyDate(date),
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      '${Formatters.weekday(date)}, ${Formatters.date(date)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!isToday)
            TextButton(
              onPressed: () =>
                  onChanged(DateTime(today.year, today.month, today.day)),
              child: const Text('Hoje'),
            ),
          IconButton(
            tooltip: 'Próximo dia',
            onPressed: () => onChanged(date.add(const Duration(days: 1))),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _AgendaSummary extends StatelessWidget {
  const _AgendaSummary({required this.appointments});

  final List<Appointment> appointments;

  @override
  Widget build(BuildContext context) {
    final completed = appointments
        .where((item) => item.status == AppointmentStatus.completed)
        .toList();
    final revenue = completed.fold<double>(0, (sum, item) => sum + item.price);
    final pending = appointments.where((item) => item.status.isActive).length;

    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Na agenda',
            value: '${appointments.length}',
            icon: Icons.event_note_rounded,
            compact: true,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: StatCard(
            label: 'Em aberto',
            value: '$pending',
            icon: Icons.pending_actions_rounded,
            accentColor: AppColors.warning,
            compact: true,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: StatCard(
            label: 'Recebido',
            value: Formatters.currency(revenue),
            icon: Icons.payments_rounded,
            accentColor: AppColors.success,
            compact: true,
          ),
        ),
      ],
    );
  }
}
