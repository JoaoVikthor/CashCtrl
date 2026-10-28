import 'package:ctrlcash/models/ingredient.dart';
import 'package:ctrlcash/models/ingredient_offer.dart';

enum PanelSort { economy, lowest, name }

class ProductPanelEntry {
  final Ingredient ingredient;
  final IngredientOffer? activeOffer;
  final IngredientOffer? bestOffer;
  final double? activePricePerUnit;
  final double? bestPricePerUnit;
  final double deltaVsBest;
  final int offersCount;
  final int activeSuppliersCount;
  final bool legacyOnly;
  final List<String> supplierNames;

  const ProductPanelEntry({
    required this.ingredient,
    required this.activeOffer,
    required this.bestOffer,
    required this.activePricePerUnit,
    required this.bestPricePerUnit,
    required this.deltaVsBest,
    required this.offersCount,
    required this.activeSuppliersCount,
    required this.legacyOnly,
    required this.supplierNames,
  });
}

class SupplierPanelRow {
  final ProductPanelEntry entry;
  final double pricePerUnit;
  final int position;
  final int ofTotal;
  final double deltaVsBest;
  final bool isBest;
  final bool isActive;

  const SupplierPanelRow({
    required this.entry,
    required this.pricePerUnit,
    required this.position,
    required this.ofTotal,
    required this.deltaVsBest,
    required this.isBest,
    required this.isActive,
  });
}

class SupplierPanelEntry {
  final String name;
  final int productsCount;
  final int bestCount;
  final List<SupplierPanelRow> rows;

  const SupplierPanelEntry({
    required this.name,
    required this.productsCount,
    required this.bestCount,
    required this.rows,
  });
}

class PanelSummary {
  final int productsWithOffers;
  final int suppliersCount;
  final int productsPayMore;
  final double economySumPerUnit;

  const PanelSummary({
    required this.productsWithOffers,
    required this.suppliersCount,
    required this.productsPayMore,
    required this.economySumPerUnit,
  });
}

class PricePanelAggregator {
  static List<IngredientOffer> _validActiveOffers(Ingredient ingredient) {
    return ingredient.offers.where((o) {
      return o.isActive && o.packageQuantity > 0 && o.packagePrice > 0;
    }).toList();
  }

  static String _normalizedSupplier(String supplier) {
    return supplier.trim().toLowerCase();
  }

  static String _unaccent(String value) {
    const accents = 'áàãâäéèêëíìîïóòõôöúùûüçÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÕÔÖÚÙÛÜÇ';
    const without = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
    final buf = StringBuffer();
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      final idx = accents.indexOf(char);
      if (idx >= 0) {
        buf.write(without[idx]);
      } else {
        buf.write(char);
      }
    }
    return buf.toString();
  }

  static String _sortKey(String value) {
    return _unaccent(value).trim().toLowerCase();
  }

  static List<String> _productNames(Ingredient ingredient) {
    return _validActiveOffers(ingredient)
        .map((o) => o.productName.trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  static Map<String, String> _supplierDisplayNames(
      List<IngredientOffer> offers) {
    final displayNames = <String, String>{};
    for (final offer in offers) {
      final key = _normalizedSupplier(offer.supplier);
      displayNames.putIfAbsent(key, () => offer.supplier.trim());
    }
    return displayNames;
  }

  static double _applyTolerance(double delta) {
    if (delta.abs() < 0.005) return 0.0;
    return delta;
  }

  static ProductPanelEntry _buildEntry(Ingredient ingredient) {
    final validActive = _validActiveOffers(ingredient);
    final activeOffer = ingredient.activeOffer;

    if (ingredient.offers.isEmpty) {
      final legacyPpu = ingredient.packageQuantity > 0
          ? ingredient.purchasePrice / ingredient.packageQuantity
          : 0.0;
      return ProductPanelEntry(
        ingredient: ingredient,
        activeOffer: null,
        bestOffer: null,
        activePricePerUnit: null,
        bestPricePerUnit: legacyPpu,
        deltaVsBest: -1,
        offersCount: 0,
        activeSuppliersCount: 0,
        legacyOnly: true,
        supplierNames: const [],
      );
    }

    final bestCandidates = List<IngredientOffer>.from(validActive)
      ..sort((a, b) => a.pricePerUnit.compareTo(b.pricePerUnit));
    final bestOffer = bestCandidates.isEmpty ? null : bestCandidates.first;

    final activePpu = activeOffer != null &&
            activeOffer.packageQuantity > 0 &&
            activeOffer.packagePrice > 0
        ? activeOffer.pricePerUnit
        : null;
    final bestPpu = bestOffer?.pricePerUnit;

    double delta;
    if (bestPpu == null || activePpu == null) {
      delta = -1;
    } else {
      delta = _applyTolerance(activePpu - bestPpu);
    }

    final displayNames = _supplierDisplayNames(validActive);
    final supplierNames = displayNames.values.toList()
      ..sort((a, b) => _sortKey(a).compareTo(_sortKey(b)));

    return ProductPanelEntry(
      ingredient: ingredient,
      activeOffer: activeOffer,
      bestOffer: bestOffer,
      activePricePerUnit: activePpu,
      bestPricePerUnit: bestPpu,
      deltaVsBest: delta,
      offersCount: ingredient.offers.length,
      activeSuppliersCount: displayNames.length,
      legacyOnly: false,
      supplierNames: supplierNames,
    );
  }

  static List<ProductPanelEntry> buildPanel(Map<String, Ingredient> asMap) {
    final entries = asMap.values.map(_buildEntry).toList();
    return sortPanel(entries, PanelSort.name);
  }

  static List<ProductPanelEntry> sortPanel(
      List<ProductPanelEntry> entries, PanelSort sort) {
    final result = List<ProductPanelEntry>.from(entries);
    switch (sort) {
      case PanelSort.economy:
        result.sort((a, b) => b.deltaVsBest.compareTo(a.deltaVsBest));
      case PanelSort.lowest:
        result.sort((a, b) {
          final aPpu = a.bestPricePerUnit ?? double.infinity;
          final bPpu = b.bestPricePerUnit ?? double.infinity;
          return aPpu.compareTo(bPpu);
        });
      case PanelSort.name:
        result.sort((a, b) => _sortKey(a.ingredient.name)
            .compareTo(_sortKey(b.ingredient.name)));
    }
    return result;
  }

  static List<ProductPanelEntry> filterPanel(
    List<ProductPanelEntry> entries, {
    String query = '',
    String supplier = '',
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedSupplier = _normalizedSupplier(supplier);
    return entries.where((entry) {
      final normalizedQueryKey = _sortKey(query);
      final matchesQuery = normalizedQuery.isEmpty ||
          _sortKey(entry.ingredient.name).contains(normalizedQueryKey) ||
          entry.supplierNames
              .any((s) => _sortKey(s).contains(normalizedQueryKey)) ||
          _productNames(entry.ingredient)
              .any((p) => _sortKey(p).contains(normalizedQueryKey));
      final matchesSupplier = normalizedSupplier.isEmpty ||
          entry.supplierNames
              .map(_normalizedSupplier)
              .contains(normalizedSupplier) ||
          (entry.activeOffer != null &&
              _normalizedSupplier(entry.activeOffer!.supplier) ==
                  normalizedSupplier);
      return matchesQuery && matchesSupplier;
    }).toList();
  }

  static PanelSummary summarize(List<ProductPanelEntry> entries) {
    var productsWithOffers = 0;
    final supplierSet = <String>{};
    var productsPayMore = 0;
    var economySumPerUnit = 0.0;

    for (final entry in entries) {
      if (!entry.legacyOnly) {
        productsWithOffers++;
        for (final name in entry.supplierNames) {
          supplierSet.add(name.toLowerCase());
        }
      }
      if (entry.deltaVsBest > 0) {
        productsPayMore++;
        economySumPerUnit += entry.deltaVsBest;
      }
    }

    return PanelSummary(
      productsWithOffers: productsWithOffers,
      suppliersCount: supplierSet.length,
      productsPayMore: productsPayMore,
      economySumPerUnit: economySumPerUnit,
    );
  }

  static List<IngredientOffer> _supplierRank(List<IngredientOffer> validActive) {
    final bySupplier = <String, IngredientOffer>{};
    for (final offer in validActive) {
      final key = _normalizedSupplier(offer.supplier);
      final existing = bySupplier[key];
      if (existing == null || offer.pricePerUnit < existing.pricePerUnit) {
        bySupplier[key] = offer;
      }
    }
    final ranked = bySupplier.values.toList();
    ranked.sort((a, b) => a.pricePerUnit.compareTo(b.pricePerUnit));
    return ranked;
  }

  static List<SupplierPanelRow> rowsForSupplier(
    List<ProductPanelEntry> entries,
    String supplierName,
  ) {
    final normalized = _normalizedSupplier(supplierName);
    final rows = <SupplierPanelRow>[];
    for (final entry in entries) {
      final validActive = _validActiveOffers(entry.ingredient);
      final bySupplier = validActive
          .where((o) => _normalizedSupplier(o.supplier) == normalized)
          .toList();
      if (bySupplier.isEmpty) continue;

      final bestOfSupplier = (List<IngredientOffer>.from(bySupplier)
            ..sort((a, b) => a.pricePerUnit.compareTo(b.pricePerUnit)))
          .first;
      final rank = _supplierRank(validActive);
      final position = rank.indexWhere(
            (o) => _normalizedSupplier(o.supplier) == normalized,
          ) +
          1;

      final activeOffer = entry.ingredient.activeOffer;
      final isActive = activeOffer != null &&
          _normalizedSupplier(activeOffer.supplier) == normalized;

      final delta = rank.isEmpty
          ? -1.0
          : _applyTolerance(bestOfSupplier.pricePerUnit - rank.first.pricePerUnit);

      rows.add(SupplierPanelRow(
        entry: entry,
        pricePerUnit: bestOfSupplier.pricePerUnit,
        position: position,
        ofTotal: rank.length,
        deltaVsBest: delta,
        isBest: position == 1,
        isActive: isActive,
      ));
    }
    rows.sort((a, b) {
      final cmp = a.position.compareTo(b.position);
      if (cmp != 0) return cmp;
      return _sortKey(a.entry.ingredient.name)
          .compareTo(_sortKey(b.entry.ingredient.name));
    });
    return rows;
  }

  static String _findDisplayName(
      List<ProductPanelEntry> entries, String normalizedKey) {
    for (final entry in entries) {
      for (final name in entry.supplierNames) {
        if (_normalizedSupplier(name) == normalizedKey) return name;
      }
      for (final offer in _validActiveOffers(entry.ingredient)) {
        if (_normalizedSupplier(offer.supplier) == normalizedKey) {
          return offer.supplier.trim();
        }
      }
    }
    return normalizedKey;
  }

  static List<SupplierPanelEntry> buildSupplierReport(
      List<ProductPanelEntry> entries) {
    final supplierKeys = <String>{};
    for (final entry in entries) {
      for (final offer in _validActiveOffers(entry.ingredient)) {
        supplierKeys.add(_normalizedSupplier(offer.supplier));
      }
    }

    final result = <SupplierPanelEntry>[];
    for (final key in supplierKeys) {
      final rows = rowsForSupplier(entries, key);
      if (rows.isEmpty) continue;
      final bestCount = rows.where((r) => r.isBest).length;
      result.add(SupplierPanelEntry(
        name: _findDisplayName(entries, key),
        productsCount: rows.length,
        bestCount: bestCount,
        rows: rows,
      ));
    }

    result.sort((a, b) {
      final cmp = b.bestCount.compareTo(a.bestCount);
      if (cmp != 0) return cmp;
      final cmp2 = b.productsCount.compareTo(a.productsCount);
      if (cmp2 != 0) return cmp2;
      return _sortKey(a.name).compareTo(_sortKey(b.name));
    });

    return result;
  }
}
