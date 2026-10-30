import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctrlcash/models/ingredient.dart';
import 'package:ctrlcash/models/ingredient_offer.dart';
import 'package:ctrlcash/models/price_audit_log.dart';
import 'package:ctrlcash/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Product roundtrip', () {
    test('toMap seguido de fromMap preserva todos os campos', () {
      final original = Product(
        id: 'prod1',
        name: 'Bolo de Chocolate',
        description: 'Bolo caseiro',
        recipe: [
          RecipeItem(ingredientId: 'farinha', ingredientName: 'Farinha', quantity: 500, inputUnit: 'g'),
          RecipeItem(ingredientId: 'acucar', ingredientName: 'Acucar', quantity: 200, inputUnit: 'kg'),
        ],
        dailyRate: 15.0,
        dailyDays: 1.0,
        hourlyRate: 0.0,
        hourlyHours: 0.0,
        commissionPercent: 0.0,
        packagingCost: 5.5,
        salePrice: 80.0,
        barcode: '7891234567890',
        createdAt: DateTime(2024, 6, 15, 10, 30),
      );

      final map = original.toMap();
      final restored = Product.fromMap('prod1', map);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.recipe.length, original.recipe.length);
      expect(restored.recipe[0].ingredientId, original.recipe[0].ingredientId);
      expect(restored.recipe[0].ingredientName, original.recipe[0].ingredientName);
      expect(restored.recipe[0].quantity, original.recipe[0].quantity);
      expect(restored.recipe[0].inputUnit, original.recipe[0].inputUnit);
      expect(restored.recipe[1].quantity, original.recipe[1].quantity);
      expect(restored.recipe[1].inputUnit, original.recipe[1].inputUnit);
      expect(restored.dailyRate, original.dailyRate);
      expect(restored.dailyDays, original.dailyDays);
      expect(restored.hourlyRate, original.hourlyRate);
      expect(restored.hourlyHours, original.hourlyHours);
      expect(restored.commissionPercent, original.commissionPercent);
      expect(restored.laborCost, original.laborCost);
      expect(restored.packagingCost, original.packagingCost);
      expect(restored.salePrice, original.salePrice);
      expect(restored.barcode, original.barcode);
      expect(restored.createdAt, original.createdAt);
      expect(restored.toMap(), map);
      expect(map['laborCost'], original.laborCost);
    });

    test('toMap inclui laborCost como espelho derivado', () {
      final product = Product(
        id: 'prod2',
        name: 'Torta',
        description: '',
        recipe: [],
        dailyRate: 100.0,
        dailyDays: 2.0,
        hourlyRate: 25.0,
        hourlyHours: 3.0,
        commissionPercent: 10.0,
        packagingCost: 5.0,
        salePrice: 500.0,
        createdAt: DateTime(2024, 6, 15),
      );

      final map = product.toMap();

      expect(map['dailyRate'], 100.0);
      expect(map['dailyDays'], 2.0);
      expect(map['hourlyRate'], 25.0);
      expect(map['hourlyHours'], 3.0);
      expect(map['commissionPercent'], 10.0);
      expect(map['laborCost'], 325.0);
    });
  });

  group('Ingredient roundtrip', () {
    test('toMap seguido de fromMap preserva campos base e offers', () {
      final now = DateTime(2024, 6, 15, 10, 30);
      final offer = IngredientOffer(
        id: 'o1',
        supplier: 'Fornecedor A',
        productName: 'Farinha Especial 1kg',
        packagePrice: 45.0,
        packageQuantity: 2.5,
        isActive: true,
        source: 'manual',
        notes: 'Oferta principal',
        createdAt: now,
        updatedAt: now,
      );
      final original = Ingredient(
        id: 'ing1',
        name: 'Farinha Especial',
        unit: IngredientUnit.kilo,
        purchasePrice: 50.0,
        packageQuantity: 1,
        createdAt: now,
        offers: [offer],
        activeOfferId: 'o1',
        averageUnitWeightGrams: 1000.0,
        correctionFactor: 1.05,
      );

      final map = original.toMap();
      final restored = Ingredient.fromMap('ing1', map);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.unit, original.unit);
      expect(restored.purchasePrice, original.purchasePrice);
      expect(restored.packageQuantity, original.packageQuantity);
      expect(restored.createdAt, original.createdAt);
      expect(restored.activeOfferId, original.activeOfferId);
      expect(restored.averageUnitWeightGrams, original.averageUnitWeightGrams);
      expect(restored.correctionFactor, original.correctionFactor);
      expect(restored.offers.length, 1);
      expect(restored.offers[0].id, offer.id);
      expect(restored.offers[0].supplier, offer.supplier);
      expect(restored.offers[0].productName, offer.productName);
      expect(restored.offers[0].packagePrice, offer.packagePrice);
      expect(restored.offers[0].packageQuantity, offer.packageQuantity);
      expect(restored.offers[0].isActive, offer.isActive);
      expect(restored.offers[0].source, offer.source);
      expect(restored.offers[0].notes, offer.notes);
      expect(restored.offers[0].createdAt, offer.createdAt);
      expect(restored.offers[0].updatedAt, offer.updatedAt);
      expect(restored.toMap(), map);
    });

    test('documento legado sem chaves novas usa defaults corretos', () {
      final legacyMap = <String, dynamic>{
        'name': 'Acucar',
        'unit': 'kg',
        'purchasePrice': 10.0,
        'packageQuantity': 1.0,
        'createdAt': DateTime(2024, 6, 15, 10, 30).toIso8601String(),
        'offers': [],
      };

      final restored = Ingredient.fromMap('ing_legacy', legacyMap);

      expect(restored.averageUnitWeightGrams, isNull);
      expect(restored.correctionFactor, 1.0);
      expect(restored.toMap()['averageUnitWeightGrams'], isNull);
      expect(restored.toMap()['correctionFactor'], 1.0);
    });

    test('correctionFactor invalido ou <= 0 vira 1.0', () {
      final baseMap = <String, dynamic>{
        'name': 'Farinha',
        'unit': 'kg',
        'purchasePrice': 20.0,
        'packageQuantity': 1.0,
        'createdAt': DateTime(2024, 6, 15, 10, 30).toIso8601String(),
        'offers': [],
      };

      final zero = Ingredient.fromMap('ing_zero', {...baseMap, 'correctionFactor': 0.0});
      final negative = Ingredient.fromMap('ing_neg', {...baseMap, 'correctionFactor': -2.0});
      final text = Ingredient.fromMap('ing_text', {...baseMap, 'correctionFactor': 'invalido'});

      expect(zero.correctionFactor, 1.0);
      expect(negative.correctionFactor, 1.0);
      expect(text.correctionFactor, 1.0);
    });

    test('averageUnitWeightGrams <= 0 ou nao numerico vira null', () {
      final baseMap = <String, dynamic>{
        'name': 'Farinha',
        'unit': 'kg',
        'purchasePrice': 20.0,
        'packageQuantity': 1.0,
        'createdAt': DateTime(2024, 6, 15, 10, 30).toIso8601String(),
        'offers': [],
      };

      final zero = Ingredient.fromMap('ing_w0', {...baseMap, 'averageUnitWeightGrams': 0.0});
      final negative = Ingredient.fromMap('ing_wneg', {...baseMap, 'averageUnitWeightGrams': -100.0});
      final text = Ingredient.fromMap('ing_wtext', {...baseMap, 'averageUnitWeightGrams': 'pesado'});

      expect(zero.averageUnitWeightGrams, isNull);
      expect(negative.averageUnitWeightGrams, isNull);
      expect(text.averageUnitWeightGrams, isNull);
    });

    test('copyWith limpa averageUnitWeightGrams para null via sentinela', () {
      final original = Ingredient(
        id: 'ing1',
        name: 'Ovo',
        unit: IngredientUnit.unidade,
        purchasePrice: 12.0,
        packageQuantity: 12,
        createdAt: DateTime(2024, 6, 15),
        averageUnitWeightGrams: 55.0,
      );

      final cleared = original.copyWith(averageUnitWeightGrams: null);

      expect(cleared.averageUnitWeightGrams, isNull);
      expect(cleared.correctionFactor, original.correctionFactor);
      expect(cleared.name, original.name);
    });

    test('copyWith preserva averageUnitWeightGrams quando sentinela nao e passada', () {
      final original = Ingredient(
        id: 'ing1',
        name: 'Ovo',
        unit: IngredientUnit.unidade,
        purchasePrice: 12.0,
        packageQuantity: 12,
        createdAt: DateTime(2024, 6, 15),
        averageUnitWeightGrams: 55.0,
      );

      final updated = original.copyWith(name: 'Ovo Grande');

      expect(updated.averageUnitWeightGrams, 55.0);
    });
  });

  group('RecipeItem roundtrip', () {
    test('toMap seguido de fromMap preserva inputUnit', () {
      final original = RecipeItem(
        ingredientId: 'leite',
        ingredientName: 'Leite',
        quantity: 250,
        inputUnit: 'ml',
      );

      final map = original.toMap();
      final restored = RecipeItem.fromMap(map);

      expect(restored.ingredientId, original.ingredientId);
      expect(restored.ingredientName, original.ingredientName);
      expect(restored.quantity, original.quantity);
      expect(restored.inputUnit, original.inputUnit);
      expect(restored.toMap(), map);
    });

    test('documento legado sem inputUnit mantem null', () {
      final legacyMap = <String, dynamic>{
        'ingredientId': 'manteiga',
        'ingredientName': 'Manteiga',
        'quantity': 100,
      };

      final restored = RecipeItem.fromMap(legacyMap);

      expect(restored.inputUnit, isNull);
      expect(restored.toMap()['inputUnit'], isNull);
    });
  });

  group('IngredientOffer roundtrip', () {
    test('toMap seguido de fromMap preserva productName', () {
      final now = DateTime(2024, 6, 15, 10, 30);
      final original = IngredientOffer(
        id: 'o1',
        supplier: 'Distribuidora Central',
        productName: 'Farinha Dona Benta 1kg',
        packagePrice: 6.5,
        packageQuantity: 1,
        isActive: true,
        source: 'manual',
        notes: 'Embalagem de 1kg',
        createdAt: now,
        updatedAt: now,
      );

      final map = original.toMap();
      final restored = IngredientOffer.fromMap(map);

      expect(restored.productName, 'Farinha Dona Benta 1kg');
      expect(restored.hasProductName, isTrue);
      expect(restored.toMap(), map);
    });

    test('fromMap sem productName mantem legado com string vazia', () {
      final now = DateTime(2024, 6, 15, 10, 30);
      final legacyMap = <String, dynamic>{
        'id': 'o1',
        'supplier': 'Fornecedor A',
        'packagePrice': 10.0,
        'packageQuantity': 1.0,
        'isActive': true,
        'source': 'manual',
        'notes': '',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      final restored = IngredientOffer.fromMap(legacyMap);

      expect(restored.productName, '');
      expect(restored.hasProductName, isFalse);
      expect(restored.supplier, 'Fornecedor A');
      expect(restored.packagePrice, 10.0);
    });

    test('copyWith atualiza productName sem perder demais campos', () {
      final now = DateTime(2024, 6, 15, 10, 30);
      final original = IngredientOffer(
        id: 'o1',
        supplier: 'Fornecedor A',
        packagePrice: 10.0,
        packageQuantity: 1,
        createdAt: now,
        updatedAt: now,
      );

      final updated = original.copyWith(
        productName: 'Açúcar Refinado 5kg',
        updatedAt: now.add(const Duration(days: 1)),
      );

      expect(updated.productName, 'Açúcar Refinado 5kg');
      expect(updated.supplier, original.supplier);
      expect(updated.createdAt, original.createdAt);
    });
  });

  group('PriceAuditLog roundtrip', () {
    test('toMap e fromMap preservam campos estaticos', () {
      final now = DateTime(2024, 6, 15, 10, 30);
      final expireAt = DateTime(2025, 6, 15);
      final original = PriceAuditLog(
        action: 'update',
        entityType: 'ingredient',
        entityId: 'ing1',
        summary: 'Preco atualizado',
        supplier: 'Fornecedor A',
        previousPrice: 40.0,
        newPrice: 45.0,
        pricePerUnit: 18.0,
        source: 'manual',
        timestamp: now,
      );

      final map = original.toMap(expireAt);
      final firestoreMap = Map<String, dynamic>.from(map);
      firestoreMap['timestamp'] = Timestamp.fromDate(now);
      final restored = PriceAuditLog.fromMap(firestoreMap);

      expect(restored.action, original.action);
      expect(restored.entityType, original.entityType);
      expect(restored.entityId, original.entityId);
      expect(restored.summary, original.summary);
      expect(restored.supplier, original.supplier);
      expect(restored.previousPrice, original.previousPrice);
      expect(restored.newPrice, original.newPrice);
      expect(restored.pricePerUnit, original.pricePerUnit);
      expect(restored.source, original.source);
      expect(restored.timestamp, original.timestamp);
      expect((map['expireAt'] as Timestamp).toDate(), expireAt);
    });
  });
}
