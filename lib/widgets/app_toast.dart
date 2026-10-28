import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppToast {
  static void success(BuildContext context, String message) {
    _show(context, message, Icons.check_circle_outline, AppColors.success, const Duration(seconds: 3));
  }

  static void error(BuildContext context, String message) {
    _show(context, message, Icons.error_outline, AppColors.danger, const Duration(seconds: 4));
  }

  static void info(BuildContext context, String message) {
    _show(context, message, Icons.info_outline, AppColors.textSec, const Duration(seconds: 3));
  }

  static void _show(
    BuildContext context,
    String message,
    IconData icon,
    Color color,
    Duration duration,
  ) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.border),
        ),
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.l),
      ),
    );
  }
}
