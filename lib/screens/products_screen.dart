import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ingredient_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import '../utils/format.dart';
import '../utils/product_calculator.dart';
import '../widgets/app_branded_header.dart';
import '../widgets/app_drawer.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(currentRoute: 'products'),
      appBar: const AppBrandedHeader(title: 'Fichas Técnicas'),
      floatingActionButton: _buildAction(context),
      body: Consumer2<ProductProvider, IngredientProvider>(
        builder: (context, pp, ip, _) {
          if (pp.loading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.gold));
          }
          if (pp.error != null) {
            return _buildErrorState();
          }
          if (pp.list.isEmpty) {
            return _buildEmpty(context, ip.list.isEmpty);
          }
          final ingredients = ip.asMap;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
            itemCount: pp.list.length,
            itemBuilder: (context, i) {
              final product = pp.list[i];
              final ticket =
                  ProductCalculator.calculate(product, ingredients);
              return _buildProductCard(context, product, ticket);
            },
          );
        },
      ),
    );
  }

  Widget _buildAction(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'products-new-fab',
      tooltip: 'Nova ficha técnica',
      backgroundColor: AppColors.greenPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      onPressed: () {
        final hasProducts = context.read<IngredientProvider>().list.isNotEmpty;
        Navigator.pushNamed(
            context, hasProducts ? '/product-form' : '/ingredient-form');
      },
      icon: const Icon(Icons.add),
      label: const Text('Nova ficha'),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: AppColors.textSec, size: 48),
            const SizedBox(height: 8),
            Text(
              'Não foi possível carregar as fichas técnicas.',
              style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Verifique sua conexão e tente novamente.',
              style: TextStyle(
                  color: AppColors.textSec,
                  fontSize: AppTypography.secondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, bool noIngredients) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.restaurant_menu_outlined,
                size: 56, color: AppColors.textSec),
            const SizedBox(height: 12),
            const Text('Nenhuma ficha técnica cadastrada',
                style: TextStyle(color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(
                noIngredients
                    ? 'Cadastre produtos primeiro para depois montar sua receita.'
                    : 'Monte sua primeira receita com os produtos cadastrados.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSec,
                    fontSize: AppTypography.secondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context,
                  noIngredients ? '/ingredient-form' : '/product-form'),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                  noIngredients ? 'Cadastrar Produto' : 'Criar Ficha Técnica',
                  style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(
      BuildContext context, product, TicketResult ticket) {
    final isLucro = ticket.isLucro;
    final verdictColor = isLucro ? AppColors.success : AppColors.danger;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pushNamed(context, '/product-detail',
          arguments: ticket.product.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.background,
                  child: Icon(
                      ticket.product.recipe.isEmpty
                          ? Icons.inventory_outlined
                          : Icons.restaurant_menu_outlined,
                      color: AppColors.gold,
                      size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ticket.product.name,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(
                          '${ticket.product.recipe.length} produto(s) na receita • Venda: ${formatCurrencyAbs(ticket.product.salePrice)}',
                          style: const TextStyle(
                              color: AppColors.textSec,
                              fontSize: AppTypography.secondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: verdictColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Custo total',
                          style: TextStyle(
                              color: AppColors.textSec,
                              fontSize: AppTypography.caption)),
                      Text(formatCurrencyAbs(ticket.totalCost),
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(isLucro ? 'Lucro' : 'Prejuízo',
                          style: TextStyle(
                              color: verdictColor,
                              fontSize: AppTypography.caption,
                              fontWeight: FontWeight.bold)),
                      Text(
                          '${isLucro ? '+' : ''}${formatCurrency(ticket.profit)}',
                          style: AppTypography.number(
                              color: verdictColor,
                              fontSize: AppTypography.section,
                              fontWeight: FontWeight.bold)),
                      Text(
                          'Margem ${ticket.marginPercent.toStringAsFixed(1)}%',
                          style: AppTypography.number(
                              color: verdictColor,
                              fontSize: AppTypography.secondary,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}