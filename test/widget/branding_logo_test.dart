import 'dart:async';

import 'package:sua_barbearia/core/theme/app_theme.dart';
import 'package:sua_barbearia/features/auth/widgets/auth_scaffold.dart';
import 'package:sua_barbearia/models/branding.dart';
import 'package:sua_barbearia/providers/branding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// A marca aparece no login, no splash e na casca de navegação. Ela nunca pode
/// sumir nem travar a tela quando a logo do proprietário falha ao carregar.
Widget buildApp(AsyncValue<Branding> branding, {bool large = false}) {
  return ProviderScope(
    overrides: [
      brandingProvider.overrideWith((ref) async {
        if (branding is AsyncError) {
          throw Exception('sem rede');
        }
        // Um Future que nunca resolve simula o estado "carregando".
        if (branding is AsyncLoading) return Completer<Branding>().future;
        return branding.requireValue;
      }),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: SuaBarbeariaWordmark(large: large))),
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
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('sem logo enviada', () {
    testWidgets('desenha a marca padrão do aplicativo', (tester) async {
      await tester.pumpWidget(buildApp(const AsyncData(Branding())));
      await tester.pump();

      expect(find.text('SUA'), findsOneWidget);
      expect(find.text('BARBEARIA'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });
  });

  group('com logo enviada', () {
    const comLogo = Branding(logoUrl: 'https://cdn.test/logo-abc123.png');

    testWidgets('usa a imagem no lugar da marca padrão', (tester) async {
      await tester.pumpWidget(buildApp(const AsyncData(comLogo)));
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('SUA'), findsNothing);
    });

    testWidgets('respeita a altura de cada contexto', (tester) async {
      await tester.pumpWidget(buildApp(const AsyncData(comLogo)));
      await tester.pump();
      final compacta = tester.widget<Image>(
        find.byType(Image),
      );
      expect(compacta.height, 62);

      await tester.pumpWidget(buildApp(const AsyncData(comLogo), large: true));
      await tester.pump();
      final grande = tester.widget<Image>(
        find.byType(Image),
      );
      expect(grande.height, 100);
    });
  });

  group('quando a logo não pode ser carregada', () {
    testWidgets('erro de rede cai para a marca padrão', (tester) async {
      // A logo é enfeite: falhar em buscá-la não pode deixar o cabeçalho vazio.
      await tester
          .pumpWidget(buildApp(AsyncError(Exception('x'), StackTrace.empty)));
      await tester.pump();

      expect(find.text('SUA'), findsOneWidget);
    });

    testWidgets('enquanto carrega também mostra a marca padrão',
        (tester) async {
      await tester.pumpWidget(buildApp(const AsyncLoading()));
      await tester.pump();

      expect(find.text('SUA'), findsOneWidget);
    });
  });

  group('nome da barbearia', () {
    testWidgets('a marca padrão usa o nome configurado', (tester) async {
      await tester.pumpWidget(
        buildApp(const AsyncData(Branding(companyName: 'Barbearia Imperial'))),
      );
      await tester.pump();

      // "Barbearia" vira a marca e "Imperial" o descritor, preservando o
      // desenho de duas linhas da marca original.
      expect(find.text('BARBEARIA'), findsOneWidget);
      expect(find.text('IMPERIAL'), findsOneWidget);
      // O nome configurado substitui o padrão, não convive com ele.
      expect(find.text('SUA'), findsNothing);
    });

    testWidgets('nome de uma palavra não inventa segunda linha',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const AsyncData(Branding(companyName: 'Barbearia'))),
      );
      await tester.pump();

      expect(find.text('BARBEARIA'), findsOneWidget);
    });

    testWidgets('nome com três palavras mantém as duas primeiras juntas',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
            const AsyncData(Branding(companyName: 'Corte Fino Barbearia'))),
      );
      await tester.pump();

      expect(find.text('CORTE FINO'), findsOneWidget);
      expect(find.text('BARBEARIA'), findsOneWidget);
    });

    testWidgets('sem resposta do servidor cai para o nome padrão',
        (tester) async {
      await tester.pumpWidget(
        buildApp(AsyncError(Exception('x'), StackTrace.empty)),
      );
      await tester.pump();

      expect(find.text('SUA'), findsOneWidget);
      expect(find.text('BARBEARIA'), findsOneWidget);
    });

    test('o padrão do modelo é o nome do produto', () {
      expect(const Branding().companyName, 'Sua Barbearia');
    });

    test('desserializa o nome vindo da API', () {
      final branding = Branding.fromJson({'company_name': 'Barbearia do Zé'});
      expect(branding.companyName, 'Barbearia do Zé');
    });

    test('payload sem nome usa o padrão', () {
      expect(Branding.fromJson({}).companyName, 'Sua Barbearia');
    });
  });

  group('orientação de envio', () {
    test('o texto de ajuda usa os valores vindos do backend', () {
      const branding = Branding(
        recommendedWidth: 600,
        recommendedHeight: 160,
        maxFileSizeMb: 2,
      );

      expect(
        branding.uploadHint,
        '600 × 160 px · PNG com fundo transparente · até 2 MB',
      );
    });

    test('respeita valores diferentes sem duplicar a regra', () {
      const branding = Branding(
        recommendedWidth: 800,
        recommendedHeight: 200,
        maxFileSizeMb: 5,
      );

      expect(branding.uploadHint, contains('800 × 200 px'));
      expect(branding.uploadHint, contains('até 5 MB'));
    });

    test('hasLogo distingue ausência de string vazia', () {
      expect(const Branding().hasLogo, isFalse);
      expect(const Branding(logoUrl: '').hasLogo, isFalse);
      expect(const Branding(logoUrl: 'https://x/y.png').hasLogo, isTrue);
    });
  });

  group('desserialização', () {
    test('lê o payload da API', () {
      final branding = Branding.fromJson({
        'logo_url': 'http://localhost:8000/media/branding/logo-abc.png',
        'recommended_width': 600,
        'recommended_height': 160,
        'max_file_size_mb': 2,
        'updated_at': '2026-09-04T18:00:00Z',
      });

      expect(branding.hasLogo, isTrue);
      expect(branding.recommendedWidth, 600);
      expect(branding.updatedAt, isNotNull);
    });

    test('payload sem logo usa os padrões', () {
      final branding = Branding.fromJson({'logo_url': null});

      expect(branding.hasLogo, isFalse);
      expect(branding.recommendedWidth, 600);
      expect(branding.maxFileSizeMb, 2);
    });
  });
}
