import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/dashboard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_providers.dart';
import '../../widgets/widgets.dart';
import '../shared/appointment_card.dart';
import '../shared/attendance_actions.dart';

class BarberDashboardPage extends ConsumerWidget {
  const BarberDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(barberDashboardProvider);
    final barber = ref.watch(currentBarberProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(barberDashboardProvider),
      child: AsyncView<BarberDashboard>(
        value: dashboard,
        onRetry: () => ref.invalidate(barberDashboardProvider),
        builder: (data) => ListView(
          padding: Responsive.pagePadding(context),
          children: [
            Row(
              children: [
                AppAvatar(
                  name: barber?.name ?? 'Barbeiro',
                  imageUrl: barber?.avatarUrl,
                  size: 52,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        barber?.name ?? 'Barbeiro',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            data.reviewsCount == 0
                                ? 'Ainda sem avaliações'
                                : '${data.rating.toStringAsFixed(1)} '
                                    '· ${data.reviewsCount} avaliações',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            StatGrid(
              minTileWidth: 160,
              children: [
                StatCard(
                  label: 'Atendimentos hoje',
                  value: '${data.appointmentsToday}',
                  icon: Icons.event_rounded,
                  trailingLabel: '${data.completedToday} concluído(s)',
                ),
                StatCard(
                  label: 'Produção hoje',
                  value: Formatters.currency(data.revenueToday),
                  icon: Icons.attach_money_rounded,
                  accentColor: AppColors.success,
                ),
                StatCard(
                  label: 'Produção no mês',
                  value: Formatters.currency(data.revenueMonth),
                  icon: Icons.calendar_month_rounded,
                  accentColor: AppColors.info,
                  trailingLabel: '${data.appointmentsMonth} atendimentos',
                ),
                StatCard(
                  label: 'Comissão do mês',
                  value: Formatters.currency(data.commissionMonth),
                  icon: Icons.savings_rounded,
                  trailingLabel:
                      'Pendente: ${Formatters.currency(data.commissionPending)}',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppSectionHeader(
              title: 'Agenda de hoje',
              subtitle: Formatters.friendlyDate(DateTime.now()),
              action: TextButton(
                onPressed: () => context.go(AppRoutes.barberAgenda),
                child: const Text('Ver agenda'),
              ),
            ),
            if (data.todayAgenda.isEmpty)
              const AppEmptyState(
                message: 'Nenhum atendimento marcado para hoje.',
                icon: Icons.event_available_outlined,
              )
            else
              ...data.todayAgenda.map(
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
            const SizedBox(height: AppSpacing.lg),
            const AppSectionHeader(title: 'Próximos clientes'),
            if (data.nextClients.isEmpty)
              const AppEmptyState(
                message: 'Sua agenda futura está livre.',
                icon: Icons.schedule_rounded,
              )
            else
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var index = 0;
                        index < data.nextClients.length;
                        index++) ...[
                      if (index > 0) const Divider(height: 1),
                      ListTile(
                        leading: AppAvatar(
                          name: data.nextClients[index].clientName,
                          size: 38,
                        ),
                        title: Text(data.nextClients[index].clientName),
                        subtitle: Text(
                          '${data.nextClients[index].serviceName} · '
                          '${Formatters.friendlyDate(data.nextClients[index].date)} '
                          'às ${data.nextClients[index].startLabel}',
                        ),
                        trailing: AppointmentStatusBadge(
                          status: data.nextClients[index].status,
                          dense: true,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (data.topServices.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              const AppSectionHeader(title: 'Seus serviços mais realizados'),
              AppCard(
                child: Column(
                  children: data.topServices
                      .map(
                        (point) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Row(
                            children: [
                              Expanded(child: Text(point.label)),
                              Text(
                                '${point.count}x',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                Formatters.currency(point.value),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
