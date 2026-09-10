import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/api_exception.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/loyalty.dart';
import '../../providers/core_providers.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/engagement_providers.dart';
import '../../widgets/widgets.dart';

class ClientLoyaltyPage extends ConsumerWidget {
  const ClientLoyaltyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loyalty = ref.watch(myLoyaltyProvider);
    final rewards = ref.watch(loyaltyRewardsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myLoyaltyProvider);
        ref.invalidate(loyaltyRewardsProvider);
      },
      child: AsyncView<LoyaltySummary>(
        value: loyalty,
        onRetry: () => ref.invalidate(myLoyaltyProvider),
        builder: (summary) => ListView(
          padding: Responsive.pagePadding(context),
          children: [
            _PointsCard(account: summary.account),
            const SizedBox(height: AppSpacing.lg),
            const AppSectionHeader(
              title: 'Recompensas',
              subtitle: 'Troque seus pontos por benefícios.',
            ),
            rewards.when(
              loading: () => const AppSkeleton(height: 120),
              error: (_, __) => const SizedBox.shrink(),
              data: (items) => items.isEmpty
                  ? const AppEmptyState(
                      message: 'Ainda não há recompensas cadastradas.',
                      icon: Icons.card_giftcard_rounded,
                    )
                  : Column(
                      children: items
                          .map(
                            (reward) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: _RewardCard(
                                reward: reward,
                                balance: summary.account.balance,
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const AppSectionHeader(title: 'Extrato de pontos'),
            if (summary.transactions.isEmpty)
              const AppEmptyState(
                message: 'Seu extrato aparecerá após o primeiro atendimento.',
                icon: Icons.receipt_long_outlined,
              )
            else
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var index = 0;
                        index < summary.transactions.length;
                        index++) ...[
                      if (index > 0) const Divider(height: 1),
                      _TransactionTile(
                        transaction: summary.transactions[index],
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _PointsCard extends StatelessWidget {
  const _PointsCard({required this.account});

  final LoyaltyAccount account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.goldDark, AppColors.gold, AppColors.goldLight],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  color: AppColors.black),
              const SizedBox(width: AppSpacing.xs),
              // `Flexible`: o nome do clube é mais largo que o antigo e, com
              // `letterSpacing`, estourava a linha em telas estreitas.
              Flexible(
                child: Text(
                  'CLUBE SUA BARBEARIA',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.black,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '${account.balance}',
            style: theme.textTheme.displayMedium?.copyWith(
              color: AppColors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'pontos disponíveis',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.black),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _MiniStat(
                label: 'Acumulados',
                value: '${account.lifetimeEarned}',
              ),
              const SizedBox(width: AppSpacing.lg),
              _MiniStat(
                label: 'Resgatados',
                value: '${account.lifetimeRedeemed}',
              ),
              const SizedBox(width: AppSpacing.lg),
              _MiniStat(
                label: 'Equivalem a',
                value: Formatters.currency(account.pointsValue),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: AppColors.black),
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(color: AppColors.black),
        ),
      ],
    );
  }
}

class _RewardCard extends ConsumerStatefulWidget {
  const _RewardCard({required this.reward, required this.balance});

  final LoyaltyReward reward;
  final int balance;

  @override
  ConsumerState<_RewardCard> createState() => _RewardCardState();
}

class _RewardCardState extends ConsumerState<_RewardCard> {
  bool _isLoading = false;

  Future<void> _redeem() async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Resgatar recompensa',
      message:
          'Trocar ${widget.reward.pointsCost} pontos por "${widget.reward.name}"? '
          'Apresente o resgate no balcão da barbearia.',
      confirmLabel: 'Resgatar',
      icon: Icons.card_giftcard_rounded,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(engagementRepositoryProvider).redeem(widget.reward.id);
      if (!mounted) return;
      AppFeedback.success(context, 'Recompensa resgatada com sucesso!');
      ref.invalidate(myLoyaltyProvider);
      ref.invalidate(clientDashboardProvider);
    } on ApiException catch (error) {
      if (mounted) AppFeedback.error(context, error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canRedeem = widget.reward.canBeRedeemedWith(widget.balance);
    final missing = widget.reward.pointsCost - widget.balance;

    return AppCard(
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child:
                const Icon(Icons.card_giftcard_rounded, color: AppColors.gold),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.reward.name, style: theme.textTheme.titleSmall),
                Text(
                  canRedeem
                      ? '${widget.reward.pointsCost} pontos'
                      : 'Faltam $missing pontos',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          AppButton(
            label: 'Resgatar',
            expanded: false,
            size: AppButtonSize.small,
            isLoading: _isLoading,
            onPressed: canRedeem ? _redeem : null,
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final LoyaltyTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = transaction.isCredit;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: (isCredit ? AppColors.success : AppColors.danger)
            .withValues(alpha: 0.14),
        child: Icon(
          isCredit ? Icons.add_rounded : Icons.remove_rounded,
          color: isCredit ? AppColors.success : AppColors.danger,
          size: 18,
        ),
      ),
      title: Text(
        transaction.description.isEmpty
            ? transaction.typeLabel
            : transaction.description,
      ),
      subtitle: Text(Formatters.dateTime(transaction.createdAt)),
      trailing: Text(
        '${isCredit ? '+' : ''}${transaction.points}',
        style: theme.textTheme.titleSmall?.copyWith(
          color: isCredit ? AppColors.success : AppColors.danger,
        ),
      ),
    );
  }
}
