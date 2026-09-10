import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../shared/app_shell.dart';

/// Navegação da área do cliente.
///
/// O fluxo principal (agendar) fica a um toque de distância em qualquer tela.
class ClientShell extends StatelessWidget {
  const ClientShell({super.key, required this.child});

  final Widget child;

  static const List<NavItem> navItems = [
    NavItem(
      label: 'Início',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      route: AppRoutes.clientHome,
    ),
    NavItem(
      label: 'Agendar',
      icon: Icons.add_circle_outline_rounded,
      selectedIcon: Icons.add_circle_rounded,
      route: AppRoutes.clientBooking,
    ),
    NavItem(
      label: 'Meus horários',
      icon: Icons.event_outlined,
      selectedIcon: Icons.event_rounded,
      route: AppRoutes.clientAppointments,
    ),
    NavItem(
      label: 'Planos',
      icon: Icons.card_membership_outlined,
      selectedIcon: Icons.card_membership_rounded,
      route: AppRoutes.clientPlans,
    ),
    NavItem(
      label: 'Fidelidade',
      icon: Icons.workspace_premium_outlined,
      selectedIcon: Icons.workspace_premium_rounded,
      route: AppRoutes.clientLoyalty,
      showInBottomBar: false,
    ),
    NavItem(
      label: 'Histórico',
      icon: Icons.history_rounded,
      selectedIcon: Icons.history_rounded,
      route: AppRoutes.clientHistory,
      showInBottomBar: false,
    ),
    NavItem(
      label: 'Perfil',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      route: AppRoutes.clientProfile,
      showInBottomBar: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final current = navItems.firstWhere(
      (item) => location.startsWith(item.route),
      orElse: () => navItems.first,
    );

    return AppShell(
      title: current.label,
      items: navItems,
      child: child,
    );
  }
}
