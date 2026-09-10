import 'json_utils.dart';

class OpeningHour {
  const OpeningHour({
    required this.id,
    required this.weekday,
    required this.weekdayLabel,
    required this.opensAt,
    required this.closesAt,
    required this.isClosed,
  });

  final int id;
  final int weekday;
  final String weekdayLabel;
  final String opensAt;
  final String closesAt;
  final bool isClosed;

  factory OpeningHour.fromJson(Map<String, dynamic> json) => OpeningHour(
        id: Json.asInt(json['id']),
        weekday: Json.asInt(json['weekday']),
        weekdayLabel: Json.asString(json['weekday_display']),
        opensAt: Json.asString(json['opens_at']),
        closesAt: Json.asString(json['closes_at']),
        isClosed: Json.asBool(json['is_closed']),
      );

  Map<String, dynamic> toJson() => {
        'weekday': weekday,
        'opens_at': opensAt,
        'closes_at': closesAt,
        'is_closed': isClosed,
      };
}

class BranchHoliday {
  const BranchHoliday({
    required this.id,
    required this.date,
    required this.description,
    this.opensAt,
    this.closesAt,
  });

  final int id;
  final DateTime? date;
  final String description;
  final String? opensAt;
  final String? closesAt;

  factory BranchHoliday.fromJson(Map<String, dynamic> json) => BranchHoliday(
        id: Json.asInt(json['id']),
        date: Json.asDate(json['date']),
        description: Json.asString(json['description']),
        opensAt: Json.asStringOrNull(json['opens_at']),
        closesAt: Json.asStringOrNull(json['closes_at']),
      );
}

class Branch {
  const Branch({
    required this.id,
    required this.uuid,
    required this.name,
    required this.city,
    required this.state,
    required this.district,
    required this.fullAddress,
    this.slug = '',
    this.cnpj = '',
    this.address = '',
    this.number = '',
    this.complement = '',
    this.zipCode = '',
    this.phone = '',
    this.whatsapp = '',
    this.email = '',
    this.latitude,
    this.longitude,
    this.coverImageUrl,
    this.slotIntervalMinutes = 30,
    this.cancellationLimitHours = 2,
    this.maxAdvanceBookingDays = 90,
    this.loyaltyPointsPerCurrencyUnit = 1,
    this.loyaltyPointValue = 0.04,
    this.isActive = true,
    this.barbersCount = 0,
    this.openingHours = const [],
    this.holidays = const [],
  });

  final int id;
  final String uuid;
  final String name;
  final String slug;
  final String cnpj;
  final String address;
  final String number;
  final String complement;
  final String district;
  final String city;
  final String state;
  final String zipCode;
  final String fullAddress;
  final double? latitude;
  final double? longitude;
  final String phone;
  final String whatsapp;
  final String email;
  final String? coverImageUrl;
  final int slotIntervalMinutes;
  final int cancellationLimitHours;
  final int maxAdvanceBookingDays;
  final double loyaltyPointsPerCurrencyUnit;
  final double loyaltyPointValue;
  final bool isActive;
  final int barbersCount;
  final List<OpeningHour> openingHours;
  final List<BranchHoliday> holidays;

  String get shortAddress => '$district, $city/$state';

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
        id: Json.asInt(json['id']),
        uuid: Json.asString(json['uuid']),
        name: Json.asString(json['name']),
        slug: Json.asString(json['slug']),
        cnpj: Json.asString(json['cnpj']),
        address: Json.asString(json['address']),
        number: Json.asString(json['number']),
        complement: Json.asString(json['complement']),
        district: Json.asString(json['district']),
        city: Json.asString(json['city']),
        state: Json.asString(json['state']),
        zipCode: Json.asString(json['zip_code']),
        fullAddress: Json.asString(json['full_address']),
        latitude: Json.asDoubleOrNull(json['latitude']),
        longitude: Json.asDoubleOrNull(json['longitude']),
        phone: Json.asString(json['phone']),
        whatsapp: Json.asString(json['whatsapp']),
        email: Json.asString(json['email']),
        coverImageUrl: Json.asStringOrNull(json['cover_image_url']),
        slotIntervalMinutes:
            Json.asInt(json['slot_interval_minutes'], fallback: 30),
        cancellationLimitHours:
            Json.asInt(json['cancellation_limit_hours'], fallback: 2),
        maxAdvanceBookingDays:
            Json.asInt(json['max_advance_booking_days'], fallback: 90),
        loyaltyPointsPerCurrencyUnit: Json.asDouble(
            json['loyalty_points_per_currency_unit'],
            fallback: 1),
        loyaltyPointValue:
            Json.asDouble(json['loyalty_point_value'], fallback: 0.04),
        isActive: Json.asBool(json['is_active'], fallback: true),
        barbersCount: Json.asInt(json['barbers_count']),
        openingHours: Json.asMapList(json['opening_hours'])
            .map(OpeningHour.fromJson)
            .toList(),
        holidays: Json.asMapList(json['holidays'])
            .map(BranchHoliday.fromJson)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'cnpj': cnpj,
        'address': address,
        'number': number,
        'complement': complement,
        'district': district,
        'city': city,
        'state': state,
        'zip_code': zipCode,
        'latitude': latitude,
        'longitude': longitude,
        'phone': phone,
        'whatsapp': whatsapp,
        'email': email,
        'slot_interval_minutes': slotIntervalMinutes,
        'cancellation_limit_hours': cancellationLimitHours,
        'max_advance_booking_days': maxAdvanceBookingDays,
        'loyalty_points_per_currency_unit': loyaltyPointsPerCurrencyUnit,
        'loyalty_point_value': loyaltyPointValue,
        'is_active': isActive,
        'opening_hours': openingHours.map((hour) => hour.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Branch && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
