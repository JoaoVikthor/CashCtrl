import '../models/price_audit_log.dart';

class AuditBuilder {
  const AuditBuilder._();

  static PriceAuditLog ingredientCreate({
    required String entityId,
    required String name,
    required double purchasePrice,
  }) =>
      PriceAuditLog(
        action: 'ingredient.create',
        entityType: 'ingredient',
        entityId: entityId,
        summary: 'Produto $name criado',
        newPrice: purchasePrice,
      );

  static PriceAuditLog ingredientUpdate({
    required String entityId,
    required String name,
    required double purchasePrice,
  }) =>
      PriceAuditLog(
        action: 'ingredient.update',
        entityType: 'ingredient',
        entityId: entityId,
        summary: 'Produto $name atualizado',
        newPrice: purchasePrice,
      );

  static PriceAuditLog ingredientDelete({
    required String entityId,
  }) =>
      PriceAuditLog(
        action: 'ingredient.delete',
        entityType: 'ingredient',
        entityId: entityId,
        summary: 'Produto removido',
      );

  static PriceAuditLog offerCreate({
    required String entityId,
    required String supplier,
    required double packagePrice,
    required double pricePerUnit,
    required String source,
  }) =>
      PriceAuditLog(
        action: 'offer.create',
        entityType: 'offer',
        entityId: entityId,
        summary: 'Oferta de $supplier criada',
        supplier: supplier,
        newPrice: packagePrice,
        pricePerUnit: pricePerUnit,
        source: source,
      );

  static PriceAuditLog offerUpdate({
    required String entityId,
    required String supplier,
    required double previousPrice,
    required double newPrice,
    required double pricePerUnit,
    required String source,
  }) =>
      PriceAuditLog(
        action: 'offer.update',
        entityType: 'offer',
        entityId: entityId,
        summary: 'Oferta de $supplier atualizada',
        supplier: supplier,
        previousPrice: previousPrice,
        newPrice: newPrice,
        pricePerUnit: pricePerUnit,
        source: source,
      );

  static PriceAuditLog offerSetActive({
    required String entityId,
    required String supplier,
    required double packagePrice,
    required double pricePerUnit,
    required String source,
  }) =>
      PriceAuditLog(
        action: 'offer.setActive',
        entityType: 'offer',
        entityId: entityId,
        summary:
            'Oferta de $supplier definida como ativa — ${pricePerUnit.toStringAsFixed(2)}/un',
        supplier: supplier,
        newPrice: packagePrice,
        pricePerUnit: pricePerUnit,
        source: source,
      );

  static PriceAuditLog offerToggleActive({
    required String entityId,
    required String supplier,
    required bool isActive,
    required double packagePrice,
    required double pricePerUnit,
    required String source,
    required bool wasActive,
  }) =>
      PriceAuditLog(
        action: 'offer.toggleActive',
        entityType: 'offer',
        entityId: entityId,
        summary: wasActive && !isActive
            ? 'Oferta de $supplier desativada; ticket volta ao preço base'
            : 'Oferta de $supplier ${isActive ? 'ativada' : 'desativada'}',
        supplier: supplier,
        previousPrice: packagePrice,
        newPrice: isActive ? packagePrice : null,
        pricePerUnit: pricePerUnit,
        source: source,
      );

  static PriceAuditLog offerDelete({
    required String entityId,
    required String supplier,
    required double packagePrice,
    required double pricePerUnit,
    required String source,
  }) =>
      PriceAuditLog(
        action: 'offer.delete',
        entityType: 'offer',
        entityId: entityId,
        summary: 'Oferta de $supplier removida',
        supplier: supplier,
        previousPrice: packagePrice,
        pricePerUnit: pricePerUnit,
        source: source,
      );

  static PriceAuditLog productCreate({
    required String entityId,
    required String name,
    required double salePrice,
  }) =>
      PriceAuditLog(
        action: 'product.create',
        entityType: 'product',
        entityId: entityId,
        summary:
            'Ficha técnica $name criada · ${salePrice.toStringAsFixed(2)}',
        newPrice: salePrice,
      );

  static PriceAuditLog productUpdate({
    required String entityId,
    required String name,
    required double? previousSalePrice,
    required double newSalePrice,
  }) =>
      PriceAuditLog(
        action: 'product.update',
        entityType: 'product',
        entityId: entityId,
        summary: previousSalePrice != null
            ? 'Ficha técnica $name atualizada · ${previousSalePrice.toStringAsFixed(2)} → ${newSalePrice.toStringAsFixed(2)}'
            : 'Ficha técnica $name atualizada · ${newSalePrice.toStringAsFixed(2)}',
        previousPrice: previousSalePrice,
        newPrice: newSalePrice,
      );

  static PriceAuditLog productDelete({
    required String entityId,
    required String name,
    required double? salePrice,
  }) =>
      PriceAuditLog(
        action: 'product.delete',
        entityType: 'product',
        entityId: entityId,
        summary: salePrice != null
            ? 'Ficha técnica $name removida · ${salePrice.toStringAsFixed(2)}'
            : 'Ficha técnica $name removida',
        previousPrice: salePrice,
      );

  static PriceAuditLog migration({
    required String entityId,
    required String summary,
    required double newPrice,
    required double pricePerUnit,
  }) =>
      PriceAuditLog(
        action: 'migration',
        entityType: 'migration',
        entityId: entityId,
        summary: summary,
        newPrice: newPrice,
        pricePerUnit: pricePerUnit,
        source: 'migration',
      );
}
