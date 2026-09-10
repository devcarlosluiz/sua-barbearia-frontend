import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../shared/app_shell.dart';

/// Navegação da área do proprietário.
class OwnerShell extends StatelessWidget {
  const OwnerShell({super.key, required this.child});

  final Widget child;

  static const List<NavItem> navItems = [
    NavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      route: AppRoutes.ownerDashboard,
    ),
    NavItem(
      label: 'Agenda',
      icon: Icons.event_note_outlined,
      selectedIcon: Icons.event_note_rounded,
      route: AppRoutes.ownerAppointments,
    ),
    NavItem(
      label: 'Financeiro',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet_rounded,
      route: AppRoutes.ownerFinance,
    ),
    NavItem(
      label: 'Clientes',
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
      route: AppRoutes.ownerClients,
    ),
    NavItem(
      label: 'Barbeiros',
      icon: Icons.content_cut_outlined,
      selectedIcon: Icons.content_cut_rounded,
      route: AppRoutes.ownerBarbers,
      showInBottomBar: false,
    ),
    NavItem(
      label: 'Serviços',
      icon: Icons.design_services_outlined,
      selectedIcon: Icons.design_services_rounded,
      route: AppRoutes.ownerServices,
      showInBottomBar: false,
    ),
    NavItem(
      label: 'Filiais',
      icon: Icons.store_outlined,
      selectedIcon: Icons.store_rounded,
      route: AppRoutes.ownerBranches,
      showInBottomBar: false,
    ),
    NavItem(
      label: 'Produtos',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2_rounded,
      route: AppRoutes.ownerProducts,
      showInBottomBar: false,
    ),
    NavItem(
      label: 'Estoque',
      icon: Icons.warehouse_outlined,
      selectedIcon: Icons.warehouse_rounded,
      route: AppRoutes.ownerInventory,
      showInBottomBar: false,
    ),
    NavItem(
      label: 'Planos',
      icon: Icons.card_membership_outlined,
      selectedIcon: Icons.card_membership_rounded,
      route: AppRoutes.ownerPlans,
      showInBottomBar: false,
    ),
    NavItem(
      label: 'Relatórios',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
      route: AppRoutes.ownerReports,
      showInBottomBar: false,
    ),
    NavItem(
      label: 'Configurações',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      route: AppRoutes.ownerSettings,
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
