import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/api_exception.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/branch.dart';
import '../../models/plan.dart';
import '../../models/service.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/plan_providers.dart';
import '../../widgets/widgets.dart';

/// Planos mensais na área do proprietário: criar, editar e ver assinantes.
class OwnerPlansPage extends ConsumerWidget {
  const OwnerPlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(plansProvider);

    return Scaffold(
      body: AsyncView<List<Plan>>(
        value: plans,
        onRetry: () => ref.invalidate(plansProvider),
        isEmpty: (items) => items.isEmpty,
        emptyIcon: Icons.card_membership_outlined,
        emptyMessage: 'Nenhum plano mensal cadastrado ainda.',
        emptyActionLabel: 'Criar plano',
        onEmptyAction: () => _openForm(context, ref),
        builder: (items) => ListView(
          padding: Responsive.pagePadding(context),
          children: [
            ...items.map(
              (plan) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _PlanCard(plan: plan),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo plano'),
      ),
    );
  }

  static Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    Plan? plan,
  }) async {
    // A listagem não traz `pays_barber_commission`. Abrir o formulário com ela
    // e salvar sobrescreveria a configuração de comissão — a mesma armadilha
    // que já apareceu na edição de barbeiros.
    Plan? full = plan;
    if (plan != null) {
      try {
        full = await ref.read(planRepositoryProvider).plan(plan.id);
      } on ApiException catch (error) {
        if (context.mounted) AppFeedback.error(context, error.message);
        return;
      }
    }

    if (!context.mounted) return;
    await AppBottomSheet.show<void>(
      context,
      title: plan == null ? 'Novo plano' : 'Editar plano',
      subtitle: full?.name,
      child: _PlanForm(plan: full),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard({required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final branches =
        ref.watch(branchesProvider).valueOrNull ?? const <Branch>[];
    final scope = plan.branchIds.isEmpty
        ? 'Todas as filiais'
        : branches
            .where((branch) => plan.branchIds.contains(branch.id))
            .map((branch) => branch.name)
            .join(', ');

    return AppCard(
      onTap: () => OwnerPlansPage._openForm(context, ref, plan: plan),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            plan.name,
                            style: theme.textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!plan.isActive) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const AppBadge(
                            label: 'Inativo',
                            color: AppColors.danger,
                            dense: true,
                          ),
                        ] else if (!plan.isPublic) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const AppBadge(
                            label: 'Oculto',
                            color: AppColors.warning,
                            dense: true,
                          ),
                        ],
                      ],
                    ),
                    Text(scope, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(plan.price),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: AppColors.gold),
                  ),
                  AppBadge(
                    label: '${plan.subscribersCount} assinante(s)',
                    color: AppColors.info,
                    icon: Icons.people_rounded,
                    dense: true,
                  ),
                ],
              ),
            ],
          ),
          if (plan.services.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xxs,
              runSpacing: AppSpacing.xxs,
              children: plan.services
                  .map(
                    (item) => AppBadge(
                      label: '${item.serviceName} · ${item.quotaLabel}',
                      color: AppColors.success,
                      dense: true,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              AppButton.text(
                label: 'Assinantes',
                icon: Icons.people_outline_rounded,
                size: AppButtonSize.small,
                onPressed: () => _openSubscribers(context, plan),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openSubscribers(BuildContext context, Plan plan) {
    return AppBottomSheet.show<void>(
      context,
      title: 'Assinantes',
      subtitle: plan.name,
      child: _SubscribersList(planId: plan.id),
    );
  }
}

// ---------------------------------------------------------------------------
// Formulário
// ---------------------------------------------------------------------------
class _PlanForm extends ConsumerStatefulWidget {
  const _PlanForm({this.plan});

  final Plan? plan;

  @override
  ConsumerState<_PlanForm> createState() => _PlanFormState();
}

class _PlanFormState extends ConsumerState<_PlanForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _overage;

  late Set<int> _branchIds;

  /// Serviço -> cota do ciclo (`0` = ilimitado).
  late Map<int, int> _quotas;
  late bool _isActive;
  late bool _isPublic;
  late bool _paysCommission;
  bool _isLoading = false;

  bool get _isEditing => widget.plan != null;

  @override
  void initState() {
    super.initState();
    final plan = widget.plan;
    _name = TextEditingController(text: plan?.name ?? '');
    _description = TextEditingController(text: plan?.description ?? '');
    _price = TextEditingController(
      text: (plan?.price ?? 0).toStringAsFixed(2),
    );
    _overage = TextEditingController(
      text: (plan?.overageDiscountPercentage ?? 0).toStringAsFixed(2),
    );
    _branchIds = {...?plan?.branchIds};
    _quotas = {
      for (final item in plan?.services ?? const <PlanServiceItem>[])
        item.serviceId: item.monthlyQuota,
    };
    _isActive = plan?.isActive ?? true;
    _isPublic = plan?.isPublic ?? true;
    _paysCommission = plan?.paysBarberCommission ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _overage.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_quotas.isEmpty) {
      AppFeedback.error(context, 'Inclua ao menos um serviço no plano.');
      return;
    }

    setState(() => _isLoading = true);
    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'price': _parse(_price.text).toStringAsFixed(2),
      'overage_discount_percentage': _parse(_overage.text).toStringAsFixed(2),
      'pays_barber_commission': _paysCommission,
      'is_active': _isActive,
      'is_public': _isPublic,
      'branches': _branchIds.toList(),
      'service_items': _quotas.entries
          .map((entry) => {'service': entry.key, 'monthly_quota': entry.value})
          .toList(),
    };

    try {
      final repository = ref.read(planRepositoryProvider);
      if (_isEditing) {
        await repository.updatePlan(widget.plan!.id, payload);
      } else {
        await repository.createPlan(payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      AppFeedback.success(
        context,
        _isEditing ? 'Plano atualizado.' : 'Plano criado.',
      );
      ref.invalidate(plansProvider);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppFeedback.error(context, error.message);
      }
    }
  }

  static double _parse(String value) =>
      double.tryParse(value.replaceAll('.', '').replaceAll(',', '.')) ??
      double.tryParse(value) ??
      0;

  Future<void> _confirmDelete() async {
    final plan = widget.plan;
    if (plan == null) return;

    final confirmed = await AppDialog.confirm(
      context,
      title: 'Excluir plano?',
      message: 'Planos com assinantes ativos não podem ser excluídos — '
          'desative-os em vez disso.',
      confirmLabel: 'Excluir',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed || !mounted) return;

    try {
      await ref.read(planRepositoryProvider).deletePlan(plan.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      AppFeedback.success(context, 'Plano excluído.');
      ref.invalidate(plansProvider);
    } on ApiException catch (error) {
      if (mounted) AppFeedback.error(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final branches = ref.watch(branchesProvider);
    final services = ref.watch(allServicesProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Nome do plano',
            controller: _name,
            hint: 'Ex.: Corte Ilimitado',
            isRequired: true,
            validator: (value) => Validators.required(value, field: 'O nome'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Descrição',
            controller: _description,
            maxLines: 2,
            hint: 'O que o cliente vê na vitrine',
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Mensalidade (R\$)',
                  controller: _price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  isRequired: true,
                  validator: Validators.money,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  label: 'Desconto acima da cota (%)',
                  controller: _overage,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  helper: 'Aplicado quando a cota do mês acabar',
                  validator: Validators.money,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Serviços incluídos', style: theme.textTheme.labelLarge),
          Text(
            'Defina quantas vezes por mês cada serviço está incluído. '
            'Zero significa ilimitado.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          services.when(
            loading: () => const AppSkeleton(height: 80),
            error: (_, __) =>
                const Text('Não foi possível carregar os serviços.'),
            data: (items) => Column(
              children: [
                for (final service in items)
                  _ServiceQuotaRow(
                    service: service,
                    quota: _quotas[service.id],
                    onToggle: (selected) => setState(() {
                      if (selected) {
                        _quotas[service.id] = 1;
                      } else {
                        _quotas.remove(service.id);
                      }
                    }),
                    onQuotaChanged: (value) =>
                        setState(() => _quotas[service.id] = value),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Filiais', style: theme.textTheme.labelLarge),
          Text(
            'Sem seleção o plano vale em toda a rede.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          branches.when(
            loading: () => const AppSkeleton(height: 40),
            error: (_, __) =>
                const Text('Não foi possível carregar as filiais.'),
            data: (items) => Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: items
                  .map(
                    (branch) => FilterChip(
                      label: Text(branch.name),
                      selected: _branchIds.contains(branch.id),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _branchIds.add(branch.id);
                        } else {
                          _branchIds.remove(branch.id);
                        }
                      }),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile.adaptive(
            value: _paysCommission,
            onChanged: (value) => setState(() => _paysCommission = value),
            title: const Text('Pagar comissão ao barbeiro'),
            subtitle: const Text(
              'O atendimento coberto pelo plano gera comissão sobre o preço '
              'do serviço, mesmo sem o cliente pagar no balcão.',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile.adaptive(
            value: _isPublic,
            onChanged: (value) => setState(() => _isPublic = value),
            title: const Text('Visível ao cliente'),
            subtitle:
                const Text('Desligue para não aparecer na vitrine do app.'),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile.adaptive(
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            title: const Text('Plano ativo'),
            subtitle: const Text('Inativos não podem ser assinados.'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: _isEditing ? 'Salvar alterações' : 'Criar plano',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
          if (_isEditing) ...[
            const SizedBox(height: AppSpacing.xs),
            AppButton.danger(
              label: 'Excluir plano',
              onPressed: _confirmDelete,
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceQuotaRow extends StatelessWidget {
  const _ServiceQuotaRow({
    required this.service,
    required this.quota,
    required this.onToggle,
    required this.onQuotaChanged,
  });

  final Service service;

  /// `null` quando o serviço não faz parte do plano.
  final int? quota;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onQuotaChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final included = quota != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Row(
        children: [
          Checkbox(
            value: included,
            onChanged: (value) => onToggle(value ?? false),
          ),
          Expanded(
            child: Text(
              service.name,
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (included)
            SizedBox(
              width: 132,
              child: DropdownButtonFormField<int>(
                initialValue: quota,
                isDense: true,
                decoration: const InputDecoration(isDense: true),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Ilimitado')),
                  DropdownMenuItem(value: 1, child: Text('1x/mês')),
                  DropdownMenuItem(value: 2, child: Text('2x/mês')),
                  DropdownMenuItem(value: 3, child: Text('3x/mês')),
                  DropdownMenuItem(value: 4, child: Text('4x/mês')),
                  DropdownMenuItem(value: 6, child: Text('6x/mês')),
                  DropdownMenuItem(value: 8, child: Text('8x/mês')),
                ],
                onChanged: (value) => onQuotaChanged(value ?? 1),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Assinantes
// ---------------------------------------------------------------------------
class _SubscribersList extends ConsumerWidget {
  const _SubscribersList({required this.planId});

  final int planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscribers = ref.watch(planSubscribersProvider(planId));

    return AsyncView<List<Subscription>>(
      value: subscribers,
      onRetry: () => ref.invalidate(planSubscribersProvider(planId)),
      isEmpty: (items) => items.isEmpty,
      emptyIcon: Icons.people_outline_rounded,
      emptyMessage: 'Nenhum assinante ainda.',
      builder: (items) => Column(
        children: [
          for (final subscription in items)
            _SubscriberTile(subscription: subscription, planId: planId),
        ],
      ),
    );
  }
}

class _SubscriberTile extends ConsumerWidget {
  const _SubscriberTile({required this.subscription, required this.planId});

  final Subscription subscription;
  final int planId;

  Color get _statusColor => switch (subscription.status) {
        SubscriptionStatus.active => AppColors.success,
        SubscriptionStatus.pendingPayment => AppColors.warning,
        SubscriptionStatus.pastDue => AppColors.danger,
        _ => AppColors.info,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final invoice = subscription.openInvoice;
    final used = subscription.quotas
        .map((quota) => quota.used)
        .fold<int>(0, (total, value) => total + value);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                      subscription.clientName,
                      style: theme.textTheme.bodyLarge,
                    ),
                    Text(
                      '${subscription.billingType.label} · '
                      '${used}x usado(s) neste ciclo',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (subscription.currentPeriodEnd != null)
                      Text(
                        'Válido até '
                        '${Formatters.date(subscription.currentPeriodEnd)}',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              AppBadge(
                label: subscription.status.label,
                color: _statusColor,
                dense: true,
              ),
            ],
          ),
          // Cliente que pagou fora do app precisa ser regularizado no caixa.
          if (invoice != null && invoice.isPending) ...[
            const SizedBox(height: AppSpacing.xxs),
            AppButton.outline(
              label: 'Confirmar pagamento de '
                  '${Formatters.currency(invoice.amount)}',
              size: AppButtonSize.small,
              onPressed: () => _confirm(context, ref, invoice),
            ),
          ],
          const Divider(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref,
    SubscriptionInvoice invoice,
  ) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Confirmar pagamento?',
      message: 'Isto libera o plano de ${subscription.clientName} e lança '
          '${Formatters.currency(invoice.amount)} como receita no caixa. '
          'Use apenas quando o pagamento foi recebido fora do app.',
      confirmLabel: 'Confirmar',
      icon: Icons.price_check_rounded,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(planRepositoryProvider).confirmInvoice(invoice.id);
      if (!context.mounted) return;
      AppFeedback.success(context, 'Pagamento confirmado.');
      ref.invalidate(planSubscribersProvider(planId));
      ref.invalidate(plansProvider);
    } on ApiException catch (error) {
      if (context.mounted) AppFeedback.error(context, error.message);
    }
  }
}
