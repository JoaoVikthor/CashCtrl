import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ingredient.dart';
import '../models/product.dart';
import '../providers/ingredient_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import '../utils/format.dart';
import '../utils/product_calculator.dart';
import '../utils/sebrae_rules.dart';
import '../utils/unit_converter.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toast.dart';
import '../widgets/search_field.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? editing;

  const ProductFormScreen({
    super.key,
    this.editing,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _saleController = TextEditingController();
  final TextEditingController _laborController = TextEditingController();
  final TextEditingController _packController = TextEditingController();
  final List<RecipeItem> _recipe = [];
  final List<TextEditingController> _qtyControllers = [];
  bool _saving = false;
  final List<String> _recipeInputUnits = [];
  String _pickerQuery = '';

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _nameController.text = e.name;
      _descController.text = e.description;
      _saleController.text =
          e.salePrice.toStringAsFixed(2).replaceAll('.', ',');
      _laborController.text =
          e.laborCost.toStringAsFixed(2).replaceAll('.', ',');
      _packController.text =
          e.packagingCost.toStringAsFixed(2).replaceAll('.', ',');
      for (final r in e.recipe) {
        _recipe.add(r);
        _recipeInputUnits.add(r.inputUnit ?? '');
        _qtyControllers.add(TextEditingController(
            text: r.quantity.toStringAsFixed(r.quantity % 1 == 0 ? 0 : 2)
                .replaceAll('.', ',')));
      }
    } else {
      _laborController.text = '0,00';
      _packController.text = '0,00';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _saleController.dispose();
    _laborController.dispose();
    _packController.dispose();
    for (final c in _qtyControllers) {
      c.dispose();
    }
    super.dispose();
  }

  double _parse(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

  double _convertedQuantity(int index, Map<String, Ingredient> ingredients) {
    final item = _recipe[index];
    final ing = ingredients[item.ingredientId];
    final raw = _parse(_qtyControllers[index]);
    final result = UnitConverter.convertToIngredientUnit(
      raw,
      _recipeInputUnits[index],
      ing?.unit.label ?? _recipeInputUnits[index],
      averageUnitWeightGrams: ing?.averageUnitWeightGrams,
    );
    return result.value;
  }

  double _lineCost(int index, Map<String, Ingredient> ingredients) {
    final item = _recipe[index];
    final ing = ingredients[item.ingredientId];
    if (ing == null) return 0.0;
    final raw = _parse(_qtyControllers[index]);
    final inputUnit = _recipeInputUnits[index];
    final conversion = UnitConverter.convertToIngredientUnit(
      raw,
      inputUnit,
      ing.unit.label,
      averageUnitWeightGrams: ing.averageUnitWeightGrams,
    );
    final inconvertible = !conversion.converted &&
        inputUnit.trim().toLowerCase() !=
            ing.unit.label.trim().toLowerCase();
    if (inconvertible) return 0.0;
    final effQty = SebraeRules.effectiveQuantity(
      raw: raw,
      inputUnit: inputUnit,
      baseUnit: ing.unit.label,
      averageUnitWeightGrams: ing.averageUnitWeightGrams,
      correctionFactor: ing.correctionFactor,
    );
    return effQty * ing.pricePerUnit;
  }

  bool _hasConversionWarning(int index, Map<String, Ingredient> ingredients) {
    final item = _recipe[index];
    final ing = ingredients[item.ingredientId];
    if (ing == null) return false;
    final raw = _parse(_qtyControllers[index]);
    if (raw <= 0) return false;
    final result = UnitConverter.convertToIngredientUnit(
      raw,
      _recipeInputUnits[index],
      ing.unit.label,
      averageUnitWeightGrams: ing.averageUnitWeightGrams,
    );
    return !result.converted && result.unit != ing.unit.label;
  }

  void _toast(String msg) {
    AppToast.error(context, msg);
  }

  void _addIngredient(Ingredient ing) {
    if (_recipe.any((r) => r.ingredientId == ing.id)) {
      _toast('Este produto já foi adicionado.');
      return;
    }
    setState(() {
      _recipe.add(RecipeItem(
          ingredientId: ing.id,
          ingredientName: ing.name,
          quantity: 0));
      _qtyControllers.add(TextEditingController(text: '0'));
      _recipeInputUnits.add(ing.unit.label);
    });
  }

  void _removeAt(int index) {
    setState(() {
      _qtyControllers[index].dispose();
      _qtyControllers.removeAt(index);
      _recipeInputUnits.removeAt(index);
      _recipe.removeAt(index);
    });
  }

  bool _validate() {
    if (_nameController.text.trim().isEmpty) {
      _toast('Informe o nome da ficha técnica.');
      return false;
    }
    final sale = _parse(_saleController);
    if (sale <= 0) {
      _toast('Informe o preço de venda (> 0).');
      return false;
    }
    if (_recipe.isEmpty) {
      _toast('Adicione ao menos um produto à receita.');
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _saving = true);
    try {
      final recipe = <RecipeItem>[];
      for (var i = 0; i < _recipe.length; i++) {
        final qty = _parse(_qtyControllers[i]);
        if (qty <= 0) {
          _toast('A quantidade de "${_recipe[i].ingredientName}" deve ser > 0.');
          setState(() => _saving = false);
          return;
        }
        recipe.add(_recipe[i].copyWith(
          quantity: qty,
          inputUnit: _recipeInputUnits[i],
        ));
      }
      final p = Product(
        id: widget.editing?.id ?? '',
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        recipe: recipe,
        laborCost: _parse(_laborController),
        packagingCost: _parse(_packController),
        salePrice: _parse(_saleController),
        createdAt: widget.editing?.createdAt ?? DateTime.now(),
      );
      final prov = context.read<ProductProvider>();
      if (widget.editing == null) {
        await prov.addProduct(p);
      } else {
        await prov.updateProduct(p);
      }
      if (!mounted) return;
      AppToast.success(
          context,
          widget.editing == null
              ? 'Ficha técnica criada!'
              : 'Ficha técnica atualizada!');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _toast('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  TicketResult _livePreview(Map<String, Ingredient> ingredients) {
    final recipe = <RecipeItem>[];
    for (var i = 0; i < _recipe.length; i++) {
      final item = _recipe[i];
      recipe.add(RecipeItem(
        ingredientId: item.ingredientId,
        ingredientName: item.ingredientName,
        quantity: _convertedQuantity(i, ingredients),
      ));
    }
    final preview = Product(
      id: widget.editing?.id ?? '__preview__',
      name: _nameController.text.trim().isEmpty
          ? 'Ficha técnica'
          : _nameController.text.trim(),
      description: _descController.text.trim(),
      recipe: recipe,
      laborCost: _parse(_laborController),
      packagingCost: _parse(_packController),
      salePrice: _parse(_saleController),
      createdAt: DateTime.now(),
    );
    return ProductCalculator.calculate(preview, ingredients);
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
          isEdit ? 'Editar Ficha' : 'Nova Ficha Técnica',
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Consumer<IngredientProvider>(
        builder: (context, ip, _) {
          if (ip.loading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.gold));
          }
          if (ip.list.isEmpty) {
            return _buildNoIngredients();
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field(_nameController, 'Nome da ficha técnica',
                    Icons.lunch_dining_outlined),
                const SizedBox(height: 14),
                _field(_descController, 'Descrição (opcional)',
                    Icons.description_outlined,
                    maxLines: 2),
                const SizedBox(height: 14),
                _field(_saleController, 'Preço de venda (R\$)',
                    Icons.point_of_sale_outlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 16),
                _buildSectionTitle(
                    'Produtos da receita', Icons.restaurant_menu),
                const SizedBox(height: 10),
                _buildAddIngredientButton(ip.list),
                const SizedBox(height: 12),
                for (var i = 0; i < _recipe.length; i++)
                  _buildRecipeRow(i, ip.asMap),
                if (_recipe.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                        'Nenhum produto adicionado. Toque em "Adicionar produto".',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: AppTypography.secondary)),
                  ),
                const SizedBox(height: 20),
                _buildSectionTitle('Custos extras', Icons.add_circle_outline),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: _field(_laborController, 'Mão de obra',
                            Icons.engineering_outlined,
                            keyboardType: const TextInputType
                                .numberWithOptions(decimal: true))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field(_packController, 'Embalagem',
                            Icons.inventory_outlined,
                            keyboardType: const TextInputType
                                .numberWithOptions(decimal: true))),
                  ],
                ),
                const SizedBox(height: 24),
                _buildLivePreview(ip.asMap),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildSaveBottom(isEdit),
    );
  }

  Widget _buildNoIngredients() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text('Cadastre produtos primeiro',
                style: TextStyle(color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text(
                'Você precisa de produtos para montar a ficha técnica.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: AppTypography.secondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/ingredients'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.greenPrimary),
              child: const Text('Ir para Produtos',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gold, size: 18),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAddIngredientButton(List<Ingredient> available) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => _showIngredientPicker(available),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
              color: AppColors.greenPrimary.withValues(alpha: 0.4), width: 1),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.gold),
            SizedBox(width: 8),
            Text('Adicionar produto',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showIngredientPicker(List<Ingredient> available) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateSheet) {
          var filtered = available;
          if (_pickerQuery.isNotEmpty) {
            final q = _pickerQuery.toLowerCase();
            filtered = available
                .where((ing) => ing.name.toLowerCase().contains(q))
                .toList();
          }
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Selecione um produto',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AppSearchField(
                    hint: 'Buscar produto…',
                    onChanged: (value) {
                      setStateSheet(() => _pickerQuery = value);
                    },
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final ing = filtered[i];
                      return ListTile(
                        leading: const Icon(Icons.science_outlined,
                            color: AppColors.gold),
                        title: Text(ing.name,
                            style: const TextStyle(
                                color: AppColors.textPrimary)),
                        subtitle: Text(
                            '${formatCurrencyAbs(ing.pricePerUnit)}/${ing.unit.label}',
                            style: const TextStyle(
                                color: AppColors.textSec,
                                fontSize: AppTypography.secondary)),
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickerQuery = '';
                          _addIngredient(ing);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecipeRow(int index, Map<String, Ingredient> ingredients) {
    final item = _recipe[index];
    final ing = ingredients[item.ingredientId];
    if (_recipeInputUnits.length <= index) {
      _recipeInputUnits.add(item.inputUnit ?? ing?.unit.label ?? 'un');
    } else if (_recipeInputUnits[index].isEmpty) {
      _recipeInputUnits[index] = item.inputUnit ?? ing?.unit.label ?? 'un';
    }
    final compatible = ing != null
        ? UnitConverter.compatibleUnits(
            ing.unit.label,
            hasAverageUnitWeight: ing.averageUnitWeightGrams != null &&
                ing.averageUnitWeightGrams! > 0,
          )
        : const <String>['un'];
    if (ing != null && !compatible.contains(_recipeInputUnits[index])) {
      _recipeInputUnits[index] = ing.unit.label;
      _qtyControllers[index].text = '0';
    }
    final lineCost = _lineCost(index, ingredients);
    final showSelector = compatible.length > 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.ingredientName,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (ing != null)
                  Text(
                      '${formatCurrencyAbs(ing.pricePerUnit)}/${ing.unit.label}',
                      style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: AppTypography.caption))
                else
                  const Text('Produto removido',
                      style: TextStyle(
                          color: AppColors.danger,
                          fontSize: AppTypography.caption)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: showSelector ? 72 : 84,
                    height: 48,
                    child: TextField(
                      controller: _qtyControllers[index],
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: AppTypography.body),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.background,
                        suffixText: showSelector ? null : ing?.unit.label,
                        suffixStyle: const TextStyle(
                            color: AppColors.gold,
                            fontSize: AppTypography.caption),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 6),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            borderSide: BorderSide(
                                color: AppColors.textPrimary
                                    .withValues(alpha: 0.08))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            borderSide: const BorderSide(
                                color: AppColors.gold, width: 1.2)),
                      ),
                    ),
                  ),
                  if (showSelector) ...[
                    const SizedBox(width: 4),
                    _buildUnitSelector(index, compatible),
                  ],
                ],
              ),
              if (_hasConversionWarning(index, ingredients)) ...[
                const SizedBox(height: 4),
                const Text('conversão não aplicada',
                    style: TextStyle(
                        color: AppColors.warning,
                        fontSize: AppTypography.caption)),
              ],
            ],
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('custo',
                    style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: AppTypography.caption)),
                Text(formatCurrencyAbs(lineCost),
                    style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: AppTypography.secondary,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.danger, size: 20),
            onPressed: () => _removeAt(index),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitSelector(int index, List<String> units) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _recipeInputUnits[index],
          dropdownColor: AppColors.card,
          icon: const Icon(Icons.arrow_drop_down,
              color: AppColors.gold, size: 18),
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppTypography.secondary),
          items: units
              .map((u) => DropdownMenuItem(
                    value: u,
                    child: Text(u,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: AppTypography.secondary)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() => _recipeInputUnits[index] = v);
            }
          },
        ),
      ),
    );
  }

  Widget _buildLivePreview(Map<String, Ingredient> ingredients) {
    final t = _livePreview(ingredients);
    final isLucro = t.isLucro;
    final color = isLucro ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isLucro ? Icons.trending_up : Icons.trending_down,
                  color: color, size: 20),
              const SizedBox(width: 8),
              Text(isLucro ? 'Projeta lucro' : 'Projeta prejuízo',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _previewRow('Produtos', formatCurrencyAbs(t.ingredientsTotal)),
          _previewRow('Mão de obra', formatCurrencyAbs(t.laborCost)),
          _previewRow('Embalagem', formatCurrencyAbs(t.packagingCost)),
          const Divider(color: AppColors.border, height: 16),
          _previewRow('Custo total', formatCurrencyAbs(t.totalCost),
              bold: true),
          _previewRow('Preço de venda', formatCurrencyAbs(t.salePrice),
              bold: true),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isLucro ? 'Lucro' : 'Prejuízo',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold)),
              Text(
                  '${isLucro ? '+' : ''}${formatCurrency(t.profit)}  •  Margem ${t.marginPercent.toStringAsFixed(1)}%',
                  style: AppTypography.number(
                      color: color,
                      fontSize: AppTypography.section,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.7),
                  fontSize: AppTypography.body,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppTypography.body,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return AppTextField(
      controller: c,
      label: label,
      icon: icon,
      keyboardType: keyboardType,
      maxLines: maxLines,
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
                  isEdit ? 'Salvar Alterações' : 'Criar Ficha Técnica',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}