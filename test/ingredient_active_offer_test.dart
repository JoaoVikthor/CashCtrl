import 'package:ctrlcash/models/ingredient.dart';
import 'package:ctrlcash/models/ingredient_offer.dart';
import 'package:flutter_test/flutter_test.dart';

IngredientOffer _offer({
  required String id,
  required String supplier,
  required double packagePrice,
  required double packageQuantity,
  bool isActive = true,
}) {
  final now = DateTime(2024, 1, 1);
  return IngredientOffer(
    id: id,
    supplier: supplier,
    packagePrice: packagePrice,
    packageQuantity: packageQuantity,
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
  );
}

Ingredient _ingredient({
  required String id,
  required String name,
  double purchasePrice = 0,
  double packageQuantity = 1,
  List<IngredientOffer> offers = const [],
  String? activeOfferId,
}) {
  return Ingredient(
    id: id,
    name: name,
    unit: IngredientUnit.unidade,
    purchasePrice: purchasePrice,
    packageQuantity: packageQuantity,
    createdAt: DateTime(2024, 1, 1),
    offers: offers,
    activeOfferId: activeOfferId,
  );
}

void main() {
  group('Ingredient.activeOffer', () {
    test('activeOfferId valido retorna oferta correspondente ativa', () {
      final offer = _offer(id: 'o1', supplier: 'A', packagePrice: 10, packageQuantity: 2);
      final ing = _ingredient(
        id: 'ing1',
        name: 'Ingrediente',
        offers: [offer],
        activeOfferId: 'o1',
      );

      expect(ing.activeOffer, isNotNull);
      expect(ing.activeOffer!.id, 'o1');
    });

    test('activeOfferId invalido ignora id e retorna primeira oferta ativa', () {
      final offers = [
        _offer(id: 'o1', supplier: 'A', packagePrice: 10, packageQuantity: 1),
        _offer(id: 'o2', supplier: 'B', packagePrice: 8, packageQuantity: 1),
      ];
      final ing = _ingredient(
        id: 'ing1',
        name: 'Ingrediente',
        offers: offers,
        activeOfferId: 'inexistente',
      );

      expect(ing.activeOffer!.id, 'o1');
    });

    test('activeOfferId apontando para oferta inativa cai no fallback ativo', () {
      final offers = [
        _offer(id: 'o1', supplier: 'A', packagePrice: 10, packageQuantity: 1, isActive: false),
        _offer(id: 'o2', supplier: 'B', packagePrice: 8, packageQuantity: 1, isActive: true),
      ];
      final ing = _ingredient(
        id: 'ing1',
        name: 'Ingrediente',
        offers: offers,
        activeOfferId: 'o1',
      );

      expect(ing.activeOffer!.id, 'o2');
    });

    test('sem ofertas retorna null', () {
      final ing = _ingredient(
        id: 'ing1',
        name: 'Ingrediente',
        purchasePrice: 10,
        packageQuantity: 1,
      );

      expect(ing.activeOffer, isNull);
    });
  });

  group('Ingredient.pricePerUnit', () {
    test('usa preco da oferta ativa quando disponivel', () {
      final offers = [
        _offer(id: 'o1', supplier: 'A', packagePrice: 20, packageQuantity: 5),
      ];
      final ing = _ingredient(
        id: 'ing1',
        name: 'Ingrediente',
        purchasePrice: 100,
        packageQuantity: 1,
        offers: offers,
        activeOfferId: 'o1',
      );

      expect(ing.pricePerUnit, 4.0);
    });

    test('fallback para purchasePrice dividido por packageQuantity', () {
      final ing = _ingredient(
        id: 'ing1',
        name: 'Ingrediente',
        purchasePrice: 50,
        packageQuantity: 10,
      );

      expect(ing.pricePerUnit, 5.0);
    });

    test('quando activeOfferId nulo usa primeira oferta ativa', () {
      final offers = [
        _offer(id: 'o1', supplier: 'A', packagePrice: 20, packageQuantity: 5),
      ];
      final ing = _ingredient(
        id: 'ing1',
        name: 'Ingrediente',
        purchasePrice: 100,
        packageQuantity: 2,
        offers: offers,
      );

      expect(ing.pricePerUnit, 4.0);
    });

    test('fallback quando nenhuma oferta ativa', () {
      final offers = [
        _offer(id: 'o1', supplier: 'A', packagePrice: 20, packageQuantity: 5, isActive: false),
      ];
      final ing = _ingredient(
        id: 'ing1',
        name: 'Ingrediente',
        purchasePrice: 80,
        packageQuantity: 4,
        offers: offers,
        activeOfferId: 'o1',
      );

      expect(ing.pricePerUnit, 20.0);
    });

    test('ofertas vazias usam base', () {
      final ing = _ingredient(
        id: 'ing1',
        name: 'Ingrediente',
        purchasePrice: 30,
        packageQuantity: 3,
        offers: [],
      );

      expect(ing.pricePerUnit, 10.0);
    });

    test('embalagem unitaria retorna preco total', () {
      final ing = _ingredient(
        id: 'ing1',
        name: 'Ingrediente',
        purchasePrice: 12,
        packageQuantity: 1,
      );

      expect(ing.pricePerUnit, 12.0);
    });

    test('packageQuantity zero evita divisao por zero', () {
      final ing = _ingredient(
        id: 'ing1',
        name: 'Ingrediente',
        purchasePrice: 10,
        packageQuantity: 0,
      );

      expect(ing.pricePerUnit, 0.0);
    });
  });

  group('Ingredient.lowestActivePricePerUnit', () {
    test('retorna menor preco entre ofertas ativas', () {
      final offers = [
        _offer(id: 'o1', supplier: 'A', packagePrice: 20, packageQuantity: 2),
        _offer(id: 'o2', supplier: 'B', packagePrice: 15, packageQuantity: 3),
      ];
      final ing = _ingredient(
        id: 'ing1',
        name: 'Ingrediente',
        offers: offers,
      );

      expect(ing.lowestActivePricePerUnit, closeTo(5.0, 0.0001));
    });

    test('retorna null quando nao ha ofertas ativas', () {
      final offers = [
        _offer(id: 'o1', supplier: 'A', packagePrice: 10, packageQuantity: 1, isActive: false),
      ];
      final ing = _ingredient(
        id: 'ing1',
        name: 'Ingrediente',
        offers: offers,
      );

      expect(ing.lowestActivePricePerUnit, isNull);
    });
  });

  group('Ingredient.bestActiveOffer', () {
    test('retorna oferta ativa mais barata', () {
      final offers = [
        _offer(id: 'o1', supplier: 'A', packagePrice: 20, packageQuantity: 1),
        _offer(id: 'o2', supplier: 'B', packagePrice: 8, packageQuantity: 1),
        _offer(id: 'o3', supplier: 'C', packagePrice: 15, packageQuantity: 1),
      ];
      final ing = _ingredient(
        id: 'ing1',
        name: 'Ingrediente',
        offers: offers,
      );

      expect(ing.bestActiveOffer!.id, 'o2');
    });

    test('retorna null sem ofertas ativas', () {
      final ing = _ingredient(
        id: 'ing1',
        name: 'Ingrediente',
      );

      expect(ing.bestActiveOffer, isNull);
    });
  });
}
