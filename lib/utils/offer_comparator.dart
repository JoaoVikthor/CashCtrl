import 'package:ctrlcash/models/ingredient.dart';
import 'package:ctrlcash/models/ingredient_offer.dart';
import 'package:ctrlcash/utils/product_calculator.dart';

class RankedOffer {
  final IngredientOffer offer;
  final bool isBest;
  final bool isActive;
  final double deltaVsActive;

  const RankedOffer({
    required this.offer,
    required this.isBest,
    required this.isActive,
    required this.deltaVsActive,
  });
}

class TicketLineSaving {
  final String ingredientId;
  final String ingredientName;
  final String supplier;
  final double currentUnitPrice;
  final double bestUnitPrice;
  final double quantity;

  const TicketLineSaving({
    required this.ingredientId,
    required this.ingredientName,
    required this.supplier,
    required this.currentUnitPrice,
    required this.bestUnitPrice,
    required this.quantity,
  });

  double get saving => (currentUnitPrice - bestUnitPrice) * quantity;
}

class TicketScenario {
  final double totalSaving;
  final double simulatedProfit;
  final double salePrice;
  final bool stillLoss;
  final List<TicketLineSaving> lines;

  const TicketScenario({
    required this.totalSaving,
    required this.simulatedProfit,
    required this.salePrice,
    required this.stillLoss,
    required this.lines,
  });
}

class OfferComparator {
  const OfferComparator._();

  static List<RankedOffer> rank(
    List<IngredientOffer> offers, {
    String? activeOfferId,
    bool considerInactive = false,
  }) {
    if (offers.isEmpty) return const [];

    final eligible = considerInactive
        ? offers
        : offers.where((o) => o.isActive).toList();

    final sorted = List<IngredientOffer>.from(eligible)
      ..sort((a, b) => a.pricePerUnit.compareTo(b.pricePerUnit));

    if (sorted.isEmpty) return const [];

    final best = sorted.first;

    IngredientOffer? active;
    if (activeOfferId != null) {
      for (final o in offers) {
        if (o.id == activeOfferId) {
          active = o;
          break;
        }
      }
    }

    return sorted.map((offer) {
      final delta = active != null
          ? offer.pricePerUnit - active.pricePerUnit
          : 0.0;
      return RankedOffer(
        offer: offer,
        isBest: offer.id == best.id,
        isActive: activeOfferId != null && offer.id == activeOfferId,
        deltaVsActive: delta,
      );
    }).toList();
  }

  static List<RankedOffer> rankAll(
    List<IngredientOffer> offers, {
    String? activeOfferId,
  }) =>
      rank(offers, activeOfferId: activeOfferId, considerInactive: true);

  static IngredientOffer? bestOffer(
    List<IngredientOffer> offers, {
    bool activeOnly = true,
  }) {
    final eligible = offers.where((o) {
      if (o.packageQuantity <= 0) return false;
      if (activeOnly && !o.isActive) return false;
      return true;
    }).toList();

    if (eligible.isEmpty) return null;

    eligible.sort((a, b) => a.pricePerUnit.compareTo(b.pricePerUnit));
    return eligible.first;
  }

  static IngredientOffer syntheticLegacyOffer(
    Ingredient ing, {
    String id = 'legacy',
  }) {
    return IngredientOffer(
      id: id,
      supplier: 'Fornecedor padrão',
      packagePrice: ing.purchasePrice,
      packageQuantity: ing.packageQuantity,
      isActive: true,
      source: 'migration',
      notes: 'Preço cadastrado migrado automaticamente',
      createdAt: ing.createdAt,
      updatedAt: ing.createdAt,
    );
  }

  static double pricePerUnitWithFallback(Ingredient ing) {
    final active = ing.activeOffer;
    if (active != null) return active.pricePerUnit;
    return ing.packageQuantity > 0
        ? ing.purchasePrice / ing.packageQuantity
        : 0.0;
  }

  static bool hasDifferentPackageSizes(List<IngredientOffer> offers) {
    if (offers.length < 2) return false;
    final quantities = offers.map((o) => o.packageQuantity).toSet();
    return quantities.length > 1;
  }

  static TicketScenario? bestSupplierScenario(TicketResult ticket) {
    final savings = <TicketLineSaving>[];

    for (final line in ticket.lines) {
      if (line.missing || line.ingredient == null) continue;

      final ing = line.ingredient!;
      final best = bestOffer(ing.offers);
      if (best == null) continue;

      if (best.pricePerUnit < line.unitPrice - 0.005) {
        savings.add(TicketLineSaving(
          ingredientId: ing.id,
          ingredientName: ing.name,
          supplier: best.supplier,
          currentUnitPrice: line.unitPrice,
          bestUnitPrice: best.pricePerUnit,
          quantity: line.item.quantity,
        ));
      }
    }

    if (savings.isEmpty) return null;

    final totalSaving = savings.fold<double>(
      0.0,
      (sum, s) => sum + s.saving,
    );
    final roundedTotal = _round2(totalSaving);

    if (roundedTotal <= 0.01) return null;

    final simulatedProfit = ticket.profit + roundedTotal;

    return TicketScenario(
      totalSaving: roundedTotal,
      simulatedProfit: simulatedProfit,
      salePrice: ticket.salePrice,
      stillLoss: simulatedProfit < 0,
      lines: savings,
    );
  }

  static double deltaUnit(IngredientOffer a, IngredientOffer b) =>
      a.pricePerUnit - b.pricePerUnit;

  static double _round2(double value) {
    return (value * 100).round() / 100;
  }
}
