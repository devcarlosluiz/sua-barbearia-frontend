import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/barber.dart';
import '../../../models/branch.dart';
import '../../../providers/catalog_providers.dart';
import '../../../providers/dashboard_providers.dart';

/// Barra de filtros dos dashboards e relatórios: período, filial e barbeiro.
class PeriodFilterBar extends ConsumerWidget {
  const PeriodFilterBar({
    super.key,
    this.showBranch = true,
    this.showBarber = true,
  });

  final bool showBranch;
  final bool showBarber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(dashboardFilterProvider);
    final controller = ref.read(dashboardFilterProvider.notifier);
    final branches = ref.watch(branchesProvider);
    final barbers =
        ref.watch(barbersProvider(CatalogFilter(branchId: filter.branchId)));
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final period in DashboardPeriod.values)
                  if (period != DashboardPeriod.custom)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xxs),
                      child: ChoiceChip(
                        label: Text(period.label),
                        selected: filter.period == period,
                        onSelected: (_) => controller.update(
                          (state) =>
                              state.copyWith(period: period, clearDates: true),
                        ),
                      ),
                    ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xxs),
                  child: ChoiceChip(
                    label: Text(
                      filter.isCustom && filter.startDate != null
                          ? '${Formatters.dateShort(filter.startDate!)} - '
                              '${Formatters.dateShort(filter.endDate ?? filter.startDate!)}'
                          : 'Personalizado',
                    ),
                    selected: filter.isCustom,
                    onSelected: (_) => _pickRange(context, ref),
                  ),
                ),
              ],
            ),
          ),
          if (showBranch || showBarber) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                if (showBranch)
                  Expanded(
                    child: branches.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (items) => _FilterDropdown<Branch>(
                        hint: 'Todas as filiais',
                        items: items,
                        selectedId: filter.branchId,
                        idOf: (item) => item.id,
                        labelOf: (item) => item.name,
                        onChanged: (branch) => controller.update(
                          (state) => branch == null
                              ? state.copyWith(
                                  clearBranch: true, clearBarber: true)
                              : state.copyWith(
                                  branchId: branch.id,
                                  clearBarber: true,
                                ),
                        ),
                      ),
                    ),
                  ),
                if (showBranch && showBarber)
                  const SizedBox(width: AppSpacing.xs),
                if (showBarber)
                  Expanded(
                    child: barbers.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (items) => _FilterDropdown<Barber>(
                        hint: 'Todos os barbeiros',
                        items: items,
                        selectedId: filter.barberId,
                        idOf: (item) => item.id,
                        labelOf: (item) => item.name,
                        onChanged: (barber) => controller.update(
                          (state) => barber == null
                              ? state.copyWith(clearBarber: true)
                              : state.copyWith(barberId: barber.id),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecione o período',
      saveText: 'Aplicar',
    );
    if (range == null) return;

    ref.read(dashboardFilterProvider.notifier).update(
          (state) => state.copyWith(
            period: DashboardPeriod.custom,
            startDate: range.start,
            endDate: range.end,
          ),
        );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.hint,
    required this.items,
    required this.selectedId,
    required this.idOf,
    required this.labelOf,
    required this.onChanged,
  });

  final String hint;
  final List<T> items;
  final int? selectedId;
  final int Function(T item) idOf;
  final String Function(T item) labelOf;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = items.where((item) => idOf(item) == selectedId).toList();

    return DropdownButtonFormField<T?>(
      initialValue: selected.isEmpty ? null : selected.first,
      isExpanded: true,
      decoration: const InputDecoration(isDense: true),
      hint: Text(hint, overflow: TextOverflow.ellipsis),
      items: [
        DropdownMenuItem<T?>(value: null, child: Text(hint)),
        ...items.map(
          (item) => DropdownMenuItem<T?>(
            value: item,
            child: Text(labelOf(item), overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
