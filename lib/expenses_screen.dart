import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
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
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/list_skeleton.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  TransactionType? _filterType;
  String? _filterCategory;
  String _search = '';

  List<String> get _availableCategories {
    final tx = context.read<TransactionProvider>();
    final set = tx.transactions.map((t) => t.category).toSet();
    final list = <String>[];
    for (final c in [...kExpenseCategories, ...kIncomeCategories]) {
      if (set.contains(c.name)) list.add(c.name);
    }
    for (final c in set) {
      if (!list.contains(c)) list.add(c);
    }
    return list;
  }

  List<AppTransaction> get _filtered {
    final tx = context.read<TransactionProvider>();
    var list = tx.transactions;
    if (_filterType != null) {
      list = list.where((t) => t.type == _filterType).toList();
    }
    if (_filterCategory != null) {
      list = list.where((t) => t.category == _filterCategory).toList();
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((t) =>
              t.description.toLowerCase().contains(q) ||
              t.category.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  int get _typeFilterIndex {
    if (_filterCategory != null) return -1;
    if (_filterType == null) return 0;
    if (_filterType == TransactionType.receita) return 1;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(currentRoute: 'expenses'),
      appBar: const AppBrandedHeader(title: 'Transações'),
      body: Consumer<TransactionProvider>(
        builder: (context, tx, _) {
          if (tx.loading) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.l,
                AppSpacing.xl,
                AppSpacing.l,
              ),
              child: ListSkeleton(itemCount: 8, itemHeight: 72),
            );
          }
          if (tx.error != null) {
            return const ErrorState(
              message: 'Não foi possível carregar as transações.\n'
                  'Verifique sua conexão e tente novamente.',
            );
          }
          return Column(
            children: [
              _buildSummary(tx),
              _buildFilters(),
              Expanded(child: _buildList(tx)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/transaction-form'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummary(TransactionProvider tx) {
    final list = _filtered;
    final receitas = list
        .where((t) => t.type.isReceita)
        .fold<double>(0, (s, t) => s + t.amount);
    final despesas = list
        .where((t) => !t.type.isReceita)
        .fold<double>(0, (s, t) => s + t.amount);
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.l,
        AppSpacing.xl,
        AppSpacing.s,
      ),
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              'Receitas',
              formatCurrencyAbs(receitas),
              AppColors.success,
              Icons.arrow_upward,
            ),
          ),
          Container(
            width: 1,
            height: 38,
            color: AppColors.textPrimary.withValues(alpha: 0.08),
          ),
          Expanded(
            child: _summaryItem(
              'Despesas',
              formatCurrencyAbs(despesas),
              AppColors.danger,
              Icons.arrow_downward,
            ),
          ),
          Container(
            width: 1,
            height: 38,
            color: AppColors.textPrimary.withValues(alpha: 0.08),
          ),
          Expanded(
            child: _summaryItem(
              'Saldo',
              formatCurrency(receitas - despesas),
              (receitas - despesas) >= 0 ? AppColors.success : AppColors.danger,
              Icons.account_balance_wallet_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color.withValues(alpha: 0.7), size: 18),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSec,
            fontSize: AppTypography.caption,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppTypography.number(
              color: color,
              fontSize: AppTypography.body,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final categorySelected = _filterCategory != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.s,
        AppSpacing.xl,
        AppSpacing.m,
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Buscar por descrição ou categoria...',
              hintStyle: const TextStyle(color: AppColors.textTertiary),
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.gold, size: 20),
              filled: true,
              fillColor: AppColors.card,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(
                  color: AppColors.textPrimary.withValues(alpha: 0.06),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(
                  color: AppColors.gold,
                  width: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                AppFilterChipRow(
                  options: const ['Todas', 'Receitas', 'Despesas'],
                  selectedIndex: _typeFilterIndex == -1 ? 0 : _typeFilterIndex,
                  onSelected: (index) => setState(() {
                    _filterCategory = null;
                    switch (index) {
                      case 1:
                        _filterType = TransactionType.receita;
                        break;
                      case 2:
                        _filterType = TransactionType.despesa;
                        break;
                      default:
                        _filterType = null;
                    }
                  }),
                ),
                const SizedBox(width: AppSpacing.s),
                PopupMenuButton<String>(
                  color: AppColors.card,
                  onSelected: (v) => setState(() {
                    _filterCategory = v;
                    _filterType = null;
                  }),
                  itemBuilder: (_) => _availableCategories
                      .map((c) => PopupMenuItem(
                            value: c,
                            child: Text(
                              c,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ))
                      .toList(),
                  child: _categoryChip(categorySelected),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.s,
      ),
      decoration: BoxDecoration(
        color: selected ? AppColors.greenPrimary : AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _filterCategory ?? 'Categoria',
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSec,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: AppTypography.body,
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          const Icon(
            Icons.filter_list,
            color: AppColors.textSec,
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildList(TransactionProvider tx) {
    final list = _filtered;
    if (list.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Nenhuma transação encontrada',
        message: 'Use o botão + para registrar uma venda ou um custo.',
        actionLabel: 'Nova transação',
        onAction: () => Navigator.pushNamed(context, '/transaction-form'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xs,
        AppSpacing.xl,
        AppSpacing.xxxl,
      ),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final t = list[i];
        final cat = findCategory(t.category, isIncome: t.type.isReceita);
        final isIncome = t.type.isReceita;
        return Dismissible(
          key: ValueKey(t.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppSpacing.xl),
            margin: const EdgeInsets.only(bottom: AppSpacing.m),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.delete, color: AppColors.danger),
          ),
          confirmDismiss: (_) => _confirmDeleteBool(t),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.m),
            padding: const EdgeInsets.all(AppSpacing.l),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.background,
                  child: Icon(cat.icon, color: cat.color, size: 20),
                ),
                const SizedBox(width: AppSpacing.l),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.description,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.s,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _tag(cat.name, cat.color),
                          Text(
                            t.paymentMethod.label,
                            style: const TextStyle(
                              color: AppColors.textSec,
                              fontSize: AppTypography.caption,
                            ),
                          ),
                          if (t.recurring)
                            const Icon(
                              Icons.repeat,
                              size: 12,
                              color: AppColors.gold,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        formatDate(t.date),
                        style: const TextStyle(
                          color: AppColors.textSec,
                          fontSize: AppTypography.caption,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'}${formatCurrencyAbs(t.amount)}',
                      style: AppTypography.number(
                        color: isIncome ? AppColors.success : AppColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PopupMenuButton<String>(
                      color: AppColors.card,
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppColors.textSec,
                        size: 18,
                      ),
                      onSelected: (v) {
                        if (v == 'edit') {
                          Navigator.pushNamed(
                            context,
                            '/transaction-form',
                            arguments: t,
                          );
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(
                            'Editar',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: AppTypography.caption,
        ),
      ),
    );
  }

  Future<bool?> _confirmDeleteBool(AppTransaction t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Excluir transação?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppTypography.title,
          ),
        ),
        content: Text(
          '"${t.description}" será removida permanentemente.',
          style: const TextStyle(color: AppColors.textSec),
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
    if (ok == true && mounted) {
      await context.read<TransactionProvider>().deleteTransaction(t.id);
      if (mounted) {
        AppToast.success(context, 'Transação excluída.');
      }
      return true;
    }
    return false;
  }
}
