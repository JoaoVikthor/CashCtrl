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
import '../utils/recurrence.dart';
import '../widgets/app_toast.dart';
import '../widgets/filter_chip_row.dart';

class TransactionFormScreen extends StatefulWidget {
  final AppTransaction? editing;

  const TransactionFormScreen({
    super.key,
    this.editing,
  });

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  late TransactionType _type;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late DateTime _date;
  PaymentMethod _paymentMethod = PaymentMethod.dinheiro;
  late String _category;
  bool _recurring = false;
  String? _recurrence;
  final TextEditingController _notesController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.editing;
    _type = t?.type ?? TransactionType.despesa;
    _date = t?.date ?? DateTime.now();
    _paymentMethod = t?.paymentMethod ?? PaymentMethod.dinheiro;
    _category = t?.category ??
        (_type.isReceita
            ? kIncomeCategories.first.name
            : kExpenseCategories.first.name);
    _recurring = t?.recurring ?? false;
    _recurrence = t?.recurrence ?? (t?.recurring == true ? 'mensal' : null);
    if (t != null) {
      _amountController.text = t.amount.toStringAsFixed(2).replaceAll('.', ',');
      _descriptionController.text = t.description;
      _notesController.text = t.notes ?? '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<CategoryDef> get _categories =>
      _type.isReceita ? kIncomeCategories : kExpenseCategories;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.greenPrimary,
            onPrimary: Colors.white,
            surface: AppColors.card,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  bool _validate() {
    final raw = _amountController.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || value <= 0) {
      AppToast.error(context, 'Informe um valor válido maior que zero.');
      return false;
    }
    if (_descriptionController.text.trim().isEmpty) {
      AppToast.error(context, 'Informe uma descrição.');
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _saving = true);
    try {
      final raw = _amountController.text.trim().replaceAll(',', '.');
      final value = double.parse(raw);
      final t = AppTransaction.create(
        id: widget.editing?.id ?? '',
        type: _type,
        category: _category,
        description: _descriptionController.text.trim(),
        amount: value,
        date: _date,
        paymentMethod: _paymentMethod,
        recurring: _recurring,
        recurrence: _recurrence,
        generatedFrom: widget.editing?.generatedFrom,
        skippedOccurrences: widget.editing?.skippedOccurrences ?? const [],
        receiptUrl: widget.editing?.receiptUrl,
        budgetId: widget.editing?.budgetId,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      final prov = context.read<TransactionProvider>();
      if (widget.editing == null) {
        await prov.addTransaction(t);
      } else {
        await prov.updateTransaction(t);
      }
      if (!mounted) return;
      AppToast.success(
        context,
        widget.editing == null
            ? 'Transação registrada!'
            : 'Transação atualizada!',
      );
      Navigator.pop(context);
    } on ArgumentError catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.message.toString());
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
          isEdit ? 'Editar Transação' : 'Nova Transação',
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
          vertical: AppSpacing.m,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTypeToggle(),
            const SizedBox(height: AppSpacing.xl),
            _buildAmountField(),
            const SizedBox(height: AppSpacing.l),
            _buildField(
              controller: _descriptionController,
              label: 'Descrição',
              icon: Icons.description_outlined,
              hint: 'Ex.: venda do dia, compra de produtos',
            ),
            const SizedBox(height: AppSpacing.l),
            _buildCategoryPicker(),
            const SizedBox(height: AppSpacing.l),
            _buildPaymentPicker(),
            const SizedBox(height: AppSpacing.l),
            _buildDateField(),
            const SizedBox(height: AppSpacing.l),
            _buildField(
              controller: _notesController,
              label: 'Observações (opcional)',
              icon: Icons.notes,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.m),
            if (widget.editing?.generatedFrom == null)
              SwitchListTile(
                value: _recurring,
                onChanged: (v) => setState(() {
                  _recurring = v;
                  _recurrence = v ? (_recurrence ?? 'mensal') : null;
                }),
                activeTrackColor: AppColors.greenPrimary,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Transação recorrente',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: const Text(
                  'Marca esta transação como recorrente (alertas automáticos em breve)',
                  style: TextStyle(
                    color: AppColors.textSec,
                    fontSize: AppTypography.secondary,
                  ),
                ),
              ),
            if (_recurring && widget.editing?.generatedFrom == null) ...[
              const SizedBox(height: AppSpacing.s),
              AppFilterChipRow(
                options: const ['Semanal', 'Mensal', 'Anual'],
                selectedIndex: kRecurrenceFrequencies.indexOf(_recurrence!),
                onSelected: (index) => setState(
                    () => _recurrence = kRecurrenceFrequencies[index]),
              ),
            ],
            const SizedBox(height: AppSpacing.s),
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
                    isEdit ? 'Salvar Alterações' : 'Registrar Transação',
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

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: _toggleButton(
              TransactionType.despesa,
              'Despesa',
              Icons.arrow_downward,
              AppColors.danger,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _toggleButton(
              TransactionType.receita,
              'Receita',
              Icons.arrow_upward,
              AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(
    TransactionType t,
    String label,
    IconData icon,
    Color color,
  ) {
    final selected = _type == t;
    return GestureDetector(
      onTap: () => setState(() {
        _type = t;
        _category = (t.isReceita ? kIncomeCategories : kExpenseCategories)
            .first
            .name;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
        decoration: BoxDecoration(
          color: selected ? AppColors.greenPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : color, size: 18),
            const SizedBox(width: AppSpacing.s),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xl,
        horizontal: AppSpacing.l,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _type.isReceita
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.danger.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Valor',
            style: TextStyle(
              color: AppColors.textSec,
              fontSize: AppTypography.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'R\$',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: AppTypography.title,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              SizedBox(
                width: 160,
                child: TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppTypography.hero,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: '0,00',
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPicker() {
    final options = <CategoryDef>[..._categories];
    if (!options.any((c) => c.name == _category)) {
      options.insert(
        0,
        findCategory(_category, isIncome: _type.isReceita),
      );
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

  Widget _buildPaymentPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PaymentMethod>(
          value: _paymentMethod,
          dropdownColor: AppColors.card,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.gold),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppTypography.body,
          ),
          items: PaymentMethod.values
              .map((m) => DropdownMenuItem(
                    value: m,
                    child: Row(
                      children: [
                        Icon(_paymentIcon(m), color: AppColors.gold, size: 20),
                        const SizedBox(width: AppSpacing.m),
                        Text(m.label),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _paymentMethod = v ?? _paymentMethod),
        ),
      ),
    );
  }

  IconData _paymentIcon(PaymentMethod m) => switch (m) {
        PaymentMethod.dinheiro => Icons.payments_outlined,
        PaymentMethod.credito => Icons.credit_card,
        PaymentMethod.debito => Icons.credit_card_outlined,
        PaymentMethod.pix => Icons.bolt,
        PaymentMethod.transferencia => Icons.account_balance_outlined,
        PaymentMethod.outro => Icons.more_horiz,
      };

  Widget _buildDateField() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.l,
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.gold,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.m),
            const Text(
              'Data',
              style: TextStyle(
                color: AppColors.textSec,
                fontSize: AppTypography.body,
              ),
            ),
            const Spacer(),
            Text(
              formatDate(_date),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSec),
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        prefixIcon: Icon(icon, color: AppColors.gold, size: 20),
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
}
