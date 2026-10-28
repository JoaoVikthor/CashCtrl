import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/transaction.dart';
import '../services/firestore_service.dart';
import 'user_provider.dart';

/// Provider de transacoes (receitas e despesas) do usuario logado.
///
/// Escuta o stream do Firestore ja ordenado por data (desc). Recebe o
/// [UserProvider] para obter o UID atual e reconectar o stream quando o
/// usuario muda (login/logout).
class TransactionProvider extends ChangeNotifier {
  TransactionProvider({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  UserProvider? _userProvider;
  String? _uid;
  StreamSubscription<List<AppTransaction>>? _sub;
  String? _generationUid;

  List<AppTransaction> _transactions = const [];
  bool _loading = true;
  String? _error;

  List<AppTransaction> get transactions => _transactions;
  bool get loading => _loading;
  String? get error => _error;

  double get totalReceitas => _transactions
      .where((t) => t.type.isReceita)
      .fold(0, (s, t) => s + t.amount);

  double get totalDespesas => _transactions
      .where((t) => !t.type.isReceita)
      .fold(0, (s, t) => s + t.amount);

  double get saldo => totalReceitas - totalDespesas;

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
      _transactions = const [];
      _loading = false;
      _generationUid = null;
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    _sub = _firestore.transactionsStream(_uid!).listen(
      (list) {
        _transactions = list;
        _loading = false;
        _error = null;
        notifyListeners();
        if (_uid != null && _generationUid != _uid) {
          _generationUid = _uid;
          _firestore
              .generateDueRecurrences(_uid!, list)
              .then((_) => 0)
              .catchError((e) {
            debugPrint(
                '[TransactionProvider] generateDueRecurrences error: $e');
            return 0;
          });
        }
      },
      onError: (e) {
        debugPrint('[TransactionProvider] stream error: $e');
        _error = e.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  Future<String> addTransaction(AppTransaction t) async {
    if (_uid == null) throw StateError('Usuário não autenticado.');
    return _firestore.addTransaction(_uid!, t);
  }

  Future<void> updateTransaction(AppTransaction t) async {
    if (_uid == null) throw StateError('Usuário não autenticado.');
    await _firestore.updateTransaction(_uid!, t);
  }

  Future<void> deleteTransaction(String id) async {
    if (_uid == null) throw StateError('Usuário não autenticado.');
    await _firestore.deleteTransaction(_uid!, id);
  }

  void reload() => _connect();

  @override
  void dispose() {
    _sub?.cancel();
    _userProvider?.removeListener(_onUserChanged);
    super.dispose();
  }
}