import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/barber.dart';
import '../../models/branch.dart';
import '../../models/service.dart';
import '../../providers/appointment_providers.dart';
import '../../providers/booking_provider.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/dashboard_providers.dart';
import '../../widgets/widgets.dart';

/// Fluxo de agendamento do cliente:
/// filial → serviço → barbeiro → data → horário → confirmação.
class ClientBookingPage extends ConsumerWidget {
  const ClientBookingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(bookingControllerProvider);

    if (booking.isFinished) {
      return _BookingSuccess(state: booking);
    }

    return Column(
      children: [
        _StepIndicator(current: booking.step),
        Expanded(
          child: ContentContainer(
            maxWidth: 760,
            child: _StepContent(step: booking.step),
          ),
        ),
      ],
    );
  }
}

class _StepIndicator extends ConsumerWidget {
  const _StepIndicator({required this.current});

  final BookingStep current;

  static const Map<BookingStep, String> _labels = {
    BookingStep.branch: 'Filial',
    BookingStep.service: 'Serviço',
    BookingStep.barber: 'Barbeiro',
    BookingStep.date: 'Data',
    BookingStep.slot: 'Horário',
    BookingStep.confirm: 'Confirmar',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    const steps = BookingStep.values;
    final currentIndex = steps.indexOf(current);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: theme.colorScheme.surface,
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final done = (index ~/ 2) < currentIndex;
            return Expanded(
              child: Container(
                height: 2,
                color: done ? AppColors.gold : theme.colorScheme.outline,
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final isDone = stepIndex < currentIndex;
          final isCurrent = stepIndex == currentIndex;

          return Tooltip(
            message: _labels[steps[stepIndex]]!,
            child: InkWell(
              onTap: isDone
                  ? () => ref
                      .read(bookingControllerProvider.notifier)
                      .goTo(steps[stepIndex])
                  : null,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              child: Container(
                height: 26,
                width: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDone || isCurrent
                      ? AppColors.gold
                      : theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrent ? AppColors.goldDark : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: AppColors.black)
                    : Text(
                        '${stepIndex + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isCurrent
                              ? AppColors.black
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StepContent extends ConsumerWidget {
  const _StepContent({required this.step});

  final BookingStep step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (step) {
      case BookingStep.branch:
        return const _BranchStep();
      case BookingStep.service:
        return const _ServiceStep();
      case BookingStep.barber:
        return const _BarberStep();
      case BookingStep.date:
        return const _DateStep();
      case BookingStep.slot:
        return const _SlotStep();
      case BookingStep.confirm:
        return const _ConfirmStep();
    }
  }
}

// ---------------------------------------------------------------------------
// 1. Filial
// ---------------------------------------------------------------------------
class _BranchStep extends ConsumerWidget {
  const _BranchStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branches = ref.watch(branchesProvider);
    final controller = ref.read(bookingControllerProvider.notifier);

    return AsyncView<List<Branch>>(
      value: branches,
      onRetry: () => ref.invalidate(branchesProvider),
      emptyMessage: 'Nenhuma filial disponível no momento.',
      isEmpty: (items) => items.isEmpty,
      builder: (items) => ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          const _StepTitle(
            title: 'Onde você quer ser atendido?',
            subtitle: 'Escolha a unidade mais conveniente.',
          ),
          ...items.map(
            (branch) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                onTap: () => controller.selectBranch(branch),
                child: Row(
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.14),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: const Icon(Icons.store_rounded,
                          color: AppColors.gold),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            branch.name,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            branch.fullAddress,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Serviço
// ---------------------------------------------------------------------------
class _ServiceStep extends ConsumerWidget {
  const _ServiceStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(bookingControllerProvider);
    final controller = ref.read(bookingControllerProvider.notifier);
    final filter = CatalogFilter(branchId: booking.branch?.id);
    final services = ref.watch(servicesProvider(filter));

    return AsyncView<List<Service>>(
      value: services,
      onRetry: () => ref.invalidate(servicesProvider(filter)),
      emptyMessage: 'Esta filial ainda não tem serviços disponíveis.',
      isEmpty: (items) => items.isEmpty,
      builder: (items) => ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          _StepTitle(
            title: 'Qual serviço você quer?',
            subtitle: 'Disponíveis na ${booking.branch?.name}.',
            onBack: controller.back,
          ),
          ...items.map(
            (service) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                onTap: () => controller.selectService(service),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          if (service.description.isNotEmpty)
                            Text(
                              service.description,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: AppSpacing.xxs),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                Formatters.duration(service.durationMinutes),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      Formatters.currency(service.price),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: AppColors.gold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Barbeiro
// ---------------------------------------------------------------------------
class _BarberStep extends ConsumerWidget {
  const _BarberStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(bookingControllerProvider);
    final controller = ref.read(bookingControllerProvider.notifier);
    final filter = CatalogFilter(
      branchId: booking.branch?.id,
      serviceId: booking.service?.id,
    );
    final barbers = ref.watch(barbersProvider(filter));

    return AsyncView<List<Barber>>(
      value: barbers,
      onRetry: () => ref.invalidate(barbersProvider(filter)),
      emptyMessage:
          'Nenhum barbeiro realiza este serviço nesta filial. Escolha outro serviço.',
      isEmpty: (items) => items.isEmpty,
      builder: (items) => ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          _StepTitle(
            title: 'Com quem você quer se atender?',
            subtitle: 'Profissionais que fazem ${booking.service?.name}.',
            onBack: controller.back,
          ),
          ...items.map(
            (barber) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                onTap: () => controller.selectBarber(barber),
                child: Row(
                  children: [
                    AppAvatar(
                      name: barber.name,
                      imageUrl: barber.avatarUrl,
                      size: 52,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            barber.name,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          if (barber.specialties.isNotEmpty)
                            Text(
                              barber.specialties.join(' · '),
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: AppSpacing.xxs),
                          if (barber.hasRating)
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 15,
                                  color: AppColors.gold,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${barber.rating.toStringAsFixed(1)} '
                                  '(${barber.reviewsCount})',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            )
                          else
                            Text(
                              'Ainda sem avaliações',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Data
// ---------------------------------------------------------------------------
class _DateStep extends ConsumerWidget {
  const _DateStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(bookingControllerProvider);
    final controller = ref.read(bookingControllerProvider.notifier);
    final today = DateTime.now();
    final maxDays = booking.branch?.maxAdvanceBookingDays ?? 60;
    final days = List.generate(
      maxDays.clamp(1, 60),
      (index) => DateTime(today.year, today.month, today.day + index),
    );

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      children: [
        _StepTitle(
          title: 'Para quando?',
          subtitle: 'Escolha o dia do seu atendimento.',
          onBack: controller.back,
        ),
        GridView.count(
          crossAxisCount: Responsive.value(
            context,
            mobile: 3,
            tablet: 5,
            desktop: 7,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.xs,
          mainAxisSpacing: AppSpacing.xs,
          childAspectRatio: 1.05,
          children: days.map((day) {
            final isSelected = booking.date != null &&
                booking.date!.year == day.year &&
                booking.date!.month == day.month &&
                booking.date!.day == day.day;

            return _DayTile(
              day: day,
              isSelected: isSelected,
              onTap: () => controller.selectDate(day),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime day;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSunday = day.weekday == DateTime.sunday;

    return InkWell(
      onTap: isSunday ? null : onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.goldDark : theme.colorScheme.outline,
          ),
        ),
        child: Opacity(
          opacity: isSunday ? 0.4 : 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                Formatters.weekday(day).substring(0, 3).toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected ? AppColors.black : null,
                ),
              ),
              Text(
                '${day.day}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.black : null,
                ),
              ),
              Text(
                Formatters.monthYear(day).split('/').first.substring(0, 3),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected ? AppColors.black : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Horário
// ---------------------------------------------------------------------------
class _SlotStep extends ConsumerWidget {
  const _SlotStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(bookingControllerProvider);
    final controller = ref.read(bookingControllerProvider.notifier);
    final slots = ref.watch(bookingSlotsProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      children: [
        _StepTitle(
          title: 'Que horas?',
          subtitle: booking.date == null
              ? null
              : '${Formatters.weekday(booking.date!)}, '
                  '${Formatters.dayMonthLong(booking.date!)}',
          onBack: controller.back,
        ),
        if (booking.errorMessage != null) ...[
          _InlineWarning(message: booking.errorMessage!),
          const SizedBox(height: AppSpacing.md),
        ],
        slots.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: AppLoading(message: 'Buscando horários livres...'),
          ),
          error: (error, _) => AppErrorState(
            message: '$error',
            onRetry: () => ref.invalidate(bookingSlotsProvider),
          ),
          data: (data) {
            if (data.slots.isEmpty) {
              return AppEmptyState(
                icon: Icons.event_busy_rounded,
                title: 'Sem horários neste dia',
                message:
                    'Este barbeiro não tem horários livres na data escolhida. '
                    'Experimente outro dia.',
                actionLabel: 'Escolher outra data',
                onAction: () => controller.goTo(BookingStep.date),
              );
            }

            return Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: data.slots
                  .map(
                    (slot) => _SlotChip(
                      slot: slot,
                      isSelected: booking.slot == slot,
                      onTap: () => controller.selectSlot(slot),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  final String slot;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.goldDark : theme.colorScheme.outline,
          ),
        ),
        child: Text(
          slot,
          style: theme.textTheme.titleSmall?.copyWith(
            color: isSelected ? AppColors.black : null,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. Confirmação
// ---------------------------------------------------------------------------
class _ConfirmStep extends ConsumerStatefulWidget {
  const _ConfirmStep();

  @override
  ConsumerState<_ConfirmStep> createState() => _ConfirmStepState();
}

class _ConfirmStepState extends ConsumerState<_ConfirmStep> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final controller = ref.read(bookingControllerProvider.notifier);
    controller.setNotes(_notesController.text.trim());

    final success = await controller.submit();
    if (!mounted) return;

    if (success) {
      invalidateAppointmentData(ref);
      ref.invalidate(clientDashboardProvider);
    } else {
      final message = ref.read(bookingControllerProvider).errorMessage;
      if (message != null) AppFeedback.error(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = ref.watch(bookingControllerProvider);
    final controller = ref.read(bookingControllerProvider.notifier);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      children: [
        _StepTitle(
          title: 'Confirme seu agendamento',
          subtitle: 'Revise os dados antes de finalizar.',
          onBack: controller.back,
        ),
        AppCard(
          child: Column(
            children: [
              _SummaryRow(
                icon: Icons.store_rounded,
                label: 'Filial',
                value: booking.branch?.name ?? '-',
              ),
              const Divider(height: AppSpacing.lg),
              _SummaryRow(
                icon: Icons.design_services_rounded,
                label: 'Serviço',
                value: booking.service?.name ?? '-',
              ),
              const Divider(height: AppSpacing.lg),
              _SummaryRow(
                icon: Icons.content_cut_rounded,
                label: 'Barbeiro',
                value: booking.barber?.name ?? '-',
              ),
              const Divider(height: AppSpacing.lg),
              _SummaryRow(
                icon: Icons.calendar_today_rounded,
                label: 'Data',
                value: booking.date == null
                    ? '-'
                    : '${Formatters.weekday(booking.date!)}, '
                        '${Formatters.date(booking.date!)}',
              ),
              const Divider(height: AppSpacing.lg),
              _SummaryRow(
                icon: Icons.schedule_rounded,
                label: 'Horário',
                value: booking.slot ?? '-',
              ),
              const Divider(height: AppSpacing.lg),
              _SummaryRow(
                icon: Icons.timer_outlined,
                label: 'Duração',
                value: Formatters.duration(booking.durationMinutes ?? 0),
              ),
              const Divider(height: AppSpacing.lg),
              _SummaryRow(
                icon: Icons.payments_rounded,
                label: 'Valor',
                value: Formatters.currency(booking.price),
                highlight: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Observações (opcional)',
          controller: _notesController,
          hint: 'Ex.: quero manter o comprimento em cima',
          maxLines: 3,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'O pagamento é feito na barbearia, no fim do atendimento.',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'CONFIRMAR AGENDAMENTO',
          icon: Icons.check_circle_outline_rounded,
          isLoading: booking.isSubmitting,
          onPressed: _confirm,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.text(
          label: 'Alterar horário',
          expanded: true,
          onPressed: () => controller.goTo(BookingStep.slot),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: highlight
                ? theme.textTheme.titleMedium?.copyWith(color: AppColors.gold)
                : theme.textTheme.titleSmall,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sucesso
// ---------------------------------------------------------------------------
class _BookingSuccess extends ConsumerWidget {
  const _BookingSuccess({required this.state});

  final BookingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appointment = state.createdAppointment!;

    return ContentContainer(
      maxWidth: 560,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 52,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Agendamento realizado com sucesso!',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${appointment.serviceName} com ${appointment.barberName}\n'
                '${Formatters.date(appointment.date)} às ${appointment.startLabel}',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Ver meus agendamentos',
                onPressed: () {
                  ref.read(bookingControllerProvider.notifier).reset();
                  context.go(AppRoutes.clientAppointments);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton.outline(
                label: 'Agendar outro horário',
                onPressed: () =>
                    ref.read(bookingControllerProvider.notifier).reset(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Auxiliares
// ---------------------------------------------------------------------------
class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.title, this.subtitle, this.onBack});

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onBack != null)
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Voltar'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: theme.colorScheme.onSurface,
              ),
            ),
          Text(title, style: theme.textTheme.headlineSmall),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(subtitle!, style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

class _InlineWarning extends StatelessWidget {
  const _InlineWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 20, color: AppColors.warning),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(message, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
