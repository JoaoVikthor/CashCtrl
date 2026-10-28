import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/firestore_service.dart';
import 'user_provider.dart';

/// Provider de produtos / fichas tecnicas do usuario logado.
///
/// Escuta o stream do Firestore (products/{uid}/...) e mantem a lista em
/// memoria. O calculo do ticket (lucro/prejuizo) e feito nas telas
/// via ProductCalculator usando o IngredientProvider.
class ProductProvider extends ChangeNotifier {
  ProductProvider({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  UserProvider? _userProvider;
  String? _uid;
  StreamSubscription<List<Product>>? _sub;

  List<Product> _list = const [];
  bool _loading = true;
  String? _error;

  List<Product> get list => _list;
  bool get loading => _loading;
  String? get error => _error;

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
    _sub = _firestore.productsStream(_uid!).listen(
      (list) {
        _list = list;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[ProductProvider] stream error: $e');
        _error = e.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  Future<String> addProduct(Product p) async {
    if (_uid == null) throw StateError('Usuário não autenticado.');
    return _firestore.addProduct(_uid!, p);
  }

  Future<void> updateProduct(Product p) async {
    if (_uid == null) throw StateError('Usuário não autenticado.');
    await _firestore.updateProduct(_uid!, p);
  }

  Future<void> deleteProduct(String id) async {
    if (_uid == null) throw StateError('Usuário não autenticado.');
    await _firestore.deleteProduct(_uid!, id);
  }

  Product? findById(String id) {
    for (final p in _list) {
      if (p.id == id) return p;
    }
    return null;
  }

  void reload() => _connect();

  @override
  void dispose() {
    _sub?.cancel();
    _userProvider?.removeListener(_onUserChanged);
    super.dispose();
  }
}