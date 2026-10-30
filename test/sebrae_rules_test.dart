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

  group('SebraeRules.factorFromWastePercent', () {
    test('3% retorna fator Sebrae ~1,030927', () {
      expect(SebraeRules.factorFromWastePercent(3), closeTo(1.030927, 1e-6));
    });

    test('0% retorna fator 1,0', () {
      expect(SebraeRules.factorFromWastePercent(0), 1.0);
    });

    test('20% retorna fator 1,25', () {
      expect(SebraeRules.factorFromWastePercent(20), 1.25);
    });

    test('negativo eh tratado como 0%', () {
      expect(SebraeRules.factorFromWastePercent(-5), 1.0);
    });

    test('100% eh clampado para fator de 99%', () {
      expect(SebraeRules.factorFromWastePercent(100), 100.0);
    });

    test('acima de 100% eh clampado para fator de 99%', () {
      expect(SebraeRules.factorFromWastePercent(150), 100.0);
    });

    test('nunca retorna valor menor que 1', () {
      expect(SebraeRules.factorFromWastePercent(0), greaterThanOrEqualTo(1.0));
      expect(SebraeRules.factorFromWastePercent(50), greaterThanOrEqualTo(1.0));
      expect(
          SebraeRules.factorFromWastePercent(100), greaterThanOrEqualTo(1.0));
    });
  });

  group('SebraeRules.wastePercentFromFactor', () {
    test('fator 1,0 retorna 0%', () {
      expect(SebraeRules.wastePercentFromFactor(1.0), 0.0);
    });

    test('fator invalido menor ou igual a 1 retorna 0%', () {
      expect(SebraeRules.wastePercentFromFactor(0.5), 0.0);
    });

    test('round-trip: percentual de entrada igual ao percentual recuperado', () {
      for (final p in [0, 3, 7, 20, 50, 99]) {
        final factor = SebraeRules.factorFromWastePercent(p.toDouble());
        final recovered = SebraeRules.wastePercentFromFactor(factor);
        expect(recovered, closeTo(p.toDouble(), 1e-9));
      }
    });
  });
}
