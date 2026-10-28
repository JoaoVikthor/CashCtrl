import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/transaction.dart' as tx;
import '../models/budget.dart';
import '../models/ingredient.dart';
import '../models/ingredient_offer.dart';
import '../models/price_audit_log.dart';
import '../models/product.dart';
import '../utils/audit_builder.dart';
import '../utils/offer_comparator.dart';
import '../utils/offer_rules.dart';
import '../utils/recurrence.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _txCol(String uid) =>
      _userDoc(uid).collection('transactions');

  CollectionReference<Map<String, dynamic>> _budgetCol(String uid) =>
      _userDoc(uid).collection('budgets');

  CollectionReference<Map<String, dynamic>> _ingredientCol(String uid) =>
      _userDoc(uid).collection('ingredients');

  DocumentReference<Map<String, dynamic>> _ingredientDoc(
          String uid, String id) =>
      _ingredientCol(uid).doc(id);

  CollectionReference<Map<String, dynamic>> _auditLogCol(String uid) =>
      _userDoc(uid).collection('price_audit_logs');

  CollectionReference<Map<String, dynamic>> _productCol(String uid) =>
      _userDoc(uid).collection('products');

  Future<void> saveUser(AppUser user) async {
    await _userDoc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Future<AppUser?> getUser(String uid) async {
    final snap = await _userDoc(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromMap(uid, snap.data()!);
  }

  Stream<List<tx.AppTransaction>> transactionsStream(String uid) {
    return _txCol(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((qs) => qs.docs
            .map((d) => tx.AppTransaction.fromMap(d.id, d.data()))
            .toList());
  }

  Future<int> generateDueRecurrences(
      String uid, List<tx.AppTransaction> transactions) async {
    final now = DateTime.now();
    final parents = transactions.where((t) {
      if (t.generatedFrom != null) return false;
      final frequency = t.effectiveRecurrence;
      if (frequency == null) return false;
      if (t.date.isAfter(now) || t.date.isAtSameMomentAs(now)) return false;
      return true;
    });

    final existingIds = <String>{};
    for (final t in transactions) {
      if (t.generatedFrom != null) {
        existingIds.add(t.id);
      }
    }

    var created = 0;
    var batch = _db.batch();
    var count = 0;

    Future<void> commitIfNeeded({bool force = false}) async {
      if (force || count >= 400) {
        await batch.commit();
        batch = _db.batch();
        count = 0;
      }
    }

    for (final parent in parents) {
      final frequency = parent.effectiveRecurrence!;
      final dates = computeDueOccurrences(
        startDate: parent.date,
        frequency: frequency,
        now: now,
      );
      for (final date in dates) {
        final id = '${parent.id}#${date.toIso8601String().substring(0, 10)}';
        if (parent.skippedOccurrences.contains(id)) continue;
        if (existingIds.contains(id)) continue;

        final snap = await _txCol(uid).doc(id).get();
        if (snap.exists) {
          existingIds.add(id);
          continue;
        }

        final generated = tx.AppTransaction(
          id: id,
          type: parent.type,
          category: parent.category,
          description: parent.description,
          amount: parent.amount,
          date: date,
          paymentMethod: parent.paymentMethod,
          recurring: false,
          generatedFrom: parent.id,
          notes: parent.notes,
          receiptUrl: parent.receiptUrl,
          budgetId: parent.budgetId,
        );
        batch.set(_txCol(uid).doc(id), generated.toMap());
        count++;
        created++;
        await commitIfNeeded();
      }
    }

    await commitIfNeeded(force: true);
    return created;
  }

  Future<String> addTransaction(String uid, tx.AppTransaction t) async {
    final ref = await _txCol(uid).add(t.toMap());
    return ref.id;
  }

  Future<void> updateTransaction(String uid, tx.AppTransaction t) async {
    await _txCol(uid).doc(t.id).set(t.toMap());
  }

  Future<void> deleteTransaction(String uid, String id) async {
    final docRef = _txCol(uid).doc(id);
    final snap = await docRef.get();
    if (snap.exists) {
      final data = snap.data()!;
      final generatedFrom = data['generatedFrom'] as String?;
      if (generatedFrom != null && generatedFrom.isNotEmpty) {
        final parentRef = _txCol(uid).doc(generatedFrom);
        final batch = _db.batch();
        batch.update(parentRef, {
          'skippedOccurrences': FieldValue.arrayUnion([id]),
        });
        batch.delete(docRef);
        await batch.commit();
        return;
      }
    }
    await docRef.delete();
  }

  Stream<List<Budget>> budgetsStream(String uid) {
    return _budgetCol(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((qs) =>
            qs.docs.map((d) => Budget.fromMap(d.id, d.data())).toList());
  }

  Future<String> addBudget(String uid, Budget b) async {
    final ref = await _budgetCol(uid).add(b.toMap());
    return ref.id;
  }

  Future<void> updateBudget(String uid, Budget b) async {
    await _budgetCol(uid).doc(b.id).set(b.toMap());
  }

  Future<void> deleteBudget(String uid, String id) async {
    await _budgetCol(uid).doc(id).delete();
  }

  Stream<List<Ingredient>> ingredientsStream(String uid) {
    return _ingredientCol(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((qs) =>
            qs.docs.map((d) => Ingredient.fromMap(d.id, d.data())).toList());
  }

  Future<String> addIngredient(String uid, Ingredient ing) async {
    final batch = _db.batch();
    final docRef = _ingredientCol(uid).doc();
    batch.set(docRef, ing.toMap());
    final log = AuditBuilder.ingredientCreate(
      entityId: docRef.id,
      name: ing.name,
      purchasePrice: ing.purchasePrice,
    );
    final logRef = _auditLogCol(uid).doc();
    batch.set(logRef, log.toMap(DateTime.now().add(const Duration(days: 180))));
    await batch.commit();
    return docRef.id;
  }

  Future<void> updateIngredient(String uid, Ingredient ing) async {
    final batch = _db.batch();
    final docRef = _ingredientDoc(uid, ing.id);
    final data = Map<String, dynamic>.from(ing.toMap());
    data.remove('offers');
    data.remove('activeOfferId');
    batch.set(docRef, data, SetOptions(merge: true));
    final log = AuditBuilder.ingredientUpdate(
      entityId: ing.id,
      name: ing.name,
      purchasePrice: ing.purchasePrice,
    );
    final logRef = _auditLogCol(uid).doc();
    batch.set(logRef, log.toMap(DateTime.now().add(const Duration(days: 180))));
    await batch.commit();
  }

  Future<void> deleteIngredient(String uid, String id) async {
    final batch = _db.batch();
    final docRef = _ingredientDoc(uid, id);
    batch.delete(docRef);
    final log = AuditBuilder.ingredientDelete(entityId: id);
    final logRef = _auditLogCol(uid).doc();
    batch.set(logRef, log.toMap(DateTime.now().add(const Duration(days: 180))));
    await batch.commit();
  }

  Future<String> upsertOffer(
      String uid, String ingredientId, IngredientOffer offer) async {
    if (offer.packagePrice <= 0 || offer.packageQuantity <= 0) {
      throw StateError(
          'O preço e a quantidade da embalagem devem ser maiores que zero (RN01).');
    }

    final docRef = _ingredientDoc(uid, ingredientId);
    final snap = await docRef.get();
    final now = DateTime.now();
    final List<IngredientOffer> current;
    String? currentActiveId;
    if (snap.exists) {
      final data = snap.data()!;
      final rawOffers = data['offers'];
      current = rawOffers is List
          ? rawOffers
              .whereType<Map>()
              .map((e) =>
                  IngredientOffer.fromMap(Map<String, dynamic>.from(e)))
              .toList()
          : [];
      currentActiveId = data['activeOfferId'] as String?;
    } else {
      current = [];
      currentActiveId = null;
    }

    final fallbackId = offer.id.isEmpty ? _ingredientCol(uid).doc().id : '';
    final result = applyOfferUpsert(
      current,
      offer,
      newOfferId: fallbackId,
      now: now,
    );

    final batch = _db.batch();
    final String offerId = result.offerId;
    final PriceAuditLog log;

    if (result.isCreate) {
      final created = result.offers.firstWhere((o) => o.id == offerId);
      if (result.offers.length == 1) {
        currentActiveId = offerId;
      }
      log = AuditBuilder.offerCreate(
        entityId: offerId,
        supplier: created.supplier,
        packagePrice: created.packagePrice,
        pricePerUnit: created.pricePerUnit,
        source: created.source,
      );
    } else {
      final updated = result.offers.firstWhere((o) => o.id == offerId);
      final previous = result.previous!;
      log = AuditBuilder.offerUpdate(
        entityId: offerId,
        supplier: updated.supplier,
        previousPrice: previous.packagePrice,
        newPrice: updated.packagePrice,
        pricePerUnit: updated.pricePerUnit,
        source: updated.source,
      );
    }

    batch.set(docRef, {
      'offers': result.offers.map((o) => o.toMap()).toList(),
      'activeOfferId': currentActiveId,
    }, SetOptions(merge: true));
    final logRef = _auditLogCol(uid).doc();
    batch.set(logRef, log.toMap(now.add(const Duration(days: 180))));
    await batch.commit();
    return offerId;
  }

  Future<void> setActiveOffer(
      String uid, String ingredientId, String offerId) async {
    final docRef = _ingredientDoc(uid, ingredientId);
    final snap = await docRef.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    final rawOffers = data['offers'];
    if (rawOffers is! List) return;
    final offers = rawOffers
        .whereType<Map>()
        .map((e) =>
            IngredientOffer.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    if (offers.isEmpty && offerId == 'legacy') return;
    final chosen = offers.firstWhere(
      (o) => o.id == offerId,
      orElse: () => throw Exception('Oferta não encontrada.'),
    );
    final updated = offers
        .map((o) => o.copyWith(isActive: o.id == chosen.id))
        .toList();

    final batch = _db.batch();
    batch.set(docRef, {
      'offers': updated.map((o) => o.toMap()).toList(),
      'activeOfferId': chosen.id,
    }, SetOptions(merge: true));
    final log = AuditBuilder.offerSetActive(
      entityId: chosen.id,
      supplier: chosen.supplier,
      packagePrice: chosen.packagePrice,
      pricePerUnit: chosen.pricePerUnit,
      source: chosen.source,
    );
    final logRef = _auditLogCol(uid).doc();
    batch.set(logRef, log.toMap(DateTime.now().add(const Duration(days: 180))));
    await batch.commit();
  }

  Future<void> toggleOfferActive(String uid, String ingredientId,
      String offerId, bool isActive) async {
    final docRef = _ingredientDoc(uid, ingredientId);
    final snap = await docRef.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    final rawOffers = data['offers'];
    if (rawOffers is! List) return;
    final offers = rawOffers
        .whereType<Map>()
        .map((e) =>
            IngredientOffer.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    final index = offers.indexWhere((o) => o.id == offerId);
    if (index < 0) return;
    final target = offers[index];
    final wasActive = (data['activeOfferId'] as String?) == offerId;
    offers[index] = target.copyWith(isActive: isActive);
    String? newActiveId = data['activeOfferId'] as String?;
    if (!isActive && newActiveId == offerId) {
      newActiveId = null;
    }

    final batch = _db.batch();
    batch.set(docRef, {
      'offers': offers.map((o) => o.toMap()).toList(),
      'activeOfferId': newActiveId,
    }, SetOptions(merge: true));
    final log = AuditBuilder.offerToggleActive(
      entityId: offerId,
      supplier: target.supplier,
      isActive: isActive,
      packagePrice: target.packagePrice,
      pricePerUnit: target.pricePerUnit,
      source: target.source,
      wasActive: wasActive,
    );
    final logRef = _auditLogCol(uid).doc();
    batch.set(logRef, log.toMap(DateTime.now().add(const Duration(days: 180))));
    await batch.commit();
  }

  Future<void> deleteOffer(
      String uid, String ingredientId, String offerId) async {
    final docRef = _ingredientDoc(uid, ingredientId);
    final snap = await docRef.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    final rawOffers = data['offers'];
    if (rawOffers is! List) return;
    final offers = rawOffers
        .whereType<Map>()
        .map((e) =>
            IngredientOffer.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    final index = offers.indexWhere((o) => o.id == offerId);
    if (index < 0) return;
    final target = offers[index];
    offers.removeAt(index);
    String? newActiveId = data['activeOfferId'] as String?;
    if (newActiveId == offerId) newActiveId = null;

    final batch = _db.batch();
    batch.set(docRef, {
      'offers': offers.map((o) => o.toMap()).toList(),
      'activeOfferId': newActiveId,
    }, SetOptions(merge: true));
    final log = AuditBuilder.offerDelete(
      entityId: offerId,
      supplier: target.supplier,
      packagePrice: target.packagePrice,
      pricePerUnit: target.pricePerUnit,
      source: target.source,
    );
    final logRef = _auditLogCol(uid).doc();
    batch.set(logRef, log.toMap(DateTime.now().add(const Duration(days: 180))));
    await batch.commit();
  }

  Future<void> migrateLegacyOffers(String uid, Ingredient ingredient) async {
    if (ingredient.offers.isNotEmpty) return;
    if (ingredient.purchasePrice <= 0 || ingredient.packageQuantity <= 0) return;

    final docRef = _ingredientDoc(uid, ingredient.id);
    final snap = await docRef.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    final alreadyMigrated = (data['legacyMigrated'] as bool?) == true;
    if (alreadyMigrated) return;
    final rawOffers = data['offers'];
    if (rawOffers is List && rawOffers.isNotEmpty) return;

    final now = DateTime.now();
    final legacy = OfferComparator.syntheticLegacyOffer(ingredient);
    final migrated = IngredientOffer(
      id: legacy.id,
      supplier: legacy.supplier,
      packagePrice: legacy.packagePrice,
      packageQuantity: legacy.packageQuantity,
      isActive: legacy.isActive,
      source: legacy.source,
      notes: legacy.notes,
      createdAt: now,
      updatedAt: now,
    );

    final batch = _db.batch();
    batch.set(docRef, {
      'offers': [migrated.toMap()],
      'activeOfferId': migrated.id,
      'legacyMigrated': true,
    }, SetOptions(merge: true));
    final log = AuditBuilder.migration(
      entityId: ingredient.id,
      summary: 'Produto ${ingredient.name}: preço base migrado para oferta',
      newPrice: migrated.packagePrice,
      pricePerUnit: migrated.pricePerUnit,
    );
    final logRef = _auditLogCol(uid).doc();
    batch.set(logRef, log.toMap(now.add(const Duration(days: 180))));
    await batch.commit();
  }

  Stream<List<PriceAuditLog>> priceAuditLogsStream(String uid,
      {int limit = 100}) {
    return _auditLogCol(uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((qs) => qs.docs
            .map((d) => PriceAuditLog.fromMap(d.data()))
            .toList());
  }

  Future<AuditLogPage> fetchPriceAuditLogs(
    String uid, {
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    var query = _auditLogCol(uid)
        .orderBy('timestamp', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.get();
    final logs = snap.docs
        .map((d) => PriceAuditLog.fromMap(d.data()))
        .toList();
    final lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
    final hasMore = snap.docs.length == limit;
    return AuditLogPage(logs: logs, lastDoc: lastDoc, hasMore: hasMore);
  }

  Future<void> purgeUserData(String uid) async {
    final colRefs = [
      _txCol(uid),
      _budgetCol(uid),
      _ingredientCol(uid),
      _productCol(uid),
      _auditLogCol(uid),
    ];

    var batch = _db.batch();
    var count = 0;

    Future<void> commitIfNeeded({bool force = false}) async {
      if (force || count >= 400) {
        await batch.commit();
        batch = _db.batch();
        count = 0;
      }
    }

    for (final col in colRefs) {
      final snap = await col.get();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
        count++;
        await commitIfNeeded();
      }
    }

    batch.delete(_userDoc(uid));
    await commitIfNeeded(force: true);
  }

  Stream<List<Product>> productsStream(String uid) {
    return _productCol(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((qs) =>
            qs.docs.map((d) => Product.fromMap(d.id, d.data())).toList());
  }

  Future<String> addProduct(String uid, Product p) async {
    final batch = _db.batch();
    final ref = _productCol(uid).doc();
    batch.set(ref, p.toMap());
    final log = AuditBuilder.productCreate(
      entityId: ref.id,
      name: p.name,
      salePrice: p.salePrice,
    );
    final logRef = _auditLogCol(uid).doc();
    batch.set(logRef, log.toMap(DateTime.now().add(const Duration(days: 180))));
    await batch.commit();
    return ref.id;
  }

  Future<void> updateProduct(String uid, Product p) async {
    final docRef = _productCol(uid).doc(p.id);
    final snap = await docRef.get();
    final previous =
        snap.exists ? Product.fromMap(snap.id, snap.data()!) : null;

    final batch = _db.batch();
    batch.set(docRef, p.toMap());
    final log = AuditBuilder.productUpdate(
      entityId: p.id,
      name: p.name,
      previousSalePrice: previous?.salePrice,
      newSalePrice: p.salePrice,
    );
    final logRef = _auditLogCol(uid).doc();
    batch.set(logRef, log.toMap(DateTime.now().add(const Duration(days: 180))));
    await batch.commit();
  }

  Future<void> deleteProduct(String uid, String id) async {
    final docRef = _productCol(uid).doc(id);
    final snap = await docRef.get();
    Product? previous;
    if (snap.exists) {
      previous = Product.fromMap(snap.id, snap.data()!);
    }

    final batch = _db.batch();
    batch.delete(docRef);
    final log = AuditBuilder.productDelete(
      entityId: id,
      name: previous?.name ?? 'Produto',
      salePrice: previous?.salePrice,
    );
    final logRef = _auditLogCol(uid).doc();
    batch.set(logRef, log.toMap(DateTime.now().add(const Duration(days: 180))));
    await batch.commit();
  }
}

class AuditLogPage {
  final List<PriceAuditLog> logs;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;

  const AuditLogPage({
    required this.logs,
    required this.lastDoc,
    required this.hasMore,
  });
}
