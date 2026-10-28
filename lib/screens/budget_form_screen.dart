import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/budget.dart';
import '../../providers/budget_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/categories.dart';
import '../../utils/format.dart';
import '../../widgets/app_toast.dart';

class BudgetFormScreen extends StatefulWidget {
  final Budget? editing;

  const BudgetFormScreen({super.key, this.editing});

  @override
  State<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  final TextEditingController _limitController = TextEditingController();
  late String _category;
  bool _saving = false;
  String? _limitError;

  @override
  void initState() {
    super.initState();
    _category = widget.editing?.category ?? kExpenseCategories.first.name;
    if (widget.editing != null) {
      _limitController.text =
          widget.editing!.limit.toStringAsFixed(2).replaceAll('.', ',');
    }
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  bool _validate() {
    final raw = _limitController.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || value <= 0) {
      setState(() => _limitError = 'Informe um limite válido maior que zero.');
      return false;
    }
    setState(() => _limitError = null);
    return true;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _saving = true);
    try {
      final raw = _limitController.text.trim().replaceAll(',', '.');
      final value = double.parse(raw);
      final b = Budget(
        id: widget.editing?.id ?? '',
        category: _category,
        limit: value,
        monthly: true,
        createdAt: widget.editing?.createdAt ?? DateTime.now(),
      );
      final prov = context.read<BudgetProvider>();
      if (widget.editing == null) {
        await prov.addBudget(b);
      } else {
        await prov.updateBudget(b);
      }
      if (!mounted) return;
      AppToast.success(
        context,
        widget.editing == null ? 'Orçamento criado!' : 'Orçamento atualizado!',
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Editar Orçamento' : 'Novo Orçamento',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.l,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Defina a categoria e o limite mensal de custos do negócio.',
              style: TextStyle(
                color: AppColors.textSec,
                fontSize: AppTypography.body,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildQuickCategories(),
            const SizedBox(height: AppSpacing.l),
            _buildCategoryPicker(),
            const SizedBox(height: AppSpacing.l),
            _buildLimitField(),
            const SizedBox(height: AppSpacing.l),
            _buildInfoCard(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.s,
            AppSpacing.xxl,
            AppSpacing.xxl,
          ),
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    isEdit ? 'Salvar Alterações' : 'Criar Orçamento',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sugestões rápidas',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: kExpenseCategories.map((c) {
            final selected = c.name == _category;
            return Material(
              color: selected ? AppColors.greenPrimary : AppColors.card,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                side: BorderSide(
                  color: selected
                      ? AppColors.greenPrimary
                      : AppColors.textPrimary.withValues(alpha: 0.08),
                ),
              ),
              child: InkWell(
                onTap: () => setState(() => _category = c.name),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.s,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        c.icon,
                        size: 16,
                        color: selected ? Colors.white : c.color,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        c.name,
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.textSec,
                          fontSize: AppTypography.secondary,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryPicker() {
    final options = <CategoryDef>[...kExpenseCategories];
    if (!options.any((c) => c.name == _category)) {
      options.insert(0, findCategory(_category));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _category,
          dropdownColor: AppColors.card,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.gold),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppTypography.body,
          ),
          items: options
              .map((c) => DropdownMenuItem(
                    value: c.name,
                    child: Row(
                      children: [
                        Icon(c.icon, color: c.color, size: 20),
                        const SizedBox(width: AppSpacing.m),
                        Text(c.name),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _category = v ?? _category),
        ),
      ),
    );
  }

  Widget _buildLimitField() {
    return TextField(
      controller: _limitController,
      onChanged: (_) => setState(() => _limitError = null),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: 'Limite mensal (R\$)',
        labelStyle: const TextStyle(color: AppColors.textSec),
        errorText: _limitError,
        prefixIcon:
            const Icon(Icons.attach_money, color: AppColors.gold, size: 20),
        prefixText: 'R\$ ',
        prefixStyle: const TextStyle(color: AppColors.gold),
        filled: true,
        fillColor: AppColors.card,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
            color: AppColors.gold,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final raw = _limitController.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw) ?? 0;
    final diaria = value > 0 ? value / 30 : 0.0;
    final semanal = value > 0 ? value / 4.33 : 0.0;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.s),
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.greenPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.greenPrimary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.gold, size: 18),
              SizedBox(width: AppSpacing.s),
              Text(
                'Referência',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          _refRow('Por dia', formatCurrencyAbs(diaria)),
          _refRow('Por semana', formatCurrencyAbs(semanal)),
        ],
      ),
    );
  }

  Widget _refRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSec),
          ),
          Text(
            value,
            style: AppTypography.number(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
