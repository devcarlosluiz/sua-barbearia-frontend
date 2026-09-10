import 'json_utils.dart';

/// Status do agendamento — espelha `appointments.AppointmentStatus`.
enum AppointmentStatus {
  pending('PENDING', 'Pendente'),
  confirmed('CONFIRMED', 'Confirmado'),
  arrived('ARRIVED', 'Cliente chegou'),
  inProgress('IN_PROGRESS', 'Em atendimento'),
  completed('COMPLETED', 'Concluído'),
  cancelled('CANCELLED', 'Cancelado'),
  noShow('NO_SHOW', 'Não compareceu');

  const AppointmentStatus(this.value, this.label);

  final String value;
  final String label;

  static AppointmentStatus fromValue(String? value) =>
      AppointmentStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => AppointmentStatus.pending,
      );

  bool get isFinal =>
      this == AppointmentStatus.completed ||
      this == AppointmentStatus.cancelled ||
      this == AppointmentStatus.noShow;

  bool get isActive => !isFinal;
}

class AppointmentStatusHistory {
  const AppointmentStatusHistory({
    required this.id,
    required this.toStatus,
    required this.toStatusLabel,
    this.fromStatusLabel = '',
    this.changedByName,
    this.reason = '',
    this.createdAt,
  });

  final int id;
  final String toStatus;
  final String toStatusLabel;
  final String fromStatusLabel;
  final String? changedByName;
  final String reason;
  final DateTime? createdAt;

  factory AppointmentStatusHistory.fromJson(Map<String, dynamic> json) =>
      AppointmentStatusHistory(
        id: Json.asInt(json['id']),
        toStatus: Json.asString(json['to_status']),
        toStatusLabel: Json.asString(json['to_status_display']),
        fromStatusLabel: Json.asString(json['from_status_display']),
        changedByName: Json.asStringOrNull(json['changed_by_name']),
        reason: Json.asString(json['reason']),
        createdAt: Json.asDate(json['created_at']),
      );
}

class Appointment {
  const Appointment({
    required this.id,
    required this.uuid,
    required this.clientId,
    required this.clientName,
    required this.barberId,
    required this.barberName,
    required this.branchId,
    required this.branchName,
    required this.serviceId,
    required this.serviceName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.status,
    this.clientPhone = '',
    this.durationMinutes = 0,
    this.notes = '',
    this.internalNotes = '',
    this.cancellationReason = '',
    this.cancelledByRole,
    this.completedAt,
    this.createdAt,
    this.hasReview = false,
    this.canBeCancelledByClient = false,
    this.commissionAmount = 0,
    this.statusHistory = const [],
  });

  final int id;
  final String uuid;
  final int clientId;
  final String clientName;
  final String clientPhone;
  final int barberId;
  final String barberName;
  final int branchId;
  final String branchName;
  final int serviceId;
  final String serviceName;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final double price;
  final AppointmentStatus status;
  final String notes;
  final String internalNotes;
  final String cancellationReason;
  final String? cancelledByRole;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final bool hasReview;
  final bool canBeCancelledByClient;
  final double commissionAmount;
  final List<AppointmentStatusHistory> statusHistory;

  /// `HH:MM` (a API devolve `HH:MM:SS`).
  String get startLabel => _clock(startTime);
  String get endLabel => _clock(endTime);

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool get isUpcoming => status.isActive && !date.isBefore(_todayOnly());

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: Json.asInt(json['id']),
        uuid: Json.asString(json['uuid']),
        clientId: Json.asInt(json['client']),
        clientName: Json.asString(json['client_name']),
        clientPhone: Json.asString(json['client_phone']),
        barberId: Json.asInt(json['barber']),
        barberName: Json.asString(json['barber_name']),
        branchId: Json.asInt(json['branch']),
        branchName: Json.asString(json['branch_name']),
        serviceId: Json.asInt(json['service']),
        serviceName: Json.asString(json['service_name']),
        date: Json.asDate(json['date']) ?? DateTime.now(),
        startTime: Json.asString(json['start_time']),
        endTime: Json.asString(json['end_time']),
        durationMinutes: Json.asInt(json['duration_minutes']),
        price: Json.asDouble(json['price']),
        status: AppointmentStatus.fromValue(json['status'] as String?),
        notes: Json.asString(json['notes']),
        internalNotes: Json.asString(json['internal_notes']),
        cancellationReason: Json.asString(json['cancellation_reason']),
        cancelledByRole: Json.asStringOrNull(json['cancelled_by_role']),
        completedAt: Json.asDate(json['completed_at']),
        createdAt: Json.asDate(json['created_at']),
        hasReview: Json.asBool(json['has_review']),
        canBeCancelledByClient: Json.asBool(json['can_be_cancelled_by_client']),
        commissionAmount: Json.asDouble(json['commission_amount']),
        statusHistory: Json.asMapList(json['status_history'])
            .map(AppointmentStatusHistory.fromJson)
            .toList(),
      );

  static String _clock(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  static DateTime _todayOnly() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Appointment && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Resposta de `GET /appointments/available-slots/`.
class AvailableSlots {
  const AvailableSlots({
    required this.date,
    required this.slots,
    required this.durationMinutes,
    required this.price,
  });

  final DateTime date;
  final List<String> slots;
  final int durationMinutes;
  final double price;

  bool get isEmpty => slots.isEmpty;

  factory AvailableSlots.fromJson(Map<String, dynamic> json) => AvailableSlots(
        date: Json.asDate(json['date']) ?? DateTime.now(),
        slots: Json.asStringList(json['slots']),
        durationMinutes: Json.asInt(json['duration_minutes']),
        price: Json.asDouble(json['price']),
      );
}

/// Agenda de um dia (`GET /appointments/agenda/`).
class DayAgenda {
  const DayAgenda({required this.date, required this.appointments});

  final DateTime date;
  final List<Appointment> appointments;

  int get count => appointments.length;

  factory DayAgenda.fromJson(Map<String, dynamic> json) => DayAgenda(
        date: Json.asDate(json['date']) ?? DateTime.now(),
        appointments: Json.asMapList(json['appointments'])
            .map(Appointment.fromJson)
            .toList(),
      );
}
