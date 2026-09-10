import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'widgets/auth_scaffold.dart';

/// Tela exibida enquanto a sessão salva é restaurada.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SuaBarbeariaWordmark(inverted: true, large: true),
            SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 26,
              width: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
