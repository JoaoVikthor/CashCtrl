import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class ActiveOfferMarker extends StatelessWidget {
  final bool active;

  const ActiveOfferMarker({super.key, this.active = true});

  @override
  Widget build(BuildContext context) {
    if (active) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: AppColors.greenPrimary,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          'ATIVA',
          style: TextStyle(
            color: Colors.white,
            fontSize: AppTypography.caption,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'INATIVA',
        style: TextStyle(
          color: AppColors.textSec,
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
