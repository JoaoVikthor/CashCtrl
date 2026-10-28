import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/format.dart';
import '../utils/offer_comparator.dart';
import 'active_offer_marker.dart';
import 'best_price_chip.dart';
import 'delta_price_text.dart';

class OfferCard extends StatelessWidget {
  final RankedOffer ranked;
  final int totalOffers;
  final VoidCallback onSet;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;

  const OfferCard({
    super.key,
    required this.ranked,
    required this.totalOffers,
    required this.onSet,
    required this.onEdit,
    required this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final offer = ranked.offer;
    final enabled = offer.isActive;

    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.m),
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.supplier,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: AppTypography.body,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (offer.hasProductName) ...[
                        Text(
                          'Produto: ${offer.productName}',
                          style: TextStyle(
                            color: AppColors.textSec,
                            fontSize: AppTypography.caption,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        '${formatCurrencyAbs(offer.packagePrice)} · ${offer.packageQuantity.toStringAsFixed(offer.packageQuantity % 1 == 0 ? 0 : 2)}',
                        style: AppTypography.number(
                          color: AppColors.textSec,
                          fontSize: AppTypography.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (ranked.isActive) ...[
                  const ActiveOfferMarker(active: true),
                  if (ranked.isBest) ...[
                    const SizedBox(width: 6),
                    const BestPriceChip(label: 'também é a melhor'),
                  ],
                ] else if (ranked.isBest)
                  const BestPriceChip(),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            Row(
              children: [
                Text(
                  formatCurrencyAbs(offer.pricePerUnit),
                  style: AppTypography.number(
                    color: AppColors.gold,
                    fontSize: AppTypography.title,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '/un',
                  style: TextStyle(
                    color: AppColors.textSec,
                    fontSize: AppTypography.secondary,
                  ),
                ),
                const Spacer(),
                if (ranked.isActive)
                  const SizedBox.shrink()
                else if (ranked.deltaVsActive.abs() < 0.005)
                  Text(
                    'sem referência',
                    style: TextStyle(
                      color: AppColors.textSec,
                      fontSize: AppTypography.caption,
                    ),
                  )
                else
                  DeltaPriceText(delta: ranked.deltaVsActive),
              ],
            ),
            Divider(
              color: AppColors.textPrimary.withValues(alpha: 0.14),
              height: AppSpacing.xxl,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (ranked.isActive)
                  Tooltip(
                    message: 'Oferta ativa',
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.check_circle,
                        color: AppColors.greenPrimary,
                        size: 22,
                      ),
                    ),
                  )
                else
                  _action(
                    Icons.check_circle_outline,
                    'Usar no ticket',
                    onSet,
                  ),
                const SizedBox(width: AppSpacing.s),
                _action(Icons.edit_outlined, 'Editar', onEdit),
                const SizedBox(width: AppSpacing.s),
                _action(
                  enabled
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  enabled ? 'Desativar' : 'Ativar',
                  onToggle,
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: AppSpacing.s),
                  _action(
                    Icons.delete_outline,
                    'Excluir',
                    onDelete!,
                    color: AppColors.textSec,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: color ?? AppColors.gold,
            size: 22,
          ),
        ),
      ),
    );
  }
}
