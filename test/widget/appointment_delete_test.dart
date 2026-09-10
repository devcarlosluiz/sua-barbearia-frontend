import 'package:sua_barbearia/core/theme/app_theme.dart';
import 'package:sua_barbearia/features/shared/attendance_actions.dart';
import 'package:sua_barbearia/models/appointment.dart';
import 'package:sua_barbearia/models/user.dart';
import 'package:sua_barbearia/providers/auth_provider.dart';
import 'package:sua_barbearia/providers/core_providers.dart';
import 'package:sua_barbearia/repositories/appointment_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

class MockAppointmentRepository extends Mock implements AppointmentRepository {}

Appointment agendamento(AppointmentStatus status) => Appointment(
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
      date: DateTime(2026, 9, 10),
      startTime: '10:00:00',
      endTime: '10:30:00',
      price: 50,
      status: status,
    );

Widget buildApp(
  MockAppointmentRepository repository, {
  required UserRole role,
  required AppointmentStatus status,
}) {
  return ProviderScope(
    overrides: [
      appointmentRepositoryProvider.overrideWithValue(repository),
      currentRoleProvider.overrideWithValue(role),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: AttendanceActions(appointment: agendamento(status)),
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
  late MockAppointmentRepository repository;

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() => repository = MockAppointmentRepository());

  Future<void> pump(
    WidgetTester tester, {
    UserRole role = UserRole.owner,
    AppointmentStatus status = AppointmentStatus.cancelled,
  }) async {
    await tester.pumpWidget(buildApp(repository, role: role, status: status));
    await tester.pump();
  }

  group('quem vê o botão', () {
    testWidgets('o dono vê excluir num agendamento cancelado', (tester) async {
      // Antes, um cancelado não oferecia nenhuma ação — ficava para sempre.
      await pump(tester);
      expect(find.text('Excluir'), findsOneWidget);
    });

    testWidgets('o barbeiro não vê', (tester) async {
      await pump(tester, role: UserRole.barber);
      expect(find.text('Excluir'), findsNothing);
    });

    testWidgets('o cliente não vê', (tester) async {
      await pump(tester, role: UserRole.client);
      expect(find.text('Excluir'), findsNothing);
    });

    testWidgets('nem o dono exclui um atendimento concluído', (tester) async {
      // Concluído tem pagamento, comissão e pontos: o backend recusa.
      await pump(tester, status: AppointmentStatus.completed);
      expect(find.text('Excluir'), findsNothing);
    });

    testWidgets('excluir convive com as ações do fluxo', (tester) async {
      await pump(tester, status: AppointmentStatus.pending);
      expect(find.text('Confirmar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Excluir'), findsOneWidget);
    });
  });

  group('confirmação', () {
    testWidgets('não apaga sem confirmar', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      expect(find.text('Excluir este agendamento?'), findsOneWidget);
      verifyNever(() => repository.delete(any()));
    });

    testWidgets('desistir da confirmação não apaga', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      verifyNever(() => repository.delete(any()));
    });

    testWidgets('confirmar apaga o agendamento', (tester) async {
      when(() => repository.delete(any())).thenAnswer((_) async {});
      await pump(tester);

      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();
      // O botão do diálogo tem o mesmo rótulo do que abriu a confirmação.
      await tester.tap(find.text('Excluir').last);
      await tester.pumpAndSettle();

      verify(() => repository.delete(42)).called(1);
    });

    testWidgets('num horário ativo o aviso empurra para o cancelamento',
        (tester) async {
      // Excluir um horário que ainda vale não avisa o cliente — cancelar avisa.
      await pump(tester, status: AppointmentStatus.confirmed);

      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('sem aviso ao cliente'),
        findsOneWidget,
      );
      expect(find.textContaining('use Cancelar'), findsOneWidget);
    });

    testWidgets('num cancelado o aviso não fala em avisar o cliente',
        (tester) async {
      await pump(tester);

      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      expect(find.textContaining('sem aviso ao cliente'), findsNothing);
      expect(find.textContaining('histórico de status'), findsOneWidget);
    });
  });
}
