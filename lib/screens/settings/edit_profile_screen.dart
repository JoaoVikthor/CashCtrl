import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/alert_banner.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/error_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _empresaController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  final TextEditingController _segmentoController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();
  bool _saving = false;
  bool _loaded = false;
  String? _loadedForUid;
  String? _photoUrl;

  @override
  void dispose() {
    _nomeController.dispose();
    _empresaController.dispose();
    _cnpjController.dispose();
    _segmentoController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  void _loadFromUser(AppUser? user) {
    if (user == null) {
      _loaded = true;
      return;
    }
    if (_loaded && _loadedForUid == user.uid) return;
    _loaded = true;
    _loadedForUid = user.uid;
    _nomeController.text = user.nome;
    _empresaController.text = user.empresa ?? '';
    _cnpjController.text = user.cnpj ?? '';
    _segmentoController.text = user.segmento ?? '';
    _telefoneController.text = user.telefone ?? '';
    _enderecoController.text = user.endereco ?? '';
    _photoUrl ??= user.photoUrl;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final provider = context.read<UserProvider>();
      final current = provider.user;
      final userUid = provider.uid;
      if (userUid == null) {
        throw StateError('Sessão expirada. Faça login novamente.');
      }
      final updated = AppUser(
        uid: userUid,
        nome: _nomeController.text.trim(),
        email: current?.email ?? provider.email ?? '',
        empresa: _empresaController.text.trim(),
        cnpj: _cnpjController.text.trim(),
        segmento: _segmentoController.text.trim(),
        telefone: _telefoneController.text.trim(),
        endereco: _enderecoController.text.trim(),
        photoUrl: _photoUrl,
        notifOrcamento: current?.notifOrcamento ?? true,
        notifRecorrentes: current?.notifRecorrentes ?? true,
        notifMargem: current?.notifMargem ?? true,
      );
      await provider.saveUser(updated);
      if (!mounted) return;
      AppToast.success(context, 'Perfil atualizado!');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Erro: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
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
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Editar Perfil',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<UserProvider>(
        builder: (context, prov, _) {
          if (prov.loadingProfile && !_loaded) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }
          if (prov.user == null && !prov.hasSession) {
            return ErrorState(
              message: prov.profileError ?? 'Perfil não carregado.',
              onRetry: () async {
                setState(() => _loaded = false);
                await prov.reloadProfile();
              },
            );
          }
          _loadFromUser(prov.user);
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl,
              vertical: AppSpacing.l,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (prov.user == null) ...[
                  _buildMissingProfileBanner(prov),
                  const SizedBox(height: AppSpacing.xl),
                ],
                _buildAvatar(prov.user?.nome ?? _nomeController.text),
                const SizedBox(height: AppSpacing.xl),
                _field(_nomeController, 'Nome completo', Icons.person_outline),
                const SizedBox(height: AppSpacing.l),
                _field(
                  _empresaController,
                  'Nome da Empresa',
                  Icons.store_outlined,
                ),
                const SizedBox(height: AppSpacing.l),
                _field(
                  _cnpjController,
                  'CNPJ (opcional)',
                  Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.l),
                _field(
                  _segmentoController,
                  'Segmento',
                  Icons.category_outlined,
                ),
                const SizedBox(height: AppSpacing.l),
                _field(
                  _telefoneController,
                  'Telefone Comercial',
                  Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.l),
                _field(
                  _enderecoController,
                  'Endereço',
                  Icons.location_on_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.s,
            AppSpacing.xxl,
            AppSpacing.xxl,
          ),
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Salvar Alterações',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMissingProfileBanner(UserProvider prov) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AlertBanner(
          message:
              'Não foi possível carregar o perfil salvo. Preencha e salve para recriá-lo.',
          icon: Icons.info_outline,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: prov.loadingProfile
                ? null
                : () async {
                    await prov.reloadProfile();
                    if (!mounted) return;
                    final error = prov.profileError;
                    if (error != null) {
                      AppToast.error(context, 'Erro: $error');
                    }
                  },
            icon: prov.loadingProfile
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      color: AppColors.gold,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.refresh,
                    size: 18,
                    color: AppColors.gold,
                  ),
            label: const Text(
              'Tentar carregar',
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(String? nome) {
    final initials = (nome?.isNotEmpty ?? false)
        ? nome!.split(' ').take(2).map((n) => n[0].toUpperCase()).join()
        : '?';
    return Center(
      child: CircleAvatar(
        radius: 48,
        backgroundColor: AppColors.greenPrimary,
        backgroundImage:
            _photoUrl != null ? NetworkImage(_photoUrl!) : null,
        child: _photoUrl != null
            ? null
            : Text(
                initials,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSec),
        prefixIcon: Icon(icon, color: AppColors.gold, size: 20),
        filled: true,
        fillColor: AppColors.card,
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
    );
  }
}
