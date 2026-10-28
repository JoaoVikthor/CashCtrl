import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/ingredient.dart';
import '../models/ingredient_offer.dart';
import '../models/price_audit_log.dart';
import '../services/firestore_service.dart';
import 'user_provider.dart';

/// Provider do parque de produtos do usuario logado.
///
/// Escuta o stream do Firestore (ingredients/{uid}/...) e expoe um mapa
/// id -> Ingredient para que o ProductProvider consiga calcular o ticket
/// das fichas tecnicas a partir dos precos atuais dos produtos.
class IngredientProvider extends ChangeNotifier {
  IngredientProvider({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  UserProvider? _userProvider;
  String? _uid;
  StreamSubscription<List<Ingredient>>? _sub;

  List<Ingredient> _list = const [];
  bool _loading = true;
  String? _error;
  Stream<List<PriceAuditLog>>? _auditLogsStream;

  List<Ingredient> get list => _list;
  bool get loading => _loading;
  String? get error => _error;

  Map<String, Ingredient> get asMap => {
        for (final i in _list) i.id: i,
      };

  void attach(UserProvider userProvider) {
    _userProvider = userProvider;
    _uid = userProvider.uid;
    _connect();
    userProvider.addListener(_onUserChanged);
  }

  void _onUserChanged() {
    final newUid = _userProvider?.uid;
    if (newUid != _uid) {
      _uid = newUid;
      _auditLogsStream = null;
      _connect();
    }
  }

  void _connect() {
    _sub?.cancel();
    if (_uid == null) {
      _list = const [];
      _loading = false;
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    _sub = _firestore.ingredientsStream(_uid!).listen(
      (list) {
        _list = list;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[IngredientProvider] stream error: $e');
        _error = e.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  Future<String> addIngredient(Ingredient ing) async {
    if (_uid == null) throw StateError('Usuário não autenticado.');
    return _firestore.addIngredient(_uid!, ing);
  }

  Future<void> updateIngredient(Ingredient ing) async {
    if (_uid == null) throw StateError('Usuário não autenticado.');
    await _firestore.updateIngredient(_uid!, ing);
  }

  Future<void> deleteIngredient(String id) async {
    if (_uid == null) throw StateError('Usuário não autenticado.');
    await _firestore.deleteIngredient(_uid!, id);
  }

  Future<String> upsertOffer(String ingredientId, IngredientOffer offer) async {
    if (_uid == null) throw StateError('Usuário não autenticado.');
    return _firestore.upsertOffer(_uid!, ingredientId, offer);
  }

  Future<void> setActiveOffer(String ingredientId, String offerId) async {
    if (_uid == null) throw StateError('Usuário não autenticado.');
    await _firestore.setActiveOffer(_uid!, ingredientId, offerId);
  }

  Future<void> toggleOfferActive(
      String ingredientId, String offerId, bool isActive) async {
    if (_uid == null) throw StateError('Usuário não autenticado.');
    await _firestore.toggleOfferActive(_uid!, ingredientId, offerId, isActive);
  }

  Future<void> deleteOffer(String ingredientId, String offerId) async {
    if (_uid == null) throw StateError('Usuário não autenticado.');
    await _firestore.deleteOffer(_uid!, ingredientId, offerId);
  }

  Stream<List<PriceAuditLog>> get auditLogs {
    if (_uid == null) return Stream.empty();
    _auditLogsStream ??= _firestore.priceAuditLogsStream(_uid!);
    return _auditLogsStream!;
  }

  void reconnectAuditLogs() {
    _auditLogsStream = null;
    notifyListeners();
  }

  void reload() => _connect();

  @override
  void dispose() {
    _sub?.cancel();
    _userProvider?.removeListener(_onUserChanged);
    super.dispose();
  }
}
