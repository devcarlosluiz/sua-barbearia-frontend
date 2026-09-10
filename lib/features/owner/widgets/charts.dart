import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/dashboard.dart';
import '../../../widgets/widgets.dart';

/// Paleta usada nas séries dos gráficos.
const List<Color> chartPalette = [
  AppColors.gold,
  AppColors.info,
  AppColors.success,
  AppColors.warning,
  AppColors.danger,
  AppColors.slate,
  AppColors.goldDark,
];

/// Gráfico de linha (faturamento por dia).
class RevenueLineChart extends StatelessWidget {
  const RevenueLineChart({
    super.key,
    required this.title,
    required this.points,
    this.height = 240,
  });

  final String title;
  final List<ChartPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (points.isEmpty) {
      return _ChartShell(
        title: title,
        height: height,
        child: const Center(child: Text('Sem dados no período selecionado.')),
      );
    }

    final spots = List.generate(
      points.length,
      (index) => FlSpot(index.toDouble(), points[index].value),
    );
    final maxY = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);

    return _ChartShell(
      title: title,
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY == 0 ? 10 : maxY * 1.2,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: theme.colorScheme.outline,
              strokeWidth: 0.6,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (value, meta) => Text(
                  Formatters.compactCurrency(value),
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (points.length / 6).ceilToDouble().clamp(1, 30),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final date = points[index].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      date == null ? '' : Formatters.dateShort(date),
                      style: theme.textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots
                  .map(
                    (spot) => LineTooltipItem(
                      Formatters.currency(spot.y),
                      theme.textTheme.labelLarge ?? const TextStyle(),
                    ),
                  )
                  .toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: AppColors.gold,
              barWidth: 3,
              dotData: FlDotData(show: points.length <= 15),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.gold.withValues(alpha: 0.3),
                    AppColors.gold.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gráfico de barras horizontais (rankings).
class RankingBarChart extends StatelessWidget {
  const RankingBarChart({
    super.key,
    required this.title,
    required this.points,
    this.valueLabel,
    this.maxItems = 6,
  });

  final String title;
  final List<ChartPoint> points;
  final String Function(ChartPoint point)? valueLabel;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = points.take(maxItems).toList();

    if (items.isEmpty) {
      return _ChartShell(
        title: title,
        height: 200,
        child: const Center(child: Text('Sem dados no período selecionado.')),
      );
    }

    final maxValue = items.map((p) => p.value).reduce((a, b) => a > b ? a : b);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.md),
          ...List.generate(items.length, (index) {
            final point = items[index];
            final ratio = maxValue == 0 ? 0.0 : point.value / maxValue;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          point.label,
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        valueLabel?.call(point) ??
                            Formatters.currency(point.value),
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 7,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      color: chartPalette[index % chartPalette.length],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Gráfico de pizza (distribuição por categoria/forma de pagamento).
class DistributionPieChart extends StatelessWidget {
  const DistributionPieChart({
    super.key,
    required this.title,
    required this.points,
    this.height = 240,
  });

  final String title;
  final List<ChartPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (points.isEmpty) {
      return _ChartShell(
        title: title,
        height: height,
        child: const Center(child: Text('Sem dados no período selecionado.')),
      );
    }

    final total = points.fold<double>(0, (sum, point) => sum + point.value);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 42,
                sections: List.generate(points.length, (index) {
                  final point = points[index];
                  final percent =
                      total == 0 ? 0.0 : (point.value / total) * 100;
                  return PieChartSectionData(
                    value: point.value,
                    color: chartPalette[index % chartPalette.length],
                    radius: 42,
                    title: percent < 8 ? '' : '${percent.toStringAsFixed(0)}%',
                    titleStyle: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: List.generate(points.length, (index) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 10,
                    width: 10,
                    decoration: BoxDecoration(
                      color: chartPalette[index % chartPalette.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${points[index].label} · '
                    '${Formatters.currency(points[index].value)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Gráfico de colunas (agendamentos por dia).
class AppointmentsBarChart extends StatelessWidget {
  const AppointmentsBarChart({
    super.key,
    required this.title,
    required this.points,
    this.height = 240,
  });

  final String title;
  final List<ChartPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (points.isEmpty) {
      return _ChartShell(
        title: title,
        height: height,
        child: const Center(child: Text('Sem dados no período selecionado.')),
      );
    }

    final maxY = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);

    return _ChartShell(
      title: title,
      height: height,
      child: BarChart(
        BarChartData(
          maxY: maxY == 0 ? 5 : maxY * 1.25,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: theme.colorScheme.outline, strokeWidth: 0.6),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (points.length / 6).ceilToDouble().clamp(1, 30),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final date = points[index].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      date == null ? '' : Formatters.dateShort(date),
                      style: theme.textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(
            points.length,
            (index) => BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: points[index].value,
                  width: 12,
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartShell extends StatelessWidget {
  const _ChartShell({
    required this.title,
    required this.child,
    required this.height,
  });

  final String title;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.md),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}
