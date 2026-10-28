import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ingredient.dart';
import '../models/ingredient_offer.dart';
import '../providers/ingredient_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import '../utils/format.dart';
import '../utils/offer_rules.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toast.dart';
import '../widgets/delta_price_text.dart';
import '../widgets/error_state.dart';
import '../widgets/offer_limit_banner.dart';

class OfferFormScreen extends StatefulWidget {
  final String ingredientId;
  final IngredientOffer? offer;

  const OfferFormScreen({
    super.key,
    required this.ingredientId,
    this.offer,
  });

  @override
  State<OfferFormScreen> createState() => _OfferFormScreenState();
}

class _OfferFormScreenState extends State<OfferFormScreen> {
  final _supplierController = TextEditingController();
  final _productNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController();
  final _notesController = TextEditingController();

  bool _saving = false;
  String? _supplierError;
  String? _priceError;
  String? _qtyError;

  @override
  void initState() {
    super.initState();
    final offer = widget.offer;
    if (offer != null) {
      _supplierController.text = offer.supplier;
      _productNameController.text = offer.productName;
      _priceController.text = _formatNumber(offer.packagePrice);
      _qtyController.text = _formatNumber(offer.packageQuantity);
      _notesController.text = offer.notes;
    }
  }

  @override
  void dispose() {
    _supplierController.dispose();
    _productNameController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatNumber(double value) {
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 2)
        .replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IngredientProvider>();
    final ingredient = provider.asMap[widget.ingredientId];
    final isEdit = widget.offer != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Voltar',
        ),
        title: Text(
          isEdit ? 'Editar oferta' : 'Nova oferta',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ingredient == null && !provider.loading
          ? const ErrorState(message: 'Produto não encontrado.')
          : _buildBody(ingredient, isEdit),
      bottomNavigationBar: ingredient == null
          ? null
          : _buildSaveBottom(ingredient, isEdit),
    );
  }

  Widget _buildBody(Ingredient? ingredient, bool isEdit) {
    if (ingredient == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    final price = _parse(_priceController.text);
    final qty = _parse(_qtyController.text);
    final perUnit = qty > 0 ? price / qty : 0.0;
    final notesLength = _notesController.text.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Informe o que você paga e quanto vem na embalagem. O app calcula o preço por unidade.',
            style: TextStyle(
                color: AppColors.textSec,
                fontSize: AppTypography.body),
          ),
          const SizedBox(height: 20),
          _field(
            controller: _supplierController,
            label: 'Nome do fornecedor',
            icon: Icons.storefront_outlined,
            errorText: _supplierError,
            helperText: 'Ex.: Distribuidora Central, Atacado do Zé',
          ),
          const SizedBox(height: 12),
          _field(
            controller: _productNameController,
            label: 'Nome do produto (como o fornecedor anuncia)',
            icon: Icons.local_offer_outlined,
            helperText: 'Ex.: Farinha de trigo tipo 1 — 5kg',
            maxLength: 80,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _field(
                  controller: _priceController,
                  label: 'Preço da embalagem (R\$)',
                  icon: Icons.attach_money,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  errorText: _priceError,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _field(
                  controller: _qtyController,
                  label: 'Qtd. da embalagem',
                  icon: Icons.scale_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  errorText: _qtyError,
                ),
              ),
              const SizedBox(width: 12),
              _unitChip(ingredient.unit.label),
            ],
          ),
          const SizedBox(height: 16),
          _buildPreview(ingredient, perUnit, qty),
          const SizedBox(height: 16),
          _field(
            controller: _notesController,
            label: 'Notas (opcional)',
            icon: Icons.notes_outlined,
            maxLines: 4,
            minLines: 2,
            maxLength: 200,
            helperText: notesLength > 160 ? '$notesLength/200' : null,
          ),
          if (isEdit && ingredient.activeOffer != null &&
              widget.offer?.id != ingredient.activeOffer!.id) ...[
            const SizedBox(height: 16),
            _buildCompareCard(ingredient.activeOffer!),
          ],
          if (!isEdit && ingredient.offersCount >= maxOffersPerIngredient) ...[
            const SizedBox(height: 16),
            OfferLimitBanner(current: ingredient.offersCount),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? errorText,
    String? helperText,
    String? counterText,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
    int? maxLines,
    int? minLines,
  }) {
    return AppTextField(
      controller: controller,
      label: label,
      icon: icon,
      keyboardType: keyboardType,
      errorText: errorText,
      helperText: helperText ?? counterText,
      maxLength: maxLength,
      maxLines: maxLines,
    );
  }

  Widget _unitChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        'unidade: $label',
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: AppTypography.body,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPreview(Ingredient ingredient, double perUnit, double qty) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              SizedBox(width: 8),
              Text(
                'Preço por unidade',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (qty <= 0)
            Text(
              'Informe a quantidade',
              style: AppTypography.number(
                color: AppColors.textPrimary,
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            Text(
              '${formatCurrencyAbs(perUnit)} / ${ingredient.unit.label}',
              style: AppTypography.number(
                color: AppColors.textPrimary,
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompareCard(IngredientOffer active) {
    final offer = widget.offer;
    if (offer == null) return const SizedBox.shrink();
    final delta = offer.pricePerUnit - active.pricePerUnit;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comparado com a oferta ativa',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: AppTypography.body,
            ),
          ),
          const SizedBox(height: 8),
          DeltaPriceText(delta: delta, fontSize: AppTypography.title),
          const SizedBox(height: 4),
          Text(
            'Ativa: ${active.supplier} · ${formatCurrencyAbs(active.pricePerUnit)}/un',
            style: const TextStyle(
                color: AppColors.textSec,
                fontSize: AppTypography.secondary),
          ),
          if (active.hasProductName) ...[
            const SizedBox(height: 2),
            Text(
              'Produto: ${active.productName}',
              style: const TextStyle(
                  color: AppColors.textSec,
                  fontSize: AppTypography.caption),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveBottom(Ingredient ingredient, bool isEdit) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: ElevatedButton(
          onPressed: _saving ? null : () => _save(ingredient, isEdit),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.greenPrimary,
            disabledBackgroundColor:
                AppColors.greenPrimary.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            elevation: 0,
          ),
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
                  isEdit ? 'Salvar alterações' : 'Salvar oferta',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _save(Ingredient ingredient, bool isEdit) async {
    setState(() {
      _supplierError = null;
      _priceError = null;
      _qtyError = null;
    });

    final supplier = _supplierController.text.trim();
    if (supplier.isEmpty) {
      setState(() => _supplierError = 'Informe o nome do fornecedor.');
      _toast('Fornecedor não pode ficar vazio.');
      return;
    }

    final price = _parse(_priceController.text);
    if (price <= 0) {
      setState(() => _priceError = 'Informe um preço maior que zero.');
      _toast('Preço da embalagem deve ser maior que zero.');
      return;
    }

    final qty = _parse(_qtyController.text);
    if (qty <= 0) {
      setState(() => _qtyError = 'Informe uma quantidade maior que zero.');
      _toast('Quantidade da embalagem deve ser maior que zero.');
      return;
    }

    if (!isEdit) {
      try {
        ensureOfferLimit(ingredient.offersCount);
      } catch (e) {
        _toast(e.toString());
        return;
      }
    }

    setState(() => _saving = true);

    try {
      final now = DateTime.now();
      final offer = IngredientOffer(
        id: isEdit ? widget.offer!.id : '',
        supplier: supplier,
        productName: _productNameController.text.trim(),
        packagePrice: price,
        packageQuantity: qty,
        isActive: isEdit ? widget.offer!.isActive : true,
        source: isEdit ? widget.offer!.source : 'manual',
        notes: _notesController.text.trim(),
        createdAt: isEdit ? widget.offer!.createdAt : now,
        updatedAt: now,
      );

      await context
          .read<IngredientProvider>()
          .upsertOffer(ingredient.id, offer);

      if (!mounted) return;
      AppToast.success(context, isEdit ? 'Oferta atualizada.' : 'Oferta salva.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _toast('Erro ao salvar oferta: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double _parse(String text) {
    return double.tryParse(text.trim().replaceAll(',', '.')) ?? 0;
  }

  void _toast(String msg) {
    AppToast.error(context, msg);
  }
}
