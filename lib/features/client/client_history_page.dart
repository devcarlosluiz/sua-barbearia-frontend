import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/api_exception.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/appointment.dart';
import '../../providers/appointment_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/engagement_providers.dart';
import '../../widgets/widgets.dart';
import '../shared/appointment_card.dart';

class ClientHistoryPage extends ConsumerWidget {
  const ClientHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(appointmentHistoryProvider);
    final pending = ref.watch(pendingReviewsProvider);
    final pendingIds = (pending.valueOrNull ?? const <Appointment>[])
        .map((item) => item.id)
        .toSet();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(appointmentHistoryProvider);
        ref.invalidate(pendingReviewsProvider);
      },
      child: AsyncView<List<Appointment>>(
        value: history,
        onRetry: () => ref.invalidate(appointmentHistoryProvider),
        emptyMessage:
            'Seu histórico aparecerá aqui após o primeiro atendimento.',
        isEmpty: (items) => items.isEmpty,
        emptyIcon: Icons.history_rounded,
        builder: (items) => ListView.separated(
          padding: Responsive.pagePadding(context),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final appointment = items[index];
            final needsReview = pendingIds.contains(appointment.id);

            return AppointmentCard(
              appointment: appointment,
              showClient: false,
              actions: [
                if (needsReview)
                  TextButton.icon(
                    onPressed: () => _review(context, ref, appointment),
                    icon: const Icon(Icons.star_rounded, size: 18),
                    label: const Text('Avaliar atendimento'),
                    style:
                        TextButton.styleFrom(foregroundColor: AppColors.gold),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Avaliado',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    Appointment appointment,
  ) async {
    await AppBottomSheet.show<void>(
      context,
      title: 'Como foi o atendimento?',
      subtitle: '${appointment.serviceName} com ${appointment.barberName}',
      child: _ReviewSheet(appointment: appointment),
    );
  }
}

class _ReviewSheet extends ConsumerStatefulWidget {
  const _ReviewSheet({required this.appointment});

  final Appointment appointment;

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(engagementRepositoryProvider).createReview(
            appointmentId: widget.appointment.id,
            rating: _rating,
            comment: _commentController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      AppFeedback.success(context, 'Obrigado pela sua avaliação!');
      ref.invalidate(pendingReviewsProvider);
      ref.invalidate(appointmentHistoryProvider);
      ref.invalidate(clientDashboardProvider);
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
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final value = index + 1;
              return IconButton(
                onPressed: () => setState(() => _rating = value),
                iconSize: 38,
                icon: Icon(
                  value <= _rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: AppColors.gold,
                ),
              );
            }),
          ),
        ),
        Center(
          child: Text(_ratingLabel(_rating), style: theme.textTheme.titleSmall),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Comentário (opcional)',
          controller: _commentController,
          hint: 'Conte como foi a experiência',
          maxLines: 4,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Enviar avaliação',
          isLoading: _isLoading,
          onPressed: _submit,
        ),
      ],
    );
  }

  static String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Muito ruim';
      case 2:
        return 'Ruim';
      case 3:
        return 'Regular';
      case 4:
        return 'Bom';
      default:
        return 'Excelente';
    }
  }
}
