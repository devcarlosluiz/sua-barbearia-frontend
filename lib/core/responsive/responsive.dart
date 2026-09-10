import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

enum ScreenSize { mobile, tablet, desktop }

/// Detecção de tamanho de tela e utilidades de layout responsivo.
///
/// O app não "estica" a interface desktop no celular: cada faixa tem a sua
/// própria navegação (sidebar no desktop, bottom bar no mobile).
class Responsive {
  const Responsive._();

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  static ScreenSize of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  static ScreenSize fromWidth(double width) {
    if (width < mobileBreakpoint) return ScreenSize.mobile;
    if (width < tabletBreakpoint) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  static bool isMobile(BuildContext context) =>
      of(context) == ScreenSize.mobile;
  static bool isTablet(BuildContext context) =>
      of(context) == ScreenSize.tablet;
  static bool isDesktop(BuildContext context) =>
      of(context) == ScreenSize.desktop;

  /// `true` quando há espaço para a navegação lateral fixa.
  static bool hasSidebar(BuildContext context) =>
      of(context) != ScreenSize.mobile;

  /// Número de colunas de grade adequado à largura atual.
  static int gridColumns(BuildContext context, {int max = 4}) {
    switch (of(context)) {
      case ScreenSize.mobile:
        return 1;
      case ScreenSize.tablet:
        return max >= 2 ? 2 : max;
      case ScreenSize.desktop:
        return max;
    }
  }

  static EdgeInsets pagePadding(BuildContext context) {
    switch (of(context)) {
      case ScreenSize.mobile:
        return const EdgeInsets.all(AppSpacing.md);
      case ScreenSize.tablet:
        return const EdgeInsets.all(AppSpacing.lg);
      case ScreenSize.desktop:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        );
    }
  }

  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (of(context)) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}

/// Constrói interfaces distintas por faixa de tela.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    switch (Responsive.of(context)) {
      case ScreenSize.mobile:
        return mobile(context);
      case ScreenSize.tablet:
        return (tablet ?? mobile)(context);
      case ScreenSize.desktop:
        return (desktop ?? tablet ?? mobile)(context);
    }
  }
}

/// Limita a largura do conteúdo em telas muito largas.
class ContentContainer extends StatelessWidget {
  const ContentContainer({
    super.key,
    required this.child,
    this.maxWidth = AppSpacing.maxContentWidth,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? Responsive.pagePadding(context),
          child: child,
        ),
      ),
    );
  }
}
