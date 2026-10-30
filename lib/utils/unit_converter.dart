class UnitConversion {
  final double value;
  final String unit;
  final bool converted;

  const UnitConversion({
    required this.value,
    required this.unit,
    required this.converted,
  });
}

class UnitConverter {
  const UnitConverter._();

  static UnitConversion convertToIngredientUnit(
    double rawValue,
    String inputUnit,
    String ingredientUnit, {
    double? averageUnitWeightGrams,
  }) {
    if (rawValue <= 0) {
      return UnitConversion(value: rawValue, unit: inputUnit, converted: false);
    }

    final input = inputUnit.trim().toLowerCase();
    final target = ingredientUnit.trim().toLowerCase();

    if (input == target) {
      return UnitConversion(value: rawValue, unit: inputUnit, converted: false);
    }

    final massUnits = {'kg', 'g'};
    final volumeUnits = {'l', 'ml'};

    final hasPm = averageUnitWeightGrams != null && averageUnitWeightGrams > 0;

    if (hasPm && (input == 'un' || target == 'un')) {
      if (input == 'un' && target == 'g') {
        return UnitConversion(
          value: rawValue * averageUnitWeightGrams,
          unit: ingredientUnit,
          converted: true,
        );
      }
      if (input == 'un' && target == 'kg') {
        return UnitConversion(
          value: rawValue * averageUnitWeightGrams / 1000,
          unit: ingredientUnit,
          converted: true,
        );
      }
      if (input == 'g' && target == 'un') {
        return UnitConversion(
          value: rawValue / averageUnitWeightGrams,
          unit: ingredientUnit,
          converted: true,
        );
      }
      if (input == 'kg' && target == 'un') {
        return UnitConversion(
          value: rawValue * 1000 / averageUnitWeightGrams,
          unit: ingredientUnit,
          converted: true,
        );
      }
    }

    if (massUnits.contains(input) && massUnits.contains(target)) {
      if (input == 'kg' && target == 'g') {
        return UnitConversion(
          value: rawValue * 1000,
          unit: ingredientUnit,
          converted: true,
        );
      }
      if (input == 'g' && target == 'kg') {
        return UnitConversion(
          value: rawValue / 1000,
          unit: ingredientUnit,
          converted: true,
        );
      }
    }

    if (volumeUnits.contains(input) && volumeUnits.contains(target)) {
      if (input == 'l' && target == 'ml') {
        return UnitConversion(
          value: rawValue * 1000,
          unit: ingredientUnit,
          converted: true,
        );
      }
      if (input == 'ml' && target == 'l') {
        return UnitConversion(
          value: rawValue / 1000,
          unit: ingredientUnit,
          converted: true,
        );
      }
    }

    return UnitConversion(value: rawValue, unit: inputUnit, converted: false);
  }

  static List<String> compatibleUnits(
    String ingredientUnit, {
    bool hasAverageUnitWeight = false,
  }) {
    final unit = ingredientUnit.trim().toLowerCase();
    switch (unit) {
      case 'kg':
        return hasAverageUnitWeight
            ? const ['kg', 'g', 'un']
            : const ['kg', 'g'];
      case 'g':
        return hasAverageUnitWeight
            ? const ['g', 'kg', 'un']
            : const ['g', 'kg'];
      case 'l':
      case 'litro':
        return const ['L', 'ml'];
      case 'ml':
        return const ['ml', 'L'];
      default:
        return [ingredientUnit];
    }
  }
}
