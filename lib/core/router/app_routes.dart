/// Caminhos de navegação do aplicativo, em um único lugar.
class AppRoutes {
  const AppRoutes._();

  // --- Públicas ---
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // --- Proprietário ---
  static const String ownerDashboard = '/owner/dashboard';
  static const String ownerBranches = '/owner/branches';
  static const String ownerBarbers = '/owner/barbers';
  static const String ownerClients = '/owner/clients';
  static const String ownerServices = '/owner/services';
  static const String ownerAppointments = '/owner/appointments';
  static const String ownerFinance = '/owner/finance';
  static const String ownerProducts = '/owner/products';
  static const String ownerInventory = '/owner/inventory';
  static const String ownerPlans = '/owner/plans';
  static const String ownerReports = '/owner/reports';
  static const String ownerSettings = '/owner/settings';

  // --- Barbeiro ---
  static const String barberDashboard = '/barber/dashboard';
  static const String barberAgenda = '/barber/agenda';
  static const String barberAppointments = '/barber/appointments';
  static const String barberProfile = '/barber/profile';

  // --- Cliente ---
  static const String clientHome = '/client/home';
  static const String clientBooking = '/client/booking';
  static const String clientAppointments = '/client/appointments';
  static const String clientHistory = '/client/history';
  static const String clientLoyalty = '/client/loyalty';
  static const String clientPlans = '/client/plans';
  static const String clientProfile = '/client/profile';

  static const List<String> publicRoutes = [
    login,
    register,
    forgotPassword,
    resetPassword,
  ];

  /// Rota inicial de cada papel após o login.
  static String homeForRole(String role) {
    switch (role) {
      case 'OWNER':
        return ownerDashboard;
      case 'BARBER':
        return barberDashboard;
      case 'CLIENT':
        return clientHome;
      default:
        return login;
    }
  }

  /// Prefixo de rota permitido para cada papel.
  static String prefixForRole(String role) {
    switch (role) {
      case 'OWNER':
        return '/owner';
      case 'BARBER':
        return '/barber';
      case 'CLIENT':
        return '/client';
      default:
        return '/';
    }
  }
}
