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
  Timer? _retryTimer;
  int _retryCount = 0;
  bool _disposed = false;

  List<Product> _list = const [];
  bool _loading = true;
  String? _error;

  List<Product> get list => _list;
  bool get loading => _loading;
  String? get error => _error;

  void attach(UserProvider userProvider) {
    _userProvider = userProvider;
    _uid = userProvider.uid;
    _connect(notify: _uid != null);
    userProvider.addListener(_onUserChanged);
  }

  void _onUserChanged() {
    final newUid = _userProvider?.uid;
    if (newUid != _uid) {
      _retryTimer?.cancel();
      _retryCount = 0;
      _uid = newUid;
      _connect();
    }
  }

  void _connect({bool notify = true}) {
    _retryTimer?.cancel();
    _sub?.cancel();
    if (_uid == null) {
      _list = const [];
      if (notify) notifyListeners();
      return;
    }
    _loading = true;
    if (notify) notifyListeners();
    final currentUid = _uid;
    _sub = _firestore.productsStream(_uid!).listen(
      (list) {
        _retryCount = 0;
        _list = list;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[ProductProvider] stream error: $e');
        if (!_disposed &&
            _uid == currentUid &&
            e.toString().contains('permission-denied') &&
            _retryCount < 2) {
          _retryCount++;
          final delay = _retryCount == 1
              ? const Duration(milliseconds: 600)
              : const Duration(milliseconds: 1500);
          _retryTimer = Timer(delay, () async {
            if (!_disposed && _uid == currentUid) {
              await _userProvider?.forceAuthRefresh();
              _connect();
            }
          });
        } else {
          _error = e.toString();
          _loading = false;
          notifyListeners();
        }
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

  void reload() {
    _retryCount = 0;
    _connect();
  }

  @override
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _sub?.cancel();
    _userProvider?.removeListener(_onUserChanged);
    super.dispose();
  }
}