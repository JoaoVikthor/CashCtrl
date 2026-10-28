import 'package:cloud_firestore/cloud_firestore.dart';

class IngredientOffer {
  final String id;
  final String supplier;
  final String productName;
  final double packagePrice;
  final double packageQuantity;
  final bool isActive;
  final String source;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const IngredientOffer({
    required this.id,
    required this.supplier,
    this.productName = '',
    required this.packagePrice,
    required this.packageQuantity,
    this.isActive = false,
    this.source = 'manual',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  double get pricePerUnit =>
      packageQuantity > 0 ? packagePrice / packageQuantity : 0;

  bool get hasProductName => productName.trim().isNotEmpty;

  factory IngredientOffer.fromMap(Map<String, dynamic> m) {
    final rawCreated = m['createdAt'];
    DateTime createdAt;
    if (rawCreated is Timestamp) {
      createdAt = rawCreated.toDate();
    } else if (rawCreated is DateTime) {
      createdAt = rawCreated;
    } else if (rawCreated is String) {
      createdAt = DateTime.tryParse(rawCreated) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    final rawUpdated = m['updatedAt'];
    DateTime updatedAt;
    if (rawUpdated is Timestamp) {
      updatedAt = rawUpdated.toDate();
    } else if (rawUpdated is DateTime) {
      updatedAt = rawUpdated;
    } else if (rawUpdated is String) {
      updatedAt = DateTime.tryParse(rawUpdated) ?? DateTime.now();
    } else {
      updatedAt = DateTime.now();
    }

    return IngredientOffer(
      id: (m['id'] ?? '') as String,
      supplier: (m['supplier'] ?? '') as String,
      productName: m['productName'] is String ? m['productName'] as String : '',
      packagePrice: ((m['packagePrice'] as num?)?.toDouble() ?? 0),
      packageQuantity: ((m['packageQuantity'] as num?)?.toDouble() ?? 0),
      isActive: (m['isActive'] ?? false) as bool,
      source: (m['source'] ?? 'manual') as String,
      notes: (m['notes'] ?? '') as String,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'supplier': supplier,
        'productName': productName,
        'packagePrice': packagePrice,
        'packageQuantity': packageQuantity,
        'isActive': isActive,
        'source': source,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  IngredientOffer copyWith({
    String? id,
    String? supplier,
    String? productName,
    double? packagePrice,
    double? packageQuantity,
    bool? isActive,
    String? source,
    String? notes,
    DateTime? updatedAt,
  }) =>
      IngredientOffer(
        id: id ?? this.id,
        supplier: supplier ?? this.supplier,
        productName: productName ?? this.productName,
        packagePrice: packagePrice ?? this.packagePrice,
        packageQuantity: packageQuantity ?? this.packageQuantity,
        isActive: isActive ?? this.isActive,
        source: source ?? this.source,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
