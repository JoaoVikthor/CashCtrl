import 'package:flutter/material.dart';

import '../models/ingredient.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/format.dart';
import '../utils/price_panel_aggregator.dart';
import 'delta_price_text.dart';

class SupplierSummaryCard extends StatefulWidget {
  final SupplierPanelEntry entry;
  final void Function(String ingredientId) onIngredientTap;

  const SupplierSummaryCard({
    super.key,
    required this.entry,
    required this.onIngredientTap,
  });

  @override
  State<SupplierSummaryCard> createState() => _SupplierSummaryCardState();
}

class _SupplierSummaryCardState extends State<SupplierSummaryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppTypography.title,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Fornece ${entry.productsCount} produtos · ★ melhor em ${entry.bestCount}',
                  style: TextStyle(
                    color: AppColors.textSec,
                    fontSize: AppTypography.caption,
                  ),
                ),
                const SizedBox(height: 10),
                _buildBestPills(),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: AppSpacing.m),
            Divider(
              color: AppColors.textPrimary.withValues(alpha: 0.07),
              height: 1,
            ),
            const SizedBox(height: AppSpacing.m),
            ...widget.entry.rows.map(_buildRow),
          ],
        ],
      ),
    );
  }

  Widget _buildBestPills() {
    final bestRows = widget.entry.rows.where((r) => r.isBest).toList();
    if (bestRows.isEmpty) return const SizedBox.shrink();
    final shown = bestRows.take(3).toList();
    final remaining = bestRows.length - shown.length;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...shown.map((r) => _bestPill(r.entry.ingredient.name)),
        if (remaining > 0) _countPill('+$remaining'),
      ],
    );
  }

  Widget _bestPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.gold, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: AppColors.gold, size: 12),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              color: AppColors.gold,
              fontSize: AppTypography.caption,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _countPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.14),
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textSec,
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRow(SupplierPanelRow row) {
    final ing = row.entry.ingredient;
    final color = _deltaColor(row.deltaVsBest);
    final label = row.isBest
        ? '★ melhor preço · ${row.position}º de ${row.ofTotal}'
        : '${row.position}º de ${row.ofTotal}';
    return GestureDetector(
      onTap: () => widget.onIngredientTap(ing.id),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m + 2,
          vertical: AppSpacing.m,
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ing.name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppTypography.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: AppTypography.caption,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${formatCurrencyAbs(row.pricePerUnit)}/${ing.unit.label}',
                  style: AppTypography.number(
                    color: AppColors.gold,
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Semantics(
                  label: 'paga ${formatCurrencyAbs(row.deltaVsBest)} por unidade a mais que o melhor preço',
                  child: DeltaPriceText(delta: row.deltaVsBest),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _deltaColor(double delta) {
    if (delta <= 0) return AppColors.success;
    if (delta < 1) return AppColors.warning;
    return AppColors.danger;
  }
}
