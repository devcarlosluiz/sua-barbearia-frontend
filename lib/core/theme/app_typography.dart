import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografia do app Sua Barbearia.
///
/// Títulos em Playfair Display (elegante, com personalidade) e texto corrido
/// em Inter (alta legibilidade em telas pequenas e no Web).
class AppTypography {
  const AppTypography._();

  static TextTheme textTheme(Color onSurface, Color muted) {
    final display = GoogleFonts.playfairDisplayTextTheme();
    final body = GoogleFonts.interTextTheme();

    return TextTheme(
      displayLarge: display.displayLarge?.copyWith(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        color: onSurface,
        letterSpacing: -0.5,
      ),
      displayMedium: display.displayMedium?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      headlineLarge: display.headlineLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      headlineSmall: display.headlineSmall?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleLarge: body.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleSmall: body.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: body.bodyLarge?.copyWith(fontSize: 16, color: onSurface),
      bodyMedium: body.bodyMedium?.copyWith(fontSize: 14, color: onSurface),
      bodySmall: body.bodySmall?.copyWith(fontSize: 12, color: muted),
      labelLarge: body.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: onSurface,
      ),
      labelMedium: body.labelMedium?.copyWith(fontSize: 12, color: muted),
      labelSmall: body.labelSmall?.copyWith(
        fontSize: 11,
        letterSpacing: 0.6,
        fontWeight: FontWeight.w600,
        color: muted,
      ),
    );
  }
}
