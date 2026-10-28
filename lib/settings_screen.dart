import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/user_provider.dart';
import 'services/auth_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_spacing.dart';
import 'theme/app_typography.dart';
import 'widgets/app_branded_header.dart';
import 'widgets/app_drawer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(currentRoute: 'settings'),
      appBar: const AppBrandedHeader(title: 'Configurações'),
      body: Consumer<UserProvider>(
        builder: (context, prov, _) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              _buildProfileHeader(prov),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Ajustes do Sistema',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppTypography.title,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Card(
                child: Column(
                  children: [
                    _buildSettingsTile(
                      context,
                      Icons.person_outline,
                      'Editar Perfil',
                      '/settings/profile',
                    ),
                    const Divider(height: 1),
                    _buildSettingsTile(
                      context,
                      Icons.notifications_none,
                      'Notificações',
                      '/settings/notifications',
                    ),
                    const Divider(height: 1),
                    _buildSettingsTile(
                      context,
                      Icons.lock_outline,
                      'Segurança e Privacidade',
                      '/settings/security',
                    ),
                    const Divider(height: 1),
                    _buildSettingsTile(
                      context,
                      Icons.help_outline,
                      'Ajuda & Suporte',
                      '/settings/help',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.danger),
                  title: const Text(
                    'Sair da Conta',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () async {
                    final nav = Navigator.of(context);
                    await context.read<AuthService>().signOut();
                    nav.pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserProvider prov) {
    final user = prov.user;
    final nome = user?.nome ?? 'Usuário';
    final email = user?.email ?? '';
    final initials = nome.split(' ').take(2).map((n) {
      if (n.isEmpty) return '?';
      return n[0].toUpperCase();
    }).join();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.greenPrimary,
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: AppTypography.title,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppTypography.section,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                      color: AppColors.textSec,
                      fontSize: AppTypography.body,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user?.empresa != null && user!.empresa!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      user.empresa!,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: AppTypography.secondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    IconData icon,
    String title,
    String route,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.gold),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: AppColors.textSec,
        size: 16,
      ),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }
}
