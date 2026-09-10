import 'json_utils.dart';
import 'service.dart';

class BarberService {
  const BarberService({
    required this.id,
    required this.serviceId,
    required this.price,
    required this.durationMinutes,
    this.service,
    this.customPrice,
    this.customDurationMinutes,
    this.isActive = true,
  });

  final int id;
  final int serviceId;
  final Service? service;
  final double price;
  final int durationMinutes;
  final double? customPrice;
  final int? customDurationMinutes;
  final bool isActive;

  String get name => service?.name ?? 'Serviço #$serviceId';

  factory BarberService.fromJson(Map<String, dynamic> json) {
    final detail = Json.asMap(json['service_detail']);
    return BarberService(
      id: Json.asInt(json['id']),
      serviceId: Json.asInt(json['service']),
      service: detail.isEmpty ? null : Service.fromJson(detail),
      price: Json.asDouble(json['price']),
      durationMinutes: Json.asInt(json['duration_minutes']),
      customPrice: Json.asDoubleOrNull(json['custom_price']),
      customDurationMinutes: Json.asIntOrNull(json['custom_duration_minutes']),
      isActive: Json.asBool(json['is_active'], fallback: true),
    );
  }
}

class WorkingHour {
  const WorkingHour({
    required this.id,
    required this.barberId,
    required this.branchId,
    required this.weekday,
    required this.weekdayLabel,
    required this.startsAt,
    required this.endsAt,
    this.branchName = '',
    this.breakStartsAt,
    this.breakEndsAt,
    this.isActive = true,
  });

  final int id;
  final int barberId;
  final int branchId;
  final String branchName;
  final int weekday;
  final String weekdayLabel;
  final String startsAt;
  final String endsAt;
  final String? breakStartsAt;
  final String? breakEndsAt;
  final bool isActive;

  bool get hasBreak => breakStartsAt != null && breakEndsAt != null;

  factory WorkingHour.fromJson(Map<String, dynamic> json) => WorkingHour(
        id: Json.asInt(json['id']),
        barberId: Json.asInt(json['barber']),
        branchId: Json.asInt(json['branch']),
        branchName: Json.asString(json['branch_name']),
        weekday: Json.asInt(json['weekday']),
        weekdayLabel: Json.asString(json['weekday_display']),
        startsAt: Json.asString(json['starts_at']),
        endsAt: Json.asString(json['ends_at']),
        breakStartsAt: Json.asStringOrNull(json['break_starts_at']),
        breakEndsAt: Json.asStringOrNull(json['break_ends_at']),
        isActive: Json.asBool(json['is_active'], fallback: true),
      );

  Map<String, dynamic> toJson() => {
        'barber': barberId,
        'branch': branchId,
        'weekday': weekday,
        'starts_at': startsAt,
        'ends_at': endsAt,
        'break_starts_at': breakStartsAt,
        'break_ends_at': breakEndsAt,
        'is_active': isActive,
      };
}

class TimeOff {
  const TimeOff({
    required this.id,
    required this.barberId,
    required this.type,
    required this.typeLabel,
    required this.startsAt,
    required this.endsAt,
    this.barberName = '',
    this.branchId,
    this.reason = '',
  });

  final int id;
  final int barberId;
  final String barberName;
  final int? branchId;
  final String type;
  final String typeLabel;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String reason;

  factory TimeOff.fromJson(Map<String, dynamic> json) => TimeOff(
        id: Json.asInt(json['id']),
        barberId: Json.asInt(json['barber']),
        barberName: Json.asString(json['barber_name']),
        branchId: Json.asIntOrNull(json['branch']),
        type: Json.asString(json['type']),
        typeLabel: Json.asString(json['type_display']),
        startsAt: Json.asDate(json['starts_at']),
        endsAt: Json.asDate(json['ends_at']),
        reason: Json.asString(json['reason']),
      );

  Map<String, dynamic> toJson() => {
        'barber': barberId,
        'branch': branchId,
        'type': type,
        'starts_at': startsAt?.toIso8601String(),
        'ends_at': endsAt?.toIso8601String(),
        'reason': reason,
      };
}

class Barber {
  const Barber({
    required this.id,
    required this.name,
    this.uuid = '',
    this.userId,
    this.firstName = '',
    this.lastName = '',
    this.nickname = '',
    this.email = '',
    this.phone = '',
    this.bio = '',
    this.avatarUrl,
    this.specialties = const [],
    this.commissionPercentage = 0,
    this.rating = 0,
    this.reviewsCount = 0,
    this.isActive = true,
    this.branchIds = const [],
    this.services = const [],
    this.workingHours = const [],
  });

  final int id;
  final String uuid;
  final int? userId;

  /// Nome de exibição (apelido, quando houver).
  final String name;

  /// Nome e sobrenome reais do usuário — usados nos formulários de edição.
  /// Só vêm no detalhe (`GET /barbers/{id}/`), não na listagem.
  final String firstName;
  final String lastName;
  final String nickname;
  final String email;
  final String phone;
  final String bio;
  final String? avatarUrl;
  final List<String> specialties;
  final double commissionPercentage;
  final double rating;
  final int reviewsCount;
  final bool isActive;
  final List<int> branchIds;
  final List<BarberService> services;
  final List<WorkingHour> workingHours;

  bool get hasRating => reviewsCount > 0;

  factory Barber.fromJson(Map<String, dynamic> json) => Barber(
        id: Json.asInt(json['id']),
        uuid: Json.asString(json['uuid']),
        userId: Json.asIntOrNull(json['user_id']),
        name: Json.asString(json['name']),
        firstName: Json.asString(json['first_name']),
        lastName: Json.asString(json['last_name']),
        nickname: Json.asString(json['nickname']),
        email: Json.asString(json['email']),
        phone: Json.asString(json['phone']),
        bio: Json.asString(json['bio']),
        avatarUrl: Json.asStringOrNull(json['avatar_url']),
        specialties: Json.asStringList(json['specialties']),
        commissionPercentage: Json.asDouble(json['commission_percentage']),
        rating: Json.asDouble(json['rating']),
        reviewsCount: Json.asInt(json['reviews_count']),
        isActive: Json.asBool(json['is_active'], fallback: true),
        branchIds: (json['branch_ids'] as List<dynamic>? ??
                json['branches'] as List<dynamic>? ??
                const [])
            .map(Json.asInt)
            .toList(),
        services: Json.asMapList(json['barber_services'])
            .map(BarberService.fromJson)
            .toList(),
        workingHours: Json.asMapList(json['working_hours'])
            .map(WorkingHour.fromJson)
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Barber && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
