import 'json_utils.dart';

/// Identidade visual do sistema: a logo exibida em todo o aplicativo.
///
/// Vem de um endpoint **público** porque a tela de login precisa dela antes de
/// existir sessão. Quando [logoUrl] é nulo, o app desenha a marca padrão.
class Branding {
  const Branding({
    this.companyName = 'Sua Barbearia',
    this.logoUrl,
    this.recommendedWidth = 600,
    this.recommendedHeight = 160,
    this.maxFileSizeMb = 2,
    this.updatedAt,
  });

  /// Nome da barbearia, exibido na marca e no título da página.
  final String companyName;

  final String? logoUrl;

  /// Formato sugerido ao proprietário na tela de configurações. Vem do backend
  /// para não duplicar a regra em dois lugares.
  final int recommendedWidth;
  final int recommendedHeight;
  final int maxFileSizeMb;
  final DateTime? updatedAt;

  bool get hasLogo => logoUrl != null && logoUrl!.isNotEmpty;

  /// Texto pronto para orientar o envio, ex.: "600 × 160 px · PNG · até 2 MB".
  String get uploadHint =>
      '$recommendedWidth × $recommendedHeight px · PNG com fundo '
      'transparente · até $maxFileSizeMb MB';

  factory Branding.fromJson(Map<String, dynamic> json) => Branding(
        companyName: Json.asString(
          json['company_name'],
          fallback: 'Sua Barbearia',
        ),
        logoUrl: Json.asStringOrNull(json['logo_url']),
        recommendedWidth: Json.asInt(json['recommended_width'], fallback: 600),
        recommendedHeight:
            Json.asInt(json['recommended_height'], fallback: 160),
        maxFileSizeMb: Json.asInt(json['max_file_size_mb'], fallback: 2),
        updatedAt: Json.asDate(json['updated_at']),
      );
}
