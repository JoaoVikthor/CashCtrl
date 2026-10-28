import 'package:ctrlcash/models/ingredient_offer.dart';
import 'package:ctrlcash/utils/offer_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('applyOfferUpsert', () {
    final baseTime = DateTime(2024, 1, 1);
    final updateTime = DateTime(2024, 6, 15);

    IngredientOffer offer({
      required String id,
      required String supplier,
      String productName = '',
      double price = 10.0,
      double quantity = 1.0,
      bool isActive = false,
      DateTime? createdAt,
      DateTime? updatedAt,
    }) =>
        IngredientOffer(
          id: id,
          supplier: supplier,
          productName: productName,
          packagePrice: price,
          packageQuantity: quantity,
          isActive: isActive,
          createdAt: createdAt ?? baseTime,
          updatedAt: updatedAt ?? baseTime,
        );

    test('substitui oferta com mesmo id permitindo renomear fornecedor', () {
      final existing = offer(id: 'a', supplier: 'Fornecedor A', price: 10.0);
      final incoming = offer(
        id: 'a',
        supplier: 'Fornecedor Novo',
        price: 12.0,
        quantity: 2.0,
        isActive: true,
        createdAt: updateTime,
        updatedAt: updateTime,
      );

      final result = applyOfferUpsert(
        [existing],
        incoming,
        newOfferId: 'unused',
        now: updateTime,
      );

      expect(result.isCreate, isFalse);
      expect(result.offerId, 'a');
      expect(result.offers.length, 1);
      expect(result.offers.first.id, 'a');
      expect(result.offers.first.supplier, 'Fornecedor Novo');
      expect(result.offers.first.packagePrice, 12.0);
      expect(result.offers.first.packageQuantity, 2.0);
      expect(result.offers.first.isActive, isTrue);
      expect(result.offers.first.createdAt, baseTime);
      expect(result.offers.first.updatedAt, updateTime);
      expect(result.previous, existing);
    });

    test('id novo e fornecedor existente substitui mantendo id existente', () {
      final existing = offer(id: 'a', supplier: 'Fornecedor A', price: 10.0);
      final incoming = offer(
        id: 'b',
        supplier: 'fornecedor a',
        price: 20.0,
        quantity: 5.0,
        isActive: true,
      );

      final result = applyOfferUpsert(
        [existing],
        incoming,
        newOfferId: 'fallback',
        now: updateTime,
      );

      expect(result.isCreate, isFalse);
      expect(result.offerId, 'a');
      expect(result.offers.length, 1);
      expect(result.offers.first.id, 'a');
      expect(result.offers.first.supplier, 'fornecedor a');
      expect(result.offers.first.packagePrice, 20.0);
      expect(result.offers.first.isActive, isTrue);
      expect(result.previous, existing);
    });

    test('cria nova oferta quando id e fornecedor sao novos', () {
      final existing = offer(id: 'a', supplier: 'Fornecedor A');
      final incoming = offer(
        id: '',
        supplier: 'Fornecedor B',
        price: 30.0,
        isActive: false,
      );

      final result = applyOfferUpsert(
        [existing],
        incoming,
        newOfferId: 'new-id',
        now: updateTime,
      );

      expect(result.isCreate, isTrue);
      expect(result.offerId, 'new-id');
      expect(result.offers.length, 2);
      expect(result.offers.last.id, 'new-id');
      expect(result.offers.last.supplier, 'Fornecedor B');
      expect(result.offers.last.isActive, isFalse);
    });

    test('ativa automaticamente a primeira oferta criada', () {
      final incoming = offer(
        id: '',
        supplier: 'Fornecedor A',
        price: 10.0,
        isActive: false,
      );

      final result = applyOfferUpsert(
        [],
        incoming,
        newOfferId: 'first-id',
        now: updateTime,
      );

      expect(result.offers.length, 1);
      expect(result.offers.first.isActive, isTrue);
      expect(result.offerId, 'first-id');
    });

    test('preserva ordem das ofertas ao atualizar pelo meio', () {
      final offers = [
        offer(id: 'a', supplier: 'A', price: 1.0),
        offer(id: 'b', supplier: 'B', price: 2.0),
        offer(id: 'c', supplier: 'C', price: 3.0),
      ];
      final incoming = offer(
        id: 'b',
        supplier: 'B Atualizado',
        price: 22.0,
      );

      final result = applyOfferUpsert(
        offers,
        incoming,
        newOfferId: 'unused',
        now: updateTime,
      );

      expect(result.offers.map((o) => o.id).toList(), ['a', 'b', 'c']);
      expect(result.offers[1].supplier, 'B Atualizado');
      expect(result.offers[1].packagePrice, 22.0);
    });

    test('nao duplica ao editar oferta trocando nome do fornecedor', () {
      final offers = [
        offer(id: 'a', supplier: 'Fornecedor A'),
        offer(id: 'b', supplier: 'Fornecedor B'),
      ];
      final incoming = offer(
        id: 'a',
        supplier: 'Fornecedor C',
        price: 15.0,
      );

      final result = applyOfferUpsert(
        offers,
        incoming,
        newOfferId: 'unused',
        now: updateTime,
      );

      expect(result.offers.length, 2);
      expect(result.offers.map((o) => o.id).toList(), ['a', 'b']);
      expect(result.offers[0].supplier, 'Fornecedor C');
      expect(result.offers[0].packagePrice, 15.0);
    });

    test('preserva productName ao atualizar oferta existente', () {
      final existing = offer(id: 'a', supplier: 'Fornecedor A');
      final incoming = offer(
        id: 'a',
        supplier: 'Fornecedor A',
        productName: 'Farinha Dona Benta 1kg',
        price: 12.0,
      );

      final result = applyOfferUpsert(
        [existing],
        incoming,
        newOfferId: 'unused',
        now: updateTime,
      );

      expect(result.isCreate, isFalse);
      expect(result.offers.first.productName, 'Farinha Dona Benta 1kg');
    });

    test('preserva productName ao criar oferta nova', () {
      final incoming = offer(
        id: '',
        supplier: 'Fornecedor B',
        productName: 'Açúcar Refinado 5kg',
        price: 30.0,
      );

      final result = applyOfferUpsert(
        const [],
        incoming,
        newOfferId: 'new-id',
        now: updateTime,
      );

      expect(result.isCreate, isTrue);
      expect(result.offers.last.productName, 'Açúcar Refinado 5kg');
    });

    test('lanca StateError ao tentar criar alem do limite de 15', () {
      final offers = List.generate(
        15,
        (i) => offer(
          id: 'offer-$i',
          supplier: 'Fornecedor $i',
          price: i.toDouble(),
        ),
      );
      final incoming = offer(
        id: '',
        supplier: 'Fornecedor Extra',
        price: 99.0,
      );

      expect(
        () => applyOfferUpsert(
          offers,
          incoming,
          newOfferId: 'extra-id',
          now: updateTime,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Limite de 15 ofertas por produto atingido'),
          ),
        ),
      );
    });

    test('atualizar fornecedor sem mudar preco mantem previousPrice igual', () {
      final existing = offer(id: 'a', supplier: 'Fornecedor A', price: 10.0);
      final incoming = offer(
        id: 'a',
        supplier: 'Fornecedor Renomeado',
        price: 10.0,
      );

      final result = applyOfferUpsert(
        [existing],
        incoming,
        newOfferId: 'unused',
        now: updateTime,
      );

      expect(result.isCreate, isFalse);
      expect(result.previous!.packagePrice, 10.0);
      expect(result.offers.first.packagePrice, 10.0);
    });
  });
}
