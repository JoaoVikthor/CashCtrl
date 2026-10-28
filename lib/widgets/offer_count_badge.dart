import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class OfferCountBadge extends StatelessWidget {
  final int count;

  const OfferCountBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final text = count == 0
        ? 'sem ofertas'
        : count == 1
            ? '1 oferta'
            : '$count ofertas';
    final bg = count == 0
        ? AppColors.textPrimary.withValues(alpha: 0.08)
        : AppColors.greenPrimary.withValues(alpha: 0.2);
    final textColor = count == 0 ? AppColors.textSec : AppColors.gold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
