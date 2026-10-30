import 'dart:math';

import 'package:ctrlcash/utils/unit_converter.dart';

class SebraeRules {
  const SebraeRules._();

  static double factorFromWastePercent(double percent) {
    if (percent <= 0) return 1.0;
    if (percent >= 100) return 100.0;
    return 100 / (100 - percent);
  }

  static double wastePercentFromFactor(double factor) {
    if (factor <= 1.0) return 0.0;
    return 100 * (factor - 1) / factor;
  }

  static double grossQuantity(double quantity, double correctionFactor) {
    return quantity * max(1.0, correctionFactor);
  }

  static bool correctionFactorApplies(String baseUnit) {
    final unit = baseUnit.trim().toLowerCase();
    return {'g', 'kg', 'un', 'pct'}.contains(unit);
  }

  static double effectiveQuantity({
    required double raw,
    required String inputUnit,
    required String baseUnit,
    required double? averageUnitWeightGrams,
    required double correctionFactor,
  }) {
    final converted = UnitConverter.convertToIngredientUnit(
      raw,
      inputUnit,
      baseUnit,
      averageUnitWeightGrams: averageUnitWeightGrams,
    );

    if (!converted.converted && inputUnit.trim().toLowerCase() != baseUnit.trim().toLowerCase()) {
      return converted.value;
    }

    if (correctionFactorApplies(baseUnit)) {
      return grossQuantity(converted.value, correctionFactor);
    }

    return converted.value;
  }
}
