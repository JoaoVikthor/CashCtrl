import 'package:cloud_firestore/cloud_firestore.dart';

import 'ingredient_offer.dart';

/// Unidades de medida suportadas para os produtos.
enum IngredientUnit { grama, kilo, litro, mililitro, unidade, pacote }

extension IngredientUnitExt on IngredientUnit {
  String get label => switch (this) {
        IngredientUnit.grama => 'g',
        IngredientUnit.kilo => 'kg',
        IngredientUnit.litro => 'L',
        IngredientUnit.mililitro => 'ml',
        IngredientUnit.unidade => 'un',
        IngredientUnit.pacote => 'pct',
      };

  String get firestoreValue => switch (this) {
        IngredientUnit.grama => 'g',
        IngredientUnit.kilo => 'kg',
        IngredientUnit.litro => 'L',
        IngredientUnit.mililitro => 'ml',
        IngredientUnit.unidade => 'un',
        IngredientUnit.pacote => 'pct',
      };

  static IngredientUnit fromFirestore(String v) => switch (v) {
        'g' => IngredientUnit.grama,
        'kg' => IngredientUnit.kilo,
        'L' => IngredientUnit.litro,
        'ml' => IngredientUnit.mililitro,
        'un' => IngredientUnit.unidade,
        _ => IngredientUnit.pacote,
      };
}

/// Produto comprado para fabricar fichas tecnicas.
///
/// O usuario informa o [purchasePrice] (preco pago) e a [packageQuantity]
/// (quantidade da embalagem). O preco por unidade base e calculado em
/// [pricePerUnit] e usado pelas fichas tecnicas para o ticket do produto.
class Ingredient {
  final String id;
  final String name;
  final IngredientUnit unit;
  final double purchasePrice;
  final double packageQuantity;
  final DateTime createdAt;
  final List<IngredientOffer> offers;
  final String? activeOfferId;

  const Ingredient({
    required this.id,
    required this.name,
    required this.unit,
    required this.purchasePrice,
    required this.packageQuantity,
    required this.createdAt,
    this.offers = const [],
    this.activeOfferId,
  });

  IngredientOffer? get activeOffer {
    if (offers.isEmpty) return null;
    if (activeOfferId != null) {
      for (final o in offers) {
        if (o.id == activeOfferId && o.isActive) return o;
      }
    }
    for (final o in offers) {
      if (o.isActive) return o;
    }
    return null;
  }

  double get pricePerUnit =>
      activeOffer?.pricePerUnit ??
      (packageQuantity > 0 ? purchasePrice / packageQuantity : 0);

  int get offersCount => offers.length;

  double? get lowestActivePricePerUnit {
    final active = offers.where((o) => o.isActive);
    if (active.isEmpty) return null;
    return active.map((o) => o.pricePerUnit).reduce((a, b) => a < b ? a : b);
  }

  IngredientOffer? get bestActiveOffer {
    final active = offers.where((o) => o.isActive).toList();
    if (active.isEmpty) return null;
    active.sort((a, b) => a.pricePerUnit.compareTo(b.pricePerUnit));
    return active.first;
  }

  factory Ingredient.fromMap(String id, Map<String, dynamic> m) {
    final rawDate = m['createdAt'];
    DateTime date;
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is DateTime) {
      date = rawDate;
    } else if (rawDate is String) {
      date = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }
    final rawOffers = m['offers'];
    List<IngredientOffer> offers = const [];
    if (rawOffers is List) {
      offers = rawOffers
          .whereType<Map>()
          .map((e) =>
              IngredientOffer.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
    return Ingredient(
      id: id,
      name: (m['name'] ?? '') as String,
      unit: IngredientUnitExt.fromFirestore((m['unit'] ?? 'un') as String),
      purchasePrice: ((m['purchasePrice'] ?? 0) as num).toDouble(),
      packageQuantity: ((m['packageQuantity'] ?? 0) as num).toDouble(),
      createdAt: date,
      offers: offers,
      activeOfferId: m['activeOfferId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'unit': unit.firestoreValue,
        'purchasePrice': purchasePrice,
        'packageQuantity': packageQuantity,
        'createdAt': createdAt.toIso8601String(),
        'offers': offers.map((o) => o.toMap()).toList(),
        'activeOfferId': activeOfferId,
      };

  Ingredient copyWith({
    String? name,
    IngredientUnit? unit,
    double? purchasePrice,
    double? packageQuantity,
    DateTime? createdAt,
    List<IngredientOffer>? offers,
    String? activeOfferId,
  }) =>
      Ingredient(
        id: id,
        name: name ?? this.name,
        unit: unit ?? this.unit,
        purchasePrice: purchasePrice ?? this.purchasePrice,
        packageQuantity: packageQuantity ?? this.packageQuantity,
        createdAt: createdAt ?? this.createdAt,
        offers: offers ?? this.offers,
        activeOfferId: activeOfferId ?? this.activeOfferId,
      );
}
