import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferência de tema do usuário, persistida entre sessões.
///
/// Fica em `SharedPreferences` de propósito: é uma preferência de interface,
/// não um segredo. A regra do projeto de nunca usar SharedPreferences vale
/// para os tokens JWT, que continuam exclusivamente em [SecureStorage].
///
/// O padrão é [ThemeMode.system] — respeitar a escolha do sistema é o
/// comportamento menos surpreendente para quem nunca abriu esta opção.
class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController() : super(ThemeMode.system) {
    _restore();
  }

  static const String storageKey = 'sua_barbearia.theme_mode';

  Future<void> _restore() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getString(storageKey);
      if (saved != null) state = modeFromName(saved);
    } catch (error) {
      // Preferência de tema não é crítica: se o armazenamento falhar, o app
      // segue no tema do sistema em vez de quebrar na abertura.
      debugPrint('[Theme] falha ao ler a preferência: $error');
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == state) return;
    state = mode;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(storageKey, mode.name);
    } catch (error) {
      debugPrint('[Theme] falha ao salvar a preferência: $error');
    }
  }

  static ThemeMode modeFromName(String value) => ThemeMode.values.firstWhere(
        (mode) => mode.name == value,
        orElse: () => ThemeMode.system,
      );

  static String labelFor(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Claro',
        ThemeMode.dark => 'Escuro',
        ThemeMode.system => 'Seguir o sistema',
      };

  /// Ícone de cada modo.
  ///
  /// Evita a família `light_mode`/`dark_mode`/`brightness_auto`: esses glifos
  /// saem em branco no build web deste projeto, mesmo estando presentes na
  /// fonte. Os escolhidos aqui foram verificados renderizando.
  static IconData iconFor(ThemeMode mode) => switch (mode) {
        ThemeMode.light => Icons.wb_sunny_rounded,
        ThemeMode.dark => Icons.nightlight_rounded,
        ThemeMode.system => Icons.contrast_rounded,
      };
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController();
});
