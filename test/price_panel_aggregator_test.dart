import 'package:ctrlcash/models/ingredient.dart';
import 'package:ctrlcash/models/ingredient_offer.dart';
import 'package:ctrlcash/utils/price_panel_aggregator.dart';
import 'package:flutter_test/flutter_test.dart';

IngredientOffer _offer({
  required String id,
  required String supplier,
  required double packagePrice,
  required double packageQuantity,
  bool isActive = true,
  String productName = '',
}) {
  final now = DateTime(2024, 1, 1);
  return IngredientOffer(
    id: id,
    supplier: supplier,
    productName: productName,
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
  required IngredientUnit unit,
  double purchasePrice = 0,
  double packageQuantity = 1,
  List<IngredientOffer> offers = const [],
  String? activeOfferId,
}) {
  return Ingredient(
    id: id,
    name: name,
    unit: unit,
    purchasePrice: purchasePrice,
    packageQuantity: packageQuantity,
    createdAt: DateTime(2024, 1, 1),
    offers: offers,
    activeOfferId: activeOfferId,
  );
}

Map<String, Ingredient> _bakeryScenario() {
  return {
    'pao': _ingredient(
      id: 'pao',
      name: 'Pão francês',
      unit: IngredientUnit.unidade,
      purchasePrice: 7.20,
      packageQuantity: 16,
      offers: [
        _offer(id: 'pao-sj', supplier: 'Atacão São Jorge', packagePrice: 8.00, packageQuantity: 16),
        _offer(id: 'pao-dc', supplier: 'Distribuidora Central', packagePrice: 7.20, packageQuantity: 16),
        _offer(id: 'pao-bf', supplier: 'Mercado Bom Farto', packagePrice: 6.90, packageQuantity: 16),
      ],
      activeOfferId: 'pao-dc',
    ),
    'mussarela': _ingredient(
      id: 'mussarela',
      name: 'Queijo mussarela',
      unit: IngredientUnit.kilo,
      purchasePrice: 39.90,
      packageQuantity: 1,
      offers: [
        _offer(id: 'muss-sj', supplier: 'Atacão São Jorge', packagePrice: 39.90, packageQuantity: 1),
        _offer(id: 'muss-dc', supplier: 'Distribuidora Central', packagePrice: 37.80, packageQuantity: 1),
        _offer(id: 'muss-mc', supplier: 'Maciel & Filhos', packagePrice: 42.50, packageQuantity: 1),
      ],
      activeOfferId: 'muss-sj',
    ),
    'presunto': _ingredient(
      id: 'presunto',
      name: 'Presunto',
      unit: IngredientUnit.kilo,
      purchasePrice: 28.90,
      packageQuantity: 1,
      offers: [
        _offer(id: 'pres-mc', supplier: 'Maciel & Filhos', packagePrice: 28.90, packageQuantity: 1),
        _offer(id: 'pres-sj', supplier: 'Atacão São Jorge', packagePrice: 26.40, packageQuantity: 1),
      ],
      activeOfferId: 'pres-mc',
    ),
    'cafe': _ingredient(
      id: 'cafe',
      name: 'Café torrado',
      unit: IngredientUnit.kilo,
      purchasePrice: 44.00,
      packageQuantity: 0.5,
      offers: [
        _offer(id: 'cafe-ec', supplier: 'Empório do Café', packagePrice: 44.00, packageQuantity: 0.5),
        _offer(id: 'cafe-sj', supplier: 'Atacão São Jorge', packagePrice: 39.90, packageQuantity: 0.5),
        _offer(id: 'cafe-mc', supplier: 'Maciel & Filhos', packagePrice: 41.50, packageQuantity: 0.5),
      ],
      activeOfferId: 'cafe-ec',
    ),
    'oleo': _ingredient(
      id: 'oleo',
      name: 'Óleo de soja',
      unit: IngredientUnit.litro,
      purchasePrice: 7.45,
      packageQuantity: 0.9,
      offers: [
        _offer(id: 'oleo-dc', supplier: 'Distribuidora Central', packagePrice: 7.89, packageQuantity: 0.9),
        _offer(id: 'oleo-sj', supplier: 'Atacão São Jorge', packagePrice: 8.49, packageQuantity: 0.9),
        _offer(id: 'oleo-bf', supplier: 'Mercado Bom Farto', packagePrice: 7.45, packageQuantity: 0.9),
      ],
      activeOfferId: 'oleo-bf',
    ),
    'acucar': _ingredient(
      id: 'acucar',
      name: 'Açúcar cristal',
      unit: IngredientUnit.kilo,
      purchasePrice: 4.29,
      packageQuantity: 1,
      offers: [
        _offer(id: 'acucar-bf', supplier: 'Mercado Bom Farto', packagePrice: 4.29, packageQuantity: 1),
        _offer(id: 'acucar-dc', supplier: 'Distribuidora Central', packagePrice: 4.55, packageQuantity: 1),
        _offer(id: 'acucar-sj', supplier: 'Atacão São Jorge', packagePrice: 4.89, packageQuantity: 1),
      ],
      activeOfferId: 'acucar-bf',
    ),
    'tomate': _ingredient(
      id: 'tomate',
      name: 'Tomate',
      unit: IngredientUnit.kilo,
      purchasePrice: 7.20,
      packageQuantity: 1,
      offers: [
        _offer(id: 'tom-hb', supplier: 'Hortifruti Boa Colheita', packagePrice: 6.50, packageQuantity: 1),
        _offer(id: 'tom-mc', supplier: 'Maciel & Filhos', packagePrice: 7.20, packageQuantity: 1),
      ],
      activeOfferId: 'tom-mc',
    ),
    'copos': _ingredient(
      id: 'copos',
      name: 'Copo descartável 200 ml',
      unit: IngredientUnit.unidade,
      purchasePrice: 18.90,
      packageQuantity: 100,
      offers: [
        _offer(id: 'copo-sj', supplier: 'Atacão São Jorge', packagePrice: 18.90, packageQuantity: 100),
        _offer(id: 'copo-dc', supplier: 'Distribuidora Central', packagePrice: 16.50, packageQuantity: 100),
      ],
      activeOfferId: 'copo-sj',
    ),
  };
}

void main() {
  group('PricePanelAggregator.buildPanel', () {
    test('calcula deltas corretos no cenário padaria', () {
      final panel = PricePanelAggregator.buildPanel(_bakeryScenario());
      final byName = {
        for (final e in panel) e.ingredient.name: e,
      };

      expect(byName['Café torrado']!.deltaVsBest, closeTo(8.20, 0.005));
      expect(byName['Queijo mussarela']!.deltaVsBest, closeTo(2.10, 0.005));
      expect(byName['Presunto']!.deltaVsBest, closeTo(2.50, 0.005));
      expect(byName['Tomate']!.deltaVsBest, closeTo(0.70, 0.005));
      expect(byName['Pão francês']!.deltaVsBest, closeTo(0.019, 0.005));
      expect(byName['Copo descartável 200 ml']!.deltaVsBest, closeTo(0.024, 0.005));

      expect(byName['Óleo de soja']!.deltaVsBest, 0.0);
      expect(byName['Açúcar cristal']!.deltaVsBest, 0.0);

      expect(byName['Óleo de soja']!.bestOffer!.supplier, 'Mercado Bom Farto');
      expect(byName['Açúcar cristal']!.bestOffer!.supplier, 'Mercado Bom Farto');
    });

    test('produto sem ofertas é legacyOnly sem economia', () {
      final map = {
        'leite': _ingredient(
          id: 'leite',
          name: 'Leite',
          unit: IngredientUnit.litro,
          purchasePrice: 5.00,
          packageQuantity: 1,
        ),
      };
      final panel = PricePanelAggregator.buildPanel(map);

      expect(panel.first.legacyOnly, true);
      expect(panel.first.bestPricePerUnit, 5.00);
      expect(panel.first.deltaVsBest, -1);
      expect(panel.first.activeSuppliersCount, 0);
      expect(panel.first.supplierNames, isEmpty);
    });

    test('sentinela -1 quando não há ofertas ativas válidas', () {
      final map = {
        'pao': _ingredient(
          id: 'pao',
          name: 'Pão',
          unit: IngredientUnit.unidade,
          purchasePrice: 10,
          packageQuantity: 1,
          offers: [
            _offer(id: 'o1', supplier: 'A', packagePrice: 10, packageQuantity: 0),
          ],
          activeOfferId: 'o1',
        ),
      };
      final panel = PricePanelAggregator.buildPanel(map);

      expect(panel.first.deltaVsBest, -1);
      expect(panel.first.bestOffer, isNull);
      expect(panel.first.activePricePerUnit, isNull);
    });
  });

  group('PricePanelAggregator.sortPanel', () {
    test('economy coloca maior delta primeiro e mantém estabilidade', () {
      final panel = PricePanelAggregator.buildPanel(_bakeryScenario());
      final sorted = PricePanelAggregator.sortPanel(panel, PanelSort.economy);

      expect(sorted.first.ingredient.name, 'Café torrado');

      final names = sorted.map((e) => e.ingredient.name).toList();
      final cafeIndex = names.indexOf('Café torrado');
      final mussIndex = names.indexOf('Queijo mussarela');
      final presIndex = names.indexOf('Presunto');
      final tomIndex = names.indexOf('Tomate');
      final paoIndex = names.indexOf('Pão francês');
      final copoIndex = names.indexOf('Copo descartável 200 ml');

      expect(cafeIndex, lessThan(presIndex));
      expect(presIndex, lessThan(mussIndex));
      expect(mussIndex, lessThan(tomIndex));
      expect(tomIndex, lessThan(copoIndex));
      expect(copoIndex, lessThan(paoIndex));
    });

    test('lowest ordena pelo menor bestPricePerUnit', () {
      final panel = PricePanelAggregator.buildPanel(_bakeryScenario());
      final sorted = PricePanelAggregator.sortPanel(panel, PanelSort.lowest);

      expect(sorted.first.ingredient.name, 'Copo descartável 200 ml');
      expect(sorted.last.ingredient.name, 'Café torrado');
    });

    test('name ordena alfabeticamente', () {
      final panel = PricePanelAggregator.buildPanel(_bakeryScenario());
      final sorted = PricePanelAggregator.sortPanel(panel, PanelSort.name);

      final names = sorted.map((e) => e.ingredient.name).toList();
      expect(names, orderedEquals([
        'Açúcar cristal',
        'Café torrado',
        'Copo descartável 200 ml',
        'Óleo de soja',
        'Pão francês',
        'Presunto',
        'Queijo mussarela',
        'Tomate',
      ]));
    });
  });

  group('PricePanelAggregator.filterPanel', () {
    test('filtra por query sem acento e case-insensitive', () {
      final panel = PricePanelAggregator.buildPanel(_bakeryScenario());
      final filtered = PricePanelAggregator.filterPanel(panel, query: 'cafe');

      expect(filtered.length, 1);
      expect(filtered.first.ingredient.name, 'Café torrado');
    });

    test('filtra por fornecedor exato case-insensitive', () {
      final panel = PricePanelAggregator.buildPanel(_bakeryScenario());
      final filtered = PricePanelAggregator.filterPanel(
        panel,
        supplier: 'Distribuidora Central',
      );

      expect(filtered.map((e) => e.ingredient.name).toSet(),
          {'Pão francês', 'Queijo mussarela', 'Óleo de soja', 'Açúcar cristal', 'Copo descartável 200 ml'});
    });

    test('combina query e supplier', () {
      final panel = PricePanelAggregator.buildPanel(_bakeryScenario());
      final filtered = PricePanelAggregator.filterPanel(
        panel,
        query: 'pao',
        supplier: 'Distribuidora Central',
      );

      expect(filtered.length, 1);
      expect(filtered.first.ingredient.name, 'Pão francês');
    });

    test('filtra por productName da oferta sem acento e case-insensitive', () {
      final map = {
        'farinha': _ingredient(
          id: 'farinha',
          name: 'Farinha de trigo',
          unit: IngredientUnit.kilo,
          purchasePrice: 5.00,
          packageQuantity: 1,
          offers: [
            _offer(
              id: 'f1',
              supplier: 'Moinho Sul',
              packagePrice: 25.00,
              packageQuantity: 5,
              productName: 'Farinha Tipo 1 Pacote 5 kg',
            ),
            _offer(
              id: 'f2',
              supplier: 'Atacado Norte',
              packagePrice: 4.90,
              packageQuantity: 1,
            ),
          ],
          activeOfferId: 'f2',
        ),
        'acucar': _ingredient(
          id: 'acucar',
          name: 'Açúcar cristal',
          unit: IngredientUnit.kilo,
          purchasePrice: 4.29,
          packageQuantity: 1,
          offers: [
            _offer(
              id: 'a1',
              supplier: 'Atacado Norte',
              packagePrice: 4.29,
              packageQuantity: 1,
            ),
          ],
          activeOfferId: 'a1',
        ),
      };
      final panel = PricePanelAggregator.buildPanel(map);

      final byProductName = PricePanelAggregator.filterPanel(
        panel,
        query: 'tipo 1',
      );
      expect(byProductName.length, 1);
      expect(byProductName.first.ingredient.name, 'Farinha de trigo');

      final byProductNameAndSupplier = PricePanelAggregator.filterPanel(
        panel,
        query: 'farinha tipo',
        supplier: 'Moinho Sul',
      );
      expect(byProductNameAndSupplier.length, 1);
      expect(byProductNameAndSupplier.first.ingredient.name, 'Farinha de trigo');

      final noMatch = PricePanelAggregator.filterPanel(panel, query: 'moida');
      expect(noMatch, isEmpty);
    });
  });

  group('PricePanelAggregator.rowsForSupplier', () {
    test('retorna posições corretas para Atacão São Jorge', () {
      final panel = PricePanelAggregator.buildPanel(_bakeryScenario());
      final rows = PricePanelAggregator.rowsForSupplier(panel, 'Atacão São Jorge');
      final byName = {
        for (final r in rows) r.entry.ingredient.name: r,
      };

      expect(byName['Café torrado']!.position, 1);
      expect(byName['Café torrado']!.ofTotal, 3);
      expect(byName['Café torrado']!.isBest, true);
      expect(byName['Café torrado']!.isActive, false);

      expect(byName['Presunto']!.position, 1);
      expect(byName['Presunto']!.ofTotal, 2);
      expect(byName['Presunto']!.isBest, true);
      expect(byName['Presunto']!.isActive, false);

      expect(byName['Queijo mussarela']!.position, 2);
      expect(byName['Queijo mussarela']!.ofTotal, 3);
      expect(byName['Queijo mussarela']!.isActive, true);

      expect(byName['Açúcar cristal']!.position, 3);
      expect(byName['Açúcar cristal']!.ofTotal, 3);
    });

    test('agrupa múltiplas ofertas do mesmo fornecedor usando a melhor', () {
      final map = {
        'ing': _ingredient(
          id: 'ing',
          name: 'Ingrediente',
          unit: IngredientUnit.kilo,
          purchasePrice: 10,
          packageQuantity: 1,
          offers: [
            _offer(id: 'a1', supplier: 'SJ', packagePrice: 10, packageQuantity: 1),
            _offer(id: 'a2', supplier: 'SJ', packagePrice: 8, packageQuantity: 1),
            _offer(id: 'b1', supplier: 'DC', packagePrice: 7, packageQuantity: 1),
          ],
          activeOfferId: 'a1',
        ),
      };
      final panel = PricePanelAggregator.buildPanel(map);
      final rows = PricePanelAggregator.rowsForSupplier(panel, 'SJ');

      expect(rows.length, 1);
      expect(rows.first.pricePerUnit, 8.0);
      expect(rows.first.position, 2);
      expect(rows.first.isActive, true);
    });
  });

  group('PricePanelAggregator.buildSupplierReport', () {
    test('retorna fornecedores com ofertas ativas ordenados por bestCount', () {
      final panel = PricePanelAggregator.buildPanel(_bakeryScenario());
      final report = PricePanelAggregator.buildSupplierReport(panel);

      final byName = {
        for (final r in report) r.name: r,
      };

      expect(byName['Atacão São Jorge']!.bestCount, 2);
      expect(byName['Atacão São Jorge']!.productsCount, 7);

      expect(report.first.bestCount, greaterThanOrEqualTo(report[1].bestCount));
      expect(
        report.map((r) => r.name).toList(),
        containsAll([
          'Atacão São Jorge',
          'Distribuidora Central',
          'Mercado Bom Farto',
          'Empório do Café',
          'Maciel & Filhos',
          'Hortifruti Boa Colheita',
        ]),
      );
    });

    test('não inclui fornecedores sem ofertas ativas', () {
      final map = {
        'ing': _ingredient(
          id: 'ing',
          name: 'Ingrediente',
          unit: IngredientUnit.kilo,
          purchasePrice: 10,
          packageQuantity: 1,
          offers: [
            _offer(id: 'o1', supplier: 'SJ', packagePrice: 10, packageQuantity: 1, isActive: false),
          ],
          activeOfferId: 'o1',
        ),
      };
      final panel = PricePanelAggregator.buildPanel(map);
      final report = PricePanelAggregator.buildSupplierReport(panel);

      expect(report, isEmpty);
    });
  });

  group('PricePanelAggregator.summarize', () {
    test('resume cenário padaria corretamente', () {
      final panel = PricePanelAggregator.buildPanel(_bakeryScenario());
      final summary = PricePanelAggregator.summarize(panel);

      expect(summary.productsWithOffers, 8);
      expect(summary.suppliersCount, 6);
      expect(summary.productsPayMore, 6);
      expect(summary.economySumPerUnit, closeTo(13.543, 0.05));
    });

    test('ignora legacyOnly na economia', () {
      final map = {
        ..._bakeryScenario(),
        'leite': _ingredient(
          id: 'leite',
          name: 'Leite',
          unit: IngredientUnit.litro,
          purchasePrice: 5.00,
          packageQuantity: 1,
        ),
      };
      final panel = PricePanelAggregator.buildPanel(map);
      final summary = PricePanelAggregator.summarize(panel);

      expect(summary.productsWithOffers, 8);
      expect(summary.productsPayMore, 6);
    });
  });
}
