import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/format.dart';
import '../utils/offer_comparator.dart';
import '../utils/product_calculator.dart';

class EconomySummaryCard extends StatelessWidget {
  final TicketScenario? scenario;
  final TicketResult ticket;
  final void Function(String ingredientId) onViewOffers;

  const EconomySummaryCard({
    super.key,
    required this.scenario,
    required this.ticket,
    required this.onViewOffers,
  });

  bool get _hasAnyOffers =>
      ticket.lines.any((l) =>
          !l.missing && l.ingredient != null && l.ingredient!.offers.isNotEmpty);

  TicketLineSaving? get _topSaving {
    if (scenario == null || scenario!.lines.isEmpty) return null;
    return scenario!.lines.reduce((a, b) => a.saving > b.saving ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    if (scenario != null && scenario!.totalSaving > 0 && !scenario!.stillLoss) {
      return _buildEconomyCase(context);
    }

    if (scenario != null && scenario!.stillLoss) {
      return _buildStillLossCase(context);
    }

    if (_hasAnyOffers) {
      return _buildStableCase(context);
    }

    return _buildNoDataCase(context);
  }

  Widget _buildEconomyCase(BuildContext context) {
    final top = _topSaving!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_down, color: AppColors.success, size: 18),
              const SizedBox(width: AppSpacing.s),
              Text(
                'Melhor fornecedor possível',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            '−${formatCurrencyAbs(scenario!.totalSaving)} no custo dos ingredientes',
            style: AppTypography.number(
              color: AppColors.success,
              fontSize: AppTypography.hero,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Nada foi alterado no ticket.',
            style: TextStyle(
              color: AppColors.textSec,
              fontSize: AppTypography.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          OutlinedButton(
            onPressed: () => onViewOffers(top.ingredientId),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.success,
              side: const BorderSide(color: AppColors.success),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: Text('Ver ofertas de ${top.ingredientName}'),
          ),
        ],
      ),
    );
  }

  Widget _buildStableCase(BuildContext context) {
    final offerCount = ticket.lines
        .where((l) =>
            !l.missing && l.ingredient != null && l.ingredient!.offers.isNotEmpty)
        .fold<int>(0, (sum, l) => sum + l.ingredient!.offers.length);
    final fewOffers = offerCount <= 1;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 18),
              const SizedBox(width: AppSpacing.s),
              Text(
                'Fornecedores já estáveis',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            fewOffers
                ? 'As ofertas ativas deste produto já são as melhores entre as cadastradas. Poucas ofertas cadastradas — cadastre mais para comparar.'
                : 'As ofertas ativas deste produto já são as melhores entre as cadastradas.',
            style: TextStyle(
              color: AppColors.textSec,
              fontSize: AppTypography.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStillLossCase(BuildContext context) {
    final top = _topSaving;
    final profit = scenario!.simulatedProfit;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: AppColors.danger, size: 18),
              const SizedBox(width: AppSpacing.s),
              Text(
                'Ainda dá prejuízo com o melhor preço',
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            '−${formatCurrencyAbs(profit)} ainda de prejuízo',
            style: AppTypography.number(
              color: AppColors.danger,
              fontSize: AppTypography.title,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Mesmo usando o melhor fornecedor de cada produto, o ticket ainda fica no vermelho. Considere revisar o preço de venda ou os custos fixos.',
            style: TextStyle(
              color: AppColors.textSec,
              fontSize: AppTypography.secondary,
            ),
          ),
          if (top != null) ...[
            const SizedBox(height: AppSpacing.m),
            OutlinedButton(
              onPressed: () => onViewOffers(top.ingredientId),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: const Text('Ver ofertas'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoDataCase(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_outlined, color: AppColors.gold, size: 18),
              const SizedBox(width: AppSpacing.s),
              Text(
                'Sem dados de fornecedores',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Cadastre ofertas nos produtos para descobrir se há economia possível.',
            style: TextStyle(
              color: AppColors.textSec,
              fontSize: AppTypography.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          OutlinedButton(
            onPressed: () => onViewOffers(''),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gold,
              side: const BorderSide(color: AppColors.gold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: const Text('Gerenciar produtos'),
          ),
        ],
      ),
    );
  }
}
