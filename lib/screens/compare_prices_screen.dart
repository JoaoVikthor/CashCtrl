import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ingredient_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/format.dart';
import '../utils/price_panel_aggregator.dart';
import '../widgets/alert_banner.dart';
import '../widgets/app_branded_header.dart';
import '../widgets/app_drawer.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/panel_product_card.dart';
import '../widgets/search_field.dart';
import '../widgets/supplier_summary_card.dart';

class ComparePricesScreen extends StatefulWidget {
  const ComparePricesScreen({super.key});

  @override
  State<ComparePricesScreen> createState() => _ComparePricesScreenState();
}

class _ComparePricesScreenState extends State<ComparePricesScreen> {
  int _tabIndex = 0;
  String _query = '';
  String _supplier = '';
  int _sortIndex = 0;

  PanelSort get _panelSort {
    switch (_sortIndex) {
      case 0:
        return PanelSort.economy;
      case 1:
        return PanelSort.lowest;
      default:
        return PanelSort.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IngredientProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(currentRoute: 'compare-prices'),
      appBar: const AppBrandedHeader(title: 'Comparar preços'),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(IngredientProvider provider) {
    if (provider.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    if (provider.error != null) {
      return ErrorState(
        message: 'Não foi possível carregar as ofertas.',
        onRetry: provider.reload,
      );
    }

    final entries = PricePanelAggregator.buildPanel(provider.asMap);
    final summary = PricePanelAggregator.summarize(entries);
    final filtered = PricePanelAggregator.filterPanel(
      entries,
      query: _query,
      supplier: _supplier,
    );
    final sorted = PricePanelAggregator.sortPanel(filtered, _panelSort);

    if (summary.productsWithOffers == 0) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
      children: [
        AppFilterChipRow(
          options: const ['Por produto', 'Por fornecedor'],
          selectedIndex: _tabIndex,
          onSelected: (index) => setState(() => _tabIndex = index),
        ),
        const SizedBox(height: 16),
        if (_tabIndex == 0) ...[
          _buildEcoLine(summary),
          AppSearchField(
            hint: 'Buscar produto ou fornecedor…',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          _buildSectionLabel('Ordenar por'),
          const SizedBox(height: 6),
          _buildSortChips(),
          const SizedBox(height: 12),
          _buildSectionLabel('Fornecedor'),
          const SizedBox(height: 6),
          _buildSupplierFilter(entries),
          const SizedBox(height: 16),
          if (summary.suppliersCount == 1) _buildOneSupplierBanner(),
          if (sorted.isEmpty) ...[
            _buildNoFilterResult(),
          ] else ...[
            ...sorted.map((e) => PanelProductCard(
                  entry: e,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/ingredient-offers',
                    arguments: e.ingredient.id,
                  ),
                )),
          ],
        ] else ...[
          _buildSupplierTab(entries),
        ],
      ],
    );
  }

  Widget _buildEcoLine(PanelSummary summary) {
    if (summary.productsPayMore > 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
              color: AppColors.success.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_down,
                    color: AppColors.success, size: 17),
                const SizedBox(width: 8),
                Text(
                  'Economia possível',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: formatCurrencyAbs(summary.economySumPerUnit),
                    style: AppTypography.number(
                      color: AppColors.gold,
                      fontSize: AppTypography.title,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text:
                        ' · combinados por unidade em ${summary.productsPayMore} produtos',
                    style: const TextStyle(
                      color: AppColors.textSec,
                      fontSize: AppTypography.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const Text(
        'Você já usa o melhor preço entre as ofertas cadastradas.',
        style: TextStyle(
            color: AppColors.textSec, fontSize: AppTypography.body),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSec,
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSortChips() {
    return AppFilterChipRow(
      options: const ['Maior economia', 'Menor preço', 'Nome'],
      selectedIndex: _sortIndex,
      onSelected: (index) => setState(() => _sortIndex = index),
    );
  }

  Widget _buildSupplierFilter(List<ProductPanelEntry> entries) {
    final suppliers = _supplierOptions(entries);
    if (suppliers.isEmpty) return const SizedBox.shrink();
    final options = <String>['Todos'];
    for (final name in suppliers) {
      options.add(_shortName(name));
    }
    return AppFilterChipRow(
      options: options,
      selectedIndex: _supplier.isEmpty
          ? 0
          : suppliers.indexWhere((s) => _isSameSupplier(s, _supplier)) + 1,
      onSelected: (index) {
        setState(() {
          _supplier = index == 0 ? '' : suppliers[index - 1];
        });
      },
    );
  }

  String _shortName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return trimmed.length > 3 ? trimmed.substring(0, 3) : trimmed;
    }
    return parts.take(2).map((p) => p.isNotEmpty ? p[0] : '').join();
  }

  List<String> _supplierOptions(List<ProductPanelEntry> entries) {
    final displayNames = <String, String>{};
    for (final entry in entries) {
      for (final name in entry.supplierNames) {
        final key = name.trim().toLowerCase();
        displayNames.putIfAbsent(key, () => name.trim());
      }
    }
    final names = displayNames.values.toList();
    names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  }

  bool _isSameSupplier(String a, String b) {
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }

  Widget _buildOneSupplierBanner() {
    return const AlertBanner(
      message: 'Cadastre mais fornecedores para ver o comparativo.',
      icon: Icons.info_outline,
    );
  }

  Widget _buildNoFilterResult() {
    return Column(
      children: [
        const Icon(Icons.search_off, color: AppColors.textSec, size: 48),
        const SizedBox(height: 12),
        Text(
          'Nenhuma oferta corresponde aos filtros.',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() {
            _query = '';
            _supplier = '';
            _sortIndex = 0;
          }),
          child: const Text(
            'Limpar filtros',
            style: TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupplierTab(List<ProductPanelEntry> entries) {
    final report = PricePanelAggregator.buildSupplierReport(entries);
    if (report.isEmpty) {
      return const EmptyState(
        icon: Icons.storefront_outlined,
        title: 'Nenhum fornecedor com ofertas',
        message:
            'Cadastre ofertas de fornecedores para ver o comparativo por fornecedor.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: report
          .map((e) => SupplierSummaryCard(
                entry: e,
                onIngredientTap: (id) => Navigator.pushNamed(
                  context,
                  '/ingredient-offers',
                  arguments: id,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.storefront_outlined,
      title: 'Nenhuma oferta cadastrada ainda',
      message:
          'Cadastre preços de fornecedores para comparar e escolher quem entra no ticket.',
      actionLabel: 'Gerenciar produtos',
      onAction: () => Navigator.pushNamed(context, '/ingredients'),
    );
  }
}
