import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/branding.dart';
import '../models/json_utils.dart';

/// Logo do sistema.
///
/// A leitura é pública (a tela de login usa antes do login); enviar e remover
/// exigem o papel OWNER, verificado no backend.
class BrandingRepository {
  const BrandingRepository(this._api);

  final ApiClient _api;

  Future<Branding> branding() async {
    final data = await _api.get('/branding/');
    return Branding.fromJson(Json.asMap(data));
  }

  /// Envia a logo. Recebe os bytes porque na web não existe caminho de arquivo.
  Future<Branding> uploadLogo({
    required Uint8List bytes,
    required String filename,
  }) async {
    final form = FormData.fromMap({
      'logo': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final data = await _api.upload('/branding/', form, method: 'PUT');
    return Branding.fromJson(Json.asMap(data));
  }

  /// Altera o nome da barbearia.
  Future<Branding> updateName(String companyName) async {
    final data = await _api.patch(
      '/branding/',
      data: {'company_name': companyName},
    );
    return Branding.fromJson(Json.asMap(data));
  }

  /// Volta para a logo padrão.
  Future<Branding> removeLogo() async {
    final data = await _api.delete('/branding/');
    return Branding.fromJson(Json.asMap(data));
  }
}
