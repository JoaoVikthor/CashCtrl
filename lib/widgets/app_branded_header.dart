import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// AppBar padrao do CashCtrl com a logo (camaleao nas cores do app).
///
/// Por padrao mostra o botao de menu (hamburger) e abre o drawer. Em telas
/// sem drawer (ex.: sub-telas de Settings), passe [showBack]=true para
/// mostrar uma seta de "voltar" no lugar do menu.
class AppBrandedHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showLogo;
  final bool centerTitle;
  final bool showBack;
  final bool goldLogo;

  const AppBrandedHeader({
    super.key,
    this.title,
    this.showLogo = true,
    this.centerTitle = true,
    this.showBack = false,
    this.goldLogo = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: showBack
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/dashboard',
                    (route) => false,
                  );
                }
              },
            )
          : Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: AppColors.textPrimary),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
      title: title != null
          ? Text(
              title!,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            )
          : goldLogo
              ? ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    AppColors.gold,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 30,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                )
              : Image.asset(
                  'assets/images/logo.png',
                  height: 30,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
      centerTitle: centerTitle,
    );
  }
}
