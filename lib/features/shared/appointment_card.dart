import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/appointment.dart';
import '../../widgets/widgets.dart';

/// Cartão de agendamento reutilizado nas três áreas do app.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onTap,
    this.showClient = true,
    this.showBarber = true,
    this.showDate = true,
    this.trailing,
    this.actions = const [],
  });

  final Appointment appointment;
  final VoidCallback? onTap;
  final bool showClient;
  final bool showBarber;
  final bool showDate;
  final Widget? trailing;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor =
        AppColors.forAppointmentStatus(appointment.status.value);

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: statusColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TimeBlock(
                                appointment: appointment, showDate: showDate),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appointment.serviceName,
                                    style: theme.textTheme.titleSmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  if (showClient)
                                    _InfoLine(
                                      icon: Icons.person_outline_rounded,
                                      text: appointment.clientName,
                                    ),
                                  if (showBarber)
                                    _InfoLine(
                                      icon: Icons.content_cut_rounded,
                                      text: appointment.barberName,
                                    ),
                                  _InfoLine(
                                    icon: Icons.store_outlined,
                                    text: appointment.branchName,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AppointmentStatusBadge(
                                  status: appointment.status,
                                  dense: true,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  Formatters.currency(appointment.price),
                                  style: theme.textTheme.titleSmall,
                                ),
                                if (trailing != null) ...[
                                  const SizedBox(height: AppSpacing.xxs),
                                  trailing!,
                                ],
                              ],
                            ),
                          ],
                        ),
                        if (appointment.notes.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            appointment.notes,
                            style: theme.textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.xxs,
                children: actions,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeBlock extends StatelessWidget {
  const _TimeBlock({required this.appointment, required this.showDate});

  final Appointment appointment;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 66,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          Text(
            appointment.startLabel,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            showDate
                ? Formatters.dateShort(appointment.date)
                : '${appointment.durationMinutes}min',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
