import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ingredient.dart';
import '../models/ingredient_offer.dart';
import '../providers/ingredient_provider.dart';
import '../providers/user_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import '../utils/format.dart';
import '../utils/offer_comparator.dart';
import '../utils/offer_rules.dart';
import '../widgets/active_offer_marker.dart';
import '../widgets/alert_banner.dart';
import '../widgets/app_toast.dart';
import '../widgets/best_price_chip.dart';
import '../widgets/confirm_action_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/offer_card.dart';
import '../widgets/offer_limit_banner.dart';
import '../widgets/search_field.dart';

class IngredientOffersScreen extends StatefulWidget {
  final String ingredientId;

  const IngredientOffersScreen({super.key, required this.ingredientId});

  @override
  State<IngredientOffersScreen> createState() => _IngredientOffersScreenState();
}

class _IngredientOffersScreenState extends State<IngredientOffersScreen> {
  String _query = '';
  int _filterIndex = 0;
  bool _onlyEconomy = false;
  bool _migrationChecked = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IngredientProvider>();
    final ingredient = provider.asMap[widget.ingredientId];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Voltar',
        ),
        title: Text(
          ingredient == null ? 'Ofertas' : 'Ofertas de ${ingredient.name}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined, color: AppColors.gold),
            tooltip: 'Histórico de preços',
            onPressed: () => Navigator.pushNamed(context, '/audit-logs'),
          ),
        ],
      ),
      body: _buildBody(provider, ingredient),
      bottomNavigationBar: ingredient == null
          ? null
          : _buildBottomCTA(ingredient),
    );
  }

  Widget _buildBody(IngredientProvider provider, Ingredient? ingredient) {
    if (provider.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    if (provider.error != null) {
      return ErrorState(
        message: 'Não foi possível carregar as ofertas.',
        onRetry: provider.reload,
      );
    }
    if (ingredient == null) {
      return const ErrorState(message: 'Produto não encontrado.');
    }

    _maybeMigrateLegacy(ingredient);

    final offers = ingredient.offers;
    final ranked = OfferComparator.rankAll(
      offers,
      activeOfferId: ingredient.activeOffer?.id,
    );
    final filtered = _applyFilters(ranked);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
      children: [
        _buildSummaryCard(ingredient),
        if (OfferComparator.hasDifferentPackageSizes(offers)) ...[
          const SizedBox(height: 12),
          const AlertBanner(
            message:
                'Atenção: embalagens de tamanhos diferentes. Compare o preço por unidade.',
            icon: Icons.warning_amber_rounded,
          ),
        ],
        const SizedBox(height: 12),
        const Text(
          'Você escolhe qual oferta entra no ticket. O app não troca sozinho.',
          style: TextStyle(
              color: AppColors.textSec,
              fontSize: AppTypography.secondary),
        ),
        const SizedBox(height: 16),
        AppSearchField(
          hint: 'Buscar fornecedor ou produto…',
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 12),
        _buildFilterRow(),
        const SizedBox(height: 16),
        _buildCounter(ingredient),
        const SizedBox(height: 16),
        if (offers.isEmpty) ...[
          _buildEmptyOrLegacy(ingredient),
        ] else if (filtered.isEmpty) ...[
          _buildNoFilterResult(),
        ] else ...[
          ...filtered.map((r) => _buildOfferCard(ingredient, r)),
        ],
        if (ingredient.offersCount >= maxOffersPerIngredient) ...[
          const SizedBox(height: 16),
          OfferLimitBanner(current: ingredient.offersCount),
        ],
      ],
    );
  }

  void _maybeMigrateLegacy(Ingredient ingredient) {
    if (_migrationChecked) return;
    if (ingredient.offers.isNotEmpty) {
      _migrationChecked = true;
      return;
    }
    if (ingredient.purchasePrice <= 0 || ingredient.packageQuantity <= 0) {
      _migrationChecked = true;
      return;
    }
    _migrationChecked = true;

    final uid = context.read<UserProvider>().uid;
    if (uid == null) return;

    context.read<FirestoreService>().migrateLegacyOffers(uid, ingredient);
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          child: AppFilterChipRow(
            options: const ['Todas', 'Ativas', 'Inativas', 'Padrão'],
            selectedIndex: _filterIndex,
            onSelected: (index) => setState(() => _filterIndex = index),
          ),
        ),
        const SizedBox(width: 8),
        _buildEconomyChip(),
      ],
    );
  }

  Widget _buildSummaryCard(Ingredient ingredient) {
    final active = ingredient.activeOffer;
    final best = ingredient.bestActiveOffer;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ingredient.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppTypography.title,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Preço por unidade de referência: ${formatCurrencyAbs(ingredient.pricePerUnit)}/${ingredient.unit.label}',
            style: const TextStyle(
                color: AppColors.textSec,
                fontSize: AppTypography.secondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (active != null) ...[
                const ActiveOfferMarker(active: true),
                const SizedBox(width: 2),
                Text(
                  active.supplier,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppTypography.secondary),
                ),
              ] else
                Text(
                  'Nenhuma oferta ativa',
                  style: TextStyle(
                      color: AppColors.warning,
                      fontSize: AppTypography.secondary),
                ),
              if (active != null &&
                  best != null &&
                  active.id == best.id) ...[
                const BestPriceChip(label: 'também é a melhor'),
              ] else if (best != null) ...[
                BestPriceChip(label: 'melhor: ${best.supplier}'),
              ],
            ],
          ),
          if (active != null && active.hasProductName) ...[
            const SizedBox(height: 6),
            Text(
              'Produto: ${active.productName}',
              style: const TextStyle(
                  color: AppColors.textSec,
                  fontSize: AppTypography.caption),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEconomyChip() {
    return GestureDetector(
      onTap: () => setState(() => _onlyEconomy = !_onlyEconomy),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _onlyEconomy
              ? AppColors.gold.withValues(alpha: 0.16)
              : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: _onlyEconomy ? AppColors.gold : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              color: _onlyEconomy ? AppColors.gold : AppColors.textSec,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'só com economia',
              style: TextStyle(
                color: _onlyEconomy ? AppColors.gold : AppColors.textSec,
                fontSize: AppTypography.secondary,
                fontWeight:
                    _onlyEconomy ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounter(Ingredient ingredient) {
    final atLimit = ingredient.offersCount >= maxOffersPerIngredient;
    return Row(
      children: [
        Text(
          '${ingredient.offersCount} de $maxOffersPerIngredient ofertas',
          style: const TextStyle(
              color: AppColors.textSec,
              fontSize: AppTypography.secondary),
        ),
        if (atLimit) ...[
          const SizedBox(width: 8),
          Text(
            'Limite de $maxOffersPerIngredient atingido',
            style: TextStyle(
              color: AppColors.warning,
              fontSize: AppTypography.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyOrLegacy(Ingredient ingredient) {
    final hasLegacy = ingredient.purchasePrice > 0 && ingredient.packageQuantity > 0;
    if (!hasLegacy) {
      return EmptyState(
        icon: Icons.storefront_outlined,
        title: 'Nenhuma oferta cadastrada',
        message:
            'Cadastre fornecedores para comparar preços e escolher quem entra no ticket.',
        actionLabel: 'Adicionar oferta',
        onAction: () => Navigator.pushNamed(
          context,
          '/offer-form',
          arguments: {'ingredientId': ingredient.id},
        ),
      );
    }

    final legacy = OfferComparator.syntheticLegacyOffer(ingredient);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Preço base do produto',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: AppTypography.body,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${formatCurrencyAbs(legacy.pricePerUnit)}/${ingredient.unit.label}',
            style: AppTypography.number(
              color: AppColors.gold,
              fontSize: AppTypography.title,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cadastre ofertas para comparar.',
            style: TextStyle(
                color: AppColors.textSec,
                fontSize: AppTypography.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFilterResult() {
    return Column(
      children: [
        const Icon(Icons.search_off, color: AppColors.textSec, size: 48),
        const SizedBox(height: 12),
        Text(
          'Nenhuma oferta corresponde aos filtros.',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() {
            _query = '';
            _filterIndex = 0;
            _onlyEconomy = false;
          }),
          child: const Text(
            'Limpar filtros',
            style: TextStyle(
                color: AppColors.gold, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildOfferCard(Ingredient ingredient, RankedOffer ranked) {
    return OfferCard(
      ranked: ranked,
      totalOffers: ingredient.offersCount,
      onSet: () => _activateOffer(ingredient, ranked.offer),
      onEdit: () => Navigator.pushNamed(
        context,
        '/offer-form',
        arguments: {
          'ingredientId': ingredient.id,
          'offer': ranked.offer,
        },
      ),
      onToggle: () => _toggleOffer(ingredient, ranked.offer),
      onDelete: () => _deleteOffer(ingredient, ranked.offer),
    );
  }

  Widget _buildBottomCTA(Ingredient ingredient) {
    final disabled = ingredient.offersCount >= maxOffersPerIngredient;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: ElevatedButton(
          onPressed: disabled
              ? null
              : () => Navigator.pushNamed(
                    context,
                    '/offer-form',
                    arguments: {'ingredientId': ingredient.id},
                  ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.greenPrimary,
            disabledBackgroundColor:
                AppColors.greenPrimary.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Adicionar oferta',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  List<RankedOffer> _applyFilters(List<RankedOffer> ranked) {
    final query = _query.trim().toLowerCase();
    var list = ranked.where((r) {
      final offer = r.offer;
      switch (_filterIndex) {
        case 1:
          return offer.isActive;
        case 2:
          return !offer.isActive;
        case 3:
          return offer.source == 'migration';
        default:
          return true;
      }
    }).where((r) {
      if (query.isEmpty) return true;
      return r.offer.supplier.toLowerCase().contains(query) ||
          r.offer.productName.toLowerCase().contains(query);
    }).toList();

    if (_onlyEconomy) {
      list = list
          .where((r) => !r.isActive && r.deltaVsActive < -0.005)
          .toList();
    }

    return list;
  }

  Future<void> _activateOffer(Ingredient ingredient, IngredientOffer offer) async {
    final delta = offer.pricePerUnit -
        (ingredient.activeOffer?.pricePerUnit ?? offer.pricePerUnit);
    final label = _offerLabel(offer);
    String body;
    if (delta.abs() < 0.005) {
      body = '$label · ${formatCurrencyAbs(offer.pricePerUnit)}/un';
    } else if (delta < 0) {
      body =
          '$label · ${formatCurrencyAbs(offer.pricePerUnit)}/un\nEconomia de ${formatCurrencyAbs(delta.abs())} por unidade em relação à ativa.';
    } else {
      body =
          '$label · ${formatCurrencyAbs(offer.pricePerUnit)}/un\nFicará ${formatCurrencyAbs(delta)} mais caro por unidade.';
    }

    final provider = context.read<IngredientProvider>();

    final ok = await ConfirmActionDialog.show(
      context,
      title: 'Usar esta oferta no ticket?',
      body: body,
      note:
          'Você pode trocar de volta quando quiser. O app não altera automaticamente.',
    );
    if (!ok) return;

    final previousActiveOfferId = ingredient.activeOffer?.id;

    try {
      await provider.setActiveOffer(ingredient.id, offer.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Oferta de ${offer.supplier} agora é a ativa.'),
          backgroundColor: AppColors.gold,
          action: previousActiveOfferId != null
              ? SnackBarAction(
                  label: 'Desfazer',
                  textColor: Colors.white,
                  onPressed: () => provider.setActiveOffer(
                    ingredient.id,
                    previousActiveOfferId,
                  ),
                )
              : null,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Não foi possível trocar a oferta: $e');
    }
  }

  Future<void> _deleteOffer(Ingredient ingredient, IngredientOffer offer) async {
    final isActive = ingredient.activeOffer?.id == offer.id;
    final label = _offerLabel(offer);
    final body = isActive
        ? '$label · ${formatCurrencyAbs(offer.pricePerUnit)}/un\nEsta é a oferta ATIVA. Ao excluir, o ticket volta ao preço base até você escolher outra oferta.'
        : '$label · ${formatCurrencyAbs(offer.pricePerUnit)}/un';
    final note = isActive
        ? 'A oferta ativa será removida.'
        : 'A exclusão pode ser desfeita logo após confirmar.';

    final provider = context.read<IngredientProvider>();

    final ok = await ConfirmActionDialog.show(
      context,
      title: 'Excluir oferta?',
      body: body,
      note: note,
    );
    if (!ok) return;

    try {
      await provider.deleteOffer(
        ingredient.id,
        offer.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Oferta de ${offer.supplier} excluída.'),
          backgroundColor: AppColors.gold,
          action: SnackBarAction(
            label: 'Desfazer',
            textColor: Colors.white,
            onPressed: () async {
              try {
                final restored = offer.copyWith(updatedAt: DateTime.now());
                await provider.upsertOffer(ingredient.id, restored);
                if (isActive) {
                  await provider.setActiveOffer(ingredient.id, restored.id);
                }
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Oferta de ${offer.supplier} restaurada.'),
                    backgroundColor: AppColors.gold,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                AppToast.error(context, 'Erro ao desfazer: $e');
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Erro ao excluir oferta: $e');
    }
  }

  Future<void> _toggleOffer(Ingredient ingredient, IngredientOffer offer) async {
    final newState = !offer.isActive;
    try {
      await context
          .read<IngredientProvider>()
          .toggleOfferActive(ingredient.id, offer.id, newState);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Erro ao alterar oferta: $e');
    }
  }

  String _offerLabel(IngredientOffer offer) {
    if (!offer.hasProductName) return offer.supplier;
    return '${offer.supplier} · ${offer.productName}';
  }
}
