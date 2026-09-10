import 'json_utils.dart';

class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    this.slug = '',
    this.displayOrder = 0,
    this.isActive = true,
    this.servicesCount = 0,
  });

  final int id;
  final String name;
  final String slug;
  final int displayOrder;
  final bool isActive;
  final int servicesCount;

  factory ServiceCategory.fromJson(Map<String, dynamic> json) =>
      ServiceCategory(
        id: Json.asInt(json['id']),
        name: Json.asString(json['name']),
        slug: Json.asString(json['slug']),
        displayOrder: Json.asInt(json['display_order']),
        isActive: Json.asBool(json['is_active'], fallback: true),
        servicesCount: Json.asInt(json['services_count']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'display_order': displayOrder,
        'is_active': isActive,
      };
}

class Service {
  const Service({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.price,
    this.uuid = '',
    this.description = '',
    this.categoryId,
    this.categoryName,
    this.imageUrl,
    this.displayOrder = 0,
    this.isActive = true,
  });

  final int id;
  final String uuid;
  final String name;
  final String description;
  final int? categoryId;
  final String? categoryName;
  final int durationMinutes;
  final double price;
  final String? imageUrl;
  final int displayOrder;
  final bool isActive;

  factory Service.fromJson(Map<String, dynamic> json) => Service(
        id: Json.asInt(json['id']),
        uuid: Json.asString(json['uuid']),
        name: Json.asString(json['name']),
        description: Json.asString(json['description']),
        categoryId: Json.asIntOrNull(json['category']),
        categoryName: Json.asStringOrNull(json['category_name']),
        durationMinutes: Json.asInt(json['duration_minutes']),
        price: Json.asDouble(json['price']),
        imageUrl: Json.asStringOrNull(json['image_url']),
        displayOrder: Json.asInt(json['display_order']),
        isActive: Json.asBool(json['is_active'], fallback: true),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'category': categoryId,
        'duration_minutes': durationMinutes,
        'price': price.toStringAsFixed(2),
        'display_order': displayOrder,
        'is_active': isActive,
      };

  Service copyWith({
    String? name,
    String? description,
    int? categoryId,
    int? durationMinutes,
    double? price,
    bool? isActive,
  }) =>
      Service(
        id: id,
        uuid: uuid,
        name: name ?? this.name,
        description: description ?? this.description,
        categoryId: categoryId ?? this.categoryId,
        categoryName: categoryName,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        price: price ?? this.price,
        imageUrl: imageUrl,
        displayOrder: displayOrder,
        isActive: isActive ?? this.isActive,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Service && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
