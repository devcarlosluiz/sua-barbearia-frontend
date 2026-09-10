import 'package:sua_barbearia/core/theme/app_theme.dart';
import 'package:sua_barbearia/models/user.dart';
import 'package:sua_barbearia/providers/core_providers.dart';
import 'package:sua_barbearia/repositories/auth_repository.dart';
import 'package:sua_barbearia/widgets/avatar_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const _cliente = User(
  id: 5,
  uuid: 'uuid-cliente',
  name: 'Carlos Mendes',
  firstName: 'Carlos',
  lastName: 'Mendes',
  email: 'cliente@suabarbearia.com',
  phone: '41977770000',
  role: UserRole.client,
);

Widget buildApp(MockAuthRepository repository, {String? imageUrl}) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: AvatarPicker(name: 'Carlos Mendes', imageUrl: imageUrl),
        ),
      ),
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

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() {
    repository = MockAuthRepository();
    when(() => repository.hasSession()).thenAnswer((_) async => false);
  });

  Future<void> pump(WidgetTester tester, {String? imageUrl}) async {
    await tester.pumpWidget(buildApp(repository, imageUrl: imageUrl));
    await tester.pump();
  }

  group('afordância', () {
    testWidgets('o selo de câmera indica que dá para trocar a foto',
        (tester) async {
      await pump(tester);
      expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);
    });

    testWidgets('sem foto mostra as iniciais do nome', (tester) async {
      await pump(tester);
      // O AppAvatar desenha as iniciais — nunca há um espaço quebrado.
      expect(find.text('CM'), findsOneWidget);
    });

    testWidgets('anuncia a ação para leitores de tela', (tester) async {
      await pump(tester);
      expect(find.byTooltip('Adicionar foto de perfil'), findsOneWidget);

      await pump(tester, imageUrl: 'https://cdn.test/foto.jpg');
      expect(find.byTooltip('Trocar a foto de perfil'), findsOneWidget);
    });
  });

  group('com foto', () {
    testWidgets('tocar abre o menu com trocar e remover', (tester) async {
      // Remover não pode ficar atrás de um gesto que ninguém descobre.
      await pump(tester, imageUrl: 'https://cdn.test/foto.jpg');

      await tester.tap(find.byIcon(Icons.photo_camera_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Trocar foto'), findsOneWidget);
      expect(find.text('Remover foto'), findsOneWidget);
    });

    testWidgets('remover pede confirmação antes de apagar', (tester) async {
      await pump(tester, imageUrl: 'https://cdn.test/foto.jpg');

      await tester.tap(find.byIcon(Icons.photo_camera_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover foto'));
      await tester.pumpAndSettle();

      expect(find.text('Remover a foto?'), findsOneWidget);
      verifyNever(() => repository.removeAvatar());
    });

    testWidgets('confirmar remove de fato', (tester) async {
      when(() => repository.removeAvatar()).thenAnswer((_) async {});
      when(() => repository.me())
          .thenAnswer((_) async => const CurrentUser(user: _cliente));

      await pump(tester, imageUrl: 'https://cdn.test/foto.jpg');

      await tester.tap(find.byIcon(Icons.photo_camera_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover foto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover'));
      await tester.pumpAndSettle();

      verify(() => repository.removeAvatar()).called(1);
    });

    testWidgets('cancelar a confirmação não remove', (tester) async {
      await pump(tester, imageUrl: 'https://cdn.test/foto.jpg');

      await tester.tap(find.byIcon(Icons.photo_camera_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover foto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      verifyNever(() => repository.removeAvatar());
    });
  });

  group('sem foto', () {
    testWidgets('tocar não abre menu — vai direto ao seletor', (tester) async {
      await pump(tester);

      await tester.tap(find.byIcon(Icons.photo_camera_rounded));
      await tester.pumpAndSettle();

      // Sem foto a única ação possível é enviar; um menu de uma opção só
      // seria um toque a mais sem ganho.
      expect(find.text('Trocar foto'), findsNothing);
      expect(find.text('Remover foto'), findsNothing);
    });
  });
}
