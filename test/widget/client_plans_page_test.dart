import 'package:sua_barbearia/core/errors/api_exception.dart';
import 'package:sua_barbearia/core/theme/app_theme.dart';
import 'package:sua_barbearia/features/client/client_plans_page.dart';
import 'package:sua_barbearia/models/plan.dart';
import 'package:sua_barbearia/providers/core_providers.dart';
import 'package:sua_barbearia/repositories/plan_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

class MockPlanRepository extends Mock implements PlanRepository {}

final _plan = Plan.fromJson({
  'id': 1,
  'name': 'Barba & Cabelo',
  'description': 'Dois cortes por mês',
  'price': '99.90',
  'overage_discount_percentage': '50.00',
  'plan_services': [
    {
      'id': 10,
      'service': 3,
      'service_name': 'Corte Masculino',
      'monthly_quota': 2,
      'is_unlimited': false,
    },
  ],
});

Map<String, dynamic> _subscriptionJson({
  String status = 'ACTIVE',
  Map<String, dynamic>? openInvoice,
  bool cancelAtPeriodEnd = false,
}) =>
    {
      'id': 5,
      'client_name': 'Carlos Mendes',
      'plan': 1,
      'plan_detail': {
        'id': 1,
        'name': 'Barba & Cabelo',
        'price': '99.90',
        'plan_services': <Map<String, dynamic>>[],
      },
      'status': status,
      'billing_type': 'PIX_MONTHLY',
      'price': '99.90',
      'current_period_start': '2026-09-01',
      'current_period_end': '2026-09-30',
      'grants_benefit': status == 'ACTIVE',
      'cancel_at_period_end': cancelAtPeriodEnd,
      'quotas': [
        {
          'service': 3,
          'service_name': 'Corte Masculino',
          'monthly_quota': 2,
          'is_unlimited': false,
          'used': 1,
          'remaining': 1,
        },
      ],
      'open_invoice': openInvoice,
    };

Widget buildApp(MockPlanRepository repository) {
  return ProviderScope(
    overrides: [planRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const ClientPlansPage(),
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
  late MockPlanRepository repository;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    // O mocktail precisa de um valor concreto para casar `any(named:)` em
    // parâmetros de tipo não anulável.
    registerFallbackValue(BillingType.pixMonthly);
  });

  setUp(() {
    repository = MockPlanRepository();
  });

  /// Renderiza em uma tela de celular — é onde o cliente usa o app.
  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp(repository));
    await tester.pumpAndSettle();
  }

  group('sem assinatura', () {
    setUp(() {
      when(() => repository.mySubscription()).thenAnswer((_) async => null);
      when(() => repository.plans()).thenAnswer((_) async => [_plan]);
    });

    testWidgets('mostra a vitrine com preço e cota', (tester) async {
      await pumpPage(tester);

      expect(find.text('Barba & Cabelo'), findsOneWidget);
      expect(find.text('Corte Masculino · 2x por mês'), findsOneWidget);
      expect(find.text('Assinar plano'), findsOneWidget);
      expect(find.textContaining('50% de desconto'), findsOneWidget);
    });

    testWidgets('abre a escolha da forma de pagamento', (tester) async {
      await pumpPage(tester);
      await tester.tap(find.text('Assinar plano'));
      await tester.pumpAndSettle();

      expect(find.text('Como você quer pagar?'), findsOneWidget);
      expect(find.text('PIX'), findsOneWidget);
      expect(find.text('Cartão de crédito'), findsOneWidget);
      // O cliente precisa saber que o cartão não passa pela barbearia.
      expect(
        find.textContaining('não passam pela barbearia'),
        findsOneWidget,
      );
    });

    testWidgets('assina com PIX e recebe o QR', (tester) async {
      when(
        () => repository.subscribe(
          planId: any(named: 'planId'),
          billingType: any(named: 'billingType'),
          branchId: any(named: 'branchId'),
        ),
      ).thenAnswer(
        (_) async => Subscription.fromJson(
          _subscriptionJson(
            status: 'PENDING_PAYMENT',
            openInvoice: {
              'id': 20,
              'plan_name': 'Barba & Cabelo',
              'amount': '99.90',
              'method': 'PIX',
              'status': 'PENDING',
              'pix_qr_code': '00020126580014br.gov.bcb.pix',
              'pix_qr_code_base64': '',
              'expires_at': '2099-01-01T10:00:00Z',
            },
          ),
        ),
      );

      await pumpPage(tester);
      await tester.tap(find.text('Assinar plano'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar para o pagamento'));
      await tester.pumpAndSettle();

      expect(find.text('Ou copie o código'), findsOneWidget);
      expect(find.text('Copiar código PIX'), findsOneWidget);
      expect(
        find.text('00020126580014br.gov.bcb.pix'),
        findsOneWidget,
      );

      // A escolha padrão é PIX.
      final captured = verify(
        () => repository.subscribe(
          planId: captureAny(named: 'planId'),
          billingType: captureAny(named: 'billingType'),
          branchId: any(named: 'branchId'),
        ),
      ).captured;
      expect(captured[0], 1);
      expect(captured[1], BillingType.pixMonthly);
    });

    testWidgets('erro ao assinar mostra mensagem amigável', (tester) async {
      when(
        () => repository.subscribe(
          planId: any(named: 'planId'),
          billingType: any(named: 'billingType'),
          branchId: any(named: 'branchId'),
        ),
      ).thenThrow(
        const ApiException(
          message: 'Você já tem uma assinatura em andamento.',
          code: 'SUBSCRIPTION_ALREADY_EXISTS',
          statusCode: 409,
        ),
      );

      await pumpPage(tester);
      await tester.tap(find.text('Assinar plano'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar para o pagamento'));
      await tester.pumpAndSettle();

      expect(
        find.text('Você já tem uma assinatura em andamento.'),
        findsOneWidget,
      );
    });
  });

  group('com assinatura ativa', () {
    setUp(() {
      when(() => repository.mySubscription()).thenAnswer(
        (_) async => Subscription.fromJson(_subscriptionJson()),
      );
      when(() => repository.plans()).thenAnswer((_) async => [_plan]);
    });

    testWidgets('mostra o plano, o status e o uso do mês', (tester) async {
      await pumpPage(tester);

      expect(find.text('Meu plano'), findsOneWidget);
      expect(find.text('Ativa'), findsOneWidget);
      expect(find.text('Seu uso neste mês'), findsOneWidget);
      expect(find.text('1 de 2 restante(s)'), findsOneWidget);
    });

    testWidgets('não oferece a vitrine para quem já assina', (tester) async {
      // O backend recusa uma segunda assinatura; o botão só falharia.
      await pumpPage(tester);

      expect(find.text('Assinar plano'), findsNothing);
      expect(find.text('Planos mensais'), findsNothing);
    });

    testWidgets('oferece o cancelamento', (tester) async {
      await pumpPage(tester);
      expect(find.text('Cancelar assinatura'), findsOneWidget);
    });

    testWidgets('avisa quando o cancelamento já foi pedido', (tester) async {
      when(() => repository.mySubscription()).thenAnswer(
        (_) async =>
            Subscription.fromJson(_subscriptionJson(cancelAtPeriodEnd: true)),
      );

      await pumpPage(tester);

      expect(
        find.textContaining('mantém os benefícios até'),
        findsOneWidget,
      );
      // Já cancelada: não oferece cancelar de novo.
      expect(find.text('Cancelar assinatura'), findsNothing);
    });
  });

  group('com pagamento em aberto', () {
    testWidgets('mostra o valor devido e o botão de pagar', (tester) async {
      when(() => repository.mySubscription()).thenAnswer(
        (_) async => Subscription.fromJson(
          _subscriptionJson(
            status: 'PENDING_PAYMENT',
            openInvoice: {
              'id': 20,
              'amount': '99.90',
              'method': 'PIX',
              'status': 'PENDING',
              'pix_qr_code': '000201',
            },
          ),
        ),
      );
      when(() => repository.plans()).thenAnswer((_) async => [_plan]);

      await pumpPage(tester);

      expect(find.text('Aguardando pagamento'), findsOneWidget);
      expect(find.textContaining('99,90 em aberto'), findsOneWidget);
      expect(find.text('Pagar agora'), findsOneWidget);
    });

    testWidgets('QR expirado oferece gerar um novo', (tester) async {
      when(() => repository.mySubscription()).thenAnswer(
        (_) async => Subscription.fromJson(
          _subscriptionJson(
            status: 'PENDING_PAYMENT',
            openInvoice: {
              'id': 20,
              'amount': '99.90',
              'method': 'PIX',
              'status': 'PENDING',
              'pix_qr_code': '000201',
              'expires_at': '2020-01-01T10:00:00Z',
            },
          ),
        ),
      );
      when(() => repository.plans()).thenAnswer((_) async => [_plan]);

      await pumpPage(tester);
      await tester.tap(find.text('Pagar agora'));
      await tester.pumpAndSettle();

      expect(find.textContaining('código PIX expirou'), findsOneWidget);
      expect(find.text('Gerar novo código PIX'), findsOneWidget);
    });
  });
}
