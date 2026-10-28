import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AlertBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;
  final Color? background;

  const AlertBanner({
    super.key,
    required this.message,
    this.icon = Icons.warning_amber_rounded,
    this.color,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppColors.warning;
    final bgColor = background ?? AppColors.warning.withValues(alpha: 0.12);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
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
    );
  }
}
