import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';
import '../models/barber.dart';
import '../models/client.dart';
import '../models/json_utils.dart';
import '../models/user.dart';

/// Resultado de `GET /auth/me/`: usuário + perfil do papel correspondente.
class CurrentUser {
  const CurrentUser({required this.user, this.client, this.barber});

  final User user;
  final Client? client;
  final Barber? barber;

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    final client = Json.asMap(json['client']);
    final barber = Json.asMap(json['barber']);
    return CurrentUser(
      user: User.fromJson(Json.asMap(json['user'])),
      client: client.isEmpty ? null : Client.fromJson(client),
      barber: barber.isEmpty ? null : Barber.fromJson(barber),
    );
  }
}

class AuthRepository {
  const AuthRepository(this._api, this._storage);

  final ApiClient _api;
  final SecureStorage _storage;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.post(
      '/auth/login/',
      data: {'email': email.trim().toLowerCase(), 'password': password},
    );
    final session = AuthSession.fromJson(Json.asMap(data));
    await _persist(session);
    return session;
  }

  Future<AuthSession> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirm,
    int? preferredBranchId,
    DateTime? birthDate,
  }) async {
    final data = await _api.post(
      '/auth/register/',
      data: {
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.replaceAll(RegExp(r'\D'), ''),
        'password': password,
        'password_confirm': passwordConfirm,
        if (preferredBranchId != null) 'preferred_branch_id': preferredBranchId,
        if (birthDate != null) 'birth_date': Json.dateOnly(birthDate),
      },
    );
    final session = AuthSession.fromJson(Json.asMap(data));
    await _persist(session);
    return session;
  }

  Future<CurrentUser> me() async {
    final data = await _api.get('/auth/me/');
    return CurrentUser.fromJson(Json.asMap(data));
  }

  /// Envia a foto de perfil. Recebe bytes porque na web não há caminho de
  /// arquivo — e o backend valida tamanho, formato e dimensões.
  Future<CurrentUser> uploadAvatar({
    required Uint8List bytes,
    required String filename,
  }) async {
    final form = FormData.fromMap({
      'avatar': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final data = await _api.upload('/auth/me/', form, method: 'PATCH');
    return CurrentUser.fromJson(Json.asMap(data));
  }

  /// Volta para o avatar de iniciais.
  Future<void> removeAvatar() => _api.delete('/auth/me/avatar/');

  Future<CurrentUser> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final data = await _api.patch(
      '/auth/me/',
      data: {
        if (firstName != null) 'first_name': firstName.trim(),
        if (lastName != null) 'last_name': lastName.trim(),
        if (phone != null) 'phone': phone.replaceAll(RegExp(r'\D'), ''),
      },
    );
    return CurrentUser.fromJson(Json.asMap(data));
  }

  Future<void> logout() async {
    final refresh = await _storage.readRefreshToken();
    try {
      if (refresh != null && refresh.isNotEmpty) {
        await _api.post('/auth/logout/', data: {'refresh': refresh});
      }
    } finally {
      // A sessão local é sempre limpa, mesmo se a chamada falhar.
      await _storage.clear();
    }
  }

  Future<void> forgotPassword(String email) =>
      _api.post('/auth/forgot-password/',
          data: {'email': email.trim().toLowerCase()});

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) =>
      _api.post(
        '/auth/reset-password/',
        data: {'token': token, 'new_password': newPassword},
      );

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _api.post(
        '/auth/change-password/',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword
        },
      );

  Future<bool> hasSession() => _storage.hasSession;

  Future<void> _persist(AuthSession session) async {
    await _storage.saveTokens(access: session.access, refresh: session.refresh);
    await _storage.saveRole(session.user.role.value);
  }
}
