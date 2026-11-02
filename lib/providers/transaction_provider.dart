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
  Timer? _retryTimer;
  int _retryCount = 0;
  bool _disposed = false;

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
      _transactions = const [];
      _loading = false;
      _generationUid = null;
      if (notify) notifyListeners();
      return;
    }
    _loading = true;
    if (notify) notifyListeners();
    final currentUid = _uid;
    _sub = _firestore.transactionsStream(_uid!).listen(
      (list) {
        _retryCount = 0;
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
        if (!_disposed &&
            _uid == currentUid &&
            e.toString().contains('permission-denied') &&
            _retryCount < 2) {
          _retryCount++;
          _retryTimer = Timer(const Duration(seconds: 1), () async {
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