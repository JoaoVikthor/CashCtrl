import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearEmailError() {
    if (_emailError != null) setState(() => _emailError = null);
  }

  void _clearPasswordError() {
    if (_passwordError != null) setState(() => _passwordError = null);
  }

  bool _validarCampos() {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    bool valid = true;

    if (email.isEmpty) {
      _emailError = 'Informe o e-mail.';
      valid = false;
    } else if (!email.contains('@') || !email.contains('.')) {
      _emailError = 'Informe um e-mail válido.';
      valid = false;
    }

    if (password.isEmpty) {
      _passwordError = 'Informe a senha.';
      valid = false;
    }

    if (!valid) setState(() {});
    return valid;
  }

  Future<void> _login() async {
    if (!_validarCampos()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);
    try {
      await context.read<AuthService>().signInWithEmail(
            email: email,
            password: password,
          );
      _navegarParaDashboard();
    } on AuthException catch (e) {
      _mostrarErro(e.message);
    } on FirebaseAuthException catch (e) {
      _mostrarErro(_mapFirebaseError(e));
    } catch (_) {
      _mostrarErro('Ocorreu um erro ao entrar.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _esqueceuSenha() async {
    final controller = TextEditingController(text: _emailController.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          'Recuperar senha',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppTypography.section,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: AppTextField(
          controller: controller,
          label: 'E-mail',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: AppTypography.body,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.greenPrimary,
            ),
            child: Text(
              'Enviar',
              style: TextStyle(
                fontSize: AppTypography.body,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email == null || email.isEmpty || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await context.read<AuthService>().sendPasswordResetEmail(email);
      if (!mounted) return;
      AppToast.success(
        context,
        'Se o e-mail existir, você receberá uma mensagem de redefinição.',
      );
    } on AuthException catch (e) {
      _mostrarErro(e.message);
    } on FirebaseAuthException catch (e) {
      _mostrarErro(_mapFirebaseError(e));
    } catch (_) {
      _mostrarErro('Ocorreu um erro ao solicitar a redefinição.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navegarParaDashboard() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  void _irParaCadastro() {
    Navigator.pushNamed(context, '/cadastro');
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    AppToast.error(context, mensagem);
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
        return 'E-mail ou senha incorretos.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      default:
        return e.message ?? 'Erro ao entrar.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxxl),
              Image.asset(
                'assets/images/logo_camaleao_dourado.png',
                height: 84,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                'CashCtrl',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppTypography.hero,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Bem-vindo de volta!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSec,
                  fontSize: AppTypography.body,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              AppTextField(
                controller: _emailController,
                label: 'E-mail',
                hint: 'seu@email.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                errorText: _emailError,
                onChanged: (_) => _clearEmailError(),
              ),
              const SizedBox(height: AppSpacing.l),
              AppTextField(
                controller: _passwordController,
                label: 'Senha',
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                errorText: _passwordError,
                onChanged: (_) => _clearPasswordError(),
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSec,
                    size: 20,
                  ),
                  onPressed: () => setState(
                    () => _obscurePassword = !_obscurePassword,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _esqueceuSenha,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s,
                      vertical: AppSpacing.m,
                    ),
                    minimumSize: const Size(44, 44),
                  ),
                  child: Text(
                    'Esqueceu a senha?',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: AppTypography.body,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.textPrimary,
                        strokeWidth: 2,
                      ),
                      )
                    : const Text(
                        'Entrar',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: AppTypography.section,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'É seu Primeiro Acesso? ',
                    style: TextStyle(
                      color: AppColors.textSec,
                      fontSize: AppTypography.body,
                    ),
                  ),
                  GestureDetector(
                    onTap: _irParaCadastro,
                    child: Text(
                      'Registre-se',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: AppTypography.body,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
