import 'package:sua_barbearia/core/errors/api_exception.dart';
import 'package:sua_barbearia/core/router/app_routes.dart';
import 'package:sua_barbearia/core/theme/app_theme.dart';
import 'package:sua_barbearia/models/branding.dart';
import 'package:sua_barbearia/providers/branding_provider.dart';
import 'package:sua_barbearia/features/auth/login_page.dart';
import 'package:sua_barbearia/models/user.dart';
import 'package:sua_barbearia/providers/core_providers.dart';
import 'package:sua_barbearia/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const _client = User(
  id: 5,
  uuid: 'uuid-client',
  name: 'Carlos Mendes',
  firstName: 'Carlos',
  lastName: 'Mendes',
  email: 'client@suabarbearia.com',
  phone: '41977770000',
  role: UserRole.client,
);

const _session = AuthSession(
  access: 'access',
  refresh: 'refresh',
  user: _client,
);

/// Router mínimo: a LoginPage navega com `context.go` após autenticar, então
/// o teste precisa de um GoRouter real no contexto.
GoRouter buildRouter() {
  return GoRouter(
    initialLocation: AppRoutes.login,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const Scaffold(body: Text('registro')),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const Scaffold(body: Text('recuperar')),
      ),
      GoRoute(
        path: AppRoutes.clientHome,
        builder: (context, state) => const Scaffold(body: Text('home cliente')),
      ),
    ],
  );
}

Widget buildApp(MockAuthRepository repository) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      // A marca no topo da tela busca a logo do sistema. Sem este override o
      // teste dispara uma chamada HTTP real e deixa um timer pendente.
      brandingProvider.overrideWith((ref) async => const Branding()),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: buildRouter(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    ),
  );
}

void main() {
  late MockAuthRepository repository;

  setUpAll(() {
    // Sem rede nos testes: usa a fonte padrão em vez de baixar do Google Fonts.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    repository = MockAuthRepository();
    when(() => repository.hasSession()).thenAnswer((_) async => false);
  });

  /// Renderiza em uma tela de celular (layout mobile do AuthScaffold).
  Future<void> pumpLogin(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp(repository));
    await tester.pump();
  }

  testWidgets('exibe os campos de e-mail e senha', (tester) async {
    await pumpLogin(tester);

    expect(find.text('Bem-vindo de volta'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Esqueci minha senha'), findsOneWidget);
  });

  testWidgets('valida e-mail inválido antes de chamar a API', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextFormField).first, 'sem-arroba');
    await tester.enterText(find.byType(TextFormField).last, '12345678');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    verifyNever(
      () => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('valida senha curta', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(
        find.byType(TextFormField).first, 'client@suabarbearia.com');
    await tester.enterText(find.byType(TextFormField).last, '123');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(
        find.text('A senha deve ter ao menos 8 caracteres.'), findsOneWidget);
  });

  testWidgets('envia as credenciais quando o formulário é válido',
      (tester) async {
    when(
      () => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => _session);
    when(() => repository.me())
        .thenAnswer((_) async => const CurrentUser(user: _client));

    await pumpLogin(tester);

    await tester.enterText(
        find.byType(TextFormField).first, 'client@suabarbearia.com');
    await tester.enterText(
        find.byType(TextFormField).last, 'SuaBarbearia@2026');
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    verify(
      () => repository.login(
        email: 'client@suabarbearia.com',
        password: 'SuaBarbearia@2026',
      ),
    ).called(1);
  });

  testWidgets('mostra mensagem amigável em credenciais inválidas',
      (tester) async {
    when(
      () => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(
      const ApiException(message: 'inválido', statusCode: 401),
    );

    await pumpLogin(tester);

    await tester.enterText(
        find.byType(TextFormField).first, 'client@suabarbearia.com');
    await tester.enterText(find.byType(TextFormField).last, 'senhaerrada');
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
  });
}
