import '../models/ingredient_offer.dart';

const int maxOffersPerIngredient = 15;

void ensureOfferLimit(int currentCount) {
  if (currentCount >= maxOffersPerIngredient) {
    throw StateError('Limite de $maxOffersPerIngredient ofertas por produto atingido.');
  }
}

class OfferUpsertResult {
  final List<IngredientOffer> offers;
  final String offerId;
  final bool isCreate;
  final IngredientOffer? previous;

  const OfferUpsertResult({
    required this.offers,
    required this.offerId,
    required this.isCreate,
    this.previous,
  });
}

OfferUpsertResult applyOfferUpsert(
  List<IngredientOffer> current,
  IngredientOffer offer, {
  required String newOfferId,
  DateTime? now,
}) {
  final normalizedSupplier = offer.supplier.trim().toLowerCase();
  final timestamp = now ?? DateTime.now();

  final idIndex = current.indexWhere((o) => o.id == offer.id);
  if (idIndex >= 0) {
    final existing = current[idIndex];
    final updated = IngredientOffer(
      id: existing.id,
      supplier: offer.supplier,
      productName: offer.productName,
      packagePrice: offer.packagePrice,
      packageQuantity: offer.packageQuantity,
      isActive: offer.isActive,
      source: offer.source,
      notes: offer.notes,
      createdAt: existing.createdAt,
      updatedAt: timestamp,
    );
    final result = List<IngredientOffer>.from(current);
    result[idIndex] = updated;
    return OfferUpsertResult(
      offers: result,
      offerId: existing.id,
      isCreate: false,
      previous: existing,
    );
  }

  final supplierIndex = current.indexWhere(
    (o) => o.supplier.trim().toLowerCase() == normalizedSupplier,
  );
  if (supplierIndex >= 0) {
    final existing = current[supplierIndex];
    final updated = IngredientOffer(
      id: existing.id,
      supplier: offer.supplier,
      productName: offer.productName,
      packagePrice: offer.packagePrice,
      packageQuantity: offer.packageQuantity,
      isActive: offer.isActive,
      source: offer.source,
      notes: offer.notes,
      createdAt: existing.createdAt,
      updatedAt: timestamp,
    );
    final result = List<IngredientOffer>.from(current);
    result[supplierIndex] = updated;
    return OfferUpsertResult(
      offers: result,
      offerId: existing.id,
      isCreate: false,
      previous: existing,
    );
  }

  ensureOfferLimit(current.length);
  final isFirst = current.isEmpty;
  final offerId = offer.id.isNotEmpty ? offer.id : newOfferId;
  final created = IngredientOffer(
    id: offerId,
    supplier: offer.supplier,
    productName: offer.productName,
    packagePrice: offer.packagePrice,
    packageQuantity: offer.packageQuantity,
    isActive: isFirst || offer.isActive,
    source: offer.source,
    notes: offer.notes,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
  final result = List<IngredientOffer>.from(current)..add(created);
  return OfferUpsertResult(
    offers: result,
    offerId: offerId,
    isCreate: true,
  );
}
