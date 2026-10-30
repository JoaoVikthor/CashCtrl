import '../models/ingredient.dart';
import '../models/product.dart';
import 'sebrae_rules.dart';
import 'unit_converter.dart';

/// Resultado do calculo do ticket de um produto.
class TicketResult {
  final Product product;
  final List<LineCost> lines;
  final double ingredientsTotal;
  final double laborCost;
  final double packagingCost;
  final double totalCost;
  final double salePrice;
  final double profit;
  final double marginPercent;
  final bool hasMissingIngredients;

  const TicketResult({
    required this.product,
    required this.lines,
    required this.ingredientsTotal,
    required this.laborCost,
    required this.packagingCost,
    required this.totalCost,
    required this.salePrice,
    required this.profit,
    required this.marginPercent,
    required this.hasMissingIngredients,
  });

  bool get isLucro => profit >= 0;
  bool get isPrejuizo => profit < 0;

  /// Markup sobre o custo (ex.: 1.5x = 50% de markup).
  double get markup => totalCost > 0 ? salePrice / totalCost : 0;
}

/// Custo de uma linha (um produto) da ficha tecnica.
class LineCost {
  final RecipeItem item;
  final Ingredient? ingredient;
  final double unitPrice;
  final double lineCost;
  final bool missing;
  final bool inconvertible;

  const LineCost({
    required this.item,
    required this.ingredient,
    required this.unitPrice,
    required this.lineCost,
    required this.missing,
    this.inconvertible = false,
  });
}

/// Calculadora pura do ticket de um produto.
///
/// Recebe o produto e o mapa de produtos disponiveis (id -> Ingredient)
/// e devolve o detalhamento: custo por ingrediente, custo total, lucro
/// ou prejuizo e margem. Sem misturar com Widgets (RN do agente logic).
class ProductCalculator {
  const ProductCalculator._();

  static TicketResult calculate(
      Product product, Map<String, Ingredient> ingredients) {
    final lines = <LineCost>[];
    double ingredientsTotal = 0;
    bool hasMissing = false;

    for (final item in product.recipe) {
      final ing = ingredients[item.ingredientId];
      if (ing == null) {
        hasMissing = true;
        lines.add(LineCost(
          item: item,
          ingredient: null,
          unitPrice: 0,
          lineCost: 0,
          missing: true,
        ));
        continue;
      }
      final unitPrice = ing.pricePerUnit;
      final inputUnit = item.inputUnit ?? ing.unit.label;
      final conversion = UnitConverter.convertToIngredientUnit(
        item.quantity,
        inputUnit,
        ing.unit.label,
        averageUnitWeightGrams: ing.averageUnitWeightGrams,
      );
      final inconvertible = !conversion.converted &&
          inputUnit.trim().toLowerCase() !=
              ing.unit.label.trim().toLowerCase();
      final effQty = SebraeRules.effectiveQuantity(
        raw: item.quantity,
        inputUnit: inputUnit,
        baseUnit: ing.unit.label,
        averageUnitWeightGrams: ing.averageUnitWeightGrams,
        correctionFactor: ing.correctionFactor,
      );
      final lineCost = inconvertible ? 0.0 : effQty * unitPrice;
      if (!inconvertible) {
        ingredientsTotal += lineCost;
      }
      lines.add(LineCost(
        item: item,
        ingredient: ing,
        unitPrice: unitPrice,
        lineCost: lineCost,
        missing: false,
        inconvertible: inconvertible,
      ));
    }

    final totalCost =
        ingredientsTotal + product.laborCost + product.packagingCost;
    final profit = product.salePrice - totalCost;
    final margin = product.salePrice > 0
        ? (profit / product.salePrice) * 100
        : 0.0;

    return TicketResult(
      product: product,
      lines: lines,
      ingredientsTotal: ingredientsTotal,
      laborCost: product.laborCost,
      packagingCost: product.packagingCost,
      totalCost: totalCost,
      salePrice: product.salePrice,
      profit: profit,
      marginPercent: margin,
      hasMissingIngredients: hasMissing,
    );
  }
}