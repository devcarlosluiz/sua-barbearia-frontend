import 'package:flutter/material.dart';

/// Paleta da identidade Sua Barbearia: preto, branco, cinza e dourado.
///
/// Nenhuma cor literal deve aparecer fora deste arquivo.
class AppColors {
  const AppColors._();

  // --- Marca ---
  static const Color gold = Color(0xFFC8A24A);
  static const Color goldLight = Color(0xFFE3C880);
  static const Color goldDark = Color(0xFF9A7A2E);

  // --- Neutros ---
  static const Color black = Color(0xFF0B0B0D);
  static const Color charcoal = Color(0xFF15161A);
  static const Color graphite = Color(0xFF1E1F25);
  static const Color slate = Color(0xFF2A2C34);

  /// Texto secundário no tema claro. Escuro o bastante para 12 px continuar
  /// legível: 6,7:1 sobre o branco, contra 4,8:1 do [grey].
  static const Color greyDark = Color(0xFF5A5C64);
  static const Color grey = Color(0xFF6E7078);
  static const Color greyLight = Color(0xFFB4B6BD);
  static const Color mist = Color(0xFFF1F2F5);
  static const Color white = Color(0xFFFFFFFF);

  // --- Semânticas ---
  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFE0A500);
  static const Color danger = Color(0xFFD64545);
  static const Color info = Color(0xFF3A7BD5);

  // --- Status de agendamento ---
  static const Color statusPending = Color(0xFFE0A500);
  static const Color statusConfirmed = Color(0xFF3A7BD5);
  static const Color statusArrived = Color(0xFF7E57C2);
  static const Color statusInProgress = Color(0xFFC8A24A);
  static const Color statusCompleted = Color(0xFF2E9E5B);
  static const Color statusCancelled = Color(0xFFD64545);
  static const Color statusNoShow = Color(0xFF6E7078);

  /// Cor associada a cada status de agendamento da API.
  static Color forAppointmentStatus(String status) {
    switch (status) {
      case 'PENDING':
        return statusPending;
      case 'CONFIRMED':
        return statusConfirmed;
      case 'ARRIVED':
        return statusArrived;
      case 'IN_PROGRESS':
        return statusInProgress;
      case 'COMPLETED':
        return statusCompleted;
      case 'CANCELLED':
        return statusCancelled;
      case 'NO_SHOW':
        return statusNoShow;
      default:
        return grey;
    }
  }
}
