import 'package:fl_chart/fl_chart.dart';
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
import '../widgets/category_pie_chart.dart';
import '../widgets/export_excel_button.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const List<String> _months = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(currentRoute: 'reports'),
      appBar: const AppBrandedHeader(title: 'Relatórios'),
      body: Consumer<TransactionProvider>(
        builder: (context, tx, _) {
          if (tx.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }
          if (tx.error != null) {
            return _buildError();
          }
          if (tx.transactions.isEmpty) {
            return _buildEmpty();
          }
          final monthly = _monthlyData(tx.transactions);
          final byCategory = <String, double>{};
          double totalDespesas = 0;
          for (final t in tx.transactions) {
            if (t.type.isReceita) continue;
            byCategory[t.category] =
                (byCategory[t.category] ?? 0) + t.amount;
            totalDespesas += t.amount;
          }
          final totalReceitas = tx.totalReceitas;
          final lucro = totalReceitas - totalDespesas;
          final margem = totalReceitas > 0
              ? (lucro / totalReceitas) * 100
              : 0.0;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Desempenho e análise do negócio',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: AppTypography.caption,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Desempenho',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: AppTypography.title,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    ExportExcelButton(
                      transactions: tx.transactions,
                      periodLabel: 'Últimos 6 meses',
                      fileName: 'relatorio_cashctrl_ultimos_6_meses.xlsx',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Análise dos últimos 6 meses do negócio',
                  style: TextStyle(
                    color: AppColors.textSec,
                    fontSize: AppTypography.body,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildKpiRow(lucro, margem, totalReceitas, totalDespesas),
                const SizedBox(height: AppSpacing.xxl),
                _buildMonthlyChart(monthly),
                const SizedBox(height: AppSpacing.xxl),
                _buildPieSection(byCategory, totalDespesas),
                const SizedBox(height: AppSpacing.xxl),
                _buildTopCategories(byCategory),
                const SizedBox(height: AppSpacing.l),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bar_chart_outlined,
              size: 56,
              color: AppColors.textSec,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Sem dados para relatórios',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppTypography.section,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Registre transações para ver análises.',
              style: TextStyle(
                color: AppColors.textSec,
                fontSize: AppTypography.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: AppColors.danger,
            ),
            SizedBox(height: AppSpacing.m),
            Text(
              'Não foi possível carregar os relatórios.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSec),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Verifique sua conexão e tente novamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: AppTypography.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_Monthly> _monthlyData(List<AppTransaction> all) {
    final now = DateTime.now();
    final list = <_Monthly>[];
    for (var i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i);
      double r = 0, e = 0;
      for (final t in all) {
        if (t.date.year == d.year && t.date.month == d.month) {
          if (t.type.isReceita) {
            r += t.amount;
          } else {
            e += t.amount;
          }
        }
      }
      list.add(_Monthly(_months[d.month - 1], r, e));
    }
    return list;
  }

  Widget _buildKpiRow(
    double lucro,
    double margem,
    double receitas,
    double despesas,
  ) {
    final isLucro = lucro >= 0;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.m,
      mainAxisSpacing: AppSpacing.m,
      childAspectRatio: 1.5,
      children: [
        _kpiCard(
          'Lucro Líquido',
          formatCurrency(lucro),
          isLucro ? AppColors.success : AppColors.danger,
          desc: isLucro ? 'Resultado positivo' : 'Resultado negativo',
        ),
        _kpiCard(
          'Margem de Lucro',
          '${margem.toStringAsFixed(1)}%',
          margem >= 0 ? AppColors.success : AppColors.danger,
          desc: 'Sobre as receitas',
        ),
        _kpiCard(
          'Total Receitas',
          formatCurrencyAbs(receitas),
          AppColors.success,
          desc: 'Entradas no período',
        ),
        _kpiCard(
          'Total de Custos',
          formatCurrencyAbs(despesas),
          AppColors.danger,
          desc: 'Custos no período',
        ),
      ],
    );
  }

  Widget _kpiCard(String title, String value, Color color, {String? desc}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSec,
              fontSize: AppTypography.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTypography.number(
                color: color,
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (desc != null) ...[
            const Spacer(),
            Text(
              desc,
              style: const TextStyle(
                color: AppColors.textSec,
                fontSize: AppTypography.caption,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(List<_Monthly> data) {
    final maxV = data.fold<double>(
        0,
        (m, d) => d.receitas > m
            ? d.receitas
            : (d.despesas > m ? d.despesas : m));
    final chartMax =
        (maxV * 1.2).ceilToDouble().clamp(1.0, double.infinity).toDouble();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Receitas vs Custos',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Row(
            children: [
              _legend(AppColors.success, 'Receitas'),
              const SizedBox(width: AppSpacing.l),
              _legend(AppColors.danger, 'Custos'),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: chartMax,
                barGroups: List.generate(data.length, (i) {
                  final d = data[i];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: d.receitas,
                        color: AppColors.success,
                        width: 7,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppRadius.sm),
                          topRight: Radius.circular(AppRadius.sm),
                        ),
                      ),
                      BarChartRodData(
                        toY: d.despesas,
                        color: AppColors.danger,
                        width: 7,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppRadius.sm),
                          topRight: Radius.circular(AppRadius.sm),
                        ),
                      ),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= data.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.s),
                          child: Text(
                            data[i].label,
                            style: const TextStyle(
                              color: AppColors.textSec,
                              fontSize: AppTypography.caption,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppColors.textPrimary.withValues(alpha: 0.06),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.s),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSec,
            fontSize: AppTypography.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPieSection(Map<String, double> byCategory, double total) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Custos por categoria',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          CategoryPieChart(values: byCategory, total: total),
        ],
      ),
    );
  }

  Widget _buildTopCategories(Map<String, double> byCategory) {
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();
    final max = top.isEmpty ? 1.0 : top.first.value;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 5 Categorias',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          for (final e in top)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        e.key,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: AppTypography.body,
                        ),
                      ),
                      Text(
                        formatCurrencyAbs(e.value),
                        style: AppTypography.number(
                          color: AppColors.gold,
                          fontSize: AppTypography.body,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: LinearProgressIndicator(
                      value: e.value / max,
                      color: findCategory(e.key).color,
                      backgroundColor: AppColors.background,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Monthly {
  final String label;
  final double receitas;
  final double despesas;
  const _Monthly(this.label, this.receitas, this.despesas);
}
