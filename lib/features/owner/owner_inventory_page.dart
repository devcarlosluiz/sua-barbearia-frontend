import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/api_exception.dart';
import '../../core/network/paginated.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/branch.dart';
import '../../models/product.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/inventory_providers.dart';
import '../../widgets/widgets.dart';

class OwnerInventoryPage extends ConsumerStatefulWidget {
  const OwnerInventoryPage({super.key});

  @override
  ConsumerState<OwnerInventoryPage> createState() => _OwnerInventoryPageState();
}

class _OwnerInventoryPageState extends ConsumerState<OwnerInventoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _BranchSelector(),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Saldos'),
              Tab(text: 'Movimentações'),
              Tab(text: 'Vendas'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [_StockTab(), _MovementsTab(), _SalesTab()],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AppBottomSheet.show<void>(
          context,
          title: 'Movimentar estoque',
          subtitle: 'Entrada, ajuste, perda ou devolução.',
          child: const _MovementForm(),
        ),
        icon: const Icon(Icons.sync_alt_rounded),
        label: const Text('Movimentar'),
      ),
    );
  }
}

class _BranchSelector extends ConsumerWidget {
  const _BranchSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branches = ref.watch(branchesProvider);
    final selected = ref.watch(stockBranchFilterProvider);
    final theme = Theme.of(context);

    return branches.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) => Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xxs),
                child: ChoiceChip(
                  label: const Text('Todas as filiais'),
                  selected: selected == null,
                  onSelected: (_) =>
                      ref.read(stockBranchFilterProvider.notifier).state = null,
                ),
              ),
              ...items.map(
                (branch) => Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xxs),
                  child: ChoiceChip(
                    label: Text(branch.name),
                    selected: selected == branch.id,
                    onSelected: (_) => ref
                        .read(stockBranchFilterProvider.notifier)
                        .state = branch.id,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockTab extends ConsumerWidget {
  const _StockTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stock = ref.watch(stockProvider);
    final lowStock =
        ref.watch(lowStockProvider).valueOrNull ?? const <StockItem>[];

    return AsyncView<Paginated<StockItem>>(
      value: stock,
      onRetry: () => ref.invalidate(stockProvider),
      emptyMessage: 'Nenhum saldo de estoque registrado.',
      isEmpty: (page) => page.isEmpty,
      emptyIcon: Icons.warehouse_outlined,
      builder: (page) => ListView(
        padding: Responsive.pagePadding(context),
        children: [
          if (lowStock.isNotEmpty) ...[
            AppCard(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderColor: AppColors.warning.withValues(alpha: 0.4),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${lowStock.length} produto(s) no estoque mínimo ou abaixo.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < page.results.length; index++) ...[
                  if (index > 0) const Divider(height: 1),
                  _StockTile(item: page.results[index]),
                ],
              ],
            ),
          ),
          AppPagination(
            currentPage: page.currentPage,
            totalPages: page.totalPages,
            totalCount: page.count,
            onPageChanged: (value) =>
                ref.read(stockPageProvider.notifier).state = value,
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _StockTile extends ConsumerWidget {
  const _StockTile({required this.item});

  final StockItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListTile(
      title: Text(item.productName),
      subtitle: Text('${item.branchName} · mínimo ${item.minimumStock}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBadge(
            label: '${item.quantity} un.',
            color: item.isBelowMinimum ? AppColors.warning : AppColors.success,
            dense: true,
          ),
          IconButton(
            tooltip: 'Definir estoque mínimo',
            icon: const Icon(Icons.tune_rounded, size: 20),
            onPressed: () => _editMinimum(context, ref, theme),
          ),
        ],
      ),
    );
  }

  Future<void> _editMinimum(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) async {
    final value = await AppDialog.prompt(
      context,
      title: 'Estoque mínimo',
      message: '${item.productName} em ${item.branchName}',
      label: 'Quantidade mínima',
      maxLines: 1,
      isRequired: true,
    );
    final parsed = int.tryParse(value ?? '');
    if (parsed == null || !context.mounted) return;

    try {
      await ref
          .read(inventoryRepositoryProvider)
          .updateMinimumStock(item.id, parsed);
      ref.invalidate(stockProvider);
      ref.invalidate(lowStockProvider);
      if (context.mounted) {
        AppFeedback.success(context, 'Estoque mínimo atualizado.');
      }
    } on ApiException catch (error) {
      if (context.mounted) AppFeedback.error(context, error.message);
    }
  }
}

class _MovementsTab extends ConsumerWidget {
  const _MovementsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movements = ref.watch(stockMovementsProvider);

    return AsyncView<Paginated<StockMovement>>(
      value: movements,
      onRetry: () => ref.invalidate(stockMovementsProvider),
      emptyMessage: 'Nenhuma movimentação registrada.',
      isEmpty: (page) => page.isEmpty,
      emptyIcon: Icons.sync_alt_rounded,
      builder: (page) => ListView(
        padding: Responsive.pagePadding(context),
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < page.results.length; index++) ...[
                  if (index > 0) const Divider(height: 1),
                  _MovementTile(movement: page.results[index]),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement});

  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = movement.isPositive ? AppColors.success : AppColors.danger;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.14),
        child: Icon(
          movement.isPositive ? Icons.add_rounded : Icons.remove_rounded,
          color: color,
          size: 18,
        ),
      ),
      title: Text(movement.productName),
      subtitle: Text(
        '${movement.typeLabel} · ${movement.branchName} · '
        '${Formatters.dateTime(movement.createdAt)}'
        '${movement.reason.isEmpty ? '' : '\n${movement.reason}'}',
      ),
      isThreeLine: movement.reason.isNotEmpty,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${movement.isPositive ? '+' : ''}${movement.quantity}',
            style: theme.textTheme.titleSmall?.copyWith(color: color),
          ),
          Text(
            '${movement.previousQuantity} → ${movement.newQuantity}',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _SalesTab extends ConsumerWidget {
  const _SalesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(salesProvider);

    return AsyncView<Paginated<Sale>>(
      value: sales,
      onRetry: () => ref.invalidate(salesProvider),
      emptyMessage: 'Nenhuma venda registrada.',
      isEmpty: (page) => page.isEmpty,
      emptyIcon: Icons.point_of_sale_rounded,
      builder: (page) => ListView(
        padding: Responsive.pagePadding(context),
        children: [
          ...page.results.map(
            (sale) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _SaleCard(sale: sale),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _SaleCard extends ConsumerWidget {
  const _SaleCard({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.clientName ?? 'Venda avulsa',
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      '${sale.branchName} · '
                      '${Formatters.dateTime(sale.completedAt ?? sale.createdAt)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(sale.total),
                    style: theme.textTheme.titleMedium,
                  ),
                  AppBadge(
                    label: sale.statusLabel,
                    color: sale.status == 'COMPLETED'
                        ? AppColors.success
                        : sale.status == 'CANCELLED'
                            ? AppColors.danger
                            : AppColors.warning,
                    dense: true,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...sale.items.map(
            (item) => Text(
              '${item.quantity}x ${item.productName} · '
              '${Formatters.currency(item.total)}',
              style: theme.textTheme.bodySmall,
            ),
          ),
          if (sale.status == 'COMPLETED') ...[
            const Divider(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _cancel(context, ref),
                icon: const Icon(Icons.undo_rounded, size: 18),
                label: const Text('Cancelar venda'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final reason = await AppDialog.prompt(
      context,
      title: 'Cancelar venda',
      message: 'Os produtos voltarão ao estoque e o pagamento será estornado.',
      label: 'Motivo',
      confirmLabel: 'Cancelar venda',
    );
    if (reason == null || !context.mounted) return;

    try {
      await ref
          .read(inventoryRepositoryProvider)
          .cancelSale(sale.id, reason: reason);
      ref.invalidate(salesProvider);
      ref.invalidate(stockProvider);
      ref.invalidate(stockMovementsProvider);
      if (context.mounted) AppFeedback.success(context, 'Venda cancelada.');
    } on ApiException catch (error) {
      if (context.mounted) AppFeedback.error(context, error.message);
    }
  }
}

class _MovementForm extends ConsumerStatefulWidget {
  const _MovementForm();

  @override
  ConsumerState<_MovementForm> createState() => _MovementFormState();
}

class _MovementFormState extends ConsumerState<_MovementForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController(text: '1');
  final _reason = TextEditingController();
  Product? _product;
  Branch? _branch;
  String _type = 'ENTRY';
  bool _isLoading = false;

  static const _types = {
    'ENTRY': 'Entrada',
    'ADJUSTMENT': 'Ajuste (saldo final)',
    'LOSS': 'Perda',
    'RETURN': 'Devolução',
  };

  @override
  void dispose() {
    _quantity.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_product == null || _branch == null) {
      AppFeedback.error(context, 'Selecione o produto e a filial.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(inventoryRepositoryProvider).registerMovement(
            productId: _product!.id,
            branchId: _branch!.id,
            type: _type,
            quantity: int.parse(_quantity.text),
            unitCost: _type == 'ENTRY' ? _product!.costPrice : null,
            reason: _reason.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      AppFeedback.success(context, 'Movimentação registrada.');
      ref.invalidate(stockProvider);
      ref.invalidate(stockMovementsProvider);
      ref.invalidate(lowStockProvider);
      ref.invalidate(productsProvider);
    } on ApiException catch (error) {
      if (mounted) AppFeedback.error(context, error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(activeProductsProvider);
    final branches = ref.watch(branchesProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppDropdown<String>(
            label: 'Tipo de movimentação',
            items: _types.keys.toList(),
            value: _type,
            isRequired: true,
            itemLabel: (value) => _types[value]!,
            onChanged: (value) => setState(() => _type = value ?? 'ENTRY'),
          ),
          const SizedBox(height: AppSpacing.md),
          products.when(
            loading: () => const AppSkeleton(height: 64),
            error: (_, __) =>
                const Text('Não foi possível carregar os produtos.'),
            data: (items) => AppDropdown<Product>(
              label: 'Produto',
              items: items,
              value: items.firstWhereOrNull((item) => item.id == _product?.id),
              isRequired: true,
              itemLabel: (product) => '${product.name} (${product.sku})',
              onChanged: (product) => setState(() => _product = product),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          branches.when(
            loading: () => const AppSkeleton(height: 64),
            error: (_, __) => const SizedBox.shrink(),
            data: (items) => AppDropdown<Branch>(
              label: 'Filial',
              items: items,
              value: _branch,
              isRequired: true,
              itemLabel: (branch) => branch.name,
              onChanged: (branch) => setState(() => _branch = branch),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: _type == 'ADJUSTMENT' ? 'Saldo final contado' : 'Quantidade',
            controller: _quantity,
            keyboardType: TextInputType.number,
            isRequired: true,
            helper: _type == 'ADJUSTMENT'
                ? 'Informe o total contado na prateleira.'
                : null,
            validator: (value) => _type == 'ADJUSTMENT'
                ? (int.tryParse(value ?? '') == null
                    ? 'Informe um número inteiro.'
                    : null)
                : Validators.positiveInteger(value),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Motivo',
            controller: _reason,
            hint: 'Ex.: compra do fornecedor, contagem mensal',
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Registrar movimentação',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
