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
/// Consta de: lista de produtos ([recipe]) + custos extras (diarista,
/// horista e comissionado) + [packagingCost] (embalagem) + [salePrice]
/// (preco de venda). O app calcula o custo total, lucro/prejuizo e
/// margem para mostrar ao usuario se o produto deu lucro ou prejuizo.
class Product {
  final String id;
  final String name;
  final String description;
  final List<RecipeItem> recipe;
  final double dailyRate;
  final double dailyDays;
  final double hourlyRate;
  final double hourlyHours;
  final double commissionPercent;
  final double packagingCost;
  final double salePrice;
  final String? barcode;
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.recipe,
    this.dailyRate = 0.0,
    this.dailyDays = 0.0,
    this.hourlyRate = 0.0,
    this.hourlyHours = 0.0,
    this.commissionPercent = 0.0,
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
    final bool hasNewKeys = m.containsKey('dailyRate') ||
        m.containsKey('hourlyRate') ||
        m.containsKey('commissionPercent');
    final double dailyRate;
    final double dailyDays;
    final double hourlyRate;
    final double hourlyHours;
    final double commissionPercent;
    if (hasNewKeys) {
      dailyRate = ((m['dailyRate'] ?? 0) as num).toDouble();
      dailyDays = ((m['dailyDays'] ?? 0) as num).toDouble();
      hourlyRate = ((m['hourlyRate'] ?? 0) as num).toDouble();
      hourlyHours = ((m['hourlyHours'] ?? 0) as num).toDouble();
      commissionPercent = ((m['commissionPercent'] ?? 0) as num).toDouble();
    } else {
      dailyRate = ((m['laborCost'] ?? 0) as num).toDouble();
      dailyDays = 1.0;
      hourlyRate = 0.0;
      hourlyHours = 0.0;
      commissionPercent = 0.0;
    }
    return Product(
      id: id,
      name: (m['name'] ?? '') as String,
      description: (m['description'] ?? '') as String,
      recipe: recipe,
      dailyRate: dailyRate,
      dailyDays: dailyDays,
      hourlyRate: hourlyRate,
      hourlyHours: hourlyHours,
      commissionPercent: commissionPercent,
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
        'dailyRate': dailyRate,
        'dailyDays': dailyDays,
        'hourlyRate': hourlyRate,
        'hourlyHours': hourlyHours,
        'commissionPercent': commissionPercent,
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
    double? dailyRate,
    double? dailyDays,
    double? hourlyRate,
    double? hourlyHours,
    double? commissionPercent,
    double? packagingCost,
    double? salePrice,
    String? barcode,
  }) =>
      Product(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        recipe: recipe ?? this.recipe,
        dailyRate: dailyRate ?? this.dailyRate,
        dailyDays: dailyDays ?? this.dailyDays,
        hourlyRate: hourlyRate ?? this.hourlyRate,
        hourlyHours: hourlyHours ?? this.hourlyHours,
        commissionPercent: commissionPercent ?? this.commissionPercent,
        packagingCost: packagingCost ?? this.packagingCost,
        salePrice: salePrice ?? this.salePrice,
        barcode: barcode ?? this.barcode,
        createdAt: createdAt,
      );

  double get dailyCost => dailyRate * dailyDays;

  double get hourlyCost => hourlyRate * hourlyHours;

  double get commissionCost =>
      salePrice > 0 && commissionPercent > 0
          ? salePrice * commissionPercent / 100
          : 0.0;

  double get laborCost => dailyCost + hourlyCost + commissionCost;

  /// Custo fixo (diarista + horista + comissionado + embalagem), sem ingredientes.
  double get fixedCost => laborCost + packagingCost;

  /// Margem brutaSobreCustoFixo: (preco - custo fixo) / preco * 100.
  /// Ignora ingredientes (precisa dos precos dos produtos para o calculo
  /// completo — ver [ProductCalculator] em lib/utils/).
  double get fixedMarginPercent {
    if (salePrice <= 0) return 0;
    return ((salePrice - fixedCost) / salePrice) * 100;
  }
}