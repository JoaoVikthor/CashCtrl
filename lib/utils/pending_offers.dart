import '../models/ingredient_offer.dart';
import 'offer_rules.dart';

class PendingOfferValidation {
  final IngredientOffer? offer;
  final String? supplierError;
  final String? priceError;
  final String? quantityError;

  const PendingOfferValidation({
    this.offer,
    this.supplierError,
    this.priceError,
    this.quantityError,
  });

  bool get isValid => offer != null;

  String? get firstError => supplierError ?? priceError ?? quantityError;
}

double parseOfferNumber(String input) {
  return double.tryParse(input.trim().replaceAll(',', '.')) ?? 0;
}

PendingOfferValidation buildPendingOffer({
  required String supplier,
  required String productName,
  required String priceInput,
  required String quantityInput,
  DateTime? now,
}) {
  final trimmedSupplier = supplier.trim();
  if (trimmedSupplier.isEmpty) {
    return const PendingOfferValidation(
      supplierError: 'Informe o nome do fornecedor.',
    );
  }

  final price = parseOfferNumber(priceInput);
  if (price <= 0) {
    return const PendingOfferValidation(
      priceError: 'Informe um preço maior que zero.',
    );
  }

  final qty = parseOfferNumber(quantityInput);
  if (qty <= 0) {
    return const PendingOfferValidation(
      quantityError: 'Informe uma quantidade maior que zero.',
    );
  }

  final timestamp = now ?? DateTime.now();
  return PendingOfferValidation(
    offer: IngredientOffer(
      id: '',
      supplier: trimmedSupplier,
      productName: productName.trim(),
      packagePrice: price,
      packageQuantity: qty,
      isActive: true,
      source: 'manual',
      createdAt: timestamp,
      updatedAt: timestamp,
    ),
  );
}

bool pendingOffersHasSupplier(
  List<IngredientOffer> offers,
  String supplier,
) {
  final target = supplier.trim().toLowerCase();
  if (target.isEmpty) return false;
  return offers.any((o) => o.supplier.trim().toLowerCase() == target);
}

bool canAddPendingOffer(int currentCount) {
  return currentCount < maxOffersPerIngredient;
}
