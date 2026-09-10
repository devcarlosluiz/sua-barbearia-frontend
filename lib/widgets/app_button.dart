import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

enum AppButtonVariant { primary, outline, text, danger }

enum AppButtonSize { small, medium, large }

/// Botão padrão do app Sua Barbearia, com estado de carregamento embutido.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
  });

  const AppButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.large,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
  }) : variant = AppButtonVariant.outline;

  const AppButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
  }) : variant = AppButtonVariant.text;

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.large,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
  }) : variant = AppButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = onPressed == null || isLoading;
    final child = _buildChild(context);

    final Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = FilledButton(
          onPressed: isDisabled ? null : onPressed,
          style: FilledButton.styleFrom(minimumSize: _minimumSize),
          child: child,
        );
      case AppButtonVariant.outline:
        button = OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(minimumSize: _minimumSize),
          child: child,
        );
      case AppButtonVariant.text:
        button = TextButton(
          onPressed: isDisabled ? null : onPressed,
          child: child,
        );
      case AppButtonVariant.danger:
        button = FilledButton(
          onPressed: isDisabled ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            minimumSize: _minimumSize,
          ),
          child: child,
        );
    }

    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }

  Size get _minimumSize {
    switch (size) {
      case AppButtonSize.small:
        return const Size(0, 40);
      case AppButtonSize.medium:
        return const Size(0, 46);
      case AppButtonSize.large:
        return const Size(0, 52);
    }
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      final color = variant == AppButtonVariant.primary
          ? Theme.of(context).colorScheme.onPrimary
          : Theme.of(context).colorScheme.primary;
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2.2, color: color),
      );
    }

    if (icon == null) return Text(label);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
