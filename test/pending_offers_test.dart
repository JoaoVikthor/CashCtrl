import 'package:ctrlcash/models/ingredient_offer.dart';
import 'package:ctrlcash/utils/pending_offers.dart';
import 'package:flutter_test/flutter_test.dart';

IngredientOffer _offer(String supplier) => IngredientOffer(
      id: '',
      supplier: supplier,
      packagePrice: 10,
      packageQuantity: 1,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  group('buildPendingOffer', () {
    test('exige fornecedor', () {
      final result = buildPendingOffer(
        supplier: '   ',
        productName: '',
        priceInput: '10',
        quantityInput: '1',
      );
      expect(result.isValid, isFalse);
      expect(result.supplierError, 'Informe o nome do fornecedor.');
      expect(result.firstError, result.supplierError);
    });

    test('exige preco maior que zero', () {
      final result = buildPendingOffer(
        supplier: 'Central',
        productName: '',
        priceInput: '0',
        quantityInput: '1',
      );
      expect(result.isValid, isFalse);
      expect(result.priceError, 'Informe um preço maior que zero.');
    });

    test('exige quantidade maior que zero', () {
      final result = buildPendingOffer(
        supplier: 'Central',
        productName: '',
        priceInput: '10',
        quantityInput: '-2',
      );
      expect(result.isValid, isFalse);
      expect(result.quantityError, 'Informe uma quantidade maior que zero.');
    });

    test('aceita virgula decimal', () {
      final result = buildPendingOffer(
        supplier: 'Central',
        productName: '',
        priceInput: '12,50',
        quantityInput: '2,5',
      );
      expect(result.isValid, isTrue);
      expect(result.offer!.packagePrice, 12.5);
      expect(result.offer!.packageQuantity, 2.5);
      expect(result.offer!.pricePerUnit, 5);
    });

    test('cria oferta sem id, ativa e com dados limpos', () {
      final now = DateTime(2026, 6, 1, 10);
      final result = buildPendingOffer(
        supplier: '  Distribuidora Central ',
        productName: '  Farinha 5kg ',
        priceInput: '20',
        quantityInput: '5',
        now: now,
      );
      final offer = result.offer!;
      expect(offer.id, isEmpty);
      expect(offer.supplier, 'Distribuidora Central');
      expect(offer.productName, 'Farinha 5kg');
      expect(offer.isActive, isTrue);
      expect(offer.source, 'manual');
      expect(offer.createdAt, now);
      expect(offer.updatedAt, now);
    });
  });

  group('pendingOffersHasSupplier', () {
    test('detecta fornecedor repetido ignorando caixa e espacos', () {
      final offers = [_offer('Atacado do Zé')];
      expect(pendingOffersHasSupplier(offers, '  atacado do zé '), isTrue);
    });

    test('retorna falso para fornecedor novo ou vazio', () {
      final offers = [_offer('Atacado do Zé')];
      expect(pendingOffersHasSupplier(offers, 'Central'), isFalse);
      expect(pendingOffersHasSupplier(offers, '   '), isFalse);
    });

    test('lista vazia nunca tem fornecedor', () {
      expect(pendingOffersHasSupplier(const [], 'Central'), isFalse);
    });
  });

  group('canAddPendingOffer', () {
    test('permite ate 14 ofertas pendentes', () {
      expect(canAddPendingOffer(0), isTrue);
      expect(canAddPendingOffer(14), isTrue);
    });

    test('bloqueia na 15a oferta pendente', () {
      expect(canAddPendingOffer(15), isFalse);
    });
  });
}
