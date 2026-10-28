import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/offer_rules.dart';
import 'alert_banner.dart';

class OfferLimitBanner extends StatelessWidget {
  final int current;

  const OfferLimitBanner({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final remaining = maxOffersPerIngredient - current;
    final atLimit = remaining <= 0;
    final text = atLimit
        ? 'Limite de $maxOffersPerIngredient ofertas atingido'
        : 'Restam $remaining ofertas';

    return AlertBanner(
      message: text,
      icon: Icons.warning_amber_rounded,
      color: AppColors.warning,
      background: AppColors.warning.withValues(alpha: 0.12),
    );
  }
}
