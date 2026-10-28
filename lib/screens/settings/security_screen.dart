import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_branded_header.dart';
import '../../widgets/app_toast.dart';
import 'terms_privacy_screen.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _isLoading = false;

  Future<void> _changePassword() async {
    final auth = context.read<AuthService>();
    final result = await _showPasswordAndValueDialog(
      title: 'Alterar senha',
      label: 'Nova senha',
      hint: 'Digite sua senha atual',
      obscureValue: true,
      valueValidator: (v) => v.length >= 6 ? null : 'Mínimo de 6 caracteres',
    );
    if (result == null || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await auth.reauthenticateWithPassword(result.password);
      await auth.updatePassword(result.value);
      if (!mounted) return;
      _showSuccess('Senha alterada com sucesso.');
    } on AuthException catch (e) {
      _showError(e.message);
    } on FirebaseAuthException catch (e) {
      _showError(_mapFirebaseError(e));
    } catch (_) {
      _showError('Ocorreu um erro ao alterar a senha.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeEmail() async {
    final auth = context.read<AuthService>();
    final result = await _showPasswordAndValueDialog(
      title: 'Alterar e-mail',
      label: 'Novo e-mail',
      hint: 'Digite sua senha atual',
      keyboardType: TextInputType.emailAddress,
      valueValidator: (v) => v.contains('@') ? null : 'Informe um e-mail válido',
    );
    if (result == null || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await auth.reauthenticateWithPassword(result.password);
      await auth.updateEmail(result.value);
      if (!mounted) return;
      _showSuccess('E-mail atualizado com sucesso.');
    } on AuthException catch (e) {
      _showError(e.message);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showError('Este e-mail já está em uso por outra conta.');
      } else {
        _showError(_mapFirebaseError(e));
      }
    } catch (_) {
      _showError('Ocorreu um erro ao alterar o e-mail.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    final password = await _showPasswordDialog(
      title: 'Excluir conta',
      description: 'Confirme sua senha para continuar.',
    );
    if (password == null || password.isEmpty || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await auth.reauthenticateWithPassword(password);
    } on AuthException catch (e) {
      _showError(e.message);
      if (mounted) setState(() => _isLoading = false);
      return;
    } on FirebaseAuthException catch (e) {
      _showError(_mapFirebaseError(e));
      if (mounted) setState(() => _isLoading = false);
      return;
    } catch (_) {
      _showError('Ocorreu um erro ao validar a senha.');
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Tem certeza?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Todos os seus dados serão apagados permanentemente. Esta ação não pode ser desfeita.',
          style: TextStyle(color: AppColors.textSec),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.gold),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    String? purgeError;
    try {
      final uid = auth.currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        throw AuthException('Não foi possível identificar o usuário.');
      }
      try {
        await firestore.purgeUserData(uid);
      } catch (e) {
        purgeError = e.toString();
      }
      await auth.deleteAccount();
      if (!mounted) return;
      if (purgeError != null) {
        _showError('Conta excluída, mas alguns dados podem ter ficado retidos.');
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } on FirebaseAuthException catch (e) {
      _showError(_mapFirebaseError(e));
    } catch (_) {
      _showError('Ocorreu um erro ao excluir a conta.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _showPasswordDialog({
    required String title,
    required String description,
  }) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: const TextStyle(color: AppColors.textSec),
            ),
            const SizedBox(height: AppSpacing.l),
            TextField(
              controller: controller,
              obscureText: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Senha atual',
                labelStyle: const TextStyle(color: AppColors.textSec),
                filled: true,
                fillColor: AppColors.background,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: AppColors.textPrimary.withValues(alpha: 0.08),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(
                    color: AppColors.gold,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.gold),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text(
              'Continuar',
              style: TextStyle(color: AppColors.greenPrimary),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  Future<_PasswordValue?> _showPasswordAndValueDialog({
    required String title,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureValue = false,
    required String? Function(String) valueValidator,
  }) async {
    final passwordController = TextEditingController();
    final valueController = TextEditingController();
    String? errorText;
    final result = await showDialog<_PasswordValue>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(
            title,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: hint,
                  labelStyle: const TextStyle(color: AppColors.textSec),
                  filled: true,
                  fillColor: AppColors.background,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                      color: AppColors.textPrimary.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(
                      color: AppColors.gold,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              TextField(
                controller: valueController,
                obscureText: obscureValue,
                keyboardType: keyboardType,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(color: AppColors.textSec),
                  errorText: errorText,
                  filled: true,
                  fillColor: AppColors.background,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                      color: AppColors.textPrimary.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(
                      color: AppColors.gold,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppColors.gold),
              ),
            ),
            TextButton(
              onPressed: () {
                final value = valueController.text.trim();
                final validation = valueValidator(value);
                if (validation != null) {
                  setStateDialog(() => errorText = validation);
                  return;
                }
                Navigator.pop(
                  ctx,
                  _PasswordValue(
                    password: passwordController.text,
                    value: value,
                  ),
                );
              },
              child: const Text(
                'Salvar',
                style: TextStyle(color: AppColors.greenPrimary),
              ),
            ),
          ],
        ),
      ),
    );
    passwordController.dispose();
    valueController.dispose();
    return result;
  }

  void _showError(String message) {
    if (!mounted) return;
    AppToast.error(context, message);
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    AppToast.success(context, message);
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'invalid-credential':
        return 'Senha incorreta.';
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
      case 'requires-recent-login':
        return 'Faça login novamente para alterar esta informação.';
      default:
        return e.message ?? 'Ocorreu um erro inesperado.';
    }
  }

  void _openTermsPrivacy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TermsPrivacyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppBrandedHeader(
        title: 'Segurança e Privacidade',
        showBack: true,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Text(
                'Conta e acesso',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppTypography.title,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Gerencie como você protege sua conta.',
                style: TextStyle(
                  color: AppColors.textSec,
                  fontSize: AppTypography.body,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _tile(Icons.lock_outline, 'Alterar senha', _changePassword),
              _tile(Icons.email_outlined, 'E-mail de recuperação', _changeEmail),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Privacidade',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppTypography.title,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              _tile(
                Icons.privacy_tip_outlined,
                'Política de Privacidade',
                _openTermsPrivacy,
              ),
              _tile(
                Icons.description_outlined,
                'Termos de Uso',
                _openTermsPrivacy,
              ),
              _tile(
                Icons.delete_forever_outlined,
                'Excluir minha conta',
                _deleteAccount,
                isDanger: true,
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap,
      {bool isDanger = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ListTile(
        leading: Icon(icon, color: isDanger ? AppColors.danger : AppColors.gold),
        title: Text(
          title,
          style: TextStyle(
            color: isDanger ? AppColors.danger : AppColors.textPrimary,
            fontWeight: isDanger ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: AppColors.textSec,
          size: 16,
        ),
        onTap: _isLoading ? null : onTap,
      ),
    );
  }
}

class _PasswordValue {
  final String password;
  final String value;

  _PasswordValue({required this.password, required this.value});
}
