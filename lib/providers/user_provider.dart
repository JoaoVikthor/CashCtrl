import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/firestore_service.dart';

/// Provider global de estado do usuario (ChangeNotifier).
///
/// Mantem o UID (do stream de autenticacao do Firebase) e o perfil completo
/// (nome, empresa, cnpj, segmento...) lido do Firestore.
class UserProvider extends ChangeNotifier {
  UserProvider({FirestoreService? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirestoreService(),
        _auth = auth;

  final FirestoreService _firestore;
  final FirebaseAuth? _auth;

  String? _uid;
  bool _isReady = false;
  AppUser? _user;
  bool _loadingProfile = false;
  String? _profileError;

  User? get _authUser {
    try {
      return (_auth ?? FirebaseAuth.instance).currentUser;
    } catch (_) {
      return null;
    }
  }

  String? get uid => _uid ?? _authUser?.uid;
  bool get hasSession => uid != null;
  String? get email => _user?.email ?? _authUser?.email;
  bool get isReady => _isReady;
  AppUser? get user => _user;
  bool get loadingProfile => _loadingProfile;
  String? get profileError => _profileError;
  bool? get notifOrcamento => _user?.notifOrcamento;
  bool? get notifRecorrentes => _user?.notifRecorrentes;
  bool? get notifMargem => _user?.notifMargem;

  void setUsuario(String? uid) {
    _uid = uid;
    _isReady = true;
    notifyListeners();
    if (uid != null) {
      loadProfile(uid);
    } else {
      _user = null;
    }
  }

  Future<void> loadProfile(String uid) async {
    _loadingProfile = true;
    _profileError = null;
    notifyListeners();
    try {
      _user = await _firestore.getUser(uid);
    } catch (e) {
      _profileError = e.toString();
    } finally {
      _loadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> saveUser(AppUser user) async {
    await _firestore.saveUser(user);
    _user = user;
    notifyListeners();
  }

  Future<void> updateNotificationPrefs({
    bool? orcamento,
    bool? recorrentes,
    bool? margem,
  }) async {
    if (_user == null) return;
    final previous = _user!;
    final updated = previous.copyWith(
      notifOrcamento: orcamento,
      notifRecorrentes: recorrentes,
      notifMargem: margem,
    );
    _user = updated;
    notifyListeners();
    try {
      await _firestore.saveUser(updated);
    } catch (e) {
      _user = previous;
      notifyListeners();
      rethrow;
    }
  }

  void limpar() {
    _uid = null;
    _isReady = false;
    _user = null;
    _profileError = null;
    notifyListeners();
  }

  Future<void> reloadProfile() async {
    if (_uid != null) await loadProfile(_uid!);
  }
}