import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/budget.dart';
import '../services/firestore_service.dart';
import 'user_provider.dart';

/// Provider de orcamentos do usuario logado.
///
/// Escuta o stream do Firestore (budgets/{uid}/...) e mantem a lista em
/// memoria. O progresso (gasto vs limite) e calculado pelas telas a partir
/// das transacoes (TransactionProvider), nao aqui.
class BudgetProvider extends ChangeNotifier {
  BudgetProvider({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  UserProvider? _userProvider;
  String? _uid;
  StreamSubscription<List<Budget>>? _sub;

  List<Budget> _budgets = const [];
  bool _loading = true;
  String? _error;

  List<Budget> get budgets => _budgets;
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
      _budgets = const [];
      _loading = false;
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    _sub = _firestore.budgetsStream(_uid!).listen(
      (list) {
        _budgets = list;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[BudgetProvider] stream error: $e');
        _error = e.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  Future<String> addBudget(Budget b) async {
    if (_uid == null) throw StateError('Usuário não autenticado.');
    return _firestore.addBudget(_uid!, b);
  }

  Future<void> updateBudget(Budget b) async {
    if (_uid == null) throw StateError('Usuário não autenticado.');
    await _firestore.updateBudget(_uid!, b);
  }

  Future<void> deleteBudget(String id) async {
    if (_uid == null) throw StateError('Usuário não autenticado.');
    await _firestore.deleteBudget(_uid!, id);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _userProvider?.removeListener(_onUserChanged);
    super.dispose();
  }
}