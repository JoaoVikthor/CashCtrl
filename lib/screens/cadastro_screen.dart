import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toast.dart';
import 'settings/terms_privacy_screen.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _aceitouTermos = false;
  bool _obscureSenha = true;
  bool _obscureConfirma = true;

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmaController = TextEditingController();
  final TextEditingController _empresaController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  final TextEditingController _segmentoController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();

  String? _nomeError;
  String? _emailError;
  String? _senhaError;
  String? _confirmaError;
  String? _empresaError;

  static const int _totalSteps = 2;

  @override
  void dispose() {
    _pageController.dispose();
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmaController.dispose();
    _empresaController.dispose();
    _cnpjController.dispose();
    _segmentoController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  void _clearNomeError() {
    if (_nomeError != null) setState(() => _nomeError = null);
  }

  void _clearEmailError() {
    if (_emailError != null) setState(() => _emailError = null);
  }

  void _clearSenhaError() {
    if (_senhaError != null) setState(() => _senhaError = null);
  }

  void _clearConfirmaError() {
    if (_confirmaError != null) setState(() => _confirmaError = null);
  }

  void _clearEmpresaError() {
    if (_empresaError != null) setState(() => _empresaError = null);
  }

  bool _validarEtapa1() {
    setState(() {
      _nomeError = null;
      _emailError = null;
      _senhaError = null;
      _confirmaError = null;
    });

    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text;
    final confirma = _confirmaController.text;
    bool valid = true;

    if (nome.isEmpty) {
      _nomeError = 'Informe o nome completo.';
      valid = false;
    }
    if (email.isEmpty || !email.contains('@')) {
      _emailError = 'Informe um e-mail válido.';
      valid = false;
    }
    if (senha.length < 6) {
      _senhaError = 'A senha deve ter ao menos 6 caracteres.';
      valid = false;
    }
    if (senha != confirma) {
      _confirmaError = 'As senhas não coincidem.';
      valid = false;
    }
    if (!_aceitouTermos) {
      _mostrarErro('É preciso aceitar os Termos de Uso.');
      valid = false;
    }

    if (!valid) setState(() {});
    return valid;
  }

  void _avancar() {
    if (_currentStep == 0) {
      if (!_validarEtapa1()) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentStep == 1) {
      _finalizarCadastro();
    }
  }

  void _voltar() {
    if (_currentStep == 0) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
    } else {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finalizarCadastro() async {
    if (_empresaController.text.trim().isEmpty) {
      setState(() => _empresaError = 'Informe o nome da empresa.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final appUser = AppUser(
        uid: '',
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        empresa: _empresaController.text.trim().isEmpty
            ? null
            : _empresaController.text.trim(),
        cnpj: _cnpjController.text.trim().isEmpty
            ? null
            : _cnpjController.text.trim(),
        segmento: _segmentoController.text.trim().isEmpty
            ? null
            : _segmentoController.text.trim(),
        telefone: _telefoneController.text.trim().isEmpty
            ? null
            : _telefoneController.text.trim(),
        endereco: _enderecoController.text.trim().isEmpty
            ? null
            : _enderecoController.text.trim(),
      );
      final user = await context.read<AuthService>().registerWithEmail(
            userProfile: appUser,
            password: _senhaController.text,
          );
      if (!mounted) return;
      await context.read<UserProvider>().loadProfile(user.uid);
      if (!mounted) return;
      AppToast.success(context, 'Cadastro realizado com sucesso!');
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
    } on AuthException catch (e) {
      _mostrarErro(e.message);
    } on FirebaseAuthException catch (e) {
      _mostrarErro(_mapFirebaseError(e));
    } catch (e) {
      _mostrarErro('Não foi possível concluir o cadastro: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    AppToast.error(context, mensagem);
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'weak-password':
        return 'Senha muito fraca.';
      default:
        return e.message ?? 'Erro ao cadastrar.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: _isLoading ? null : _voltar,
        ),
        title: Text(
          'Criar Conta',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppTypography.section,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.s),
            _buildStepIndicator(),
            const SizedBox(height: AppSpacing.m),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  _buildEtapaDadosPessoais(),
                  _buildEtapaNegocio(),
                ],
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final active = index == _currentStep;
          final done = index < _currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                  right: index == _totalSteps - 1 ? 0 : AppSpacing.s),
              height: 6,
              decoration: BoxDecoration(
                color: done
                    ? AppColors.greenPrimary
                    : active
                        ? AppColors.gold
                        : AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEtapaDadosPessoais() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Dados Pessoais', 'Conte-nos quem é você.'),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            controller: _nomeController,
            label: 'Nome completo',
            textInputAction: TextInputAction.next,
            errorText: _nomeError,
            onChanged: (_) => _clearNomeError(),
          ),
          const SizedBox(height: AppSpacing.m),
          AppTextField(
            controller: _emailController,
            label: 'E-mail',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            errorText: _emailError,
            onChanged: (_) => _clearEmailError(),
          ),
          const SizedBox(height: AppSpacing.m),
          AppTextField(
            controller: _senhaController,
            label: 'Senha',
            obscureText: _obscureSenha,
            textInputAction: TextInputAction.next,
            errorText: _senhaError,
            onChanged: (_) => _clearSenhaError(),
            suffix: IconButton(
              icon: Icon(
                _obscureSenha
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSec,
                size: 20,
              ),
              onPressed: () => setState(
                () => _obscureSenha = !_obscureSenha,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          AppTextField(
            controller: _confirmaController,
            label: 'Confirmação de senha',
            obscureText: _obscureConfirma,
            textInputAction: TextInputAction.done,
            errorText: _confirmaError,
            onChanged: (_) => _clearConfirmaError(),
            suffix: IconButton(
              icon: Icon(
                _obscureConfirma
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSec,
                size: 20,
              ),
              onPressed: () => setState(
                () => _obscureConfirma = !_obscureConfirma,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: _aceitouTermos,
                onChanged: (v) => setState(() => _aceitouTermos = v ?? false),
                activeColor: AppColors.greenPrimary,
                checkColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.textSec),
              ),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => setState(
                          () => _aceitouTermos = !_aceitouTermos),
                      child: Text(
                        'Aceito os ',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: AppTypography.body,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TermsPrivacyScreen()),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Termos de Uso',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: AppTypography.body,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEtapaNegocio() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Sobre o Negócio', 'Informações da sua empresa.'),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            controller: _empresaController,
            label: 'Nome da Empresa',
            textInputAction: TextInputAction.next,
            errorText: _empresaError,
            onChanged: (_) => _clearEmpresaError(),
          ),
          const SizedBox(height: AppSpacing.m),
          AppTextField(
            controller: _cnpjController,
            label: 'CNPJ (Opcional)',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.m),
          AppTextField(
            controller: _segmentoController,
            label: 'Segmento',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.m),
          AppTextField(
            controller: _telefoneController,
            label: 'Telefone Comercial',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.m),
          AppTextField(
            controller: _enderecoController,
            label: 'Endereço',
            textInputAction: TextInputAction.done,
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.s),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppTypography.title,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: TextStyle(
            color: AppColors.textSec,
            fontSize: AppTypography.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    final isLast = _currentStep == _totalSteps - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.s,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: _isLoading ? null : _voltar,
            child: Text(
              _currentStep == 0 ? 'Cancelar' : 'Voltar',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: AppTypography.body,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _avancar,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.textPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isLast ? 'Finalizar Cadastro' : 'Próximo',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: AppTypography.section,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
