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
import '../utils/pending_offers.dart';
import '../utils/unit_converter.dart';
import '../widgets/alert_banner.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toast.dart';
import '../widgets/section_header.dart';
import '../widgets/active_offer_marker.dart';
import '../widgets/best_price_chip.dart';

class IngredientFormScreen extends StatefulWidget {
  final Ingredient? editing;

  const IngredientFormScreen({super.key, this.editing});

  @override
  State<IngredientFormScreen> createState() => _IngredientFormScreenState();
}

class _IngredientFormScreenState extends State<IngredientFormScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _offerSupplierController =
      TextEditingController();
  final TextEditingController _offerProductNameController =
      TextEditingController();
  final TextEditingController _offerPriceController = TextEditingController();
  final TextEditingController _offerQtyController = TextEditingController();
  final TextEditingController _avgWeightController = TextEditingController();
  final TextEditingController _correctionFactorController =
      TextEditingController();
  final List<IngredientOffer> _pendingOffers = [];
  IngredientUnit _unit = IngredientUnit.grama;
  bool _saving = false;
  bool _showOfferForm = false;
  String? _nameError;
  String? _priceError;
  String? _qtyError;
  String? _offerSupplierError;
  String? _offerPriceError;
  String? _offerQtyError;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _nameController.text = e.name;
      _priceController.text =
          e.purchasePrice.toStringAsFixed(2).replaceAll('.', ',');
      _qtyController.text =
          e.packageQuantity.toStringAsFixed(e.packageQuantity % 1 == 0 ? 0 : 2)
              .replaceAll('.', ',');
      _unit = e.unit;
      final pm = e.averageUnitWeightGrams;
      _avgWeightController.text = pm != null ? formatQuantity(pm) : '';
      _correctionFactorController.text = formatQuantity(e.correctionFactor);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _offerSupplierController.dispose();
    _offerProductNameController.dispose();
    _offerPriceController.dispose();
    _offerQtyController.dispose();
    _avgWeightController.dispose();
    _correctionFactorController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _nameError = null;
      _priceError = null;
      _qtyError = null;
    });

    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = 'Informe o nome do produto.');
      AppToast.error(context, 'Informe o nome do produto.');
      return false;
    }
    final price =
        double.tryParse(_priceController.text.trim().replaceAll(',', '.'));
    if (price == null || price <= 0) {
      setState(() => _priceError = 'Informe um preço de compra válido (> 0).');
      AppToast.error(context, 'Informe um preço de compra válido (> 0).');
      return false;
    }
    final qty =
        double.tryParse(_qtyController.text.trim().replaceAll(',', '.'));
    if (qty == null || qty <= 0) {
      setState(() => _qtyError = 'Informe a quantidade da embalagem (> 0).');
      AppToast.error(context, 'Informe a quantidade da embalagem (> 0).');
      return false;
    }
    final pmText = _avgWeightController.text.trim();
    if (pmText.isNotEmpty) {
      final pm = double.tryParse(pmText.replaceAll(',', '.'));
      if (pm == null || pm <= 0) {
        AppToast.error(context, 'Peso médio da unidade inválido.');
        return false;
      }
    }
    final fcText = _correctionFactorController.text.trim();
    if (fcText.isNotEmpty) {
      final fc = double.tryParse(fcText.replaceAll(',', '.'));
      if (fc == null || fc <= 0) {
        AppToast.error(context, 'Fator de correção inválido.');
        return false;
      }
    }
    return true;
  }

  void _toast(String msg) {
    AppToast.error(context, msg);
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _saving = true);
    try {
      final name = _nameController.text.trim();
      final purchasePrice =
          double.parse(_priceController.text.trim().replaceAll(',', '.'));
      final packageQuantity =
          double.parse(_qtyController.text.trim().replaceAll(',', '.'));
      final pmText = _avgWeightController.text.trim();
      final double? avgWeight =
          pmText.isEmpty ? null : double.parse(pmText.replaceAll(',', '.'));
      final fcText = _correctionFactorController.text.trim();
      final double correctionFactor =
          fcText.isEmpty ? 1.0 : double.parse(fcText.replaceAll(',', '.'));
      final ing = widget.editing?.copyWith(
            name: name,
            unit: _unit,
            purchasePrice: purchasePrice,
            packageQuantity: packageQuantity,
            averageUnitWeightGrams: avgWeight,
            correctionFactor: correctionFactor,
          ) ??
          Ingredient(
            id: '',
            name: name,
            unit: _unit,
            purchasePrice: purchasePrice,
            packageQuantity: packageQuantity,
            createdAt: DateTime.now(),
            averageUnitWeightGrams: avgWeight,
            correctionFactor: correctionFactor,
          );
      final prov2 = context.read<IngredientProvider>();
      if (widget.editing == null) {
        final newId = await prov2.addIngredient(ing);
        var savedOffers = 0;
        String? offerFailure;
        for (final pending in _pendingOffers) {
          try {
            await prov2.upsertOffer(newId, pending);
            savedOffers++;
          } catch (e) {
            offerFailure ??= e is StateError ? e.message : e.toString();
          }
        }
        if (!mounted) return;
        if (offerFailure != null) {
          AppToast.error(
              context,
              'Produto cadastrado, mas $savedOffers de ${_pendingOffers.length} oferta(s) falharam: $offerFailure');
        } else if (savedOffers > 0) {
          AppToast.success(
              context, 'Produto cadastrado com $savedOffers oferta(s)!');
        } else {
          AppToast.success(context, 'Produto cadastrado!');
        }
        Navigator.pop(context);
        return;
      }
      await prov2.updateIngredient(ing);
      if (!mounted) return;
      AppToast.success(context, 'Produto atualizado!');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _toast('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatQuantity(double value) {
    return value
        .toStringAsFixed(value % 1 == 0 ? 0 : 2)
        .replaceAll('.', ',');
  }

  void _setUnit(IngredientUnit next) {
    if (next == _unit) return;
    if (_pendingOffers.isEmpty) {
      setState(() => _unit = next);
      return;
    }
    final previousLabel = _unit.label;
    final converted = <IngredientOffer>[];
    for (final offer in _pendingOffers) {
      final result = UnitConverter.convertToIngredientUnit(
          offer.packageQuantity, previousLabel, next.label);
      if (!result.converted && previousLabel != next.label) {
        AppToast.error(
            context,
            'Remova as ofertas pendentes antes de trocar para ${next.label}.');
        return;
      }
      converted.add(offer.copyWith(packageQuantity: result.value));
    }
    setState(() {
      _unit = next;
      _pendingOffers
        ..clear()
        ..addAll(converted);
    });
  }

  void _openOfferForm() {
    if (!canAddPendingOffer(_pendingOffers.length)) {
      AppToast.error(context,
          'Limite de $maxOffersPerIngredient ofertas por produto atingido.');
      return;
    }
    setState(() {
      _showOfferForm = true;
      _offerSupplierError = null;
      _offerPriceError = null;
      _offerQtyError = null;
    });
  }

  void _clearOfferForm() {
    _offerSupplierController.clear();
    _offerProductNameController.clear();
    _offerPriceController.clear();
    _offerQtyController.clear();
  }

  void _cancelOfferForm() {
    setState(() {
      _showOfferForm = false;
      _offerSupplierError = null;
      _offerPriceError = null;
      _offerQtyError = null;
    });
    _clearOfferForm();
  }

  void _addPendingOffer() {
    if (!canAddPendingOffer(_pendingOffers.length)) {
      AppToast.error(context,
          'Limite de $maxOffersPerIngredient ofertas por produto atingido.');
      return;
    }

    final validation = buildPendingOffer(
      supplier: _offerSupplierController.text,
      productName: _offerProductNameController.text,
      priceInput: _offerPriceController.text,
      quantityInput: _offerQtyController.text,
    );

    setState(() {
      _offerSupplierError = validation.supplierError;
      _offerPriceError = validation.priceError;
      _offerQtyError = validation.quantityError;
    });

    if (!validation.isValid) {
      AppToast.error(
          context, validation.firstError ?? 'Revise os dados da oferta.');
      return;
    }

    final offer = validation.offer!;
    if (pendingOffersHasSupplier(_pendingOffers, offer.supplier)) {
      setState(() =>
          _offerSupplierError = 'Você já adicionou esse fornecedor.');
      AppToast.error(
          context, 'Já existe uma oferta pendente desse fornecedor.');
      return;
    }

    setState(() {
      _pendingOffers.add(offer);
      _showOfferForm = false;
      _offerSupplierError = null;
      _offerPriceError = null;
      _offerQtyError = null;
    });
    _clearOfferForm();
    AppToast.success(
        context, 'Oferta adicionada. Ela será salva junto com o produto.');
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
          isEdit ? 'Editar Produto' : 'Novo Produto',
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
                'Cadastre um produto que você compra e que entra nas fichas técnicas. O app calcula o preço por unidade automaticamente.',
                style: TextStyle(
                    color: AppColors.textSec,
                    fontSize: AppTypography.body)),
            const SizedBox(height: 20),
            _field(_nameController, 'Nome do produto', Icons.inventory_2_outlined,
                errorText: _nameError),
            const SizedBox(height: 16),
            _field(_priceController, 'Preço de compra (R\$)',
                Icons.attach_money,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                errorText: _priceError),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    flex: 2,
                    child: _field(_qtyController, 'Qtd. da embalagem',
                        Icons.scale_outlined,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        errorText: _qtyError)),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _unitPicker(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _field(_avgWeightController, 'Peso médio da unidade (g)',
                Icons.scale_outlined,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 16),
            _field(_correctionFactorController, 'Fator de correção',
                Icons.percent,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                hint: '1,0 = sem perdas'),
            const SizedBox(height: 16),
            _buildPreview(),
            const SizedBox(height: 24),
            _buildDefaultSupplierSection(context),
            const SizedBox(height: 24),
            isEdit
                ? _buildOffersSection(context)
                : _buildPendingOffersSection(),
            const SizedBox(height: 16),
            const Text(
              'Você escolhe qual oferta entra no ticket. O app não troca sozinho.',
              style: TextStyle(
                  color: AppColors.textSec,
                  fontSize: AppTypography.secondary),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildSaveBottom(isEdit),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text,
      String? errorText,
      String? helperText,
      String? hint,
      int? maxLength}) {
    return AppTextField(
      controller: c,
      label: label,
      icon: icon,
      keyboardType: keyboardType,
      errorText: errorText,
      helperText: helperText,
      hint: hint,
      maxLength: maxLength,
    );
  }

  Widget _unitPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<IngredientUnit>(
          value: _unit,
          dropdownColor: AppColors.card,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.gold),
          style: const TextStyle(
              color: AppColors.textPrimary, fontSize: AppTypography.body),
          items: IngredientUnit.values
              .map((u) => DropdownMenuItem(
                  value: u,
                  child: Row(
                    children: [
                      const Icon(Icons.straighten,
                          color: AppColors.gold, size: 18),
                      const SizedBox(width: 8),
                      Text(u.label),
                    ],
                  )))
              .toList(),
          onChanged: (v) => _setUnit(v ?? _unit),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final price =
        double.tryParse(_priceController.text.trim().replaceAll(',', '.')) ?? 0;
    final qty =
        double.tryParse(_qtyController.text.trim().replaceAll(',', '.')) ?? 0;
    final perUnit = qty > 0 ? price / qty : 0.0;
    final active = widget.editing?.activeOffer;
    final pending = widget.editing == null && _pendingOffers.isNotEmpty
        ? _pendingOffers.first
        : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.greenPrimary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
              color: AppColors.greenPrimary.withValues(alpha: 0.3), width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.lightbulb_outline, color: AppColors.gold, size: 18),
            SizedBox(width: 8),
            Text('Preço por unidade base',
                style: TextStyle(
                    color: AppColors.gold, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Text('${formatCurrencyAbs(perUnit)} / ${_unit.label}',
              style: AppTypography.number(
                  color: AppColors.textPrimary,
                  fontSize: AppTypography.title,
                  fontWeight: FontWeight.bold)),
          if (active != null) ...[
            const SizedBox(height: 8),
            Text(
              'Com oferta ativa, o ticket usa ${formatCurrencyAbs(active.pricePerUnit)}/${_unit.label} (${active.supplier}).',
              style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: AppTypography.secondary),
            ),
          ] else if (pending != null) ...[
            const SizedBox(height: 8),
            Text(
              'Após salvar, o ticket usa ${formatCurrencyAbs(pending.pricePerUnit)}/${_unit.label} (${pending.supplier}).',
              style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: AppTypography.secondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultSupplierSection(BuildContext context) {
    final ing = widget.editing;
    final active = ing?.activeOffer;
    final bool isNew = ing == null;

    if (active != null) {
      final current = ing!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
              icon: Icons.storefront_outlined, title: 'Fornecedor padrão'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ativa agora',
                    style: TextStyle(
                        color: AppColors.gold,
                        fontSize: AppTypography.secondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(active.supplier,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: AppTypography.section)),
                    ),
                    const ActiveOfferMarker(),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${formatCurrencyAbs(active.packagePrice)} · ${active.packageQuantity.toStringAsFixed(active.packageQuantity % 1 == 0 ? 0 : 2)} ${current.unit.label} · ${formatCurrencyAbs(active.pricePerUnit)}/${current.unit.label}',
                  style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: AppTypography.body),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/offer-form',
                        arguments: {
                          'ingredientId': current.id,
                          'offer': active,
                        },
                      ),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.gold,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: const Text('Editar oferta'),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/ingredient-offers',
                        arguments: current.id,
                      ),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.gold,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: Text('Ver todas (${current.offersCount})'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (ing != null && ing.offers.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
              icon: Icons.storefront_outlined, title: 'Fornecedor padrão'),
          const SizedBox(height: 12),
          const AlertBanner(
            message:
                'Nenhuma oferta ativa. O ticket usa o preço base deste produto.',
            icon: Icons.warning_amber,
          ),
        ],
      );
    }

    final content = Column(
      children: [
        const Icon(Icons.storefront_outlined,
            color: AppColors.textSec, size: 28),
        const SizedBox(height: 8),
        Text(
          isNew
              ? 'A primeira oferta adicionada abaixo será o fornecedor padrão do produto.'
              : 'Nenhuma oferta cadastrada.',
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: AppColors.textSec, fontSize: AppTypography.secondary),
        ),
        if (isNew) ...[
          const SizedBox(height: 12),
          _registerSupplierHint(),
        ],
        if (ing != null) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(
              context,
              '/offer-form',
              arguments: {'ingredientId': ing.id},
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.greenPrimary,
              side: const BorderSide(color: AppColors.greenPrimary),
              disabledForegroundColor:
                  AppColors.textPrimary.withValues(alpha: 0.38),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            child: const Text('Adicionar primeira oferta'),
          ),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
            icon: Icons.storefront_outlined, title: 'Fornecedor padrão'),
        const SizedBox(height: 12),
        if (isNew)
          Material(
            color: AppColors.card,
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: InkWell(
              onTap: _openOfferForm,
              splashColor: AppColors.gold.withValues(alpha: 0.08),
              highlightColor: AppColors.gold.withValues(alpha: 0.04),
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: content,
                ),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.md)),
            child: content,
          ),
      ],
    );
  }

  Widget _registerSupplierHint() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_circle_outline, color: AppColors.gold, size: 18),
        SizedBox(width: 6),
        Text(
          'Cadastrar fornecedor',
          style: TextStyle(
              color: AppColors.gold,
              fontSize: AppTypography.secondary,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildPendingOffersSection() {
    final atLimit = !canAddPendingOffer(_pendingOffers.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          icon: Icons.storefront_outlined,
          title: 'Ofertas',
          trailing: Text(
            '${_pendingOffers.length}/$maxOffersPerIngredient',
            style: const TextStyle(
                color: AppColors.textSec,
                fontSize: AppTypography.secondary),
          ),
        ),
        const SizedBox(height: 12),
        if (_pendingOffers.isEmpty && !_showOfferForm) ...[
          Material(
            color: AppColors.card,
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: InkWell(
              onTap: _openOfferForm,
              splashColor: AppColors.gold.withValues(alpha: 0.08),
              highlightColor: AppColors.gold.withValues(alpha: 0.04),
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.storefront_outlined,
                          color: AppColors.textSec, size: 28),
                      const SizedBox(height: 8),
                      const Text(
                        'Nenhum fornecedor adicionado ainda.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textSec,
                            fontSize: AppTypography.secondary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Você pode cadastrar as ofertas agora: elas serão salvas junto com o produto.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textSec,
                            fontSize: AppTypography.secondary),
                      ),
                      const SizedBox(height: 12),
                      _registerSupplierHint(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ] else if (_pendingOffers.isNotEmpty) ...[
          for (var i = 0; i < _pendingOffers.length; i++)
            _pendingOfferCard(i),
          const SizedBox(height: 4),
          const Text(
            'A primeira oferta adicionada fica como ativa; as demais entram na comparação de preços.',
            style: TextStyle(
                color: AppColors.textSec,
                fontSize: AppTypography.secondary),
          ),
        ],
        if (_showOfferForm) ...[
          const SizedBox(height: 12),
          _buildPendingOfferForm(),
        ],
        if (atLimit) ...[
          const SizedBox(height: 8),
          Text(
            'Limite de $maxOffersPerIngredient ofertas por produto atingido.',
            style: const TextStyle(
                color: AppColors.textSec,
                fontSize: AppTypography.secondary),
          ),
        ],
      ],
    );
  }

  Widget _pendingOfferCard(int index) {
    final offer = _pendingOffers[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(offer.supplier,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (offer.hasProductName) ...[
                  const SizedBox(height: 2),
                  Text(offer.productName,
                      style: const TextStyle(
                          color: AppColors.textSec,
                          fontSize: AppTypography.secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 4),
                Text(
                  '${formatCurrencyAbs(offer.pricePerUnit)}/${_unit.label}',
                  style: AppTypography.number(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: AppTypography.body),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatCurrencyAbs(offer.packagePrice)} · ${_formatQuantity(offer.packageQuantity)} ${_unit.label}',
                  style: const TextStyle(
                      color: AppColors.textSec,
                      fontSize: AppTypography.caption),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _pendingOffers.removeAt(index)),
            icon: const Icon(Icons.delete_outline,
                color: AppColors.danger, size: 20),
            tooltip: 'Remover oferta',
          ),
        ],
      ),
    );
  }

  Widget _buildPendingOfferForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nova oferta · unidade: ${_unit.label}',
              style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: AppTypography.body)),
          const SizedBox(height: 12),
          _field(_offerSupplierController, 'Nome do fornecedor',
              Icons.storefront_outlined,
              errorText: _offerSupplierError,
              helperText: 'Ex.: Distribuidora Central, Atacado do Zé'),
          const SizedBox(height: 12),
          _field(_offerProductNameController,
              'Nome do produto (como o fornecedor anuncia)',
              Icons.local_offer_outlined,
              maxLength: 80,
              helperText: 'Ex.: Farinha de trigo tipo 1 — 5kg'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _field(_offerPriceController,
                    'Preço da embalagem (R\$)', Icons.attach_money,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    errorText: _offerPriceError),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _field(_offerQtyController, 'Qtd.', Icons.scale_outlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    errorText: _offerQtyError),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _cancelOfferForm,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSec,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _addPendingOffer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.greenPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: const Text('Adicionar oferta',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOffersSection(BuildContext context) {
    final ing = widget.editing;
    if (ing == null) return const SizedBox.shrink();
    final active = ing.activeOffer;
    final best = ing.bestActiveOffer;
    final previewOffers = ing.offers.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          icon: Icons.storefront_outlined,
          title: 'Ofertas',
          trailing: Text(
            '${ing.offersCount}/$maxOffersPerIngredient',
            style: const TextStyle(
                color: AppColors.textSec,
                fontSize: AppTypography.secondary),
          ),
        ),
        const SizedBox(height: 12),
        if (previewOffers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.md)),
            child: const Text(
              'Nenhuma oferta ainda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSec,
                  fontSize: AppTypography.secondary),
            ),
          )
        else
          Column(
            children: previewOffers.map((o) {
              final isActive = active?.id == o.id;
              final isBest = best?.id == o.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.supplier,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(
                            '${formatCurrencyAbs(o.pricePerUnit)}/${ing.unit.label}',
                            style: AppTypography.number(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: AppTypography.body),
                          ),
                        ],
                      ),
                    ),
                    if (isActive) ...[
                      const ActiveOfferMarker(),
                      const SizedBox(width: 6),
                    ],
                    if (isBest && active?.id != best?.id) ...[
                      const BestPriceChip(),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        if (ing.offersCount > 3) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/ingredient-offers',
                arguments: ing.id),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Ver todas as ${ing.offersCount} ofertas',
                  style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: AppTypography.secondary,
                      fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.arrow_forward,
                    color: AppColors.gold, size: 14),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSaveBottom(bool isEdit) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.greenPrimary,
            disabledBackgroundColor:
                AppColors.greenPrimary.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md)),
            elevation: 0,
          ),
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(
                  isEdit ? 'Salvar Alterações' : 'Cadastrar Produto',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}