import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import 'firestore_service.dart';

/// Servico de autenticacao do CashCtrl.
///
/// Centraliza o acesso ao FirebaseAuth e expoe o stream de estado de
/// autenticacao para ser consumido via [StreamProvider] no main.dart.
/// Mantem o isolamento por UID exigido pela RN02 nas regras do Firestore.
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirestoreService? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirestoreService();

  final FirebaseAuth _auth;
  final FirestoreService _firestore;

  /// Stream do estado de autenticacao: emite o [User] atual ou null.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Usuario atualmente autenticado (ou null).
  User? get currentUser => _auth.currentUser;

  /// Login com e-mail e senha.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(friendlyAuthError(e));
    }
  }

  /// Registro com e-mail e senha + persistencia do perfil no Firestore
  /// (colecao users/{uid}). Recebe o modelo [AppUser] montado pela tela
  /// de cadastro (passo 1 + passo 2) e o salva apos criar o Auth user.
  Future<User> registerWithEmail({
    required AppUser userProfile,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: userProfile.email,
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) {
        throw AuthException('Não foi possível obter o UID do usuário.');
      }
      final withUid = AppUser(
        uid: uid,
        nome: userProfile.nome,
        email: userProfile.email,
        empresa: userProfile.empresa,
        cnpj: userProfile.cnpj,
        segmento: userProfile.segmento,
        telefone: userProfile.telefone,
        endereco: userProfile.endereco,
        photoUrl: userProfile.photoUrl,
      );
      await _firestore.saveUser(withUid);
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(friendlyAuthError(e));
    } on FirebaseException catch (e) {
      throw AuthException('Erro ao salvar perfil: ${e.message ?? e.toString()}');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(friendlyAuthError(e));
    }
  }

  Future<void> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw AuthException('Sessão inválida. Faça login novamente.');
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(friendlyAuthError(e));
    }
  }

  Future<void> updateEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('Nenhum usuário autenticado.');
    }
    try {
      await user.updateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      throw AuthException(friendlyAuthError(e));
    }
  }

  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('Nenhum usuário autenticado.');
    }
    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthException(friendlyAuthError(e));
    }
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('Nenhum usuário autenticado.');
    }
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(friendlyAuthError(e));
    }
  }

  /// Encerra a sessao atual.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Mapeia codigos de erro do FirebaseAuth para mensagens amigaveis em
  /// portugues, reutilizaveis pelas telas de Login/Cadastro.
  static String friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'Senha muito fraca.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      case 'operation-not-allowed':
        return 'Operação não permitida.';
      default:
        return e.message ?? 'Ocorreu um erro inesperado.';
    }
  }
}

/// Excecao de autenticacao com mensagem amigavel em portugues.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}