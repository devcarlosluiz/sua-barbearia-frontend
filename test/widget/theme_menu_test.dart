import 'package:sua_barbearia/core/router/app_routes.dart';
import 'package:sua_barbearia/core/theme/app_theme.dart';
import 'package:sua_barbearia/features/shared/app_shell.dart';
import 'package:sua_barbearia/providers/engagement_providers.dart';
import 'package:sua_barbearia/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// O seletor de tema vive na casca de navegação, então o teste monta a casca
/// dentro de um GoRouter real — `AppShell` lê `GoRouterState.of(context)`.
/// `NavigationBar` exige ao menos dois destinos — como nas cascas reais.
const _items = [
  NavItem(
    label: 'Início',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    route: AppRoutes.clientHome,
  ),
  NavItem(
    label: 'Planos',
    icon: Icons.card_membership_outlined,
    selectedIcon: Icons.card_membership_rounded,
    route: AppRoutes.clientPlans,
  ),
];

Widget buildApp() {
  final router = GoRouter(
    initialLocation: AppRoutes.clientHome,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(
          title: 'Início',
          items: _items,
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.clientHome,
            builder: (context, state) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: AppRoutes.clientPlans,
            builder: (context, state) => const SizedBox.shrink(),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    // A casca busca o contador de notificações ao montar. Sem este override o
    // teste dispara uma chamada HTTP real e deixa um timer pendente.
    overrides: [
      unreadNotificationsProvider.overrideWith((ref) async => 0),
    ],
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

  Future<void> pumpShell(WidgetTester tester,
      {Size size = const Size(390, 844)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
  }

  testWidgets('o seletor de tema aparece no mobile', (tester) async {
    await pumpShell(tester);
    expect(find.byIcon(Icons.wb_sunny_rounded), findsOneWidget);
  });

  testWidgets('o seletor de tema aparece no desktop', (tester) async {
    // A barra superior do desktop é outro widget: precisa do botão também.
    await pumpShell(tester, size: const Size(1400, 900));
    expect(find.byIcon(Icons.wb_sunny_rounded), findsOneWidget);
  });

  testWidgets('o menu oferece as três opções', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.byIcon(Icons.wb_sunny_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Claro'), findsOneWidget);
    expect(find.text('Escuro'), findsOneWidget);
    // Voltar a seguir o sistema não pode ficar escondido.
    expect(find.text('Seguir o sistema'), findsOneWidget);
  });

  testWidgets('escolher "Escuro" troca o tema do app', (tester) async {
    await pumpShell(tester);

    final antes = Theme.of(tester.element(find.byType(Scaffold).first));
    expect(antes.brightness, Brightness.light);

    await tester.tap(find.byIcon(Icons.wb_sunny_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();

    final depois = Theme.of(tester.element(find.byType(Scaffold).first));
    expect(depois.brightness, Brightness.dark);
    // E o ícone passa a refletir o brilho em uso.
    expect(find.byIcon(Icons.nightlight_rounded), findsOneWidget);
    expect(find.byIcon(Icons.wb_sunny_rounded), findsNothing);
  });

  testWidgets('escolher "Claro" volta atrás', (tester) async {
    SharedPreferences.setMockInitialValues({
      ThemeModeController.storageKey: ThemeMode.dark.name,
    });

    await pumpShell(tester);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.nightlight_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.nightlight_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Claro'));
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.byType(Scaffold).first));
    expect(theme.brightness, Brightness.light);
  });
}
