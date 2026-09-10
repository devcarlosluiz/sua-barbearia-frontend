import 'package:sua_barbearia/core/router/app_routes.dart';
import 'package:sua_barbearia/core/theme/app_theme.dart';
import 'package:sua_barbearia/features/client/client_shell.dart';
import 'package:sua_barbearia/providers/engagement_providers.dart';
import 'package:sua_barbearia/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Usa a casca REAL do cliente, não um harness sintético.
Widget buildApp() {
  final router = GoRouter(
    initialLocation: AppRoutes.clientHome,
    routes: [
      ShellRoute(
        builder: (context, state, child) => ClientShell(child: child),
        routes: [
          for (final item in ClientShell.navItems)
            GoRoute(
              path: item.route,
              builder: (context, state) => const SizedBox.shrink(),
            ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [unreadNotificationsProvider.overrideWith((ref) async => 0)],
    child: Consumer(
      builder: (context, ref, _) => MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ref.watch(themeModeProvider),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    ),
  );
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a casca do cliente mostra o seletor de tema no desktop',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 820);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.wb_sunny_rounded), findsOneWidget);
  });

  testWidgets('a casca do cliente mostra o seletor de tema no celular',
      (tester) async {
    // O relato foi justamente este caso: no celular, na Início do cliente.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.wb_sunny_rounded), findsOneWidget);
  });

  testWidgets('no celular o menu do avatar também oferece o tema, escrito',
      (tester) async {
    // Caminho que não depende de um glifo da fonte de ícones ser desenhado.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();

    expect(find.text('Tema'), findsOneWidget);
  });

  testWidgets('escolher o tema pelo menu do avatar troca o brilho',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tema'));
    await tester.pumpAndSettle();

    // A folha lista os três modos com o rótulo escrito.
    expect(find.text('Escuro'), findsOneWidget);
    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );
  });
}
