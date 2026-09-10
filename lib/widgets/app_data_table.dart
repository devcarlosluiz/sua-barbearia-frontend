import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import 'app_card.dart';

/// Tabela de dados responsiva usada nas telas de gestão (desktop/tablet).
///
/// No mobile as mesmas listas são exibidas como cartões — esta tabela nunca é
/// "espremida" em telas pequenas.
class AppDataTable extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.emptyMessage = 'Nenhum registro encontrado.',
  });

  final List<String> columns;
  final List<AppDataRow> rows;
  final void Function(int index)? onRowTap;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (rows.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Text(emptyMessage, style: theme.textTheme.bodyMedium),
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(
                  theme.colorScheme.surfaceContainerHighest,
                ),
                columnSpacing: AppSpacing.lg,
                horizontalMargin: AppSpacing.md,
                showCheckboxColumn: false,
                columns: columns
                    .map(
                        (label) => DataColumn(label: Text(label.toUpperCase())))
                    .toList(),
                rows: List.generate(rows.length, (index) {
                  final row = rows[index];
                  return DataRow(
                    onSelectChanged:
                        onRowTap == null ? null : (_) => onRowTap!(index),
                    cells: row.cells.map(DataCell.new).toList(),
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AppDataRow {
  const AppDataRow({required this.cells});

  final List<Widget> cells;
}
