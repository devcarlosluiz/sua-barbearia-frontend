import 'json_utils.dart';

class Client {
  const Client({
    required this.id,
    required this.name,
    this.uuid = '',
    this.email = '',
    this.phone = '',
    this.firstName = '',
    this.lastName = '',
    this.avatarUrl,
    this.birthDate,
    this.cpf = '',
    this.preferredBranchId,
    this.preferredBranchName,
    this.preferredBarberId,
    this.preferredBarberName,
    this.favoriteServiceId,
    this.favoriteServiceName,
    this.notes = '',
    this.acceptsMarketing = true,
    this.loyaltyPoints = 0,
    this.totalVisits = 0,
    this.totalSpent = 0,
    this.averageTicket = 0,
    this.lastVisitAt,
  });

  final int id;
  final String uuid;
  final String name;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? avatarUrl;
  final DateTime? birthDate;
  final String cpf;
  final int? preferredBranchId;
  final String? preferredBranchName;
  final int? preferredBarberId;
  final String? preferredBarberName;
  final int? favoriteServiceId;
  final String? favoriteServiceName;
  final String notes;
  final bool acceptsMarketing;
  final int loyaltyPoints;
  final int totalVisits;
  final double totalSpent;
  final double averageTicket;
  final DateTime? lastVisitAt;

  bool get isNew => totalVisits == 0;

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: Json.asInt(json['id']),
        uuid: Json.asString(json['uuid']),
        name: Json.asString(json['name']),
        firstName: Json.asString(json['first_name']),
        lastName: Json.asString(json['last_name']),
        email: Json.asString(json['email']),
        phone: Json.asString(json['phone']),
        avatarUrl: Json.asStringOrNull(json['avatar_url']),
        birthDate: Json.asDate(json['birth_date']),
        cpf: Json.asString(json['cpf']),
        preferredBranchId: Json.asIntOrNull(json['preferred_branch']),
        preferredBranchName: Json.asStringOrNull(json['preferred_branch_name']),
        preferredBarberId: Json.asIntOrNull(json['preferred_barber']),
        preferredBarberName: Json.asStringOrNull(json['preferred_barber_name']),
        favoriteServiceId: Json.asIntOrNull(json['favorite_service']),
        favoriteServiceName: Json.asStringOrNull(json['favorite_service_name']),
        notes: Json.asString(json['notes']),
        acceptsMarketing:
            Json.asBool(json['accepts_marketing'], fallback: true),
        loyaltyPoints: Json.asInt(json['loyalty_points']),
        totalVisits: Json.asInt(json['total_visits']),
        totalSpent: Json.asDouble(json['total_spent']),
        averageTicket: Json.asDouble(json['average_ticket']),
        lastVisitAt: Json.asDate(json['last_visit_at']),
      );

  /// Payload aceito por `PATCH /clients/me/`.
  Map<String, dynamic> toSelfUpdateJson() => {
        'birth_date': Json.dateOnly(birthDate),
        'cpf': cpf,
        'preferred_branch': preferredBranchId,
        'preferred_barber': preferredBarberId,
        'accepts_marketing': acceptsMarketing,
      };

  Client copyWith({
    DateTime? birthDate,
    String? cpf,
    int? preferredBranchId,
    int? preferredBarberId,
    bool? acceptsMarketing,
    String? notes,
  }) =>
      Client(
        id: id,
        uuid: uuid,
        name: name,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        avatarUrl: avatarUrl,
        birthDate: birthDate ?? this.birthDate,
        cpf: cpf ?? this.cpf,
        preferredBranchId: preferredBranchId ?? this.preferredBranchId,
        preferredBranchName: preferredBranchName,
        preferredBarberId: preferredBarberId ?? this.preferredBarberId,
        preferredBarberName: preferredBarberName,
        favoriteServiceId: favoriteServiceId,
        favoriteServiceName: favoriteServiceName,
        notes: notes ?? this.notes,
        acceptsMarketing: acceptsMarketing ?? this.acceptsMarketing,
        loyaltyPoints: loyaltyPoints,
        totalVisits: totalVisits,
        totalSpent: totalSpent,
        averageTicket: averageTicket,
        lastVisitAt: lastVisitAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Client && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
