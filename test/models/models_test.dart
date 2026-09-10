import 'package:sua_barbearia/models/appointment.dart';
import 'package:sua_barbearia/models/branch.dart';
import 'package:sua_barbearia/models/dashboard.dart';
import 'package:sua_barbearia/models/service.dart';
import 'package:sua_barbearia/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

/// Os payloads abaixo reproduzem o formato real devolvido pela API do Sua Barbearia.
void main() {
  group('User', () {
    test('desserializa o payload do login', () {
      final user = User.fromJson({
        'id': 1,
        'uuid': '85123e1b-72f7-40d6-ad02-4e23ad84a7ad',
        'name': 'Carlos Proprietário',
        'first_name': 'Carlos',
        'last_name': 'Proprietário',
        'email': 'owner@suabarbearia.com',
        'phone': '41999990000',
        'role': 'OWNER',
        'avatar_url': null,
        'is_active': true,
        'is_verified': true,
      });

      expect(user.id, 1);
      expect(user.role, UserRole.owner);
      expect(user.role.isOwner, isTrue);
      expect(user.avatarUrl, isNull);
    });

    test('papel desconhecido não quebra a desserialização', () {
      final user = User.fromJson({'id': 2, 'role': 'MANAGER'});
      expect(user.role, UserRole.unknown);
    });
  });

  group('Service', () {
    test('converte preço em string decimal do DRF', () {
      final service = Service.fromJson({
        'id': 3,
        'name': 'Corte Masculino',
        'duration_minutes': 30,
        'price': '45.00',
        'is_active': true,
      });

      expect(service.price, 45.0);
      expect(service.durationMinutes, 30);
    });
  });

  group('Branch', () {
    test('desserializa filial com horários', () {
      final branch = Branch.fromJson({
        'id': 4,
        'uuid': 'abc',
        'name': 'Sua Barbearia Centro',
        'city': 'Curitiba',
        'state': 'PR',
        'district': 'Centro',
        'full_address': 'Rua XV de Novembro, 1200 - Centro - Curitiba/PR',
        'latitude': '-25.4295200',
        'cancellation_limit_hours': 2,
        'slot_interval_minutes': 30,
        'opening_hours': [
          {
            'id': 1,
            'weekday': 0,
            'weekday_display': 'Segunda-feira',
            'opens_at': '09:00:00',
            'closes_at': '20:00:00',
            'is_closed': false,
          },
        ],
      });

      expect(branch.name, 'Sua Barbearia Centro');
      expect(branch.latitude, closeTo(-25.42952, 0.00001));
      expect(branch.openingHours, hasLength(1));
      expect(branch.openingHours.first.weekdayLabel, 'Segunda-feira');
      expect(branch.shortAddress, 'Centro, Curitiba/PR');
    });
  });

  group('Appointment', () {
    Map<String, dynamic> payload({String status = 'CONFIRMED'}) => {
          'id': 10,
          'uuid': 'uuid-10',
          'client': 1,
          'client_name': 'Carlos Mendes',
          'client_phone': '41977770000',
          'barber': 2,
          'barber_name': 'Jota',
          'branch': 4,
          'branch_name': 'Sua Barbearia Centro',
          'service': 3,
          'service_name': 'Corte Masculino',
          'date': '2026-09-10',
          'start_time': '09:00:00',
          'end_time': '09:30:00',
          'duration_minutes': 30,
          'price': '45.00',
          'status': status,
          'notes': '',
        };

    test('normaliza horários para HH:MM', () {
      final appointment = Appointment.fromJson(payload());
      expect(appointment.startLabel, '09:00');
      expect(appointment.endLabel, '09:30');
    });

    test('mapeia o status e sua natureza', () {
      expect(
        Appointment.fromJson(payload()).status,
        AppointmentStatus.confirmed,
      );
      expect(
        Appointment.fromJson(payload(status: 'COMPLETED')).status.isFinal,
        isTrue,
      );
      expect(
        Appointment.fromJson(payload(status: 'IN_PROGRESS')).status.isActive,
        isTrue,
      );
    });

    test('converte o preço decimal', () {
      expect(Appointment.fromJson(payload()).price, 45.0);
    });
  });

  group('AvailableSlots', () {
    test('desserializa a resposta de horários livres', () {
      final slots = AvailableSlots.fromJson({
        'date': '2026-09-10',
        'duration_minutes': 30,
        'price': '45.00',
        'slots': ['09:00', '09:30', '10:30'],
      });

      expect(slots.slots, hasLength(3));
      expect(slots.isEmpty, isFalse);
      expect(slots.price, 45.0);
      expect(slots.date.day, 10);
    });

    test('lida com lista vazia', () {
      final slots = AvailableSlots.fromJson({
        'date': '2026-09-10',
        'slots': <String>[],
      });
      expect(slots.isEmpty, isTrue);
    });
  });

  group('ClientDashboard', () {
    test('desserializa o resumo do cliente', () {
      final dashboard = ClientDashboard.fromJson({
        'total_visits': 2,
        'total_spent': 105.0,
        'average_ticket': 52.5,
        'loyalty_points': 105,
        'upcoming_count': 1,
        'pending_reviews': 0,
        'reviews_given': 2,
        'last_visit_at': '2026-08-22T14:30:00Z',
        'next_appointment': null,
        'preferred_branch': null,
        'preferred_barber': null,
        'favorite_service': null,
      });

      expect(dashboard.totalVisits, 2);
      expect(dashboard.loyaltyPoints, 105);
      expect(dashboard.hasUpcoming, isFalse);
      expect(dashboard.lastVisitAt, isNotNull);
    });
  });

  group('OwnerDashboard', () {
    test('achata KPIs e gráficos aninhados', () {
      final dashboard = OwnerDashboard.fromJson({
        'period': {'start_date': '2026-08-05', 'end_date': '2026-09-03'},
        'kpis': {
          'revenue_today': '150.00',
          'revenue_month': '1570.00',
          'revenue_period': '1570.00',
          'expense_period': '500.00',
          'balance_period': '1070.00',
          'appointments_today': 3,
          'appointments_period': 50,
          'completed_appointments': 40,
          'cancelled_appointments': 6,
          'no_show_appointments': 4,
          'average_ticket': '52.30',
          'total_clients': 20,
          'new_clients': 5,
          'products_sold': 12,
          'products_revenue': '380.00',
          'pending_commissions': '620.00',
        },
        'charts': {
          'revenue_by_day': [
            {'date': '2026-09-01', 'total': '250.00'},
          ],
          'top_services': [
            {
              'service__id': 3,
              'service__name': 'Corte',
              'count': 12,
              'revenue': '540.00'
            },
          ],
          'payment_methods': [
            {'method': 'PIX', 'count': 10, 'total': '450.00'},
          ],
        },
      });

      expect(dashboard.revenuePeriod, 1570.0);
      expect(dashboard.cancellationRate, closeTo(12.0, 0.01));
      expect(dashboard.noShowRate, closeTo(8.0, 0.01));
      expect(dashboard.revenueByDay, hasLength(1));
      expect(dashboard.topServices.first.label, 'Corte');
      expect(dashboard.paymentMethods.first.label, 'PIX');
    });
  });
}
