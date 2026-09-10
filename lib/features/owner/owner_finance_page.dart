import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/api_exception.dart';
import '../../core/network/paginated.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/barber.dart';
import '../../models/branch.dart';
import '../../models/dashboard.dart';
import '../../models/finance.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/finance_providers.dart';
import '../../widgets/widgets.dart';
import 'widgets/charts.dart';

class OwnerFinancePage extends ConsumerStatefulWidget {
  const OwnerFinancePage({super.key});

  @override
  ConsumerState<OwnerFinancePage> createState() => _OwnerFinancePageState();
}

class _OwnerFinancePageState extends ConsumerState<OwnerFinancePage>
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
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Caixa'),
              Tab(text: 'Lançamentos'),
              Tab(text: 'Comissões'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _CashFlowTab(),
                _TransactionsTab(),
                _CommissionsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AppBottomSheet.show<void>(
          context,
          title: 'Novo lançamento',
          child: const _TransactionForm(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Lançamento'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Caixa
// ---------------------------------------------------------------------------
class _CashFlowTab extends ConsumerWidget {
  const _CashFlowTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(cashFlowSummaryProvider);

    return Column(
      children: [
        const _FinancePeriodBar(),
        Expanded(
          child: AsyncView<CashFlowSummary>(
            value: summary,
            onRetry: () => ref.invalidate(cashFlowSummaryProvider),
            builder: (data) => ListView(
              padding: Responsive.pagePadding(context),
              children: [
                StatGrid(
                  minTileWidth: 190,
                  children: [
                    StatCard(
                      label: 'Receitas',
                      value: Formatters.currency(data.totalIncome),
                      icon: Icons.arrow_downward_rounded,
                      accentColor: AppColors.success,
                    ),
                    StatCard(
                      label: 'Despesas',
                      value: Formatters.currency(data.totalExpense),
                      icon: Icons.arrow_upward_rounded,
                      accentColor: AppColors.danger,
                    ),
                    StatCard(
                      label: 'Saldo',
                      value: Formatters.currency(data.balance),
                      icon: Icons.account_balance_wallet_rounded,
                      accentColor: data.balance >= 0
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                DistributionPieChart(
                  title: 'Recebimentos por forma de pagamento',
                  points: data.byPaymentMethod
                      .map(
                        (item) => ChartPoint(
                          label: _paymentLabel(item.method),
                          value: item.total,
                          count: item.count,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                RankingBarChart(
                  title: 'Movimento por categoria',
                  points: data.byCategory
                      .map(
                        (item) => ChartPoint(
                          label: '${_categoryLabel(item.category)} '
                              '(${item.type == 'INCOME' ? 'receita' : 'despesa'})',
                          value: item.total,
                          count: item.count,
                        ),
                      )
                      .toList(),
                  maxItems: 10,
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.download_rounded),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(
                        child: Text(
                          'Exporte os lançamentos do período em CSV para a contabilidade.',
                        ),
                      ),
                      AppButton.outline(
                        label: 'Exportar',
                        expanded: false,
                        size: AppButtonSize.small,
                        onPressed: () => _showExportInfo(context, data),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showExportInfo(BuildContext context, CashFlowSummary data) {
    AppDialog.show<void>(
      context,
      title: 'Exportar lançamentos',
      content: Text(
        'A exportação em CSV está disponível na API:\n\n'
        'GET /api/v1/finance/transactions/export/'
        '?start_date=${Formatters.isoDate(data.startDate)}'
        '&end_date=${Formatters.isoDate(data.endDate)}\n\n'
        'Abra o endereço autenticado no navegador para baixar o arquivo.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  static String _paymentLabel(String value) {
    const labels = {
      'PIX': 'PIX',
      'CASH': 'Dinheiro',
      'CREDIT_CARD': 'Crédito',
      'DEBIT_CARD': 'Débito',
      'LOYALTY': 'Pontos',
      'OTHER': 'Outro',
    };
    return labels[value] ?? value;
  }

  static String _categoryLabel(String value) {
    const labels = {
      'SERVICES': 'Serviços',
      'PRODUCTS': 'Produtos',
      'SALARY': 'Salários',
      'COMMISSION': 'Comissões',
      'RENT': 'Aluguel',
      'ELECTRICITY': 'Energia',
      'WATER': 'Água',
      'INTERNET': 'Internet',
      'SUPPLIES': 'Insumos',
      'MARKETING': 'Marketing',
      'TAXES': 'Impostos',
      'OTHER': 'Outros',
    };
    return labels[value] ?? value;
  }
}

class _FinancePeriodBar extends ConsumerWidget {
  const _FinancePeriodBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(financeFilterProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final period in DashboardPeriod.values)
              if (period != DashboardPeriod.custom)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xxs),
                  child: ChoiceChip(
                    label: Text(period.label),
                    selected: filter.period == period,
                    onSelected: (_) => ref
                        .read(financeFilterProvider.notifier)
                        .update(
                            (state) => state.copyWith(period: period, page: 1)),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lançamentos
// ---------------------------------------------------------------------------
class _TransactionsTab extends ConsumerWidget {
  const _TransactionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);
    final filter = ref.watch(financeFilterProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: AppSearchField(
                  hint: 'Buscar por descrição',
                  onSearch: (value) => ref
                      .read(financeFilterProvider.notifier)
                      .update(
                          (state) => state.copyWith(search: value, page: 1)),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              SegmentedButton<String?>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<String?>(value: null, label: Text('Todos')),
                  ButtonSegment<String?>(
                      value: 'INCOME', label: Text('Receitas')),
                  ButtonSegment<String?>(
                      value: 'EXPENSE', label: Text('Despesas')),
                ],
                selected: {filter.type},
                onSelectionChanged: (values) =>
                    ref.read(financeFilterProvider.notifier).update(
                          (state) => values.first == null
                              ? state.copyWith(clearType: true, page: 1)
                              : state.copyWith(type: values.first, page: 1),
                        ),
              ),
            ],
          ),
        ),
        Expanded(
          child: AsyncView<Paginated<FinanceTransaction>>(
            value: transactions,
            onRetry: () => ref.invalidate(transactionsProvider),
            emptyMessage: 'Nenhum lançamento no período.',
            isEmpty: (page) => page.isEmpty,
            builder: (page) => ListView(
              padding: Responsive.pagePadding(context),
              children: [
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var index = 0;
                          index < page.results.length;
                          index++) ...[
                        if (index > 0) const Divider(height: 1),
                        _TransactionTile(transaction: page.results[index]),
                      ],
                    ],
                  ),
                ),
                AppPagination(
                  currentPage: page.currentPage,
                  totalPages: page.totalPages,
                  totalCount: page.count,
                  onPageChanged: (value) => ref
                      .read(financeFilterProvider.notifier)
                      .update((state) => state.copyWith(page: value)),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.transaction});

  final FinanceTransaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isIncome = transaction.type == TransactionType.income;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: (isIncome ? AppColors.success : AppColors.danger)
            .withValues(alpha: 0.14),
        child: Icon(
          isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
          color: isIncome ? AppColors.success : AppColors.danger,
          size: 18,
        ),
      ),
      title: Text(transaction.description),
      subtitle: Text(
        '${Formatters.date(transaction.date)} · ${transaction.categoryLabel}'
        '${transaction.branchName.isEmpty ? '' : ' · ${transaction.branchName}'}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${isIncome ? '+' : '-'} ${Formatters.currency(transaction.amount)}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: isIncome ? AppColors.success : AppColors.danger,
            ),
          ),
          if (!transaction.isAutomatic)
            IconButton(
              tooltip: 'Excluir lançamento',
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              onPressed: () => _delete(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Excluir lançamento',
      message: 'Deseja excluir "${transaction.description}"?',
      confirmLabel: 'Excluir',
      isDestructive: true,
    );
    if (!confirmed) return;

    try {
      await ref
          .read(financeRepositoryProvider)
          .deleteTransaction(transaction.id);
      ref.invalidate(transactionsProvider);
      ref.invalidate(cashFlowSummaryProvider);
      if (context.mounted) AppFeedback.success(context, 'Lançamento excluído.');
    } on ApiException catch (error) {
      if (context.mounted) AppFeedback.error(context, error.message);
    }
  }
}

class _TransactionForm extends ConsumerStatefulWidget {
  const _TransactionForm();

  @override
  ConsumerState<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<_TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _type = 'EXPENSE';
  String _category = 'OTHER';
  Branch? _branch;
  Barber? _barber;
  DateTime _date = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_branch == null) {
      AppFeedback.error(context, 'Selecione a filial do lançamento.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(financeRepositoryProvider).createTransaction(
            branchId: _branch!.id,
            type: _type,
            category: _category,
            description: _descriptionController.text.trim(),
            amount: double.parse(_amountController.text.replaceAll(',', '.')),
            date: _date,
            barberId: _barber?.id,
            notes: _notesController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      AppFeedback.success(context, 'Lançamento registrado.');
      ref.invalidate(transactionsProvider);
      ref.invalidate(cashFlowSummaryProvider);
      ref.invalidate(ownerDashboardProvider);
    } on ApiException catch (error) {
      if (mounted) AppFeedback.error(context, error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branches = ref.watch(branchesProvider);
    final barbers =
        ref.watch(barbersProvider(CatalogFilter(branchId: _branch?.id)));
    final choices = ref.watch(financeChoicesProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<String>(
                value: 'INCOME',
                label: Text('Receita'),
                icon: Icon(Icons.arrow_downward_rounded),
              ),
              ButtonSegment<String>(
                value: 'EXPENSE',
                label: Text('Despesa'),
                icon: Icon(Icons.arrow_upward_rounded),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (values) =>
                setState(() => _type = values.first),
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
          choices.when(
            loading: () => const AppSkeleton(height: 64),
            error: (_, __) => const SizedBox.shrink(),
            data: (data) {
              final categories = data['categories'] ?? const [];
              return AppDropdown<String>(
                label: 'Categoria',
                items: categories.map((item) => item['value']!).toList(),
                value: _category,
                isRequired: true,
                itemLabel: (value) => categories.firstWhere(
                  (item) => item['value'] == value,
                  orElse: () => {'label': value},
                )['label']!,
                onChanged: (value) =>
                    setState(() => _category = value ?? 'OTHER'),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Descrição',
            controller: _descriptionController,
            isRequired: true,
            validator: (value) =>
                Validators.required(value, field: 'A descrição'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Valor',
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [MoneyInputFormatter()],
            isRequired: true,
            validator: Validators.money,
          ),
          const SizedBox(height: AppSpacing.md),
          AppDatePicker(
            label: 'Data',
            value: _date,
            isRequired: true,
            onChanged: (value) => setState(() => _date = value),
          ),
          const SizedBox(height: AppSpacing.md),
          barbers.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (items) => AppDropdown<Barber>(
              label: 'Barbeiro (opcional)',
              hint: 'Nenhum',
              items: items,
              value: _barber,
              itemLabel: (barber) => barber.name,
              onChanged: (barber) => setState(() => _barber = barber),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Observações',
            controller: _notesController,
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Salvar lançamento',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Comissões
// ---------------------------------------------------------------------------
class _CommissionsTab extends ConsumerStatefulWidget {
  const _CommissionsTab();

  @override
  ConsumerState<_CommissionsTab> createState() => _CommissionsTabState();
}

class _CommissionsTabState extends ConsumerState<_CommissionsTab> {
  final Set<int> _selected = {};
  bool _isPaying = false;

  Future<void> _pay() async {
    if (_selected.isEmpty) return;
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Pagar comissões',
      message: 'Confirmar o pagamento de ${_selected.length} comissão(ões)? '
          'A despesa será lançada automaticamente no caixa.',
      confirmLabel: 'Pagar',
      icon: Icons.payments_rounded,
    );
    if (!confirmed) return;

    setState(() => _isPaying = true);
    try {
      final result = await ref
          .read(financeRepositoryProvider)
          .payCommissions(_selected.toList());
      if (!mounted) return;
      AppFeedback.success(
        context,
        '${result['paid_count']} comissão(ões) paga(s): '
        '${Formatters.currencyFromString('${result['total_amount']}')}',
      );
      setState(_selected.clear);
      ref.invalidate(commissionsProvider);
      ref.invalidate(cashFlowSummaryProvider);
      ref.invalidate(ownerDashboardProvider);
    } on ApiException catch (error) {
      if (mounted) AppFeedback.error(context, error.message);
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commissions = ref.watch(commissionsProvider);
    final filter = ref.watch(commissionFilterProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SegmentedButton<String?>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<String?>(
                  value: 'PENDING', label: Text('Pendentes')),
              ButtonSegment<String?>(value: 'PAID', label: Text('Pagas')),
              ButtonSegment<String?>(value: null, label: Text('Todas')),
            ],
            selected: {filter.status},
            onSelectionChanged: (values) {
              setState(_selected.clear);
              ref.read(commissionFilterProvider.notifier).update(
                    (state) => values.first == null
                        ? state.copyWith(clearStatus: true, page: 1)
                        : state.copyWith(status: values.first, page: 1),
                  );
            },
          ),
        ),
        Expanded(
          child: AsyncView<Paginated<Commission>>(
            value: commissions,
            onRetry: () => ref.invalidate(commissionsProvider),
            emptyMessage: 'Nenhuma comissão encontrada.',
            isEmpty: (page) => page.isEmpty,
            builder: (page) => ListView(
              padding: Responsive.pagePadding(context),
              children: [
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var index = 0;
                          index < page.results.length;
                          index++) ...[
                        if (index > 0) const Divider(height: 1),
                        _CommissionTile(
                          commission: page.results[index],
                          isSelected:
                              _selected.contains(page.results[index].id),
                          onToggle: (value) => setState(() {
                            if (value) {
                              _selected.add(page.results[index].id);
                            } else {
                              _selected.remove(page.results[index].id);
                            }
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
                AppPagination(
                  currentPage: page.currentPage,
                  totalPages: page.totalPages,
                  totalCount: page.count,
                  onPageChanged: (value) => ref
                      .read(commissionFilterProvider.notifier)
                      .update((state) => state.copyWith(page: value)),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
        if (_selected.isNotEmpty)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AppButton(
                label: 'Pagar ${_selected.length} comissão(ões)',
                icon: Icons.payments_rounded,
                isLoading: _isPaying,
                onPressed: _pay,
              ),
            ),
          ),
      ],
    );
  }
}

class _CommissionTile extends StatelessWidget {
  const _CommissionTile({
    required this.commission,
    required this.isSelected,
    required this.onToggle,
  });

  final Commission commission;
  final bool isSelected;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CheckboxListTile(
      value: isSelected,
      onChanged:
          commission.isPending ? (value) => onToggle(value ?? false) : null,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(commission.barberName),
      subtitle: Text(
        '${commission.serviceName ?? 'Venda de produto'} · '
        '${Formatters.date(commission.referenceDate)} · '
        '${commission.percentage.toStringAsFixed(0)}% de '
        '${Formatters.currency(commission.baseAmount)}',
      ),
      secondary: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Formatters.currency(commission.amount),
            style: theme.textTheme.titleSmall,
          ),
          AppBadge(
            label: commission.statusLabel,
            color: commission.isPaid ? AppColors.success : AppColors.warning,
            dense: true,
          ),
        ],
      ),
    );
  }
}
