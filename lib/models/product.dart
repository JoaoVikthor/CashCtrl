import 'package:cloud_firestore/cloud_firestore.dart';

/// Uma linha da ficha tecnica: qtd usada de um produto na ficha.
///
/// Guarda o [ingredientId] (referencia viva ao parque de produtos) e um
/// snapshot do [ingredientName] para nao quebrar a exibicao caso o
/// produto seja apagado. O custo da linha e calculado a partir do preco
/// por unidade atual do produto (ver [ProductCalculator]).
class RecipeItem {
  final String ingredientId;
  final String ingredientName;
  final double quantity;
  final String? inputUnit;

  const RecipeItem({
    required this.ingredientId,
    required this.ingredientName,
    required this.quantity,
    this.inputUnit,
  });

  factory RecipeItem.fromMap(Map<String, dynamic> m) => RecipeItem(
        ingredientId: (m['ingredientId'] ?? '') as String,
        ingredientName: (m['ingredientName'] ?? '') as String,
        quantity: ((m['quantity'] ?? 0) as num).toDouble(),
        inputUnit: m['inputUnit'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'ingredientId': ingredientId,
        'ingredientName': ingredientName,
        'quantity': quantity,
        'inputUnit': inputUnit,
      };

  RecipeItem copyWith({
    String? ingredientId,
    String? ingredientName,
    double? quantity,
    String? inputUnit,
  }) =>
      RecipeItem(
        ingredientId: ingredientId ?? this.ingredientId,
        ingredientName: ingredientName ?? this.ingredientName,
        quantity: quantity ?? this.quantity,
        inputUnit: inputUnit ?? this.inputUnit,
      );
}

/// Produto / ficha tecnica (ticket).
///
/// Consta de: lista de produtos ([recipe]) + [laborCost] (mao de obra) +
/// [packagingCost] (embalagem) + [salePrice] (preco de venda). O app
/// calcula o custo total, lucro/prejuizo e margem para mostrar ao
/// usuario se o produto deu lucro ou prejuizo.
class Product {
  final String id;
  final String name;
  final String description;
  final List<RecipeItem> recipe;
  final double laborCost;
  final double packagingCost;
  final double salePrice;
  final String? barcode;
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.recipe,
    required this.laborCost,
    required this.packagingCost,
    required this.salePrice,
    this.barcode,
    required this.createdAt,
  });

  factory Product.fromMap(String id, Map<String, dynamic> m) {
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
    final rawRecipe = m['recipe'];
    List<RecipeItem> recipe = const [];
    if (rawRecipe is List) {
      recipe = rawRecipe
          .map((e) =>
              RecipeItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return Product(
      id: id,
      name: (m['name'] ?? '') as String,
      description: (m['description'] ?? '') as String,
      recipe: recipe,
      laborCost: ((m['laborCost'] ?? 0) as num).toDouble(),
      packagingCost: ((m['packagingCost'] ?? 0) as num).toDouble(),
      salePrice: ((m['salePrice'] ?? 0) as num).toDouble(),
      barcode: m['barcode'] as String?,
      createdAt: date,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'recipe': recipe.map((r) => r.toMap()).toList(),
        'laborCost': laborCost,
        'packagingCost': packagingCost,
        'salePrice': salePrice,
        'barcode': barcode,
        'createdAt': createdAt.toIso8601String(),
      };

  Product copyWith({
    String? name,
    String? description,
    List<RecipeItem>? recipe,
    double? laborCost,
    double? packagingCost,
    double? salePrice,
    String? barcode,
  }) =>
      Product(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        recipe: recipe ?? this.recipe,
        laborCost: laborCost ?? this.laborCost,
        packagingCost: packagingCost ?? this.packagingCost,
        salePrice: salePrice ?? this.salePrice,
        barcode: barcode ?? this.barcode,
        createdAt: createdAt,
      );

  /// Custo fixo (mao de obra + embalagem), sem ingredientes.
  double get fixedCost => laborCost + packagingCost;

  /// Margem brutaSobreCustoFixo: (preco - custo fixo) / preco * 100.
  /// Ignora ingredientes (precisa dos precos dos produtos para o calculo
  /// completo — ver [ProductCalculator] em lib/utils/).
  double get fixedMarginPercent {
    if (salePrice <= 0) return 0;
    return ((salePrice - fixedCost) / salePrice) * 100;
  }
}