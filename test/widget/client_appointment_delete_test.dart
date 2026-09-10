import 'package:sua_barbearia/core/theme/app_theme.dart';
import 'package:sua_barbearia/features/client/client_appointments_page.dart';
import 'package:sua_barbearia/models/appointment.dart';
import 'package:sua_barbearia/providers/core_providers.dart';
import 'package:sua_barbearia/repositories/appointment_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

class MockAppointmentRepository extends Mock implements AppointmentRepository {}

Appointment agendamento({required bool dentroDoPrazo}) => Appointment(
      id: 42,
      uuid: 'uuid-42',
      clientId: 7,
      clientName: 'Carlos Mendes',
      barberId: 3,
      barberName: 'Kauê',
      branchId: 1,
      branchName: 'Centro',
      serviceId: 2,
      serviceName: 'Corte',
      date: DateTime.now().add(const Duration(days: 3)),
      startTime: '10:00:00',
      endTime: '10:30:00',
      price: 50,
      status: AppointmentStatus.confirmed,
      canBeCancelledByClient: dentroDoPrazo,
    );

Widget buildApp(MockAppointmentRepository repository) {
  return ProviderScope(
    overrides: [
      appointmentRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: ClientAppointmentsPage()),
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
  late MockAppointmentRepository repository;

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() => repository = MockAppointmentRepository());

  Future<void> pump(WidgetTester tester, {bool dentroDoPrazo = true}) async {
    when(() => repository.upcoming()).thenAnswer(
      (_) async => [agendamento(dentroDoPrazo: dentroDoPrazo)],
    );
    await tester.pumpWidget(buildApp(repository));
    await tester.pumpAndSettle();
  }

  testWidgets('dentro do prazo o cliente vê cancelar e excluir',
      (tester) async {
    await pump(tester);

    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Excluir'), findsOneWidget);
  });

  testWidgets('fora do prazo não há excluir — só o aviso', (tester) async {
    // Excluir não pode contornar o prazo de cancelamento da filial.
    await pump(tester, dentroDoPrazo: false);

    expect(find.text('Excluir'), findsNothing);
    expect(find.text('Cancelar'), findsNothing);
    expect(find.text('Cancelamento pelo app encerrado'), findsOneWidget);
  });

  testWidgets('excluir pede confirmação e diferencia de cancelar',
      (tester) async {
    await pump(tester);

    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Excluir agendamento'), findsOneWidget);
    expect(find.textContaining('sem registro do motivo'), findsOneWidget);
    expect(find.textContaining('use Cancelar'), findsOneWidget);
    verifyNever(() => repository.delete(any()));
  });

  testWidgets('manter não apaga', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manter'));
    await tester.pumpAndSettle();

    verifyNever(() => repository.delete(any()));
  });

  testWidgets('confirmar apaga o agendamento', (tester) async {
    when(() => repository.delete(any())).thenAnswer((_) async {});
    await pump(tester);

    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir').last);
    await tester.pumpAndSettle();

    verify(() => repository.delete(42)).called(1);
  });
}
