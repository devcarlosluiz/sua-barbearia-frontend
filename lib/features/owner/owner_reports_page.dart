import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/dashboard.dart';
import '../../models/review.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/engagement_providers.dart';
import '../../widgets/widgets.dart';
import 'widgets/charts.dart';
import 'widgets/period_filter_bar.dart';

/// Relatórios consolidados: produção, ocupação, avaliações e exportações.
class OwnerReportsPage extends ConsumerWidget {
  const OwnerReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(ownerDashboardProvider);
    final reviews = ref.watch(reviewSummaryProvider(null));

    return Column(
      children: [
        const PeriodFilterBar(),
        Expanded(
          child: AsyncView<OwnerDashboard>(
            value: dashboard,
            onRetry: () => ref.invalidate(ownerDashboardProvider),
            builder: (data) => ListView(
              padding: Responsive.pagePadding(context),
              children: [
                const AppSectionHeader(
                  title: 'Resultado do período',
                  subtitle: 'Consolidado de receitas, despesas e atendimentos.',
                ),
                _PeriodSummaryTable(data: data),
                const SizedBox(height: AppSpacing.lg),
                const AppSectionHeader(title: 'Produção por barbeiro'),
                RankingBarChart(
                  title: 'Faturamento gerado',
                  points: data.topBarbers,
                  maxItems: 12,
                  valueLabel: (point) =>
                      '${point.count} atend. · ${Formatters.currency(point.value)}',
                ),
                const SizedBox(height: AppSpacing.md),
                const AppSectionHeader(title: 'Serviços'),
                RankingBarChart(
                  title: 'Mais vendidos',
                  points: data.topServices,
                  maxItems: 12,
                  valueLabel: (point) =>
                      '${point.count}x · ${Formatters.currency(point.value)}',
                ),
                const SizedBox(height: AppSpacing.md),
                const AppSectionHeader(title: 'Filiais'),
                RankingBarChart(
                  title: 'Faturamento por unidade',
                  points: data.revenueByBranch,
                ),
                const SizedBox(height: AppSpacing.md),
                const AppSectionHeader(title: 'Satisfação'),
                AsyncView<ReviewSummary>(
                  value: reviews,
                  onRetry: () => ref.invalidate(reviewSummaryProvider(null)),
                  builder: (summary) => _RatingCard(summary: summary),
                ),
                const SizedBox(height: AppSpacing.md),
                _ExportCard(data: data),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PeriodSummaryTable extends StatelessWidget {
  const _PeriodSummaryTable({required this.data});

  final OwnerDashboard data;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, Color?)>[
      ('Receita', Formatters.currency(data.revenuePeriod), AppColors.success),
      ('Despesa', Formatters.currency(data.expensePeriod), AppColors.danger),
      (
        'Saldo',
        Formatters.currency(data.balancePeriod),
        data.balancePeriod >= 0 ? AppColors.success : AppColors.danger,
      ),
      ('Agendamentos', '${data.appointmentsPeriod}', null),
      ('Atendimentos concluídos', '${data.completedAppointments}', null),
      (
        'Cancelamentos',
        '${data.cancelledAppointments} (${data.cancellationRate.toStringAsFixed(1)}%)',
        null,
      ),
      (
        'Faltas (no-show)',
        '${data.noShowAppointments} (${data.noShowRate.toStringAsFixed(1)}%)',
        null,
      ),
      ('Ticket médio', Formatters.currency(data.averageTicket), null),
      ('Clientes novos', '${data.newClients}', null),
      ('Produtos vendidos', '${data.productsSold}', null),
      (
        'Receita de produtos',
        Formatters.currency(data.productsRevenue),
        null,
      ),
      (
        'Comissões pendentes',
        Formatters.currency(data.pendingCommissions),
        AppColors.warning,
      ),
    ];

    final theme = Theme.of(context);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child:
                        Text(rows[index].$1, style: theme.textTheme.bodyMedium),
                  ),
                  Text(
                    rows[index].$2,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: rows[index].$3),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.summary});

  final ReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (summary.total == 0) {
      return const AppEmptyState(
        message: 'Ainda não há avaliações no período.',
        icon: Icons.star_outline_rounded,
      );
    }

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(
                summary.average.toStringAsFixed(1),
                style: theme.textTheme.displayMedium
                    ?.copyWith(color: AppColors.gold),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < summary.average.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 16,
                    color: AppColors.gold,
                  ),
                ),
              ),
              Text(
                '${summary.total} avaliação(ões)',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final rating = 5 - index;
                final count = summary.countFor(rating);
                final ratio = summary.total == 0 ? 0.0 : count / summary.total;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        child:
                            Text('$rating', style: theme.textTheme.bodySmall),
                      ),
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusPill),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 6,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '$count',
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard({required this.data});

  final OwnerDashboard data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.download_rounded),
              const SizedBox(width: AppSpacing.sm),
              Text('Exportações', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Baixe os lançamentos financeiros do período em CSV '
            '(${Formatters.date(data.startDate)} a ${Formatters.date(data.endDate)}) '
            'pelo endpoint autenticado:',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          SelectableText(
            '/api/v1/finance/transactions/export/'
            '?start_date=${Formatters.isoDate(data.startDate)}'
            '&end_date=${Formatters.isoDate(data.endDate)}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}
