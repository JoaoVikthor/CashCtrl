import 'package:ctrlcash/utils/sebrae_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SebraeRules.grossQuantity', () {
    test('aplica fator de correcao maior que 1', () {
      expect(SebraeRules.grossQuantity(60, 1.5), 90);
    });

    test('fator igual a 1 nao altera quantidade', () {
      expect(SebraeRules.grossQuantity(60, 1.0), 60);
    });

    test('fator invalido menor que 1 eh clampado para 1', () {
      expect(SebraeRules.grossQuantity(60, 0.5), 60);
    });
  });

  group('SebraeRules.correctionFactorApplies', () {
    test('aplica para massa e contagem', () {
      expect(SebraeRules.correctionFactorApplies('g'), true);
      expect(SebraeRules.correctionFactorApplies('kg'), true);
      expect(SebraeRules.correctionFactorApplies('un'), true);
      expect(SebraeRules.correctionFactorApplies('pct'), true);
    });

    test('nao aplica para volume', () {
      expect(SebraeRules.correctionFactorApplies('ml'), false);
      expect(SebraeRules.correctionFactorApplies('L'), false);
    });

    test('case-insensitive', () {
      expect(SebraeRules.correctionFactorApplies('KG'), true);
      expect(SebraeRules.correctionFactorApplies('Ml'), false);
    });
  });

  group('SebraeRules.effectiveQuantity', () {
    test('tomate: 0.5 un, base g, pm 120, FC 1.0 = 60 g', () {
      final result = SebraeRules.effectiveQuantity(
        raw: 0.5,
        inputUnit: 'un',
        baseUnit: 'g',
        averageUnitWeightGrams: 120,
        correctionFactor: 1.0,
      );
      expect(result, 60);
    });

    test('tomate: 0.5 un, base g, pm 120, FC 1.5 = 90 g', () {
      final result = SebraeRules.effectiveQuantity(
        raw: 0.5,
        inputUnit: 'un',
        baseUnit: 'g',
        averageUnitWeightGrams: 120,
        correctionFactor: 1.5,
      );
      expect(result, 90);
    });

    test('tomate: 0.5 un, base kg, pm 120, FC 1.0 = 0.06 kg', () {
      final result = SebraeRules.effectiveQuantity(
        raw: 0.5,
        inputUnit: 'un',
        baseUnit: 'kg',
        averageUnitWeightGrams: 120,
        correctionFactor: 1.0,
      );
      expect(result, 0.06);
    });

    test('volume: ml ignora fator de correcao', () {
      final result = SebraeRules.effectiveQuantity(
        raw: 200,
        inputUnit: 'ml',
        baseUnit: 'ml',
        averageUnitWeightGrams: null,
        correctionFactor: 1.4,
      );
      expect(result, 200);
    });

    test('fator de correcao 0.5 eh clampado para 1.0', () {
      final result = SebraeRules.effectiveQuantity(
        raw: 0.5,
        inputUnit: 'un',
        baseUnit: 'g',
        averageUnitWeightGrams: 120,
        correctionFactor: 0.5,
      );
      expect(result, 60);
    });

    test('entrada un sem peso medio retem valor cru', () {
      final result = SebraeRules.effectiveQuantity(
        raw: 0.5,
        inputUnit: 'un',
        baseUnit: 'g',
        averageUnitWeightGrams: null,
        correctionFactor: 1.5,
      );
      expect(result, 0.5);
    });
  });
}
