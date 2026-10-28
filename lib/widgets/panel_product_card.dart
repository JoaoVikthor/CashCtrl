import 'package:flutter/material.dart';

import '../models/ingredient.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/format.dart';
import '../utils/price_panel_aggregator.dart';
import 'active_offer_marker.dart';
import 'best_price_chip.dart';
import 'delta_price_text.dart';

class _SupplierMini {
  final String name;
  final double pricePerUnit;

  const _SupplierMini({required this.name, required this.pricePerUnit});
}

class PanelProductCard extends StatelessWidget {
  final ProductPanelEntry entry;
  final VoidCallback onTap;

  const PanelProductCard({
    super.key,
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
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
                Expanded(child: _buildNameBlock()),
                const SizedBox(width: AppSpacing.s),
                _buildPills(),
              ],
            ),
            const SizedBox(height: 10),
            _buildBestBlock(),
            const SizedBox(height: AppSpacing.s),
            _buildTicketLine(),
            const SizedBox(height: AppSpacing.s),
            _buildMiniChips(),
            if (entry.deltaVsBest > 0) ...[
              const SizedBox(height: 9),
              _buildEcoChip(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNameBlock() {
    final ing = entry.ingredient;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ing.name,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppTypography.body,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          _unitLine(),
          style: TextStyle(
            color: AppColors.textSec,
            fontSize: AppTypography.caption,
          ),
        ),
      ],
    );
  }

  String _unitLine() {
    final ing = entry.ingredient;
    final best = entry.bestOffer;
    final base = 'por ${ing.unit.label}';
    if (best == null) return base;
    return '$base · ${_formatQuantity(best.packageQuantity, ing.unit.label)}';
  }

  Widget _buildPills() {
    if (entry.legacyOnly) {
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
          'sem comparação',
          style: TextStyle(
            color: AppColors.textSec,
            fontSize: AppTypography.caption,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final active = entry.activeOffer;
    final best = entry.bestOffer;
    final isActiveBest = active != null && best != null && active.id == best.id;

    return Wrap(
      spacing: 5,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.end,
      children: [
        if (active != null && isActiveBest) const ActiveOfferMarker(),
        if (best != null) const BestPriceChip(),
      ],
    );
  }

  Widget _buildBestBlock() {
    final best = entry.bestOffer;
    if (entry.legacyOnly || best == null) {
      return _buildLegacyBestBlock();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${formatCurrencyAbs(best.pricePerUnit)}/${entry.ingredient.unit.label}',
              style: AppTypography.number(
                color: AppColors.gold,
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: Text(
                '${best.supplier} · ${formatCurrencyAbs(best.packagePrice)} · ${_formatQuantity(best.packageQuantity, entry.ingredient.unit.label)}',
                style: TextStyle(
                  color: AppColors.textSec,
                  fontSize: AppTypography.caption,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (best.hasProductName) ...[
          const SizedBox(height: 2),
          Text(
            'Produto: ${best.productName}',
            style: TextStyle(
              color: AppColors.textSec,
              fontSize: AppTypography.caption,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildLegacyBestBlock() {
    final ppu = entry.bestPricePerUnit ?? 0;
    return Text(
      '${formatCurrencyAbs(ppu)}/${entry.ingredient.unit.label}',
      style: AppTypography.number(
        color: AppColors.gold,
        fontSize: AppTypography.title,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTicketLine() {
    final active = entry.activeOffer;
    final best = entry.bestOffer;

    if (entry.legacyOnly) {
      return const SizedBox.shrink();
    }

    if (active != null && best != null && active.id == best.id) {
      return Row(
        children: [
          const Icon(Icons.star, color: AppColors.gold, size: 12),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'também é a melhor — ',
            style: TextStyle(
              color: AppColors.textSec,
              fontSize: AppTypography.caption,
            ),
          ),
          const DeltaPriceText(delta: 0),
          Text(
            ' sem delta',
            style: TextStyle(
              color: AppColors.textSec,
              fontSize: AppTypography.caption,
            ),
          ),
        ],
      );
    }

    if (active == null) {
      final ing = entry.ingredient;
      return Text(
        'No ticket: preço base · ${formatCurrencyAbs(ing.pricePerUnit)}/${ing.unit.label}',
        style: TextStyle(
          color: AppColors.textSec,
          fontSize: AppTypography.caption,
        ),
      );
    }

    if (best == null) {
      return Text(
        'No ticket: ${active.supplier} · sem comparação',
        style: TextStyle(
          color: AppColors.textSec,
          fontSize: AppTypography.caption,
        ),
      );
    }

    return Semantics(
      label: 'No ticket: ${active.supplier}. paga ${formatCurrencyAbs(entry.deltaVsBest)} por unidade a mais que o melhor preço',
      child: Row(
        children: [
          Text(
            'No ticket: ',
            style: TextStyle(
              color: AppColors.textSec,
              fontSize: AppTypography.caption,
            ),
          ),
          Text(
            active.supplier,
            style: TextStyle(
              color: AppColors.textSec,
              fontSize: AppTypography.caption,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            ' · ',
            style: TextStyle(
              color: AppColors.textSec,
              fontSize: AppTypography.caption,
            ),
          ),
          DeltaPriceText(delta: entry.deltaVsBest),
        ],
      ),
    );
  }

  Widget _buildMiniChips() {
    final others = _otherSuppliers();
    if (others.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.s,
      runSpacing: 6,
      children: others.map(_miniChip).toList(),
    );
  }

  List<_SupplierMini> _otherSuppliers() {
    if (entry.legacyOnly || entry.bestOffer == null) return const [];
    final bestKey = entry.bestOffer!.supplier.trim().toLowerCase();
    final offers = entry.ingredient.offers
        .where((o) => o.isActive && o.packageQuantity > 0 && o.packagePrice > 0)
        .where((o) => o.supplier.trim().toLowerCase() != bestKey)
        .toList();
    offers.sort((a, b) => a.pricePerUnit.compareTo(b.pricePerUnit));
    return offers
        .take(3)
        .map((o) => _SupplierMini(name: o.supplier, pricePerUnit: o.pricePerUnit))
        .toList();
  }

  Widget _miniChip(_SupplierMini s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        '${_abbreviate(s.name)} ${formatCurrencyAbs(s.pricePerUnit)}',
        style: AppTypography.number(
          color: AppColors.textSec,
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEcoChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.trending_down, color: AppColors.success, size: 13),
          const SizedBox(width: 5),
          Text(
            '−${formatCurrencyAbs(entry.deltaVsBest)}/${entry.ingredient.unit.label}',
            style: AppTypography.number(
              color: AppColors.success,
              fontSize: AppTypography.caption,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatQuantity(double qty, String unit) {
    final isInt = qty % 1 == 0;
    final qtyStr = isInt ? qty.toStringAsFixed(0) : qty.toStringAsFixed(2);
    return '$qtyStr $unit';
  }

  String _abbreviate(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      String? first;
      String? last;
      for (final rune in parts.first.runes) {
        if (String.fromCharCode(rune).toUpperCase() != String.fromCharCode(rune).toLowerCase()) {
          first = String.fromCharCode(rune).toUpperCase();
          break;
        }
      }
      for (final rune in parts.last.runes) {
        if (String.fromCharCode(rune).toUpperCase() != String.fromCharCode(rune).toLowerCase()) {
          last = String.fromCharCode(rune).toUpperCase();
          break;
        }
      }
      if (first != null && last != null) return '$first$last';
    }
    return trimmed.substring(0, trimmed.length < 2 ? trimmed.length : 2).toUpperCase();
  }
}
