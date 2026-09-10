import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';

/// Avatar circular com fallback para as iniciais do nome.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 44,
    this.backgroundColor,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background =
        backgroundColor ?? AppColors.gold.withValues(alpha: 0.18);

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          height: size,
          width: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _initials(theme, background),
          errorWidget: (_, __, ___) => _initials(theme, background),
        ),
      );
    }
    return _initials(theme, background);
  }

  Widget _initials(ThemeData theme, Color background) {
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        Formatters.initials(name),
        style: theme.textTheme.titleSmall?.copyWith(
          fontSize: size * 0.36,
          color: theme.brightness == Brightness.dark
              ? AppColors.goldLight
              : AppColors.goldDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
