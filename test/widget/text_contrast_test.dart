import 'dart:math' as math;

import 'package:sua_barbearia/core/theme/app_theme.dart';
import 'package:sua_barbearia/widgets/app_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Luminância relativa da WCAG 2.1.
double _luminance(Color color) {
  double channel(double value) {
    return value <= 0.03928
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// Razão de contraste entre duas cores opacas (1 a 21).
double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  // O tema puxa fontes do Google Fonts; sem binding e sem desligar o download,
  // só construí-lo já falha.
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('texto secundário tem contraste suficiente', () {
    // 4.5:1 é o mínimo da WCAG AA para texto normal. O texto secundário do app
    // é usado em 12 px — ficar no limite já é apertado, ficar abaixo some.
    const minimo = 4.5;

    for (final nome in ['claro', 'escuro']) {
      ThemeData tema() => nome == 'claro' ? AppTheme.light : AppTheme.dark;

      testWidgets('$nome: onSurfaceVariant sobre o card', (tester) async {
        final theme = tema();
        expect(
          contrast(
              theme.colorScheme.onSurfaceVariant, theme.colorScheme.surface),
          greaterThanOrEqualTo(minimo),
        );
      });

      testWidgets('$nome: onSurfaceVariant sobre o fundo da tela',
          (tester) async {
        // A tela vazia desenha a mensagem direto sobre o fundo do Scaffold.
        final theme = tema();
        expect(
          contrast(
            theme.colorScheme.onSurfaceVariant,
            theme.scaffoldBackgroundColor,
          ),
          greaterThanOrEqualTo(minimo),
        );
      });

      testWidgets('$nome: bodySmall sobre o card', (tester) async {
        final theme = tema();
        expect(
          contrast(
              theme.textTheme.bodySmall!.color!, theme.colorScheme.surface),
          greaterThanOrEqualTo(minimo),
        );
      });
    }

    testWidgets('a cor de borda continua clara — ela não é cor de texto',
        (tester) async {
      // Guarda o contraponto: `outline` é fraca de propósito. O bug foi usá-la
      // como cor de texto, não o valor dela.
      final theme = AppTheme.light;
      expect(
        contrast(theme.colorScheme.outline, theme.colorScheme.surface),
        lessThan(4.5),
      );
    });
  });

  testWidgets('a mensagem da tela vazia usa a cor de texto secundário',
      (tester) async {
    final theme = AppTheme.light;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: AppEmptyState(
            message: 'Você ainda não tem horários marcados.',
          ),
        ),
      ),
    );

    final texto = tester.widget<Text>(
      find.text('Você ainda não tem horários marcados.'),
    );
    expect(texto.style?.color, theme.colorScheme.onSurfaceVariant);
    expect(texto.style?.color, isNot(theme.colorScheme.outline));
  });
}
