import 'json_utils.dart';

class Review {
  const Review({
    required this.id,
    required this.appointmentId,
    required this.rating,
    this.uuid = '',
    this.clientName = '',
    this.barberName = '',
    this.branchName = '',
    this.serviceName = '',
    this.appointmentDate,
    this.comment = '',
    this.reply = '',
    this.repliedAt,
    this.isPublished = true,
    this.createdAt,
  });

  final int id;
  final String uuid;
  final int appointmentId;
  final String clientName;
  final String barberName;
  final String branchName;
  final String serviceName;
  final DateTime? appointmentDate;
  final int rating;
  final String comment;
  final String reply;
  final DateTime? repliedAt;
  final bool isPublished;
  final DateTime? createdAt;

  bool get hasReply => reply.isNotEmpty;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: Json.asInt(json['id']),
        uuid: Json.asString(json['uuid']),
        appointmentId: Json.asInt(json['appointment']),
        clientName: Json.asString(json['client_name']),
        barberName: Json.asString(json['barber_name']),
        branchName: Json.asString(json['branch_name']),
        serviceName: Json.asString(json['service_name']),
        appointmentDate: Json.asDate(json['appointment_date']),
        rating: Json.asInt(json['rating']),
        comment: Json.asString(json['comment']),
        reply: Json.asString(json['reply']),
        repliedAt: Json.asDate(json['replied_at']),
        isPublished: Json.asBool(json['is_published'], fallback: true),
        createdAt: Json.asDate(json['created_at']),
      );
}

class ReviewSummary {
  const ReviewSummary({
    required this.average,
    required this.total,
    this.distribution = const {},
  });

  final double average;
  final int total;

  /// Nota (1..5) -> quantidade.
  final Map<int, int> distribution;

  int countFor(int rating) => distribution[rating] ?? 0;

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    final distribution = <int, int>{};
    for (final item in Json.asMapList(json['distribution'])) {
      distribution[Json.asInt(item['rating'])] = Json.asInt(item['count']);
    }
    return ReviewSummary(
      average: Json.asDouble(json['average']),
      total: Json.asInt(json['total']),
      distribution: distribution,
    );
  }
}
