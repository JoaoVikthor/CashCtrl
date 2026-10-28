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
    String ingredientUnit,
  ) {
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

  static List<String> compatibleUnits(String ingredientUnit) {
    final unit = ingredientUnit.trim().toLowerCase();
    switch (unit) {
      case 'kg':
        return const ['kg', 'g'];
      case 'g':
        return const ['g', 'kg'];
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
