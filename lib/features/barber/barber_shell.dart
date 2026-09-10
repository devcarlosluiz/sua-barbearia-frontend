import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../shared/app_shell.dart';

/// Navegação da área do barbeiro.
class BarberShell extends StatelessWidget {
  const BarberShell({super.key, required this.child});

  final Widget child;

  static const List<NavItem> navItems = [
    NavItem(
      label: 'Início',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      route: AppRoutes.barberDashboard,
    ),
    NavItem(
      label: 'Agenda',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month_rounded,
      route: AppRoutes.barberAgenda,
    ),
    NavItem(
      label: 'Atendimentos',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      route: AppRoutes.barberAppointments,
    ),
    NavItem(
      label: 'Perfil',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      route: AppRoutes.barberProfile,
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
