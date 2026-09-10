import 'package:sua_barbearia/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cria o container e aguarda a leitura assíncrona da preferência salva.
Future<ProviderContainer> buildContainer() async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(themeModeProvider);
  await Future<void>.delayed(Duration.zero);
  return container;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('padrão', () {
    test('sem preferência salva segue o sistema', () async {
      final container = await buildContainer();
      expect(container.read(themeModeProvider), ThemeMode.system);
    });
  });

  group('persistência', () {
    test('a escolha é gravada', () async {
      final container = await buildContainer();
      await container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(ThemeModeController.storageKey),
        ThemeMode.dark.name,
      );
    });

    test('a escolha sobrevive ao reinício do app', () async {
      SharedPreferences.setMockInitialValues({
        ThemeModeController.storageKey: ThemeMode.dark.name,
      });

      final container = await buildContainer();
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('voltar para o sistema também é persistido', () async {
      final container = await buildContainer();
      final controller = container.read(themeModeProvider.notifier);

      await controller.setMode(ThemeMode.light);
      await controller.setMode(ThemeMode.system);

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(ThemeModeController.storageKey),
        ThemeMode.system.name,
      );
      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('valor salvo inválido não quebra a abertura', () async {
      // Uma versão antiga (ou um valor adulterado) não pode travar o app.
      SharedPreferences.setMockInitialValues({
        ThemeModeController.storageKey: 'sepia',
      });

      final container = await buildContainer();
      expect(container.read(themeModeProvider), ThemeMode.system);
    });
  });

  group('troca de modo', () {
    test('alterna entre claro e escuro', () async {
      final container = await buildContainer();
      final controller = container.read(themeModeProvider.notifier);

      await controller.setMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);

      await controller.setMode(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);
    });

    test('escolher o modo atual não muda nada', () async {
      final container = await buildContainer();
      final controller = container.read(themeModeProvider.notifier);
      await controller.setMode(ThemeMode.light);

      var mudancas = 0;
      container.listen(themeModeProvider, (_, __) => mudancas++);
      await controller.setMode(ThemeMode.light);

      expect(mudancas, 0);
    });
  });

  group('rótulos e ícones', () {
    test('cobrem os três modos', () {
      expect(ThemeModeController.labelFor(ThemeMode.light), 'Claro');
      expect(ThemeModeController.labelFor(ThemeMode.dark), 'Escuro');
      expect(
        ThemeModeController.labelFor(ThemeMode.system),
        'Seguir o sistema',
      );

      final icones = ThemeMode.values.map(ThemeModeController.iconFor).toSet();
      expect(icones, hasLength(3), reason: 'cada modo tem o seu ícone');
    });

    test('modeFromName aceita os nomes válidos', () {
      for (final mode in ThemeMode.values) {
        expect(ThemeModeController.modeFromName(mode.name), mode);
      }
    });
  });
}
