import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/paginated.dart';
import '../../core/responsive/responsive.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/barber.dart';
import '../../models/finance.dart';
import '../../models/review.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/engagement_providers.dart';
import '../../providers/finance_providers.dart';
import '../../widgets/widgets.dart';

class BarberProfilePage extends ConsumerWidget {
  const BarberProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barber = ref.watch(currentBarberProvider);
    final user = ref.watch(currentUserProvider);

    if (barber == null) {
      return const AppErrorState(
        title: 'Perfil de barbeiro não encontrado.',
        message: 'Fale com a administração da barbearia.',
      );
    }

    final commissions = ref.watch(commissionsProvider);
    final reviews = ref.watch(reviewsProvider(barber.id));
    final workingHours = ref.watch(workingHoursProvider(barber.id));

    return ListView(
      padding: Responsive.pagePadding(context),
      children: [
        AppCard(
          child: Row(
            children: [
              // A foto é do usuário, não do perfil de barbeiro: usa a do
              // usuário logado para refletir a troca na hora.
              AvatarPicker(
                name: barber.name,
                imageUrl: user?.avatarUrl ?? barber.avatarUrl,
                size: 64,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      barber.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      user?.email ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: [
                        AppBadge(
                          label: 'Comissão '
                              '${barber.commissionPercentage.toStringAsFixed(0)}%',
                          color: AppColors.gold,
                          icon: Icons.percent_rounded,
                          dense: true,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        if (barber.hasRating)
                          AppBadge(
                            label: barber.rating.toStringAsFixed(1),
                            color: AppColors.warning,
                            icon: Icons.star_rounded,
                            dense: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (barber.specialties.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          const AppSectionHeader(title: 'Especialidades'),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: barber.specialties
                .map((item) => Chip(label: Text(item)))
                .toList(),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        const AppSectionHeader(
          title: 'Minha jornada',
          subtitle: 'Definida pela administração.',
        ),
        AsyncView<List<WorkingHour>>(
          value: workingHours,
          onRetry: () => ref.invalidate(workingHoursProvider(barber.id)),
          emptyMessage: 'Nenhuma jornada cadastrada.',
          isEmpty: (items) => items.isEmpty,
          builder: (items) => AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  if (index > 0) const Divider(height: 1),
                  ListTile(
                    dense: true,
                    title: Text(items[index].weekdayLabel),
                    subtitle: Text(items[index].branchName),
                    trailing: Text(
                      '${Formatters.clock(items[index].startsAt)} - '
                      '${Formatters.clock(items[index].endsAt)}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppSectionHeader(title: 'Minhas comissões'),
        AsyncView<Paginated<Commission>>(
          value: commissions,
          onRetry: () => ref.invalidate(commissionsProvider),
          emptyMessage: 'Nenhuma comissão pendente.',
          isEmpty: (page) => page.isEmpty,
          builder: (page) => AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < page.results.length; index++) ...[
                  if (index > 0) const Divider(height: 1),
                  ListTile(
                    dense: true,
                    title: Text(page.results[index].serviceName ?? 'Comissão'),
                    subtitle: Text(
                      '${Formatters.date(page.results[index].referenceDate)} · '
                      '${page.results[index].percentage.toStringAsFixed(0)}% de '
                      '${Formatters.currency(page.results[index].baseAmount)}',
                    ),
                    trailing: Text(
                      Formatters.currency(page.results[index].amount),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppSectionHeader(title: 'Minhas avaliações'),
        AsyncView<List<Review>>(
          value: reviews,
          onRetry: () => ref.invalidate(reviewsProvider(barber.id)),
          emptyMessage: 'Você ainda não recebeu avaliações.',
          isEmpty: (items) => items.isEmpty,
          emptyIcon: Icons.star_outline_rounded,
          builder: (items) => Column(
            children: items
                .take(10)
                .map(
                  (review) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ReviewTile(review: review),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton.outline(
          label: 'Sair da conta',
          icon: Icons.logout_rounded,
          onPressed: () async {
            final confirmed = await AppDialog.confirm(
              context,
              title: 'Sair da conta',
              message: 'Você precisará entrar novamente.',
              confirmLabel: 'Sair',
              isDestructive: true,
            );
            if (!confirmed) return;
            await ref.read(authControllerProvider.notifier).logout();
            if (context.mounted) context.go(AppRoutes.login);
          },
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(
                5,
                (index) => Icon(
                  index < review.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 16,
                  color: AppColors.gold,
                ),
              ),
              const Spacer(),
              Text(
                Formatters.date(review.createdAt),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(review.comment, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${review.clientName} · ${review.serviceName}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
