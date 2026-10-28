import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/budget_provider.dart';
import '../providers/ingredient_provider.dart';
import '../providers/product_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/categories.dart';
import '../utils/format.dart';
import '../widgets/app_branded_header.dart';
import '../widgets/app_drawer.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/list_skeleton.dart';
import '../widgets/section_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static bool _runCheckDone = false;
  String? _checkedUid;

  static const List<String> _weekdays = [
    'Domingo',
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
  ];

  static const List<String> _months = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(currentRoute: 'dashboard'),
      appBar: const AppBrandedHeader(goldLogo: true),
      floatingActionButton: _buildFab(),
      body: Consumer5<TransactionProvider, UserProvider, BudgetProvider,
          ProductProvider, IngredientProvider>(
        builder: (context, tx, userProvider, bp, pp, ip, _) {
          _maybeRunChecks(tx, userProvider, bp, pp, ip);
          if (tx.loading) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.l),
              child: ListSkeleton(itemCount: 6, itemHeight: 76),
            );
          }
          if (tx.error != null) {
            return ErrorState(
              message: tx.error!,
              onRetry: () => context.read<TransactionProvider>().reload(),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreeting(userProvider),
                const SizedBox(height: AppSpacing.xl),
                _buildHeroCard(tx),
                const SizedBox(height: AppSpacing.xxl),
                _buildQuickActions(context),
                const SizedBox(height: AppSpacing.xxl),
                _buildRecentTransactions(context, tx),
                const SizedBox(height: AppSpacing.xxl),
                const SizedBox(height: 96),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget? _buildFab() {
    final tx = context.watch<TransactionProvider>();
    if (tx.loading || tx.error != null) return null;
    return FloatingActionButton(
      onPressed: () => Navigator.pushNamed(context, '/transaction-form'),
      child: const Icon(Icons.add),
    );
  }

  void _maybeRunChecks(
    TransactionProvider tx,
    UserProvider userProvider,
    BudgetProvider bp,
    ProductProvider pp,
    IngredientProvider ip,
  ) {
    final user = userProvider.user;
    final uid = userProvider.uid;
    if (user == null || uid == null) return;
    if (_runCheckDone && _checkedUid == uid) return;
    if (tx.loading || bp.loading || pp.loading || ip.loading) return;
    if (tx.transactions.isEmpty &&
        bp.budgets.isEmpty &&
        pp.list.isEmpty &&
        ip.list.isEmpty) {
      return;
    }

    _runCheckDone = true;
    _checkedUid = uid;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await NotificationService.instance.runStartupChecks(
          user: user,
          budgets: bp.budgets,
          transactions: tx.transactions,
          products: pp.list,
          ingredients: ip.list,
        );
      } catch (_) {}
    });
  }

  String _greetingDate() {
    final now = DateTime.now();
    return '${_weekdays[now.weekday % 7]}, ${now.day} de ${_months[now.month - 1]}';
  }

  Widget _buildGreeting(UserProvider userProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Olá, ${userProvider.user?.nome.split(' ').first ?? ''}!',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppTypography.title,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _greetingDate(),
          style: TextStyle(
            color: AppColors.textSec,
            fontSize: AppTypography.secondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          'Visão operacional do negócio',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: AppTypography.caption,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(TransactionProvider tx) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Saldo do negócio',
                  style: TextStyle(
                    color: AppColors.textSec,
                    fontSize: AppTypography.secondary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/reports'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.insights_outlined, size: 14),
                label: const Text('Relatórios'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatCurrency(tx.saldo),
              style: AppTypography.number(
                fontSize: AppTypography.hero,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(
          icon: Icons.bolt_outlined,
          title: 'Ações rápidas',
        ),
        const SizedBox(height: AppSpacing.m),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildQuickAction(
                  context,
                  icon: Icons.inventory_2_outlined,
                  label: 'Ver produtos',
                  hint: 'Itens das fichas',
                  route: '/ingredients',
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: _buildQuickAction(
                  context,
                  icon: Icons.restaurant_menu,
                  label: 'Fichas técnicas',
                  hint: 'Custo e ticket',
                  route: '/products',
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: _buildQuickAction(
                  context,
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Novo orçamento',
                  hint: 'Limites por categoria',
                  route: '/budget-form',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String hint,
    required String route,
  }) {
    return Material(
      color: AppColors.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.gold, size: 20),
              const SizedBox(height: AppSpacing.m),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: AppTypography.secondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                hint,
                style: const TextStyle(
                  color: AppColors.textSec,
                  fontSize: AppTypography.caption,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context, TransactionProvider tx) {
    final recent = tx.transactions.take(5).toList();
    return Column(
      children: [
        SectionHeader(
          icon: Icons.receipt_long_outlined,
          title: 'Movimentações recentes',
          trailing: TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/expenses'),
            child: Text(
              'Ver todas',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: AppTypography.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        if (recent.isEmpty)
          EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Nenhuma movimentação ainda',
            message: 'Registre a primeira venda ou custo do negócio.',
            actionLabel: 'Nova Transação',
            onAction: () => Navigator.pushNamed(context, '/transaction-form'),
          )
        else
          Column(
            children: recent.map((t) => _buildTransactionItem(t)).toList(),
          ),
      ],
    );
  }

  Widget _buildTransactionItem(AppTransaction t) {
    final cat = findCategory(t.category, isIncome: t.type.isReceita);
    final isIncome = t.type.isReceita;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.background,
            child: Icon(cat.icon, color: cat.color, size: 20),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.description,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${t.category} • ${formatDateShort(t.date)}',
                  style: TextStyle(
                    color: AppColors.textSec,
                    fontSize: AppTypography.caption,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${formatCurrencyAbs(t.amount)}',
            style: AppTypography.number(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w600,
              color: isIncome ? AppColors.success : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}
