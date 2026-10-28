import 'package:ctrlcash/utils/recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeDueOccurrences', () {
    test('semanal simples', () {
      final start = DateTime(2024, 1, 1);
      final now = DateTime(2024, 1, 22);
      final result = computeDueOccurrences(
        startDate: start,
        frequency: 'semanal',
        now: now,
      );
      expect(result, [
        DateTime(2024, 1, 8),
        DateTime(2024, 1, 15),
        DateTime(2024, 1, 22),
      ]);
    });

    test('mensal dia 31 em fevereiro faz clamp para ultimo dia', () {
      final start = DateTime(2023, 12, 31);
      final now = DateTime(2024, 3, 1);
      final result = computeDueOccurrences(
        startDate: start,
        frequency: 'mensal',
        now: now,
      );
      expect(result, [
        DateTime(2024, 1, 31),
        DateTime(2024, 2, 29),
      ]);
    });

    test('mensal dia 15 gera varias parcelas', () {
      final start = DateTime(2024, 1, 15);
      final now = DateTime(2024, 4, 15);
      final result = computeDueOccurrences(
        startDate: start,
        frequency: 'mensal',
        now: now,
      );
      expect(result, [
        DateTime(2024, 2, 15),
        DateTime(2024, 3, 15),
        DateTime(2024, 4, 15),
      ]);
    });

    test('anual', () {
      final start = DateTime(2022, 6, 10);
      final now = DateTime(2024, 6, 15);
      final result = computeDueOccurrences(
        startDate: start,
        frequency: 'anual',
        now: now,
      );
      expect(result, [
        DateTime(2023, 6, 10),
        DateTime(2024, 6, 10),
      ]);
    });

    test('startDate futuro retorna lista vazia', () {
      final start = DateTime(2024, 6, 1);
      final now = DateTime(2024, 5, 1);
      final result = computeDueOccurrences(
        startDate: start,
        frequency: 'mensal',
        now: now,
      );
      expect(result, isEmpty);
    });

    test('janela de 3 meses', () {
      final start = DateTime(2024, 1, 1);
      final now = DateTime(2024, 4, 1);
      final result = computeDueOccurrences(
        startDate: start,
        frequency: 'mensal',
        now: now,
      );
      expect(result, [
        DateTime(2024, 2, 1),
        DateTime(2024, 3, 1),
        DateTime(2024, 4, 1),
      ]);
    });
  });

  group('nextOccurrenceAfter', () {
    test('proxima > after', () {
      final start = DateTime(2024, 1, 1);
      final after = DateTime(2024, 1, 15);
      final next = nextOccurrenceAfter(
        startDate: start,
        frequency: 'mensal',
        after: after,
      );
      expect(next, DateTime(2024, 2, 1));
    });

    test('clamp fim do mes', () {
      final start = DateTime(2024, 1, 31);
      final after = DateTime(2024, 2, 1);
      final next = nextOccurrenceAfter(
        startDate: start,
        frequency: 'mensal',
        after: after,
      );
      expect(next, DateTime(2024, 2, 29));
    });

    test('semanal', () {
      final start = DateTime(2024, 1, 1);
      final after = DateTime(2024, 1, 20);
      final next = nextOccurrenceAfter(
        startDate: start,
        frequency: 'semanal',
        after: after,
      );
      expect(next, DateTime(2024, 1, 22));
    });

    test('anual', () {
      final start = DateTime(2022, 5, 10);
      final after = DateTime(2024, 1, 1);
      final next = nextOccurrenceAfter(
        startDate: start,
        frequency: 'anual',
        after: after,
      );
      expect(next, DateTime(2024, 5, 10));
    });
  });
}
