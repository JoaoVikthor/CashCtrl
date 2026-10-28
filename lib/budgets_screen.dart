import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/budget.dart';
import '../models/transaction.dart';
import '../providers/budget_provider.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/categories.dart';
import '../utils/format.dart';
import '../widgets/app_branded_header.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_toast.dart';
import '../widgets/error_state.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(currentRoute: 'budgets'),
      appBar: const AppBrandedHeader(title: 'Orçamentos'),
      body: Consumer2<BudgetProvider, TransactionProvider>(
        builder: (context, bp, tx, _) {
          if (bp.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }
          if (bp.error != null) {
            return const ErrorState(
              message: 'Não foi possível carregar os orçamentos.\n'
                  'Verifique sua conexão e tente novamente.',
            );
          }
          final spentByCat = _spentByCategory(tx);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Limites do negócio',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppTypography.title,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Acompanhe quanto o negócio já gastou em cada categoria neste mês.',
                  style: TextStyle(
                    color: AppColors.textSec,
                    fontSize: AppTypography.body,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (bp.budgets.isEmpty) _buildEmpty(context),
                for (final b in bp.budgets)
                  _buildBudgetProgress(
                    context,
                    b,
                    spentByCat[b.category] ?? 0,
                  ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/budget-form'),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Novo Orçamento',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Map<String, double> _spentByCategory(TransactionProvider tx) {
    final now = DateTime.now();
    final map = <String, double>{};
    for (final t in tx.transactions) {
      if (t.type.isReceita) continue;
      if (t.date.month == now.month && t.date.year == now.year) {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }

  Widget _buildEmpty(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_outlined,
            color: AppColors.textSec,
            size: 40,
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            'Crie seu primeiro orçamento',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppTypography.section,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Defina limites por categoria e acompanhe os custos do negócio.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSec,
              fontSize: AppTypography.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetProgress(
    BuildContext context,
    Budget b,
    double spent,
  ) {
    final percent = b.limit > 0 ? (spent / b.limit).clamp(0.0, 1.0) : 0.0;
    final isOver = spent > b.limit;
    final remaining = b.limit - spent;
    final cat = findCategory(b.category);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.l),
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(cat.icon, color: cat.color, size: 18),
                  const SizedBox(width: AppSpacing.s),
                  Text(
                    b.category,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                color: AppColors.card,
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.textSec,
                  size: 18,
                ),
                onSelected: (v) async {
                  if (v == 'edit') {
                    if (!context.mounted) return;
                    Navigator.pushNamed(
                      context,
                      '/budget-form',
                      arguments: b,
                    );
                  } else if (v == 'delete') {
                    await context.read<BudgetProvider>().deleteBudget(b.id);
                    if (!context.mounted) return;
                    AppToast.success(context, 'Orçamento excluído.');
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text(
                      'Editar',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Excluir',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${formatCurrencyAbs(spent)} / ${formatCurrencyAbs(b.limit)}',
                style: TextStyle(
                  color: isOver ? AppColors.danger : AppColors.gold,
                  fontSize: AppTypography.body,
                ),
              ),
              Text(
                isOver
                    ? 'Ultrapassou'
                    : 'Falta ${formatCurrencyAbs(remaining)}',
                style: TextStyle(
                  color: isOver ? AppColors.danger : AppColors.success,
                  fontSize: AppTypography.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: percent,
              color: isOver ? AppColors.danger : cat.color,
              backgroundColor: AppColors.background,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            '${(percent * 100).toStringAsFixed(0)}% usado',
            style: TextStyle(
              color: AppColors.textSec,
              fontSize: AppTypography.caption,
            ),
          ),
        ],
      ),
    );
  }
}
