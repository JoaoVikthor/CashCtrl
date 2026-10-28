import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/categories.dart';
import '../utils/format.dart';

class CategoryPieChart extends StatefulWidget {
  final Map<String, double> values;
  final String centerLabel;
  final double total;

  const CategoryPieChart({
    super.key,
    required this.values,
    this.centerLabel = 'Despesas',
    required this.total,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final entries = widget.values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty || widget.total <= 0) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.donut_small_outlined,
                size: 56,
                color: AppColors.textPrimary.withValues(alpha: 0.2),
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                'Sem despesas registradas',
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final cat = findCategory(e.key);
      final isTouched = _touched == i;
      final percent = (e.value / widget.total) * 100;
      final radius = isTouched ? 62.0 : 52.0;
      sections.add(PieChartSectionData(
        color: cat.color,
        value: e.value,
        radius: radius,
        title: isTouched
            ? '${e.key}\n${percent.toStringAsFixed(0)}%'
            : '${percent.toStringAsFixed(0)}%',
        titleStyle: TextStyle(
          fontSize: isTouched ? AppTypography.body : AppTypography.caption,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        borderSide: isTouched
            ? BorderSide(
                color: AppColors.textPrimary.withValues(alpha: 0.3),
                width: 2,
              )
            : BorderSide.none,
      ));
    }

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 38,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      _touched =
                          response?.touchedSection?.touchedSectionIndex;
                    });
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          flex: 4,
          child: SizedBox(
            height: 200,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (var i = 0; i < entries.length; i++)
                  _legendRow(
                    entries[i].key,
                    entries[i].value,
                    findCategory(entries[i].key).color,
                    _touched == i,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendRow(String name, double value, Color color, bool highlight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: highlight
                    ? AppColors.textPrimary
                    : AppColors.textPrimary.withValues(alpha: 0.7),
                fontSize: AppTypography.secondary,
                fontWeight:
                    highlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            formatCurrencyAbs(value),
            style: AppTypography.number(
              color: AppColors.textPrimary,
              fontSize: AppTypography.caption,
            ),
          ),
        ],
      ),
    );
  }
}
