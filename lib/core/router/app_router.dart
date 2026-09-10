import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/forgot_password_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/auth/splash_page.dart';
import '../../features/barber/barber_agenda_page.dart';
import '../../features/barber/barber_appointments_page.dart';
import '../../features/barber/barber_dashboard_page.dart';
import '../../features/barber/barber_profile_page.dart';
import '../../features/barber/barber_shell.dart';
import '../../features/client/client_appointments_page.dart';
import '../../features/client/client_booking_page.dart';
import '../../features/client/client_history_page.dart';
import '../../features/client/client_home_page.dart';
import '../../features/client/client_loyalty_page.dart';
import '../../features/client/client_plans_page.dart';
import '../../features/client/client_profile_page.dart';
import '../../features/client/client_shell.dart';
import '../../features/owner/owner_appointments_page.dart';
import '../../features/owner/owner_barbers_page.dart';
import '../../features/owner/owner_branches_page.dart';
import '../../features/owner/owner_clients_page.dart';
import '../../features/owner/owner_dashboard_page.dart';
import '../../features/owner/owner_finance_page.dart';
import '../../features/owner/owner_inventory_page.dart';
import '../../features/owner/owner_products_page.dart';
import '../../features/owner/owner_plans_page.dart';
import '../../features/owner/owner_reports_page.dart';
import '../../features/owner/owner_services_page.dart';
import '../../features/owner/owner_settings_page.dart';
import '../../features/owner/owner_shell.dart';
import '../../providers/auth_provider.dart';
import 'app_routes.dart';

/// Notifica o GoRouter sempre que o estado de autenticação muda.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(this._ref) {
    _ref.listen<AuthState>(
      authControllerProvider,
      (previous, next) {
        if (previous?.status != next.status || previous?.role != next.role) {
          notifyListeners();
        }
      },
    );
  }

  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final isPublic = AppRoutes.publicRoutes.contains(location);

      // Ainda restaurando a sessão: mantém o splash.
      if (auth.isUnknown) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (!auth.isAuthenticated) {
        return isPublic ? null : AppRoutes.login;
      }

      final home = AppRoutes.homeForRole(auth.role.value);
      if (isPublic || location == AppRoutes.splash) return home;

      // Guarda de papel: um barbeiro nunca entra em /owner, por exemplo.
      final prefix = AppRoutes.prefixForRole(auth.role.value);
      if (!location.startsWith(prefix)) return home;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) =>
            ResetPasswordPage(token: state.uri.queryParameters['token']),
      ),

      // ---------------- Proprietário ----------------
      ShellRoute(
        builder: (context, state, child) => OwnerShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.ownerDashboard,
            builder: (context, state) => const OwnerDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.ownerBranches,
            builder: (context, state) => const OwnerBranchesPage(),
          ),
          GoRoute(
            path: AppRoutes.ownerBarbers,
            builder: (context, state) => const OwnerBarbersPage(),
          ),
          GoRoute(
            path: AppRoutes.ownerClients,
            builder: (context, state) => const OwnerClientsPage(),
          ),
          GoRoute(
            path: AppRoutes.ownerServices,
            builder: (context, state) => const OwnerServicesPage(),
          ),
          GoRoute(
            path: AppRoutes.ownerAppointments,
            builder: (context, state) => const OwnerAppointmentsPage(),
          ),
          GoRoute(
            path: AppRoutes.ownerFinance,
            builder: (context, state) => const OwnerFinancePage(),
          ),
          GoRoute(
            path: AppRoutes.ownerProducts,
            builder: (context, state) => const OwnerProductsPage(),
          ),
          GoRoute(
            path: AppRoutes.ownerInventory,
            builder: (context, state) => const OwnerInventoryPage(),
          ),
          GoRoute(
            path: AppRoutes.ownerPlans,
            builder: (context, state) => const OwnerPlansPage(),
          ),
          GoRoute(
            path: AppRoutes.ownerReports,
            builder: (context, state) => const OwnerReportsPage(),
          ),
          GoRoute(
            path: AppRoutes.ownerSettings,
            builder: (context, state) => const OwnerSettingsPage(),
          ),
        ],
      ),

      // ---------------- Barbeiro ----------------
      ShellRoute(
        builder: (context, state, child) => BarberShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.barberDashboard,
            builder: (context, state) => const BarberDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.barberAgenda,
            builder: (context, state) => const BarberAgendaPage(),
          ),
          GoRoute(
            path: AppRoutes.barberAppointments,
            builder: (context, state) => const BarberAppointmentsPage(),
          ),
          GoRoute(
            path: AppRoutes.barberProfile,
            builder: (context, state) => const BarberProfilePage(),
          ),
        ],
      ),

      // ---------------- Cliente ----------------
      ShellRoute(
        builder: (context, state, child) => ClientShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.clientHome,
            builder: (context, state) => const ClientHomePage(),
          ),
          GoRoute(
            path: AppRoutes.clientBooking,
            builder: (context, state) => const ClientBookingPage(),
          ),
          GoRoute(
            path: AppRoutes.clientAppointments,
            builder: (context, state) => const ClientAppointmentsPage(),
          ),
          GoRoute(
            path: AppRoutes.clientHistory,
            builder: (context, state) => const ClientHistoryPage(),
          ),
          GoRoute(
            path: AppRoutes.clientLoyalty,
            builder: (context, state) => const ClientLoyaltyPage(),
          ),
          GoRoute(
            path: AppRoutes.clientPlans,
            builder: (context, state) => const ClientPlansPage(),
          ),
          GoRoute(
            path: AppRoutes.clientProfile,
            builder: (context, state) => const ClientProfilePage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        _RouteErrorPage(location: state.uri.toString()),
  );
});

class _RouteErrorPage extends ConsumerWidget {
  const _RouteErrorPage({required this.location});

  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.explore_off_rounded, size: 56),
              const SizedBox(height: 16),
              Text(
                'Página não encontrada',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(location, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(
                  auth.isAuthenticated
                      ? AppRoutes.homeForRole(auth.role.value)
                      : AppRoutes.login,
                ),
                child: const Text('Voltar ao início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
