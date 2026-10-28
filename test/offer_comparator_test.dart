import 'package:ctrlcash/models/ingredient.dart';
import 'package:ctrlcash/models/ingredient_offer.dart';
import 'package:ctrlcash/models/product.dart';
import 'package:ctrlcash/utils/offer_comparator.dart';
import 'package:ctrlcash/utils/product_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

IngredientOffer _offer({
  required String id,
  required String supplier,
  required double packagePrice,
  required double packageQuantity,
  bool isActive = true,
  String source = 'manual',
  String notes = '',
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime(2024, 1, 1);
  return IngredientOffer(
    id: id,
    supplier: supplier,
    packagePrice: packagePrice,
    packageQuantity: packageQuantity,
    isActive: isActive,
    source: source,
    notes: notes,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
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

Product _product({
  required String id,
  required List<RecipeItem> recipe,
  double salePrice = 100,
  double laborCost = 0,
  double packagingCost = 0,
}) {
  return Product(
    id: id,
    name: 'Produto $id',
    description: '',
    recipe: recipe,
    laborCost: laborCost,
    packagingCost: packagingCost,
    salePrice: salePrice,
    createdAt: DateTime(2024, 1, 1),
  );
}

void main() {
  group('OfferComparator.rank', () {
    test('ordena por pricePerUnit ascendente e marca a melhor ativa', () {
      final offers = [
        _offer(id: 'b', supplier: 'B', packagePrice: 20, packageQuantity: 10),
        _offer(id: 'a', supplier: 'A', packagePrice: 5, packageQuantity: 10),
        _offer(id: 'c', supplier: 'C', packagePrice: 15, packageQuantity: 10),
      ];

      final ranked = OfferComparator.rank(offers, activeOfferId: 'c');

      expect(ranked.map((r) => r.offer.id).toList(), ['a', 'c', 'b']);
      expect(ranked[0].isBest, true);
      expect(ranked[0].isActive, false);
      expect(ranked[1].isBest, false);
      expect(ranked[1].isActive, true);
      expect(ranked[2].isBest, false);
      expect(ranked[2].isActive, false);
    });

    test('deltaVsActive positivo quando mais caro, negativo quando mais barato', () {
      final offers = [
        _offer(id: 'barato', supplier: 'B', packagePrice: 5, packageQuantity: 1),
        _offer(id: 'ativo', supplier: 'A', packagePrice: 10, packageQuantity: 1),
        _offer(id: 'caro', supplier: 'C', packagePrice: 15, packageQuantity: 1),
      ];

      final ranked = OfferComparator.rank(offers, activeOfferId: 'ativo');

      final byId = {for (final r in ranked) r.offer.id: r};
      expect(byId['barato']!.deltaVsActive, -5.0);
      expect(byId['ativo']!.deltaVsActive, 0.0);
      expect(byId['caro']!.deltaVsActive, 5.0);
    });

    test('sem oferta ativa os deltas são zero', () {
      final offers = [
        _offer(id: 'a', supplier: 'A', packagePrice: 10, packageQuantity: 1),
        _offer(id: 'b', supplier: 'B', packagePrice: 20, packageQuantity: 1),
      ];

      final ranked = OfferComparator.rank(offers);

      expect(ranked.every((r) => r.deltaVsActive == 0.0), true);
    });

    test('lista vazia retorna lista vazia', () {
      expect(OfferComparator.rank([]), isEmpty);
    });

    test('rankAll considera ofertas inativas no ranking', () {
      final offers = [
        _offer(id: 'inativa', supplier: 'I', packagePrice: 1, packageQuantity: 1, isActive: false),
        _offer(id: 'ativa', supplier: 'A', packagePrice: 5, packageQuantity: 1),
      ];

      final ranked = OfferComparator.rankAll(offers, activeOfferId: 'ativa');

      expect(ranked.first.offer.id, 'inativa');
      expect(ranked.first.isActive, false);
    });
  });

  group('OfferComparator.bestOffer', () {
    test('retorna a oferta ativa mais barata por padrao', () {
      final offers = [
        _offer(id: 'a', supplier: 'A', packagePrice: 10, packageQuantity: 1),
        _offer(id: 'b', supplier: 'B', packagePrice: 5, packageQuantity: 1),
        _offer(id: 'c', supplier: 'C', packagePrice: 1, packageQuantity: 1, isActive: false),
      ];

      final best = OfferComparator.bestOffer(offers);
      expect(best!.id, 'b');
    });

    test('quando activeOnly=false inclui inativas', () {
      final offers = [
        _offer(id: 'a', supplier: 'A', packagePrice: 10, packageQuantity: 1),
        _offer(id: 'c', supplier: 'C', packagePrice: 1, packageQuantity: 1, isActive: false),
      ];

      final best = OfferComparator.bestOffer(offers, activeOnly: false);
      expect(best!.id, 'c');
    });

    test('ignora ofertas com packageQuantity <= 0', () {
      final offers = [
        _offer(id: 'invalida', supplier: 'I', packagePrice: 1, packageQuantity: 0),
        _offer(id: 'valida', supplier: 'V', packagePrice: 10, packageQuantity: 1),
      ];

      final best = OfferComparator.bestOffer(offers);
      expect(best!.id, 'valida');
    });

    test('empate mantem a primeira apos ordenacao estavel', () {
      final offers = [
        _offer(id: 'primeira', supplier: 'P', packagePrice: 10, packageQuantity: 1),
        _offer(id: 'segunda', supplier: 'S', packagePrice: 10, packageQuantity: 1),
      ];

      final best = OfferComparator.bestOffer(offers);
      expect(best!.id, 'primeira');
    });

    test('lista vazia retorna null', () {
      expect(OfferComparator.bestOffer([]), isNull);
    });
  });

  group('OfferComparator.syntheticLegacyOffer', () {
    test('espelha preco legado com source migration', () {
      final ing = _ingredient(
        id: 'ing1',
        name: 'Farinha',
        purchasePrice: 10,
        packageQuantity: 20,
      );

      final legacy = OfferComparator.syntheticLegacyOffer(ing);

      expect(legacy.supplier, 'Fornecedor padrão');
      expect(legacy.packagePrice, 10.0);
      expect(legacy.packageQuantity, 20.0);
      expect(legacy.pricePerUnit, 0.5);
      expect(legacy.isActive, true);
      expect(legacy.source, 'migration');
      expect(legacy.notes, 'Preço cadastrado migrado automaticamente');
      expect(legacy.createdAt, ing.createdAt);
      expect(legacy.updatedAt, ing.createdAt);
    });
  });

  group('OfferComparator.hasDifferentPackageSizes', () {
    test('true quando ha quantidades distintas', () {
      final offers = [
        _offer(id: 'a', supplier: 'A', packagePrice: 10, packageQuantity: 1),
        _offer(id: 'b', supplier: 'B', packagePrice: 10, packageQuantity: 0.5),
      ];
      expect(OfferComparator.hasDifferentPackageSizes(offers), true);
    });

    test('false quando todas iguais', () {
      final offers = [
        _offer(id: 'a', supplier: 'A', packagePrice: 10, packageQuantity: 1),
        _offer(id: 'b', supplier: 'B', packagePrice: 20, packageQuantity: 1),
      ];
      expect(OfferComparator.hasDifferentPackageSizes(offers), false);
    });

    test('false com uma unica oferta', () {
      final offers = [
        _offer(id: 'a', supplier: 'A', packagePrice: 10, packageQuantity: 1),
      ];
      expect(OfferComparator.hasDifferentPackageSizes(offers), false);
    });

    test('false quando vazio', () {
      expect(OfferComparator.hasDifferentPackageSizes([]), false);
    });
  });

  group('OfferComparator.bestSupplierScenario', () {
    test('retorna cenario com economia agregada e ignora linha sem economia', () {
      final ingComEco = _ingredient(
        id: 'ing1',
        name: 'Farinha',
        offers: [
          _offer(id: 'o1-caro', supplier: 'Mercado', packagePrice: 10, packageQuantity: 1),
          _offer(id: 'o1-barato', supplier: 'Atacado', packagePrice: 4, packageQuantity: 1),
        ],
        activeOfferId: 'o1-caro',
      );
      final ingSemEco = _ingredient(
        id: 'ing2',
        name: 'Acucar',
        offers: [
          _offer(id: 'o2', supplier: 'Atacado', packagePrice: 10, packageQuantity: 1),
        ],
        activeOfferId: 'o2',
      );
      final product = _product(
        id: 'p1',
        recipe: [
          RecipeItem(ingredientId: 'ing1', ingredientName: 'Farinha', quantity: 3),
          RecipeItem(ingredientId: 'ing2', ingredientName: 'Acucar', quantity: 2),
        ],
        salePrice: 100,
      );
      final ticket = ProductCalculator.calculate(product, {
        'ing1': ingComEco,
        'ing2': ingSemEco,
      });

      final scenario = OfferComparator.bestSupplierScenario(ticket);

      expect(scenario, isNotNull);
      expect(scenario!.totalSaving, 18.0);
      expect(scenario.lines.length, 1);
      expect(scenario.lines.first.ingredientId, 'ing1');
      expect(scenario.lines.first.saving, 18.0);
      expect(scenario.simulatedProfit, ticket.profit + 18.0);
      expect(scenario.stillLoss, false);
    });

    test('retorna null quando nao ha economia', () {
      final ing = _ingredient(
        id: 'ing1',
        name: 'Farinha',
        offers: [
          _offer(id: 'o1', supplier: 'Atacado', packagePrice: 10, packageQuantity: 1),
        ],
        activeOfferId: 'o1',
      );
      final product = _product(
        id: 'p1',
        recipe: [
          RecipeItem(ingredientId: 'ing1', ingredientName: 'Farinha', quantity: 1),
        ],
      );
      final ticket = ProductCalculator.calculate(product, {'ing1': ing});

      expect(OfferComparator.bestSupplierScenario(ticket), isNull);
    });

    test('retorna null quando ofertas estao vazias', () {
      final ing = _ingredient(id: 'ing1', name: 'Farinha');
      final product = _product(
        id: 'p1',
        recipe: [
          RecipeItem(ingredientId: 'ing1', ingredientName: 'Farinha', quantity: 1),
        ],
      );
      final ticket = ProductCalculator.calculate(product, {'ing1': ing});

      expect(OfferComparator.bestSupplierScenario(ticket), isNull);
    });

    test('ignora linhas missing', () {
      final ing = _ingredient(
        id: 'ing1',
        name: 'Farinha',
        offers: [
          _offer(id: 'o1-caro', supplier: 'Mercado', packagePrice: 5, packageQuantity: 1),
          _offer(id: 'o1-barato', supplier: 'Atacado', packagePrice: 1, packageQuantity: 1),
        ],
        activeOfferId: 'o1-caro',
      );
      final product = _product(
        id: 'p1',
        recipe: [
          RecipeItem(ingredientId: 'ing1', ingredientName: 'Farinha', quantity: 1),
          RecipeItem(ingredientId: 'missing', ingredientName: 'Missing', quantity: 1),
        ],
      );
      final ticket = ProductCalculator.calculate(product, {'ing1': ing});

      final scenario = OfferComparator.bestSupplierScenario(ticket);
      expect(scenario, isNotNull);
      expect(scenario!.lines.length, 1);
    });

    test('stillLoss true quando prejuizo persiste', () {
      final ing = _ingredient(
        id: 'ing1',
        name: 'Farinha',
        offers: [
          _offer(id: 'o1-caro', supplier: 'Mercado', packagePrice: 5, packageQuantity: 1),
          _offer(id: 'o1-barato', supplier: 'Atacado', packagePrice: 1, packageQuantity: 1),
        ],
        activeOfferId: 'o1-caro',
      );
      final product = _product(
        id: 'p1',
        recipe: [
          RecipeItem(ingredientId: 'ing1', ingredientName: 'Farinha', quantity: 1),
        ],
        salePrice: 5,
        laborCost: 10,
      );
      final ticket = ProductCalculator.calculate(product, {'ing1': ing});

      final scenario = OfferComparator.bestSupplierScenario(ticket);
      expect(scenario, isNotNull);
      expect(scenario!.stillLoss, true);
    });

    test('nao gera falsa economia por arredondamento', () {
      final ing = _ingredient(
        id: 'ing1',
        name: 'Farinha',
        offers: [
          _offer(id: 'o1', supplier: 'Atacado', packagePrice: 0.3, packageQuantity: 1),
        ],
        activeOfferId: 'o1',
      );
      final product = _product(
        id: 'p1',
        recipe: [
          RecipeItem(ingredientId: 'ing1', ingredientName: 'Farinha', quantity: 1),
        ],
      );
      final ticket = ProductCalculator.calculate(product, {'ing1': ing});

      expect(OfferComparator.bestSupplierScenario(ticket), isNull);
    });

    test('nao considera economia abaixo da tolerancia de 0.005', () {
      final ing = _ingredient(
        id: 'ing1',
        name: 'Farinha',
        offers: [
          _offer(id: 'o1-caro', supplier: 'Mercado', packagePrice: 0.3005, packageQuantity: 1),
          _offer(id: 'o1-barato', supplier: 'Atacado', packagePrice: 0.3, packageQuantity: 1),
        ],
        activeOfferId: 'o1-caro',
      );
      final product = _product(
        id: 'p1',
        recipe: [
          RecipeItem(ingredientId: 'ing1', ingredientName: 'Farinha', quantity: 1),
        ],
      );
      final ticket = ProductCalculator.calculate(product, {'ing1': ing});

      expect(OfferComparator.bestSupplierScenario(ticket), isNull);
    });
  });

  group('OfferComparator.deltaUnit', () {
    test('retorna diferenca de pricePerUnit', () {
      final a = _offer(id: 'a', supplier: 'A', packagePrice: 10, packageQuantity: 1);
      final b = _offer(id: 'b', supplier: 'B', packagePrice: 7, packageQuantity: 1);
      expect(OfferComparator.deltaUnit(a, b), 3.0);
    });
  });
}
