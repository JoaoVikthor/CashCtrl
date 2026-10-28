import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/app_info.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  static const List<_DrawerEntry> _items = [
    _DrawerEntry(icon: Icons.dashboard_outlined, label: 'Dashboard', route: '/dashboard'),
    _DrawerEntry(icon: Icons.inventory_2_outlined, label: 'Produtos', route: '/ingredients'),
    _DrawerEntry(icon: Icons.restaurant_menu_outlined, label: 'Fichas Técnicas', route: '/products'),
    _DrawerEntry(icon: Icons.account_balance_outlined, label: 'Orçamentos', route: '/budgets'),
    _DrawerEntry(icon: Icons.receipt_long_outlined, label: 'Transações', route: '/expenses'),
    _DrawerEntry(icon: Icons.bar_chart_outlined, label: 'Relatórios', route: '/reports'),
    _DrawerEntry(icon: Icons.settings_outlined, label: 'Configurações', route: '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final normalizedRoute =
        currentRoute.startsWith('/') ? currentRoute : '/$currentRoute';
    return Drawer(
      backgroundColor: AppColors.card,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const Divider(
              color: AppColors.border,
              thickness: 1,
              height: 1,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.s,
                  horizontal: AppSpacing.m,
                ),
                children: _items
                    .map((item) => _drawerTile(context, item, normalizedRoute))
                    .toList(growable: false),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.s,
                AppSpacing.xl,
                AppSpacing.xxl,
              ),
              child: Text(
                '${AppInfo.appName} ${AppInfo.version}',
                style: TextStyle(
                  color: AppColors.textSec,
                  fontSize: AppTypography.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.m,
        AppSpacing.xl,
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo_drawer.png',
            width: 40,
            height: 40,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.account_circle_outlined,
              color: AppColors.gold,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CashCtrl',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppTypography.title,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Adaptar. Resolver. Desenvolver.',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: AppTypography.secondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.textPrimary),
            tooltip: 'Fechar',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _drawerTile(BuildContext context, _DrawerEntry entry, String current) {
    final isSelected = current == entry.route;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.greenPrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.gold : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          Expanded(
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              leading: Icon(
                entry.icon,
                color: isSelected ? AppColors.textPrimary : AppColors.gold,
              ),
              title: Text(
                entry.label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                if (!isSelected) {
                  Navigator.pushReplacementNamed(context, entry.route);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerEntry {
  final IconData icon;
  final String label;
  final String route;

  const _DrawerEntry({
    required this.icon,
    required this.label,
    required this.route,
  });
}
