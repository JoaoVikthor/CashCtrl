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
          RecipeItem(ingredientId: 'farinha', ingredientName: 'Farinha', quantity: 500),
          RecipeItem(ingredientId: 'acucar', ingredientName: 'Acucar', quantity: 200),
        ],
        laborCost: 15.0,
        packagingCost: 5.5,
        salePrice: 80.0,
        barcode: '7891234567890',
        photoUrl: 'https://example.com/bolo.png',
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
      expect(restored.recipe[1].quantity, original.recipe[1].quantity);
      expect(restored.laborCost, original.laborCost);
      expect(restored.packagingCost, original.packagingCost);
      expect(restored.salePrice, original.salePrice);
      expect(restored.barcode, original.barcode);
      expect(restored.photoUrl, original.photoUrl);
      expect(restored.createdAt, original.createdAt);
      expect(restored.toMap(), map);
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
