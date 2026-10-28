import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ingredient.dart';
import '../providers/ingredient_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import '../utils/format.dart';
import '../widgets/app_branded_header.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_toast.dart';
import '../widgets/offer_count_badge.dart';
import '../widgets/active_offer_marker.dart';
import '../widgets/best_price_chip.dart';

class IngredientsScreen extends StatelessWidget {
  const IngredientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(currentRoute: 'ingredients'),
      appBar: const AppBrandedHeader(title: 'Produtos'),
      body: Consumer<IngredientProvider>(
        builder: (context, prov, _) {
          if (prov.loading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.gold));
          }
          if (prov.error != null) {
            return _buildErrorState();
          }
          if (prov.list.isEmpty) {
            return _buildEmpty(context);
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Itens que entram nas fichas técnicas',
                        style: TextStyle(
                          color: AppColors.textSec,
                          fontSize: AppTypography.secondary,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/compare-prices'),
                      icon: const Icon(Icons.compare_arrows_outlined, size: 18),
                      label: const Text('Comparar preços'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.card,
                        foregroundColor: AppColors.gold,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: AppTypography.secondary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                  itemCount: prov.list.length,
                  itemBuilder: (context, i) =>
                      _buildIngredientCard(context, prov.list[i]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateSheet(context),
        backgroundColor: AppColors.greenPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'O que você quer criar?',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppTypography.title,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Produtos são os itens comprados. Fichas técnicas são os pratos vendidos.',
                  style: TextStyle(
                    color: AppColors.textSec,
                    fontSize: AppTypography.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCreateOption(
                  context: context,
                  icon: Icons.inventory_2_outlined,
                  title: 'Produto',
                  description: 'Item que entra na receita (ex.: queijo, farinha).',
                  route: '/ingredient-form',
                ),
                const SizedBox(height: 12),
                _buildCreateOption(
                  context: context,
                  icon: Icons.restaurant_menu,
                  title: 'Receita / Ficha Técnica',
                  description: 'Prato vendido, com custo e ticket calculados.',
                  route: '/product-form',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreateOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required String route,
  }) {
    return Material(
      color: AppColors.background,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, route);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.card,
                child: Icon(icon, color: AppColors.gold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: AppTypography.body,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textSec,
                        fontSize: AppTypography.caption,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSec,
                size: 14,
              ),
            ],
          ),
        ),
      ),
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
              'Não foi possível carregar os produtos.',
              style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Verifique sua conexão e tente novamente.',
              style: const TextStyle(
                  color: AppColors.textSec, fontSize: AppTypography.secondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 56, color: AppColors.textSec),
            const SizedBox(height: 12),
            Text('Nenhum produto cadastrado',
                style: TextStyle(color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text(
                'Cadastre os produtos que entram nas suas fichas técnicas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textSec,
                    fontSize: AppTypography.secondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/ingredient-form'),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Cadastrar produto',
                  style: TextStyle(color: Colors.white)),
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

  Widget _buildIngredientCard(BuildContext context, Ingredient ing) {
    final activeIsBest =
        ing.activeOffer != null && ing.activeOffer?.id == ing.bestActiveOffer?.id;
    return Dismissible(
      key: ValueKey(ing.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: AppColors.danger),
      ),
      confirmDismiss: (_) => _confirmDelete(context, ing),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/ingredient-form',
            arguments: ing),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.background,
                child: const Icon(Icons.inventory_2_outlined,
                    color: AppColors.gold, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ing.name,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    OfferCountBadge(count: ing.offersCount),
                    const SizedBox(height: 4),
                    Text(
                        '${formatCurrencyAbs(ing.purchasePrice)} / ${ing.packageQuantity.toStringAsFixed(ing.packageQuantity % 1 == 0 ? 0 : 2)} ${ing.unit.label}',
                        style: const TextStyle(
                            color: AppColors.textSec,
                            fontSize: AppTypography.secondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Preço por unidade',
                      style: TextStyle(
                          color: AppColors.textSec,
                          fontSize: AppTypography.caption)),
                  const SizedBox(height: 2),
                  Text('${formatCurrencyAbs(ing.pricePerUnit)}/${ing.unit.label}',
                      style: AppTypography.number(
                          color: AppColors.gold,
                          fontSize: AppTypography.section,
                          fontWeight: FontWeight.bold)),
                  if (ing.offers.length >= 2) ...[
                    const SizedBox(height: 6),
                    const ActiveOfferMarker(),
                    if (!activeIsBest) ...[
                      const SizedBox(height: 4),
                      const BestPriceChip(),
                    ],
                  ],
                ],
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.storefront_outlined,
                    color: AppColors.gold, size: 22),
                tooltip: 'Ver ofertas',
                onPressed: () => Navigator.pushNamed(context, '/ingredient-offers',
                    arguments: ing.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, Ingredient ing) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Excluir produto?',
            style: TextStyle(color: AppColors.textPrimary, fontSize: AppTypography.section)),
        content: Text(
            '"${ing.name}" será removido. As fichas técnicas que o usam podem ficar sem custo calculado.',
            style: TextStyle(
                color: AppColors.textPrimary.withValues(alpha: 0.7))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.gold))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<IngredientProvider>().deleteIngredient(ing.id);
      if (context.mounted) {
        AppToast.success(context, 'Produto excluído.');
      }
      return true;
    }
    return false;
  }
}