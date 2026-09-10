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
import '../../models/client.dart';
import '../../models/payment.dart';
import '../../models/product.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/client_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/inventory_providers.dart';
import '../../widgets/widgets.dart';

class OwnerProductsPage extends ConsumerWidget {
  const OwnerProductsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppSearchField(
              hint: 'Buscar por nome, SKU ou código de barras',
              onSearch: (value) => ref
                  .read(productFilterProvider.notifier)
                  .update((state) => state.copyWith(search: value, page: 1)),
            ),
          ),
          Expanded(
            child: AsyncView<Paginated<Product>>(
              value: products,
              onRetry: () => ref.invalidate(productsProvider),
              emptyMessage: 'Nenhum produto cadastrado.',
              isEmpty: (page) => page.isEmpty,
              emptyIcon: Icons.inventory_2_outlined,
              emptyActionLabel: 'Cadastrar produto',
              onEmptyAction: () => _openForm(context, ref),
              builder: (page) => ListView(
                padding: Responsive.pagePadding(context),
                children: [
                  ...page.results.map(
                    (product) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _ProductCard(product: product),
                    ),
                  ),
                  AppPagination(
                    currentPage: page.currentPage,
                    totalPages: page.totalPages,
                    totalCount: page.count,
                    onPageChanged: (value) => ref
                        .read(productFilterProvider.notifier)
                        .update((state) => state.copyWith(page: value)),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (cart.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: FloatingActionButton.extended(
                heroTag: 'cart',
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white,
                onPressed: () => AppBottomSheet.show<void>(
                  context,
                  title: 'Finalizar venda',
                  child: const _CheckoutSheet(),
                ),
                icon: const Icon(Icons.shopping_cart_rounded),
                label: Text(
                  '${cart.fold<int>(0, (sum, line) => sum + line.quantity)} item(ns) · '
                  '${Formatters.currency(ref.watch(cartTotalProvider))}',
                ),
              ),
            ),
          FloatingActionButton.extended(
            heroTag: 'newProduct',
            onPressed: () => _openForm(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Novo produto'),
          ),
        ],
      ),
    );
  }

  static Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    Product? product,
  }) async {
    await AppBottomSheet.show<void>(
      context,
      title: product == null ? 'Novo produto' : 'Editar produto',
      subtitle: product?.name,
      child: _ProductForm(product: product),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: () => OwnerProductsPage._openForm(context, ref, product: product),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(Icons.inventory_2_outlined),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        product.name,
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!product.isActive) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const AppBadge(
                        label: 'Inativo',
                        color: AppColors.grey,
                        dense: true,
                      ),
                    ],
                  ],
                ),
                Text('SKU ${product.sku}', style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    AppBadge(
                      label: '${product.totalStock} em estoque',
                      color: product.hasLowStock
                          ? AppColors.warning
                          : AppColors.success,
                      icon: product.hasLowStock
                          ? Icons.warning_amber_rounded
                          : Icons.check_rounded,
                      dense: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.currency(product.salePrice),
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: AppColors.gold),
              ),
              IconButton(
                tooltip: 'Adicionar à venda',
                onPressed: product.totalStock > 0
                    ? () {
                        ref.read(cartProvider.notifier).add(product);
                        AppFeedback.success(
                          context,
                          '${product.name} adicionado à venda.',
                        );
                      }
                    : null,
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductForm extends ConsumerStatefulWidget {
  const _ProductForm({this.product});

  final Product? product;

  @override
  ConsumerState<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<_ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.product?.name ?? '');
  late final TextEditingController _sku =
      TextEditingController(text: widget.product?.sku ?? '');
  late final TextEditingController _barcode =
      TextEditingController(text: widget.product?.barcode ?? '');
  late final TextEditingController _cost = TextEditingController(
    text: (widget.product?.costPrice ?? 0).toStringAsFixed(2),
  );
  late final TextEditingController _price = TextEditingController(
    text: (widget.product?.salePrice ?? 0).toStringAsFixed(2),
  );
  late final TextEditingController _commission = TextEditingController(
    text: (widget.product?.commissionPercentage ?? 0).toStringAsFixed(2),
  );
  late final TextEditingController _description =
      TextEditingController(text: widget.product?.description ?? '');

  late bool _isActive = widget.product?.isActive ?? true;
  bool _isLoading = false;

  bool get _isEditing => widget.product != null;

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _barcode.dispose();
    _cost.dispose();
    _price.dispose();
    _commission.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'sku': _sku.text.trim().toUpperCase(),
      'barcode': _barcode.text.trim(),
      'description': _description.text.trim(),
      'cost_price':
          double.parse(_cost.text.replaceAll(',', '.')).toStringAsFixed(2),
      'sale_price':
          double.parse(_price.text.replaceAll(',', '.')).toStringAsFixed(2),
      'commission_percentage':
          double.parse(_commission.text.replaceAll(',', '.'))
              .toStringAsFixed(2),
      'is_active': _isActive,
    };

    try {
      final repository = ref.read(inventoryRepositoryProvider);
      if (_isEditing) {
        await repository.updateProduct(widget.product!.id, payload);
      } else {
        await repository.createProduct(payload);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      AppFeedback.success(
        context,
        _isEditing ? 'Produto atualizado.' : 'Produto criado.',
      );
      ref.invalidate(productsProvider);
      ref.invalidate(activeProductsProvider);
    } on ApiException catch (error) {
      if (mounted) {
        AppFeedback.error(context, error.errorFor('sku') ?? error.message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Nome',
            controller: _name,
            isRequired: true,
            validator: (value) => Validators.required(value, field: 'O nome'),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'SKU',
                  controller: _sku,
                  isRequired: true,
                  validator: (value) =>
                      Validators.required(value, field: 'O SKU'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  label: 'Código de barras',
                  controller: _barcode,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Preço de custo',
                  controller: _cost,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [MoneyInputFormatter()],
                  validator: Validators.money,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  label: 'Preço de venda',
                  controller: _price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [MoneyInputFormatter()],
                  isRequired: true,
                  validator: Validators.money,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Comissão do barbeiro (%)',
            controller: _commission,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [MoneyInputFormatter()],
            helper: 'Percentual pago ao barbeiro que vender este produto.',
            validator: (value) => Validators.money(value, isRequired: false),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Descrição',
            controller: _description,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile.adaptive(
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            title: const Text('Produto ativo'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: _isEditing ? 'Salvar alterações' : 'Criar produto',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
          if (_isEditing && widget.product!.stockByBranch.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const AppSectionHeader(title: 'Estoque por filial'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var index = 0;
                      index < widget.product!.stockByBranch.length;
                      index++) ...[
                    if (index > 0) const Divider(height: 1),
                    ListTile(
                      dense: true,
                      title:
                          Text(widget.product!.stockByBranch[index].branchName),
                      subtitle: Text(
                        'Mínimo: ${widget.product!.stockByBranch[index].minimumStock}',
                      ),
                      trailing: AppBadge(
                        label:
                            '${widget.product!.stockByBranch[index].quantity} un.',
                        color:
                            widget.product!.stockByBranch[index].isBelowMinimum
                                ? AppColors.warning
                                : AppColors.success,
                        dense: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Fechamento da venda de produtos (PDV simples).
class _CheckoutSheet extends ConsumerStatefulWidget {
  const _CheckoutSheet();

  @override
  ConsumerState<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<_CheckoutSheet> {
  Branch? _branch;
  Client? _client;
  PaymentMethod _method = PaymentMethod.pix;
  bool _isLoading = false;

  Future<void> _submit() async {
    final lines = ref.read(cartProvider);
    if (_branch == null) {
      AppFeedback.error(context, 'Selecione a filial da venda.');
      return;
    }
    if (lines.isEmpty) {
      AppFeedback.error(context, 'Adicione ao menos um produto.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(inventoryRepositoryProvider).createSale(
            branchId: _branch!.id,
            items: lines,
            clientId: _client?.id,
            paymentMethod: _method.value,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      AppFeedback.success(context, 'Venda registrada com sucesso.');
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(productsProvider);
      ref.invalidate(salesProvider);
      ref.invalidate(stockProvider);
      ref.invalidate(ownerDashboardProvider);
    } on ApiException catch (error) {
      if (mounted) AppFeedback.error(context, error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final branches = ref.watch(branchesProvider);
    final clients = ref.watch(clientsProvider);
    final theme = Theme.of(context);

    if (lines.isEmpty) {
      return const AppEmptyState(
        message: 'O carrinho está vazio.',
        icon: Icons.shopping_cart_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...lines.map(
          (line) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(line.product.name),
            subtitle: Text(
              '${Formatters.currency(line.product.salePrice)} · '
              'estoque: ${line.product.totalStock}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => ref
                      .read(cartProvider.notifier)
                      .setQuantity(line.product.id, line.quantity - 1),
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
                Text('${line.quantity}', style: theme.textTheme.titleSmall),
                IconButton(
                  onPressed: () => ref
                      .read(cartProvider.notifier)
                      .setQuantity(line.product.id, line.quantity + 1),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
          ),
        ),
        const Divider(),
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
        clients.when(
          loading: () => const AppSkeleton(height: 64),
          error: (_, __) => const SizedBox.shrink(),
          data: (page) => AppDropdown<Client>(
            label: 'Cliente (opcional)',
            hint: 'Venda avulsa',
            items: page.results,
            value: _client,
            itemLabel: (client) => client.name,
            onChanged: (client) => setState(() => _client = client),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Forma de pagamento', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: PaymentMethod.checkoutOptions
              .map(
                (method) => ChoiceChip(
                  label: Text(method.label),
                  selected: _method == method,
                  onSelected: (_) => setState(() => _method = method),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: theme.textTheme.titleSmall),
              Text(
                Formatters.currency(total),
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: AppColors.success),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Confirmar venda',
          icon: Icons.point_of_sale_rounded,
          isLoading: _isLoading,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton.text(
          label: 'Esvaziar carrinho',
          expanded: true,
          onPressed: () {
            ref.read(cartProvider.notifier).clear();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
