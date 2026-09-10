import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/dashboard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/engagement_providers.dart';
import '../../widgets/widgets.dart';
import '../shared/appointment_card.dart';

class ClientHomePage extends ConsumerWidget {
  const ClientHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(clientDashboardProvider);
    final user = ref.watch(currentUserProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(clientDashboardProvider);
        ref.invalidate(pendingReviewsProvider);
      },
      child: AsyncView<ClientDashboard>(
        value: dashboard,
        onRetry: () => ref.invalidate(clientDashboardProvider),
        builder: (data) => ListView(
          padding: Responsive.pagePadding(context),
          children: [
            _Greeting(name: user?.firstName ?? 'Cliente'),
            const SizedBox(height: AppSpacing.md),
            _BookingCallToAction(hasUpcoming: data.hasUpcoming),
            const SizedBox(height: AppSpacing.lg),
            if (data.nextAppointment != null) ...[
              const AppSectionHeader(
                title: 'Seu próximo horário',
                subtitle: 'Chegue com 5 minutos de antecedência.',
              ),
              AppointmentCard(
                appointment: data.nextAppointment!,
                showClient: false,
                onTap: () => context.go(AppRoutes.clientAppointments),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            const AppSectionHeader(title: 'Seus números'),
            StatGrid(
              minTileWidth: 160,
              children: [
                StatCard(
                  label: 'Pontos de fidelidade',
                  value: '${data.loyaltyPoints}',
                  icon: Icons.workspace_premium_rounded,
                  trailingLabel: 'Toque para ver as recompensas',
                  onTap: () => context.go(AppRoutes.clientLoyalty),
                ),
                StatCard(
                  label: 'Visitas',
                  value: '${data.totalVisits}',
                  icon: Icons.event_available_rounded,
                  accentColor: AppColors.info,
                ),
                StatCard(
                  label: 'Total investido',
                  value: Formatters.currency(data.totalSpent),
                  icon: Icons.payments_rounded,
                  accentColor: AppColors.success,
                ),
                StatCard(
                  label: 'Ticket médio',
                  value: Formatters.currency(data.averageTicket),
                  icon: Icons.trending_up_rounded,
                ),
              ],
            ),
            if (data.pendingReviews > 0) ...[
              const SizedBox(height: AppSpacing.lg),
              _PendingReviewsCard(count: data.pendingReviews),
            ],
            const SizedBox(height: AppSpacing.lg),
            const AppSectionHeader(title: 'Suas preferências'),
            _PreferencesCard(dashboard: data),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Bom dia'
        : hour < 18
            ? 'Boa tarde'
            : 'Boa noite';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$greeting,', style: theme.textTheme.bodyMedium),
        Text(name, style: theme.textTheme.headlineSmall),
      ],
    );
  }
}

class _BookingCallToAction extends StatelessWidget {
  const _BookingCallToAction({required this.hasUpcoming});

  final bool hasUpcoming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.charcoal, AppColors.black],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasUpcoming
                ? 'Quer marcar mais um?'
                : 'Pronto para o próximo corte?',
            style: theme.textTheme.titleLarge?.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Escolha filial, serviço, barbeiro e horário em menos de 1 minuto.',
            style:
                theme.textTheme.bodySmall?.copyWith(color: AppColors.greyLight),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'AGENDAR HORÁRIO',
            icon: Icons.calendar_month_rounded,
            onPressed: () => context.go(AppRoutes.clientBooking),
          ),
        ],
      ),
    );
  }
}

class _PendingReviewsCard extends StatelessWidget {
  const _PendingReviewsCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: () => context.go(AppRoutes.clientHistory),
      borderColor: AppColors.gold.withValues(alpha: 0.4),
      color: AppColors.gold.withValues(alpha: 0.08),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: AppColors.gold, size: 28),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 1
                      ? 'Você tem 1 atendimento para avaliar'
                      : 'Você tem $count atendimentos para avaliar',
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  'Sua opinião ajuda a barbearia a melhorar.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({required this.dashboard});

  final ClientDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _PreferenceRow(
            icon: Icons.store_rounded,
            label: 'Filial favorita',
            value: dashboard.preferredBranch?.name ?? 'Ainda não definida',
          ),
          const Divider(height: AppSpacing.lg),
          _PreferenceRow(
            icon: Icons.content_cut_rounded,
            label: 'Barbeiro favorito',
            value: dashboard.preferredBarber?.name ?? 'Ainda não definido',
          ),
          const Divider(height: AppSpacing.lg),
          _PreferenceRow(
            icon: Icons.design_services_rounded,
            label: 'Serviço mais pedido',
            value: dashboard.favoriteService?.name ?? 'Ainda não definido',
          ),
          const Divider(height: AppSpacing.lg),
          _PreferenceRow(
            icon: Icons.schedule_rounded,
            label: 'Última visita',
            value: dashboard.lastVisitAt == null
                ? 'Esta será a primeira!'
                : Formatters.date(dashboard.lastVisitAt),
          ),
        ],
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
