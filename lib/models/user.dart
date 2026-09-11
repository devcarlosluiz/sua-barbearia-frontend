import 'json_utils.dart';

/// Papéis do sistema. Espelham `accounts.UserRole` no backend.
enum UserRole {
  owner('OWNER', 'Proprietário'),
  barber('BARBER', 'Barbeiro'),
  client('CLIENT', 'Cliente'),
  unknown('UNKNOWN', 'Desconhecido');

  const UserRole(this.value, this.label);

  final String value;
  final String label;

  static UserRole fromValue(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.unknown,
    );
  }

  bool get isOwner => this == UserRole.owner;
  bool get isBarber => this == UserRole.barber;
  bool get isClient => this == UserRole.client;
}

class User {
  const User({
    required this.id,
    required this.uuid,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    this.avatarUrl,
    this.isActive = true,
    this.isVerified = false,
  });

  final int id;
  final String uuid;
  final String name;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final UserRole role;
  final String? avatarUrl;
  final bool isActive;
  final bool isVerified;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: Json.asInt(json['id']),
      uuid: Json.asString(json['uuid']),
      name: Json.asString(json['name']),
      firstName: Json.asString(json['first_name']),
      lastName: Json.asString(json['last_name']),
      email: Json.asString(json['email']),
      phone: Json.asString(json['phone']),
      role: UserRole.fromValue(json['role'] as String?),
      avatarUrl: Json.asStringOrNull(json['avatar_url']),
      isActive: Json.asBool(json['is_active'], fallback: true),
      isVerified: Json.asBool(json['is_verified']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'uuid': uuid,
        'name': name,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'role': role.value,
        'avatar_url': avatarUrl,
        'is_active': isActive,
        'is_verified': isVerified,
      };

  User copyWith({
    String? name,
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
  }) {
    return User(
      id: id,
      uuid: uuid,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive,
      isVerified: isVerified,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is User && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Resposta do login/registro: tokens + usuário.
class AuthSession {
  const AuthSession({
    required this.access,
    required this.refresh,
    required this.user,
    this.isNewAccount = false,
  });

  final String access;
  final String refresh;
  final User user;

  /// `true` quando a conta acabou de ser criada. Só o login com o Google
  /// devolve isso — é o mesmo endpoint para entrar e para se cadastrar, e a
  /// mensagem de boas-vindas depende de saber qual dos dois aconteceu.
  final bool isNewAccount;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      access: Json.asString(json['access']),
      refresh: Json.asString(json['refresh']),
      user: User.fromJson(Json.asMap(json['user'])),
      isNewAccount: Json.asBool(json['created']),
    );
  }
}
