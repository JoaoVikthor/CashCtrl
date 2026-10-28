import 'package:ctrlcash/utils/unit_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnitConverter.convertToIngredientUnit', () {
    test('converte g para kg', () {
      final result = UnitConverter.convertToIngredientUnit(100, 'g', 'kg');
      expect(result.value, 0.1);
      expect(result.unit, 'kg');
      expect(result.converted, true);
    });

    test('converte kg para g', () {
      final result = UnitConverter.convertToIngredientUnit(2, 'kg', 'g');
      expect(result.value, 2000);
      expect(result.unit, 'g');
      expect(result.converted, true);
    });

    test('converte L para ml', () {
      final result = UnitConverter.convertToIngredientUnit(1.5, 'L', 'ml');
      expect(result.value, 1500);
      expect(result.unit, 'ml');
      expect(result.converted, true);
    });

    test('converte ml para L', () {
      final result = UnitConverter.convertToIngredientUnit(500, 'ml', 'L');
      expect(result.value, 0.5);
      expect(result.unit, 'L');
      expect(result.converted, true);
    });

    test('unidades iguais nao convertem', () {
      final result = UnitConverter.convertToIngredientUnit(5, 'un', 'un');
      expect(result.value, 5);
      expect(result.unit, 'un');
      expect(result.converted, false);
    });

    test('familias incompativeis nao convertem', () {
      final result = UnitConverter.convertToIngredientUnit(10, 'un', 'kg');
      expect(result.value, 10);
      expect(result.unit, 'un');
      expect(result.converted, false);
    });

    test('zero retorna sem conversao', () {
      final result = UnitConverter.convertToIngredientUnit(0, 'g', 'kg');
      expect(result.value, 0);
      expect(result.converted, false);
    });

    test('valor negativo retorna sem conversao', () {
      final result = UnitConverter.convertToIngredientUnit(-100, 'g', 'kg');
      expect(result.value, -100);
      expect(result.converted, false);
    });

    test('comparacao case-insensitive', () {
      final result = UnitConverter.convertToIngredientUnit(1000, 'G', 'Kg');
      expect(result.value, 1);
      expect(result.unit, 'Kg');
      expect(result.converted, true);
    });
  });

  group('UnitConverter.compatibleUnits', () {
    test('kg retorna kg e g', () {
      expect(UnitConverter.compatibleUnits('kg'), ['kg', 'g']);
    });

    test('g retorna g e kg', () {
      expect(UnitConverter.compatibleUnits('g'), ['g', 'kg']);
    });

    test('L retorna L e ml', () {
      expect(UnitConverter.compatibleUnits('L'), ['L', 'ml']);
    });

    test('ml retorna ml e L', () {
      expect(UnitConverter.compatibleUnits('ml'), ['ml', 'L']);
    });

    test('unidade generica retorna apenas ela mesma', () {
      expect(UnitConverter.compatibleUnits('un'), ['un']);
      expect(UnitConverter.compatibleUnits('pct'), ['pct']);
    });

    test('case-insensitive para litro', () {
      expect(UnitConverter.compatibleUnits('litro'), ['L', 'ml']);
      expect(UnitConverter.compatibleUnits('l'), ['L', 'ml']);
    });
  });
}
