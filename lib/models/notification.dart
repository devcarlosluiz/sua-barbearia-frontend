import 'json_utils.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.uuid = '',
    this.typeLabel = '',
    this.data = const {},
    this.appointmentId,
    this.isRead = false,
    this.readAt,
    this.createdAt,
  });

  final int id;
  final String uuid;
  final String type;
  final String typeLabel;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final int? appointmentId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: Json.asInt(json['id']),
        uuid: Json.asString(json['uuid']),
        type: Json.asString(json['type']),
        typeLabel: Json.asString(json['type_display']),
        title: Json.asString(json['title']),
        body: Json.asString(json['body']),
        data: Json.asMap(json['data']),
        appointmentId: Json.asIntOrNull(json['appointment']),
        isRead: Json.asBool(json['is_read']),
        readAt: Json.asDate(json['read_at']),
        createdAt: Json.asDate(json['created_at']),
      );
}
