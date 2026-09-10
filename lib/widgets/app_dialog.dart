import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import 'app_button.dart';

/// Diálogos padronizados do aplicativo.
class AppDialog {
  const AppDialog._();

  /// Confirmação genérica. Retorna `true` quando o usuário confirma.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    bool isDestructive = false,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          icon: icon == null
              ? null
              : Icon(
                  icon,
                  color: isDestructive
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  size: 32,
                ),
          title: Text(title),
          content: Text(message, style: theme.textTheme.bodyMedium),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
            if (isDestructive)
              AppButton.danger(
                label: confirmLabel,
                expanded: false,
                size: AppButtonSize.small,
                onPressed: () => Navigator.of(context).pop(true),
              )
            else
              AppButton(
                label: confirmLabel,
                expanded: false,
                size: AppButtonSize.small,
                onPressed: () => Navigator.of(context).pop(true),
              ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// Diálogo com conteúdo livre (formulários, detalhes...).
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget content,
    List<Widget>? actions,
    double maxWidth = 520,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(child: content),
        ),
        actions: actions,
      ),
    );
  }

  /// Solicita um texto ao usuário (ex.: motivo de cancelamento).
  static Future<String?> prompt(
    BuildContext context, {
    required String title,
    String? message,
    String label = 'Descrição',
    String confirmLabel = 'Confirmar',
    int maxLines = 3,
    bool isRequired = false,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null) ...[
              Text(message, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.md),
            ],
            TextField(
              controller: controller,
              maxLines: maxLines,
              autofocus: true,
              decoration: InputDecoration(labelText: label),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          AppButton(
            label: confirmLabel,
            expanded: false,
            size: AppButtonSize.small,
            onPressed: () {
              final text = controller.text.trim();
              if (isRequired && text.isEmpty) return;
              Navigator.of(context).pop(text);
            },
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}

/// Bottom sheet padronizado (mobile-first).
class AppBottomSheet {
  const AppBottomSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget child,
    bool isScrollControlled = true,
    String? subtitle,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleLarge),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(subtitle,
                                style: theme.textTheme.bodySmall),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
