import 'package:ctrlcash/models/ingredient.dart';
import 'package:ctrlcash/models/product.dart';
import 'package:ctrlcash/utils/product_calculator.dart';
import 'package:ctrlcash/utils/sebrae_rules.dart';
import 'package:flutter_test/flutter_test.dart';

Ingredient _ingredient({
  required String id,
  required String name,
  double purchasePrice = 0,
  double packageQuantity = 1,
}) {
  return Ingredient(
    id: id,
    name: name,
    unit: IngredientUnit.unidade,
    purchasePrice: purchasePrice,
    packageQuantity: packageQuantity,
    createdAt: DateTime(2024, 1, 1),
  );
}

Product _product({
  required String id,
  required List<RecipeItem> recipe,
  double salePrice = 100,
  double laborTotal = 0,
  double dailyRate = 0,
  double dailyDays = 0,
  double hourlyRate = 0,
  double hourlyHours = 0,
  double commissionPercent = 0,
  double packagingCost = 0,
}) {
  return Product(
    id: id,
    name: 'Produto $id',
    description: '',
    recipe: recipe,
    dailyRate: laborTotal > 0 ? laborTotal : dailyRate,
    dailyDays: laborTotal > 0 ? 1 : dailyDays,
    hourlyRate: hourlyRate,
    hourlyHours: hourlyHours,
    commissionPercent: commissionPercent,
    packagingCost: packagingCost,
    salePrice: salePrice,
    createdAt: DateTime(2024, 1, 1),
  );
}

Ingredient _sebraeIngredient({
  required String id,
  required String name,
  required IngredientUnit unit,
  required double purchasePrice,
  required double packageQuantity,
  double? averageUnitWeightGrams,
  double correctionFactor = 1.0,
}) {
  return Ingredient(
    id: id,
    name: name,
    unit: unit,
    purchasePrice: purchasePrice,
    packageQuantity: packageQuantity,
    createdAt: DateTime(2024, 1, 1),
    averageUnitWeightGrams: averageUnitWeightGrams,
    correctionFactor: correctionFactor,
  );
}

void main() {
  group('ProductCalculator.calculate', () {
    test('custo por ingrediente é quantidade vezes preco unitario', () {
      final farinha = _ingredient(
        id: 'farinha',
        name: 'Farinha',
        purchasePrice: 10,
        packageQuantity: 2,
      );
      final acucar = _ingredient(
        id: 'acucar',
        name: 'Acucar',
        purchasePrice: 20,
        packageQuantity: 5,
      );
      final product = _product(
        id: 'p1',
        recipe: [
          RecipeItem(ingredientId: 'farinha', ingredientName: 'Farinha', quantity: 3),
          RecipeItem(ingredientId: 'acucar', ingredientName: 'Acucar', quantity: 2),
        ],
      );

      final ticket = ProductCalculator.calculate(product, {
        'farinha': farinha,
        'acucar': acucar,
      });

      final farinhaLine = ticket.lines.firstWhere((l) => l.item.ingredientId == 'farinha');
      final acucarLine = ticket.lines.firstWhere((l) => l.item.ingredientId == 'acucar');

      expect(farinhaLine.unitPrice, 5.0);
      expect(farinhaLine.lineCost, 15.0);
      expect(acucarLine.unitPrice, 4.0);
      expect(acucarLine.lineCost, 8.0);
      expect(ticket.ingredientsTotal, 23.0);
    });

    test('subtotal somente dos ingredientes', () {
      final ing = _ingredient(
        id: 'ing1',
        name: 'Ingrediente',
        purchasePrice: 50,
        packageQuantity: 1,
      );
      final product = _product(
        id: 'p1',
        recipe: [
          RecipeItem(ingredientId: 'ing1', ingredientName: 'Ingrediente', quantity: 2),
        ],
        laborTotal: 10,
        packagingCost: 5,
      );

      final ticket = ProductCalculator.calculate(product, {'ing1': ing});

      expect(ticket.ingredientsTotal, 100.0);
    });

    test('custo total inclui ingredientes, mao de obra e embalagem', () {
      final ing = _ingredient(
        id: 'ing1',
        name: 'Ingrediente',
        purchasePrice: 30,
        packageQuantity: 1,
      );
      final product = _product(
        id: 'p1',
        recipe: [
          RecipeItem(ingredientId: 'ing1', ingredientName: 'Ingrediente', quantity: 1),
        ],
        laborTotal: 20,
        packagingCost: 10,
      );

      final ticket = ProductCalculator.calculate(product, {'ing1': ing});

      expect(ticket.totalCost, 60.0);
    });

    test('lucro quando preco de venda maior que custo total', () {
      final ing = _ingredient(
        id: 'ing1',
        name: 'Ingrediente',
        purchasePrice: 40,
        packageQuantity: 1,
      );
      final product = _product(
        id: 'p1',
        recipe: [
          RecipeItem(ingredientId: 'ing1', ingredientName: 'Ingrediente', quantity: 1),
        ],
        salePrice: 100,
      );

      final ticket = ProductCalculator.calculate(product, {'ing1': ing});

      expect(ticket.profit, 60.0);
      expect(ticket.isLucro, true);
      expect(ticket.isPrejuizo, false);
    });

    test('prejuizo quando preco de venda menor que custo total', () {
      final ing = _ingredient(
        id: 'ing1',
        name: 'Ingrediente',
        purchasePrice: 80,
        packageQuantity: 1,
      );
      final product = _product(
        id: 'p1',
        recipe: [
          RecipeItem(ingredientId: 'ing1', ingredientName: 'Ingrediente', quantity: 1),
        ],
        salePrice: 50,
      );

      final ticket = ProductCalculator.calculate(product, {'ing1': ing});

      expect(ticket.profit, -30.0);
      expect(ticket.isLucro, false);
      expect(ticket.isPrejuizo, true);
    });

    test('margem percentual calculada sobre preco de venda', () {
      final ing = _ingredient(
        id: 'ing1',
        name: 'Ingrediente',
        purchasePrice: 60,
        packageQuantity: 1,
      );
      final product = _product(
        id: 'p1',
        recipe: [
          RecipeItem(ingredientId: 'ing1', ingredientName: 'Ingrediente', quantity: 1),
        ],
        salePrice: 100,
      );

      final ticket = ProductCalculator.calculate(product, {'ing1': ing});

      expect(ticket.marginPercent, 40.0);
    });

    test('veredito lucro quando lucro zero', () {
      final ing = _ingredient(
        id: 'ing1',
        name: 'Ingrediente',
        purchasePrice: 100,
        packageQuantity: 1,
      );
      final product = _product(
        id: 'p1',
        recipe: [
          RecipeItem(ingredientId: 'ing1', ingredientName: 'Ingrediente', quantity: 1),
        ],
        salePrice: 100,
      );

      final ticket = ProductCalculator.calculate(product, {'ing1': ing});

      expect(ticket.profit, 0.0);
      expect(ticket.isLucro, true);
    });

    test('produto ausente na receita gera linha missing e hasMissingIngredients true', () {
      final product = _product(
        id: 'p1',
        recipe: [
          RecipeItem(ingredientId: 'missing', ingredientName: 'Missing', quantity: 1),
        ],
      );

      final ticket = ProductCalculator.calculate(product, {});

      expect(ticket.hasMissingIngredients, true);
      expect(ticket.lines.length, 1);
      expect(ticket.lines.first.missing, true);
      expect(ticket.lines.first.ingredient, isNull);
      expect(ticket.lines.first.lineCost, 0.0);
      expect(ticket.ingredientsTotal, 0.0);
    });

    test('markup é preco de venda sobre custo total', () {
      final ing = _ingredient(
        id: 'ing1',
        name: 'Ingrediente',
        purchasePrice: 50,
        packageQuantity: 1,
      );
      final product = _product(
        id: 'p1',
        recipe: [
          RecipeItem(ingredientId: 'ing1', ingredientName: 'Ingrediente', quantity: 1),
        ],
        salePrice: 100,
      );

      final ticket = ProductCalculator.calculate(product, {'ing1': ing});

      expect(ticket.markup, 2.0);
    });

    test('markup zero quando custo total zero', () {
      final product = _product(
        id: 'p1',
        recipe: [],
        salePrice: 100,
      );

      final ticket = ProductCalculator.calculate(product, {});

      expect(ticket.markup, 0.0);
    });
  });

  group('ProductCalculator com unidade digitada, Peso Médio e Desperdício', () {
    test('cenário tomate: 0,5 un com pm 120 g e Desperdício 33% custa R\$ 0,72', () {
      final tomate = _sebraeIngredient(
        id: 'tomate',
        name: 'Tomate',
        unit: IngredientUnit.kilo,
        purchasePrice: 8,
        packageQuantity: 1,
        averageUnitWeightGrams: 120,
        correctionFactor: 1.5,
      );
      final product = _product(
        id: 'p1',
        recipe: [
          RecipeItem(
              ingredientId: 'tomate',
              ingredientName: 'Tomate',
              quantity: 0.5,
              inputUnit: 'un'),
        ],
      );

      final ticket = ProductCalculator.calculate(product, {'tomate': tomate});
      final line = ticket.lines.first;

      expect(line.inconvertible, false);
      expect(line.missing, false);
      expect(line.lineCost, closeTo(0.72, 1e-9));
      expect(ticket.ingredientsTotal, closeTo(0.72, 1e-9));
      expect(ticket.hasMissingIngredients, false);
    });

    test('cenário tomate: R\$ 10/kg, 60 g, Desperdício 3% custa ~R\$ 0,62', () {
      final tomate = _sebraeIngredient(
        id: 'tomate',
        name: 'Tomate',
        unit: IngredientUnit.grama,
        purchasePrice: 10,
        packageQuantity: 1000,
        correctionFactor: SebraeRules.factorFromWastePercent(3),
      );
      final product = _product(
        id: 'p1',
        recipe: [
          RecipeItem(
              ingredientId: 'tomate',
              ingredientName: 'Tomate',
              quantity: 60,
              inputUnit: 'g'),
        ],
      );

      final ticket = ProductCalculator.calculate(product, {'tomate': tomate});
      final line = ticket.lines.first;

      expect(line.inconvertible, false);
      expect(line.missing, false);
      expect(line.lineCost, closeTo(0.62, 0.005));
      expect(ticket.ingredientsTotal, closeTo(0.62, 0.005));
      expect(ticket.hasMissingIngredients, false);
    });

    test('mesmo cenário sem Desperdício custa R\$ 0,48', () {
      final tomate = _sebraeIngredient(
        id: 'tomate',
        name: 'Tomate',
        unit: IngredientUnit.kilo,
        purchasePrice: 8,
        packageQuantity: 1,
        averageUnitWeightGrams: 120,
        correctionFactor: 1.0,
      );
      final product = _product(
        id: 'p1',
        recipe: [
          RecipeItem(
              ingredientId: 'tomate',
              ingredientName: 'Tomate',
              quantity: 0.5,
              inputUnit: 'un'),
        ],
      );

      final ticket = ProductCalculator.calculate(product, {'tomate': tomate});

      expect(ticket.lines.first.lineCost, closeTo(0.48, 1e-9));
      expect(ticket.ingredientsTotal, closeTo(0.48, 1e-9));
    });

    test('item legado sem inputUnit e FC 1,0 mantém o comportamento antigo', () {
      final farinha = _sebraeIngredient(
        id: 'farinha',
        name: 'Farinha',
        unit: IngredientUnit.kilo,
        purchasePrice: 10,
        packageQuantity: 2,
        averageUnitWeightGrams: 120,
        correctionFactor: 1.0,
      );
      final product = _product(
        id: 'p1',
        recipe: [
          RecipeItem(
              ingredientId: 'farinha', ingredientName: 'Farinha', quantity: 3),
        ],
      );

      final ticket =
          ProductCalculator.calculate(product, {'farinha': farinha});
      final line = ticket.lines.first;

      expect(line.inconvertible, false);
      expect(line.unitPrice, 5.0);
      expect(line.lineCost, 15.0);
      expect(ticket.ingredientsTotal, 15.0);
      expect(ticket.hasMissingIngredients, false);
    });

    test('un sem Peso Médio é inconvertível: custo zero e fora do total', () {
      final tomate = _sebraeIngredient(
        id: 'tomate',
        name: 'Tomate',
        unit: IngredientUnit.kilo,
        purchasePrice: 8,
        packageQuantity: 1,
        correctionFactor: 1.5,
      );
      final product = _product(
        id: 'p1',
        recipe: [
          RecipeItem(
              ingredientId: 'tomate',
              ingredientName: 'Tomate',
              quantity: 0.5,
              inputUnit: 'un'),
        ],
      );

      final ticket = ProductCalculator.calculate(product, {'tomate': tomate});
      final line = ticket.lines.first;

      expect(line.inconvertible, true);
      expect(line.missing, false);
      expect(line.lineCost, 0.0);
      expect(ticket.ingredientsTotal, 0.0);
      expect(ticket.hasMissingIngredients, false);
    });

    test('volume com Desperdício 33% ignora o Desperdício no custo', () {
      final leite = _sebraeIngredient(
        id: 'leite',
        name: 'Leite',
        unit: IngredientUnit.mililitro,
        purchasePrice: 10,
        packageQuantity: 1000,
        correctionFactor: 1.5,
      );
      final product = _product(
        id: 'p1',
        recipe: [
          RecipeItem(
              ingredientId: 'leite', ingredientName: 'Leite', quantity: 1, inputUnit: 'L'),
        ],
      );

      final ticket = ProductCalculator.calculate(product, {'leite': leite});
      final line = ticket.lines.first;

      expect(line.inconvertible, false);
      expect(line.lineCost, closeTo(10.0, 1e-9));
      expect(ticket.ingredientsTotal, closeTo(10.0, 1e-9));
    });
  });

  group('ProductCalculator com custos extras desagregados', () {
    test('comissao de 10% sobre venda R\$ 25 reduz lucro em 2,5', () {
      final product = _product(
        id: 'p1',
        recipe: [],
        salePrice: 25,
        commissionPercent: 10,
      );

      final ticket = ProductCalculator.calculate(product, {});

      expect(ticket.commissionCost, 2.5);
      expect(ticket.laborCost, 2.5);
      expect(ticket.totalCost, 2.5);
      expect(ticket.profit, 22.5);
    });

    test('comissao com preco de venda zero fica zero', () {
      final product = _product(
        id: 'p1',
        recipe: [],
        salePrice: 0,
        commissionPercent: 10,
      );

      final ticket = ProductCalculator.calculate(product, {});

      expect(ticket.commissionCost, 0.0);
      expect(ticket.laborCost, 0.0);
      expect(ticket.totalCost, 0.0);
    });

    test('diarista 2 dias x R\$ 100 custa 200', () {
      final product = _product(
        id: 'p1',
        recipe: [],
        salePrice: 500,
        dailyRate: 100,
        dailyDays: 2,
      );

      final ticket = ProductCalculator.calculate(product, {});

      expect(ticket.dailyCost, 200.0);
      expect(ticket.laborCost, 200.0);
      expect(ticket.totalCost, 200.0);
      expect(ticket.profit, 300.0);
    });

    test('horista 3h x R\$ 25 custa 75', () {
      final product = _product(
        id: 'p1',
        recipe: [],
        salePrice: 200,
        hourlyRate: 25,
        hourlyHours: 3,
      );

      final ticket = ProductCalculator.calculate(product, {});

      expect(ticket.hourlyCost, 75.0);
      expect(ticket.laborCost, 75.0);
      expect(ticket.totalCost, 75.0);
      expect(ticket.profit, 125.0);
    });

    test('soma dos tres custos no laborCost e totalCost', () {
      final product = _product(
        id: 'p1',
        recipe: [],
        salePrice: 1000,
        dailyRate: 100,
        dailyDays: 1,
        hourlyRate: 25,
        hourlyHours: 2,
        commissionPercent: 5,
      );

      final ticket = ProductCalculator.calculate(product, {});

      expect(ticket.dailyCost, 100.0);
      expect(ticket.hourlyCost, 50.0);
      expect(ticket.commissionCost, 50.0);
      expect(ticket.laborCost, 200.0);
      expect(ticket.totalCost, 200.0);
      expect(ticket.profit, 800.0);
    });

    test('fromMap legado com laborCost mapeia para diarista', () {
      final product = Product.fromMap('p_legacy', <String, dynamic>{
        'name': 'Produto antigo',
        'description': '',
        'recipe': [],
        'laborCost': 30.0,
        'packagingCost': 0.0,
        'salePrice': 100.0,
        'createdAt': DateTime(2024, 1, 1).toIso8601String(),
      });

      expect(product.dailyRate, 30.0);
      expect(product.dailyDays, 1.0);
      expect(product.hourlyRate, 0.0);
      expect(product.commissionPercent, 0.0);
      expect(product.laborCost, 30.0);
    });
  });
}
