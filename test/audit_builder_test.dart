import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctrlcash/models/price_audit_log.dart';
import 'package:ctrlcash/utils/audit_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void _assertBaseMap(
  Map<String, dynamic> map,
  PriceAuditLog log,
  DateTime expireAt,
) {
  expect(map['action'], log.action);
  expect(map['entityType'], log.entityType);
  expect(map['entityId'], log.entityId);
  expect(map['summary'], log.summary);
  expect(map['supplier'], log.supplier);
  expect(map['previousPrice'], log.previousPrice);
  expect(map['newPrice'], log.newPrice);
  expect(map['pricePerUnit'], log.pricePerUnit);
  expect(map['source'], log.source);
  expect(map['timestamp'], isA<FieldValue>());
  expect(map['expireAt'], isA<Timestamp>());
  expect((map['expireAt'] as Timestamp).toDate(), expireAt);
}

void main() {
  group('AuditBuilder.ingredientCreate', () {
    test('preenche campos e toMap corretamente', () {
      final createdAt = DateTime(2024, 6, 15);
      final expireAt = createdAt.add(const Duration(days: 180));
      final log = AuditBuilder.ingredientCreate(
        entityId: 'ing1',
        name: 'Farinha',
        purchasePrice: 12.0,
      );

      expect(log.action, 'ingredient.create');
      expect(log.entityType, 'ingredient');
      expect(log.entityId, 'ing1');
      expect(log.summary, 'Produto Farinha criado');
      expect(log.newPrice, 12.0);
      expect(log.previousPrice, isNull);

      final map = log.toMap(expireAt);
      _assertBaseMap(map, log, expireAt);
    });
  });

  group('AuditBuilder.ingredientUpdate', () {
    test('preenche campos e toMap corretamente', () {
      final createdAt = DateTime(2024, 6, 15);
      final expireAt = createdAt.add(const Duration(days: 180));
      final log = AuditBuilder.ingredientUpdate(
        entityId: 'ing1',
        name: 'Farinha',
        purchasePrice: 14.0,
      );

      expect(log.action, 'ingredient.update');
      expect(log.entityType, 'ingredient');
      expect(log.entityId, 'ing1');
      expect(log.summary, 'Produto Farinha atualizado');
      expect(log.newPrice, 14.0);
      expect(log.previousPrice, isNull);

      final map = log.toMap(expireAt);
      _assertBaseMap(map, log, expireAt);
    });
  });

  group('AuditBuilder.ingredientDelete', () {
    test('preenche campos e toMap corretamente', () {
      final createdAt = DateTime(2024, 6, 15);
      final expireAt = createdAt.add(const Duration(days: 180));
      final log = AuditBuilder.ingredientDelete(entityId: 'ing1');

      expect(log.action, 'ingredient.delete');
      expect(log.entityType, 'ingredient');
      expect(log.entityId, 'ing1');
      expect(log.summary, 'Produto removido');
      expect(log.newPrice, isNull);
      expect(log.previousPrice, isNull);

      final map = log.toMap(expireAt);
      _assertBaseMap(map, log, expireAt);
    });
  });

  group('AuditBuilder.offerCreate', () {
    test('preenche campos e toMap corretamente', () {
      final createdAt = DateTime(2024, 6, 15);
      final expireAt = createdAt.add(const Duration(days: 180));
      final log = AuditBuilder.offerCreate(
        entityId: 'o1',
        supplier: 'Fornecedor A',
        packagePrice: 100.0,
        pricePerUnit: 10.0,
        source: 'manual',
      );

      expect(log.action, 'offer.create');
      expect(log.entityType, 'offer');
      expect(log.entityId, 'o1');
      expect(log.summary, 'Oferta de Fornecedor A criada');
      expect(log.supplier, 'Fornecedor A');
      expect(log.newPrice, 100.0);
      expect(log.pricePerUnit, 10.0);
      expect(log.previousPrice, isNull);
      expect(log.source, 'manual');

      final map = log.toMap(expireAt);
      _assertBaseMap(map, log, expireAt);
    });
  });

  group('AuditBuilder.offerUpdate', () {
    test('preenche campos e toMap corretamente', () {
      final createdAt = DateTime(2024, 6, 15);
      final expireAt = createdAt.add(const Duration(days: 180));
      final log = AuditBuilder.offerUpdate(
        entityId: 'o1',
        supplier: 'Fornecedor A',
        previousPrice: 90.0,
        newPrice: 100.0,
        pricePerUnit: 10.0,
        source: 'manual',
      );

      expect(log.action, 'offer.update');
      expect(log.entityType, 'offer');
      expect(log.entityId, 'o1');
      expect(log.summary, 'Oferta de Fornecedor A atualizada');
      expect(log.supplier, 'Fornecedor A');
      expect(log.previousPrice, 90.0);
      expect(log.newPrice, 100.0);
      expect(log.pricePerUnit, 10.0);

      final map = log.toMap(expireAt);
      _assertBaseMap(map, log, expireAt);
    });
  });

  group('AuditBuilder.offerSetActive', () {
    test('preenche campos e toMap corretamente', () {
      final createdAt = DateTime(2024, 6, 15);
      final expireAt = createdAt.add(const Duration(days: 180));
      final log = AuditBuilder.offerSetActive(
        entityId: 'o1',
        supplier: 'Fornecedor A',
        packagePrice: 100.0,
        pricePerUnit: 10.0,
        source: 'manual',
      );

      expect(log.action, 'offer.setActive');
      expect(log.entityType, 'offer');
      expect(log.entityId, 'o1');
      expect(log.summary, 'Oferta de Fornecedor A definida como ativa — 10.00/un');
      expect(log.newPrice, 100.0);
      expect(log.pricePerUnit, 10.0);

      final map = log.toMap(expireAt);
      _assertBaseMap(map, log, expireAt);
    });
  });

  group('AuditBuilder.offerToggleActive', () {
    test('desativacao com wasActive true gera resumo de volta ao preco base', () {
      final createdAt = DateTime(2024, 6, 15);
      final expireAt = createdAt.add(const Duration(days: 180));
      final log = AuditBuilder.offerToggleActive(
        entityId: 'o1',
        supplier: 'Fornecedor A',
        isActive: false,
        packagePrice: 100.0,
        pricePerUnit: 10.0,
        source: 'manual',
        wasActive: true,
      );

      expect(log.action, 'offer.toggleActive');
      expect(log.summary, 'Oferta de Fornecedor A desativada; ticket volta ao preço base');
      expect(log.previousPrice, 100.0);
      expect(log.newPrice, isNull);

      final map = log.toMap(expireAt);
      _assertBaseMap(map, log, expireAt);
    });

    test('ativacao define newPrice igual ao packagePrice', () {
      final createdAt = DateTime(2024, 6, 15);
      final expireAt = createdAt.add(const Duration(days: 180));
      final log = AuditBuilder.offerToggleActive(
        entityId: 'o1',
        supplier: 'Fornecedor A',
        isActive: true,
        packagePrice: 100.0,
        pricePerUnit: 10.0,
        source: 'manual',
        wasActive: false,
      );

      expect(log.summary, 'Oferta de Fornecedor A ativada');
      expect(log.newPrice, 100.0);

      final map = log.toMap(expireAt);
      _assertBaseMap(map, log, expireAt);
    });
  });

  group('AuditBuilder.offerDelete', () {
    test('preenche campos e toMap corretamente', () {
      final createdAt = DateTime(2024, 6, 15);
      final expireAt = createdAt.add(const Duration(days: 180));
      final log = AuditBuilder.offerDelete(
        entityId: 'o1',
        supplier: 'Fornecedor A',
        packagePrice: 100.0,
        pricePerUnit: 10.0,
        source: 'manual',
      );

      expect(log.action, 'offer.delete');
      expect(log.summary, 'Oferta de Fornecedor A removida');
      expect(log.previousPrice, 100.0);
      expect(log.newPrice, isNull);

      final map = log.toMap(expireAt);
      _assertBaseMap(map, log, expireAt);
    });
  });

  group('AuditBuilder.productCreate', () {
    test('preenche campos e toMap corretamente', () {
      final createdAt = DateTime(2024, 6, 15);
      final expireAt = createdAt.add(const Duration(days: 180));
      final log = AuditBuilder.productCreate(
        entityId: 'p1',
        name: 'Bolo',
        salePrice: 35.0,
      );

      expect(log.action, 'product.create');
      expect(log.entityType, 'product');
      expect(log.entityId, 'p1');
      expect(log.summary, 'Ficha técnica Bolo criada · 35.00');
      expect(log.newPrice, 35.0);
      expect(log.previousPrice, isNull);

      final map = log.toMap(expireAt);
      _assertBaseMap(map, log, expireAt);
    });
  });

  group('AuditBuilder.productUpdate', () {
    test('com previousSalePrice mostra seta de evolucao', () {
      final createdAt = DateTime(2024, 6, 15);
      final expireAt = createdAt.add(const Duration(days: 180));
      final log = AuditBuilder.productUpdate(
        entityId: 'p1',
        name: 'Bolo',
        previousSalePrice: 30.0,
        newSalePrice: 35.0,
      );

      expect(log.action, 'product.update');
      expect(log.summary, 'Ficha técnica Bolo atualizada · 30.00 → 35.00');
      expect(log.previousPrice, 30.0);
      expect(log.newPrice, 35.0);

      final map = log.toMap(expireAt);
      _assertBaseMap(map, log, expireAt);
    });

    test('sem previousSalePrice omite seta', () {
      final createdAt = DateTime(2024, 6, 15);
      final expireAt = createdAt.add(const Duration(days: 180));
      final log = AuditBuilder.productUpdate(
        entityId: 'p1',
        name: 'Bolo',
        previousSalePrice: null,
        newSalePrice: 35.0,
      );

      expect(log.summary, 'Ficha técnica Bolo atualizada · 35.00');
      expect(log.previousPrice, isNull);
      expect(log.newPrice, 35.0);

      final map = log.toMap(expireAt);
      _assertBaseMap(map, log, expireAt);
    });
  });

  group('AuditBuilder.productDelete', () {
    test('com salePrice inclui valor no resumo', () {
      final createdAt = DateTime(2024, 6, 15);
      final expireAt = createdAt.add(const Duration(days: 180));
      final log = AuditBuilder.productDelete(
        entityId: 'p1',
        name: 'Bolo',
        salePrice: 35.0,
      );

      expect(log.action, 'product.delete');
      expect(log.summary, 'Ficha técnica Bolo removida · 35.00');
      expect(log.previousPrice, 35.0);
      expect(log.newPrice, isNull);

      final map = log.toMap(expireAt);
      _assertBaseMap(map, log, expireAt);
    });

    test('sem salePrice omite valor', () {
      final createdAt = DateTime(2024, 6, 15);
      final expireAt = createdAt.add(const Duration(days: 180));
      final log = AuditBuilder.productDelete(
        entityId: 'p1',
        name: 'Bolo',
        salePrice: null,
      );

      expect(log.summary, 'Ficha técnica Bolo removida');
      expect(log.previousPrice, isNull);

      final map = log.toMap(expireAt);
      _assertBaseMap(map, log, expireAt);
    });
  });

  group('AuditBuilder.migration', () {
    test('preenche campos e toMap corretamente', () {
      final createdAt = DateTime(2024, 6, 15);
      final expireAt = createdAt.add(const Duration(days: 180));
      final log = AuditBuilder.migration(
        entityId: 'ing1',
        summary: 'Migracao legada',
        newPrice: 12.0,
        pricePerUnit: 6.0,
      );

      expect(log.action, 'migration');
      expect(log.entityType, 'migration');
      expect(log.entityId, 'ing1');
      expect(log.summary, 'Migracao legada');
      expect(log.newPrice, 12.0);
      expect(log.pricePerUnit, 6.0);
      expect(log.source, 'migration');

      final map = log.toMap(expireAt);
      _assertBaseMap(map, log, expireAt);
    });
  });
}
