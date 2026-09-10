import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/appointment.dart';
import '../../models/payment.dart';
import '../../models/user.dart';
import '../../providers/appointment_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/finance_providers.dart';
import '../../widgets/widgets.dart';

/// Ações do fluxo de atendimento (chegou → iniciar → finalizar).
///
/// Reutilizadas pelo barbeiro e pelo proprietário.
class AttendanceActions extends ConsumerStatefulWidget {
  const AttendanceActions({super.key, required this.appointment});

  final Appointment appointment;

  @override
  ConsumerState<AttendanceActions> createState() => _AttendanceActionsState();
}

class _AttendanceActionsState extends ConsumerState<AttendanceActions> {
  bool _isLoading = false;

  Future<void> _run(
      Future<Appointment> Function() action, String message) async {
    setState(() => _isLoading = true);
    try {
      await action();
      if (!mounted) return;
      AppFeedback.success(context, message);
      invalidateAppointmentData(ref);
      ref.invalidate(barberDashboardProvider);
      ref.invalidate(ownerDashboardProvider);
    } on ApiException catch (error) {
      if (mounted) AppFeedback.error(context, error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.sm),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // Excluir é do dono: um barbeiro apagando o próprio horário faria sumir a
    // evidência de uma falta. O backend recusa do mesmo jeito — esconder o
    // botão só evita o erro previsível.
    final canDelete = ref.watch(currentRoleProvider) == UserRole.owner &&
        widget.appointment.status != AppointmentStatus.completed;

    final actions = _statusActions(context);
    if (!canDelete) {
      return actions.length == 1 ? actions.first : _wrap(actions);
    }
    return _wrap([...actions, _deleteButton(context)]);
  }

  Widget _wrap(List<Widget> children) => Wrap(
        spacing: AppSpacing.xxs,
        runSpacing: AppSpacing.xxs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      );

  List<Widget> _statusActions(BuildContext context) {
    final repository = ref.read(appointmentRepositoryProvider);
    final appointment = widget.appointment;

    switch (appointment.status) {
      case AppointmentStatus.pending:
        return [
          TextButton.icon(
            onPressed: () => _run(
              () => repository.confirm(appointment.id),
              'Agendamento confirmado.',
            ),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Confirmar'),
          ),
          _cancelButton(context, repository),
        ];

      case AppointmentStatus.confirmed:
        return [
          TextButton.icon(
            onPressed: () => _run(
              () => repository.arrive(appointment.id),
              'Chegada registrada.',
            ),
            icon: const Icon(Icons.how_to_reg_rounded, size: 18),
            label: const Text('Cliente chegou'),
          ),
          TextButton.icon(
            onPressed: () => _run(
              () => repository.noShow(appointment.id),
              'Marcado como falta.',
            ),
            icon: const Icon(Icons.person_off_rounded, size: 18),
            label: const Text('Faltou'),
          ),
          _cancelButton(context, repository),
        ];

      case AppointmentStatus.arrived:
        return [
          AppButton(
            label: 'Iniciar atendimento',
            icon: Icons.play_arrow_rounded,
            expanded: false,
            size: AppButtonSize.small,
            onPressed: () => _run(
              () => repository.start(appointment.id),
              'Atendimento iniciado.',
            ),
          ),
        ];

      case AppointmentStatus.inProgress:
        return [
          AppButton(
            label: 'Finalizar e receber',
            icon: Icons.point_of_sale_rounded,
            expanded: false,
            size: AppButtonSize.small,
            onPressed: () => _complete(context),
          ),
        ];

      case AppointmentStatus.completed:
      case AppointmentStatus.cancelled:
      case AppointmentStatus.noShow:
        return const [SizedBox.shrink()];
    }
  }

  /// Exclusão definitiva — o registro some da agenda e do histórico.
  Widget _deleteButton(BuildContext context) {
    final appointment = widget.appointment;
    // Enquanto o horário ainda vale, cancelar é quase sempre o certo: o cliente
    // é avisado e fica o motivo. O aviso evita que "excluir" vire o atalho.
    final isActive = appointment.status == AppointmentStatus.pending ||
        appointment.status == AppointmentStatus.confirmed ||
        appointment.status == AppointmentStatus.arrived ||
        appointment.status == AppointmentStatus.inProgress;

    return TextButton.icon(
      onPressed: () => _delete(isActive: isActive),
      icon: const Icon(Icons.delete_outline_rounded, size: 18),
      label: const Text('Excluir'),
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _delete({required bool isActive}) async {
    final appointment = widget.appointment;
    final quando =
        '${Formatters.date(appointment.date)} às ${appointment.startLabel}';

    final confirmed = await AppDialog.confirm(
      context,
      title: 'Excluir este agendamento?',
      message: isActive
          ? 'O horário de ${appointment.clientName} em $quando será apagado '
              'para sempre, sem aviso ao cliente.\n\n'
              'Para desmarcar registrando o motivo, use Cancelar.'
          : 'O registro de ${appointment.clientName} em $quando será apagado '
              'para sempre, junto com o histórico de status.',
      confirmLabel: 'Excluir',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(appointmentRepositoryProvider).delete(appointment.id);
      if (!mounted) return;
      AppFeedback.success(context, 'Agendamento excluído.');
      invalidateAppointmentData(ref);
      ref.invalidate(barberDashboardProvider);
      ref.invalidate(ownerDashboardProvider);
    } on ApiException catch (error) {
      if (mounted) AppFeedback.error(context, error.message);
    } finally {
      // O card some da lista quando a exclusão dá certo: mexer no estado de um
      // widget já desmontado seria erro.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _cancelButton(BuildContext context, dynamic repository) {
    return TextButton.icon(
      onPressed: () async {
        final reason = await AppDialog.prompt(
          context,
          title: 'Cancelar agendamento',
          message: 'Informe o motivo do cancelamento (opcional).',
          label: 'Motivo',
          confirmLabel: 'Cancelar agendamento',
        );
        if (reason == null || !mounted) return;
        await _run(
          () => repository.cancel(widget.appointment.id, reason: reason),
          'Agendamento cancelado.',
        );
      },
      icon: const Icon(Icons.close_rounded, size: 18),
      label: const Text('Cancelar'),
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _complete(BuildContext context) async {
    await AppBottomSheet.show<void>(
      context,
      title: 'Finalizar atendimento',
      subtitle:
          '${widget.appointment.serviceName} · ${widget.appointment.clientName}',
      child: CompleteAppointmentForm(appointment: widget.appointment),
    );
  }
}

/// Formulário de fechamento do atendimento com registro de pagamento.
class CompleteAppointmentForm extends ConsumerStatefulWidget {
  const CompleteAppointmentForm({super.key, required this.appointment});

  final Appointment appointment;

  @override
  ConsumerState<CompleteAppointmentForm> createState() =>
      _CompleteAppointmentFormState();
}

class _CompleteAppointmentFormState
    extends ConsumerState<CompleteAppointmentForm> {
  late final TextEditingController _amountController =
      TextEditingController(text: widget.appointment.price.toStringAsFixed(2));
  final _discountController = TextEditingController(text: '0.00');
  final _notesController = TextEditingController();
  PaymentMethod _method = PaymentMethod.pix;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _amount =>
      double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;

  double get _discount =>
      double.tryParse(_discountController.text.replaceAll(',', '.')) ?? 0;

  double get _total => (_amount - _discount).clamp(0, double.infinity);

  Future<void> _submit() async {
    if (_discount > _amount) {
      AppFeedback.error(context, 'O desconto não pode ser maior que o valor.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(appointmentRepositoryProvider).complete(
            widget.appointment.id,
            paymentMethod: _method.value,
            amount: _amount,
            discountAmount: _discount,
            notes: _notesController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      AppFeedback.success(
        context,
        'Atendimento concluído. ${Formatters.currency(_total)} recebido.',
      );
      invalidateAppointmentData(ref);
      ref.invalidate(barberDashboardProvider);
      ref.invalidate(ownerDashboardProvider);
      ref.invalidate(cashFlowSummaryProvider);
      ref.invalidate(commissionsProvider);
    } on ApiException catch (error) {
      if (mounted) AppFeedback.error(context, error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'Valor do serviço',
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [MoneyInputFormatter()],
          prefixIcon: Icons.attach_money_rounded,
          onChanged: (_) => setState(() {}),
          isRequired: true,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Desconto',
          controller: _discountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [MoneyInputFormatter()],
          prefixIcon: Icons.local_offer_outlined,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Forma de pagamento', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: PaymentMethod.checkoutOptions
              .map(
                (method) => ChoiceChip(
                  label: Text(method.label),
                  selected: _method == method,
                  onSelected: (_) => setState(() => _method = method),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Observação (opcional)',
          controller: _notesController,
          maxLines: 2,
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total a receber', style: theme.textTheme.titleSmall),
              Text(
                Formatters.currency(_total),
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: AppColors.success),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Confirmar recebimento',
          icon: Icons.check_circle_outline_rounded,
          isLoading: _isLoading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
