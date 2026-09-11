import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sua_barbearia/core/router/app_routes.dart';
import 'package:sua_barbearia/core/theme/app_theme.dart';
import 'package:sua_barbearia/features/auth/register_page.dart';
import 'package:sua_barbearia/models/branch.dart';
import 'package:sua_barbearia/models/user.dart';
import 'package:sua_barbearia/providers/catalog_providers.dart';
import 'package:sua_barbearia/providers/core_providers.dart';
import 'package:sua_barbearia/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const _client = User(
  id: 7,
  uuid: 'uuid-client',
  name: 'Joana Souza',
  firstName: 'Joana',
  lastName: 'Souza',
  email: 'joana@gmail.com',
  phone: '41988887777',
  role: UserRole.client,
);

const _session = AuthSession(
  access: 'access',
  refresh: 'refresh',
  user: _client,
);

Widget buildApp(MockAuthRepository repository) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      branchesProvider.overrideWith((ref) async => const <Branch>[]),
    ],
    child: MaterialApp.router(
      theme: AppTheme.dark,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      routerConfig: GoRouter(
        initialLocation: AppRoutes.register,
        routes: [
          GoRoute(
            path: AppRoutes.register,
            builder: (context, state) => const RegisterPage(),
          ),
          GoRoute(
            path: AppRoutes.login,
            builder: (context, state) => const Scaffold(body: Text('login')),
          ),
          GoRoute(
            path: AppRoutes.clientHome,
            builder: (context, state) =>
                const Scaffold(body: Text('home cliente')),
          ),
        ],
      ),
    ),
  );
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    when(() => repository.hasSession()).thenAnswer((_) async => false);
  });

  /// Renderiza em uma tela de celular (layout mobile do AuthScaffold).
  Future<void> pumpRegister(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp(repository));
    await tester.pumpAndSettle();
  }

  testWidgets('o cadastro não pede data de nascimento', (tester) async {
    await pumpRegister(tester);

    expect(find.text('Criar conta'), findsWidgets);
    expect(find.text('Data de nascimento'), findsNothing);
  });

  testWidgets('cadastra sem enviar data de nascimento', (tester) async {
    when(
      () => repository.register(
        firstName: any(named: 'firstName'),
        lastName: any(named: 'lastName'),
        email: any(named: 'email'),
        phone: any(named: 'phone'),
        password: any(named: 'password'),
        passwordConfirm: any(named: 'passwordConfirm'),
        preferredBranchId: any(named: 'preferredBranchId'),
      ),
    ).thenAnswer((_) async => _session);
    when(() => repository.me())
        .thenAnswer((_) async => const CurrentUser(user: _client));

    await pumpRegister(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Joana');
    await tester.enterText(find.byType(TextFormField).at(2), 'joana@gmail.com');
    await tester.enterText(find.byType(TextFormField).at(3), '41988887777');
    await tester.enterText(find.byType(TextFormField).at(4), 'SenhaTeste@2026');
    await tester.enterText(find.byType(TextFormField).at(5), 'SenhaTeste@2026');

    final botao = find.widgetWithText(FilledButton, 'Criar conta');
    await tester.ensureVisible(botao);
    await tester.pumpAndSettle();
    await tester.tap(botao);
    await tester.pumpAndSettle();

    verify(
      () => repository.register(
        firstName: 'Joana',
        lastName: '',
        email: 'joana@gmail.com',
        phone: any(named: 'phone'),
        password: 'SenhaTeste@2026',
        passwordConfirm: 'SenhaTeste@2026',
        preferredBranchId: null,
      ),
    ).called(1);
  });
}
