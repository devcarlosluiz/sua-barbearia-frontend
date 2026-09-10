import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/dashboard.dart';
import '../../providers/dashboard_providers.dart';
import '../../widgets/widgets.dart';
import 'widgets/charts.dart';
import 'widgets/period_filter_bar.dart';

class OwnerDashboardPage extends ConsumerWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(ownerDashboardProvider);

    return Column(
      children: [
        const PeriodFilterBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(ownerDashboardProvider),
            child: AsyncView<OwnerDashboard>(
              value: dashboard,
              onRetry: () => ref.invalidate(ownerDashboardProvider),
              builder: (data) => ListView(
                padding: Responsive.pagePadding(context),
                children: [
                  _KpiSection(data: data),
                  const SizedBox(height: AppSpacing.lg),
                  RevenueLineChart(
                    title: 'Faturamento por dia',
                    points: data.revenueByDay,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ChartsRow(
                    children: [
                      AppointmentsBarChart(
                        title: 'Agendamentos por dia',
                        points: data.appointmentsByDay,
                      ),
                      DistributionPieChart(
                        title: 'Formas de pagamento',
                        points: data.paymentMethods,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ChartsRow(
                    children: [
                      RankingBarChart(
                        title: 'Serviços mais vendidos',
                        points: data.topServices,
                        valueLabel: (point) =>
                            '${point.count}x · ${Formatters.currency(point.value)}',
                      ),
                      RankingBarChart(
                        title: 'Barbeiros com maior produção',
                        points: data.topBarbers,
                        valueLabel: (point) =>
                            '${point.count}x · ${Formatters.currency(point.value)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ChartsRow(
                    children: [
                      RankingBarChart(
                        title: 'Faturamento por filial',
                        points: data.revenueByBranch,
                      ),
                      DistributionPieChart(
                        title: 'Despesas por categoria',
                        points: data.expensesByCategory,
                      ),
                    ],
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

class _KpiSection extends StatelessWidget {
  const _KpiSection({required this.data});

  final OwnerDashboard data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatGrid(
          minTileWidth: 190,
          children: [
            StatCard(
              label: 'Faturamento hoje',
              value: Formatters.currency(data.revenueToday),
              icon: Icons.today_rounded,
              accentColor: AppColors.success,
            ),
            StatCard(
              label: 'Faturamento do mês',
              value: Formatters.currency(data.revenueMonth),
              icon: Icons.calendar_month_rounded,
              accentColor: AppColors.success,
            ),
            StatCard(
              label: 'Receita do período',
              value: Formatters.currency(data.revenuePeriod),
              icon: Icons.trending_up_rounded,
              trailingLabel:
                  'Despesas: ${Formatters.currency(data.expensePeriod)}',
            ),
            StatCard(
              label: 'Saldo do período',
              value: Formatters.currency(data.balancePeriod),
              icon: Icons.account_balance_wallet_rounded,
              accentColor: data.balancePeriod >= 0
                  ? AppColors.success
                  : AppColors.danger,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        StatGrid(
          minTileWidth: 165,
          children: [
            StatCard(
              label: 'Agendamentos hoje',
              value: '${data.appointmentsToday}',
              icon: Icons.event_rounded,
              accentColor: AppColors.info,
              compact: true,
            ),
            StatCard(
              label: 'Serviços realizados',
              value: '${data.completedAppointments}',
              icon: Icons.check_circle_rounded,
              accentColor: AppColors.success,
              compact: true,
            ),
            StatCard(
              label: 'Ticket médio',
              value: Formatters.currency(data.averageTicket),
              icon: Icons.receipt_long_rounded,
              compact: true,
            ),
            StatCard(
              label: 'Clientes',
              value: '${data.totalClients}',
              icon: Icons.people_rounded,
              trailingLabel: '${data.newClients} novo(s) no período',
              compact: true,
            ),
            StatCard(
              label: 'Cancelamentos',
              value: '${data.cancelledAppointments}',
              icon: Icons.event_busy_rounded,
              accentColor: AppColors.danger,
              trailingLabel: '${data.cancellationRate.toStringAsFixed(1)}%',
              compact: true,
            ),
            StatCard(
              label: 'No-show',
              value: '${data.noShowAppointments}',
              icon: Icons.person_off_rounded,
              accentColor: AppColors.warning,
              trailingLabel: '${data.noShowRate.toStringAsFixed(1)}%',
              compact: true,
            ),
            StatCard(
              label: 'Produtos vendidos',
              value: '${data.productsSold}',
              icon: Icons.inventory_2_rounded,
              trailingLabel: Formatters.currency(data.productsRevenue),
              compact: true,
            ),
            StatCard(
              label: 'Comissões a pagar',
              value: Formatters.currency(data.pendingCommissions),
              icon: Icons.savings_rounded,
              accentColor: AppColors.warning,
              compact: true,
            ),
          ],
        ),
      ],
    );
  }
}

/// Duas colunas no desktop, empilhadas no mobile.
class _ChartsRow extends StatelessWidget {
  const _ChartsRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(height: AppSpacing.md),
            children[index],
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(width: AppSpacing.md),
          Expanded(child: children[index]),
        ],
      ],
    );
  }
}
