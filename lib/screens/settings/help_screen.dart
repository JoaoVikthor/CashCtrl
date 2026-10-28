import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/app_info.dart';
import '../../widgets/app_branded_header.dart';
import '../../widgets/app_toast.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppBrandedHeader(title: 'Ajuda & Suporte', showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text(
            'Central de ajuda',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppTypography.title,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Tire dúvidas e encontre suporte.',
            style: TextStyle(
              color: AppColors.textSec,
              fontSize: AppTypography.body,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _tile(Icons.menu_book_outlined, 'Como usar o CashCtrl', () {
            _showInfo(context,
                'O CashCtrl organiza o negócio em transações, orçamentos, produtos e fichas técnicas. Use o menu para navegar entre as telas.');
          }),
          _tile(Icons.receipt_long_outlined, 'Registrar transações', () {
            _showInfo(context,
                'Em "Transações", toque no + para registrar uma receita ou despesa do negócio. Informe valor, categoria e data.');
          }),
          _tile(Icons.account_balance_outlined, 'Criar orçamentos', () {
            _showInfo(context,
                'Em "Orçamentos", defina um limite mensal por categoria. O app calcula quanto o negócio já gastou.');
          }),
          _tile(Icons.inventory_2_outlined, 'Produtos', () {
            _showInfo(context,
                'Em "Produtos", cadastre os itens que você compra. O app calcula o preço por unidade automaticamente (ex.: preço por grama) e compara fornecedores.');
          }),
          _tile(Icons.lunch_dining_outlined, 'Ficha técnica / Ticket', () {
            _showInfo(context,
                'Em "Fichas técnicas", crie um prato selecionando os produtos, a quantidade usada, mão de obra e embalagem. O app mostra o custo por item e se o prato dá lucro ou prejuízo.');
          }),
          _tile(Icons.support_agent_outlined, 'Falar com suporte', () {
            AppToast.info(context, 'Contato: suporte@ctrlcash.app');
          }),
          _tile(Icons.bug_report_outlined, 'Reportar um problema', () {
            _showReportDialog(context);
          }),
          const SizedBox(height: AppSpacing.xxl),
          const Text(
            'Sobre o app',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Container(
            padding: const EdgeInsets.all(AppSpacing.l),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppInfo.appName} ${AppInfo.version}',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppSpacing.s),
                Text(
                  'Gestão financeira do negócio com cálculo de ticket e ficha técnica de produtos.',
                  style: TextStyle(
                    color: AppColors.textSec,
                    fontSize: AppTypography.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ListTile(
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
        onTap: onTap,
      ),
    );
  }

  void _showInfo(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Ajuda',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          text,
          style: const TextStyle(color: AppColors.textSec),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Entendi',
              style: TextStyle(color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final controller = TextEditingController();
    const supportEmail = 'suporte@ctrlcash.app';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Reportar um problema',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Descreva o que aconteceu:',
              style: TextStyle(color: AppColors.textSec),
            ),
            const SizedBox(height: AppSpacing.m),
            TextField(
              controller: controller,
              maxLines: 4,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.background,
                hintText: 'Explique o problema...',
                hintStyle: const TextStyle(color: AppColors.textSec),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            const Text(
              'Envie para:',
              style: TextStyle(color: AppColors.textSec),
            ),
            const SizedBox(height: AppSpacing.s),
            Container(
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Row(
                children: [
                  Icon(Icons.email_outlined, color: AppColors.gold),
                  SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Text(
                      supportEmail,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSec),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                const ClipboardData(text: supportEmail),
              );
              if (!context.mounted) return;
              Navigator.pop(ctx);
              AppToast.success(
                context,
                'E-mail copiado — envie para suporte@ctrlcash.app',
              );
            },
            icon: const Icon(Icons.copy, color: Colors.white, size: 18),
            label: const Text(
              'Copiar e-mail',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
