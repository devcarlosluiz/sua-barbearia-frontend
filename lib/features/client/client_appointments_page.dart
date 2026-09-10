import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/api_exception.dart';
import '../../core/responsive/responsive.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/appointment.dart';
import '../../providers/appointment_providers.dart';
import '../../providers/booking_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/dashboard_providers.dart';
import '../../widgets/widgets.dart';
import '../shared/appointment_card.dart';

class ClientAppointmentsPage extends ConsumerWidget {
  const ClientAppointmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingAppointmentsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(upcomingAppointmentsProvider),
      child: AsyncView<List<Appointment>>(
        value: upcoming,
        onRetry: () => ref.invalidate(upcomingAppointmentsProvider),
        emptyMessage:
            'Você ainda não tem horários marcados. Que tal agendar o próximo?',
        isEmpty: (items) => items.isEmpty,
        emptyIcon: Icons.event_available_outlined,
        emptyActionLabel: 'Agendar horário',
        onEmptyAction: () => context.go(AppRoutes.clientBooking),
        builder: (items) => ListView.separated(
          padding: Responsive.pagePadding(context),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) => _ClientAppointmentTile(
            appointment: items[index],
          ),
        ),
      ),
    );
  }
}

class _ClientAppointmentTile extends ConsumerWidget {
  const _ClientAppointmentTile({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppointmentCard(
      appointment: appointment,
      showClient: false,
      actions: [
        if (appointment.status.isActive)
          TextButton.icon(
            onPressed: () => _reschedule(context, ref),
            icon: const Icon(Icons.edit_calendar_rounded, size: 18),
            label: const Text('Remarcar'),
          ),
        if (appointment.canBeCancelledByClient) ...[
          TextButton.icon(
            onPressed: () => _cancel(context, ref),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Cancelar'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
          // Excluir segue o mesmo prazo do cancelamento: sem isso seria a porta
          // dos fundos para sumir com o horário minutos antes.
          TextButton.icon(
            onPressed: () => _delete(context, ref),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Excluir'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ] else if (appointment.status.isActive)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              'Cancelamento pelo app encerrado',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Cancelar agendamento',
      message: 'Deseja cancelar ${appointment.serviceName} de '
          '${Formatters.date(appointment.date)} às ${appointment.startLabel}?',
      confirmLabel: 'Cancelar horário',
      cancelLabel: 'Manter',
      isDestructive: true,
      icon: Icons.event_busy_rounded,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(appointmentRepositoryProvider).cancel(appointment.id,
          reason: 'Cancelado pelo cliente no aplicativo.');
      if (!context.mounted) return;
      AppFeedback.success(context, 'Agendamento cancelado.');
      invalidateAppointmentData(ref);
      ref.invalidate(clientDashboardProvider);
    } on ApiException catch (error) {
      if (context.mounted) AppFeedback.error(context, error.message);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Excluir agendamento',
      // A diferença tem de ficar clara: cancelar avisa a barbearia, excluir
      // apaga. Sem isso o cliente escolhe no escuro entre dois botões iguais.
      message: 'O horário de ${Formatters.date(appointment.date)} às '
          '${appointment.startLabel} será apagado do sistema, sem registro do '
          'motivo.\n\nSe quiser apenas desmarcar avisando a barbearia, use '
          'Cancelar.',
      confirmLabel: 'Excluir',
      cancelLabel: 'Manter',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(appointmentRepositoryProvider).delete(appointment.id);
      if (!context.mounted) return;
      AppFeedback.success(context, 'Agendamento excluído.');
      invalidateAppointmentData(ref);
      ref.invalidate(clientDashboardProvider);
    } on ApiException catch (error) {
      if (context.mounted) AppFeedback.error(context, error.message);
    }
  }

  Future<void> _reschedule(BuildContext context, WidgetRef ref) async {
    await AppBottomSheet.show<void>(
      context,
      title: 'Remarcar atendimento',
      subtitle: '${appointment.serviceName} com ${appointment.barberName}',
      child: _RescheduleSheet(appointment: appointment),
    );
  }
}

class _RescheduleSheet extends ConsumerStatefulWidget {
  const _RescheduleSheet({required this.appointment});

  final Appointment appointment;

  @override
  ConsumerState<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends ConsumerState<_RescheduleSheet> {
  late DateTime _date = widget.appointment.date;
  String? _slot;
  bool _isLoading = false;
  AvailableSlots? _slots;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _slot = null;
    });
    try {
      final slots =
          await ref.read(appointmentRepositoryProvider).availableSlots(
                branchId: widget.appointment.branchId,
                barberId: widget.appointment.barberId,
                serviceId: widget.appointment.serviceId,
                date: _date,
              );
      if (mounted) setState(() => _slots = slots);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (_slot == null) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(appointmentRepositoryProvider).reschedule(
            widget.appointment.id,
            date: _date,
            startTime: _slot!,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      AppFeedback.success(context, 'Agendamento remarcado com sucesso.');
      invalidateAppointmentData(ref);
      ref.invalidate(clientDashboardProvider);
      ref.invalidate(bookingSlotsProvider);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
        await _loadSlots();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppDatePicker(
          label: 'Nova data',
          value: _date,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 90)),
          onChanged: (value) {
            setState(() => _date = value);
            _loadSlots();
          },
        ),
        const SizedBox(height: AppSpacing.md),
        if (_error != null) ...[
          Text(
            _error!,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (_isLoading && _slots == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: AppLoading(compact: true),
          )
        else if ((_slots?.slots ?? []).isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              'Sem horários livres neste dia. Escolha outra data.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          )
        else
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: _slots!.slots
                .map(
                  (slot) => ChoiceChip(
                    label: Text(slot),
                    selected: _slot == slot,
                    onSelected: (_) => setState(() => _slot = slot),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Confirmar novo horário',
          isLoading: _isLoading,
          onPressed: _slot == null ? null : _submit,
        ),
      ],
    );
  }
}
