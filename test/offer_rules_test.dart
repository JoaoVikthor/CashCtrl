import 'package:ctrlcash/utils/offer_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ensureOfferLimit', () {
    test('aceita contagem zero sem lancar', () {
      expect(() => ensureOfferLimit(0), returnsNormally);
    });

    test('aceita contagem 14 sem lancar', () {
      expect(() => ensureOfferLimit(14), returnsNormally);
    });

    test('lanca StateError ao atingir limite de 15', () {
      expect(
        () => ensureOfferLimit(15),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Limite de 15 ofertas por produto atingido'),
          ),
        ),
      );
    });
  });

  group('maxOffersPerIngredient', () {
    test('limite e 15', () {
      expect(maxOffersPerIngredient, 15);
    });
  });
}
