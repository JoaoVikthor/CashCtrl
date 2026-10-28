import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_branded_header.dart';
import '../../widgets/app_toast.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Set<String> _savingKeys = {};

  Future<void> _updatePref(String key, bool value) async {
    setState(() => _savingKeys.add(key));
    final provider = context.read<UserProvider>();
    try {
      switch (key) {
        case 'orcamento':
          await provider.updateNotificationPrefs(orcamento: value);
          break;
        case 'recorrentes':
          await provider.updateNotificationPrefs(recorrentes: value);
          break;
        case 'margem':
          await provider.updateNotificationPrefs(margem: value);
          break;
      }
      if (!mounted) return;
      AppToast.success(context, 'Preferência salva');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Erro ao salvar preferência: $e');
    } finally {
      if (mounted) setState(() => _savingKeys.remove(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final orcamento = provider.notifOrcamento ?? true;
    final recorrentes = provider.notifRecorrentes ?? true;
    final margem = provider.notifMargem ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppBrandedHeader(title: 'Notificações', showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text(
            'Preferências de alerta',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppTypography.title,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Alertas automáticos ao abrir o app',
            style: TextStyle(
              color: AppColors.textSec,
              fontSize: AppTypography.body,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _switchTile(
            title: 'Alerta de orçamento estourado',
            subtitle: 'Avisa quando um orçamento estourar',
            value: orcamento,
            saving: _savingKeys.contains('orcamento'),
            onChanged: (value) => _updatePref('orcamento', value),
          ),
          _switchTile(
            title: 'Lembrete de despesas recorrentes',
            subtitle: 'Avisa sobre contas recorrentes vencendo em até 3 dias',
            value: recorrentes,
            saving: _savingKeys.contains('recorrentes'),
            onChanged: (value) => _updatePref('recorrentes', value),
          ),
          _switchTile(
            title: 'Produtos com baixa margem',
            subtitle: 'Avisa quando um produto ficar no vermelho',
            value: margem,
            saving: _savingKeys.contains('margem'),
            onChanged: (value) => _updatePref('margem', value),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.l),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Row(
              children: [
                Icon(Icons.schedule, color: AppColors.gold),
                SizedBox(width: AppSpacing.m),
                Text(
                  'Horário das notificações',
                  style: TextStyle(color: AppColors.textSec),
                ),
                Spacer(),
                Text(
                  'Ao abrir o app',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required bool saving,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.xs),
        activeTrackColor: AppColors.greenPrimary,
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        subtitle: saving
            ? const Text(
                'Salvando...',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: AppTypography.secondary,
                ),
              )
            : Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSec,
                  fontSize: AppTypography.secondary,
                ),
              ),
        value: value,
        onChanged: saving ? null : onChanged,
      ),
    );
  }
}
