import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ingredient.dart';
import '../providers/ingredient_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import '../utils/format.dart';
import '../utils/product_calculator.dart';
import '../utils/offer_comparator.dart';
import '../widgets/alert_banner.dart';
import '../widgets/app_toast.dart';
import '../widgets/economy_summary_card.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productId = ModalRoute.of(context)?.settings.arguments as String?;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Ticket da Ficha',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (productId != null)
            PopupMenuButton<String>(
              color: AppColors.card,
              icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
              onSelected: (v) async {
                if (v == 'edit') {
                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(context, '/product-form',
                      arguments: productId);
                } else if (v == 'delete') {
                  final ok = await _confirmDelete(context);
                  if (ok == true && context.mounted) {
                    await context.read<ProductProvider>().deleteProduct(productId);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    AppToast.success(context, 'Ficha técnica excluída.');
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: 'edit',
                    child: Text('Editar',
                        style: TextStyle(color: AppColors.textPrimary))),
                PopupMenuItem(
                    value: 'delete',
                    child: Text('Excluir',
                        style: TextStyle(color: AppColors.danger))),
              ],
            ),
        ],
      ),
      body: productId == null
          ? Center(
              child: Text('Ficha técnica não encontrada.',
                  style: TextStyle(
                      color: AppColors.textPrimary.withValues(alpha: 0.7))))
          : Consumer2<ProductProvider, IngredientProvider>(
              builder: (context, pp, ip, _) {
                final product = pp.list
                    .where((p) => p.id == productId)
                    .firstOrNull;
                if (product == null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off,
                            color: AppColors.textSec, size: 40),
                        const SizedBox(height: 8),
                        Text('Ficha técnica não encontrada.',
                            style: TextStyle(
                                color: AppColors.textPrimary
                                    .withValues(alpha: 0.7))),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.greenPrimary),
                          child: const Text('Voltar',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }
                final ticket =
                    ProductCalculator.calculate(product, ip.asMap);
                return _buildTicket(context, ticket);
              },
            ),
    );
  }

  Widget _buildTicket(BuildContext context, TicketResult t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.product.name,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppTypography.title,
                  fontWeight: FontWeight.bold)),
          if (t.product.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(t.product.description,
                style: const TextStyle(
                    color: AppColors.textSec,
                    fontSize: AppTypography.body)),
          ],
          const SizedBox(height: 24),
          _buildVerdictCard(t),
          const SizedBox(height: 16),
          EconomySummaryCard(
            scenario: OfferComparator.bestSupplierScenario(t),
            ticket: t,
            onViewOffers: (ingredientId) {
              if (ingredientId.isEmpty) {
                Navigator.pushNamed(context, '/ingredients');
              } else {
                Navigator.pushNamed(
                  context,
                  '/ingredient-offers',
                  arguments: ingredientId,
                );
              }
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Receita por produto', Icons.restaurant_menu),
          const SizedBox(height: 12),
          if (t.hasMissingIngredients)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: AlertBanner(
                message:
                    'Um ou mais produtos foram removidos. O custo pode estar incompleto.',
                icon: Icons.warning_amber,
              ),
            ),
          for (final line in t.lines) _buildProductLine(line, t.totalCost),
          const SizedBox(height: 8),
          _costSummaryRow('Subtotal produtos',
              formatCurrencyAbs(t.ingredientsTotal)),
          _costSummaryRow('Mão de obra', formatCurrencyAbs(t.laborCost)),
          _costSummaryRow('Embalagem', formatCurrencyAbs(t.packagingCost)),
          const Divider(color: AppColors.border, height: 24),
          _costSummaryRow('Custo total', formatCurrencyAbs(t.totalCost),
              bold: true),
          _costSummaryRow('Preço de venda', formatCurrencyAbs(t.salePrice),
              bold: true),
          const Divider(color: AppColors.border, height: 24),
          const SizedBox(height: 8),
          _buildFinalVerdict(t),
          const SizedBox(height: 16),
        ],
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
                fontSize: AppTypography.section,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildVerdictCard(TicketResult t) {
    final isLucro = t.isLucro;
    final color = isLucro ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5)),
      child: Column(
        children: [
          Icon(isLucro ? Icons.check_circle : Icons.cancel,
              color: color, size: 40),
          const SizedBox(height: 8),
          Text(isLucro ? 'Dá lucro' : 'Dá prejuízo',
              style: TextStyle(
                  color: color,
                  fontSize: AppTypography.section,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${isLucro ? '+' : ''}${formatCurrency(t.profit)}',
              style: AppTypography.number(
                  color: color,
                  fontSize: AppTypography.hero,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
              'Margem de ${t.marginPercent.toStringAsFixed(1)}%  •  Markup ${t.markup.toStringAsFixed(2)}x',
              style: const TextStyle(
                  color: AppColors.textSec,
                  fontSize: AppTypography.body)),
        ],
      ),
    );
  }

  Widget _buildProductLine(LineCost line, double totalCost) {
    final showShare = !line.missing && totalCost > 0;
    final share =
        showShare ? (line.lineCost / totalCost).clamp(0.0, 1.0).toDouble() : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.science_outlined,
                  color: AppColors.gold, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(line.item.ingredientName,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (line.missing)
                      const Text('Produto removido do cadastro',
                          style: TextStyle(
                              color: AppColors.danger,
                              fontSize: AppTypography.caption))
                    else
                      Text(
                          '${formatQuantity(line.item.quantity)} ${line.item.inputUnit ?? line.ingredient?.unit.label ?? ''}',
                          style: const TextStyle(
                              color: AppColors.textSec,
                              fontSize: AppTypography.caption)),
                  ],
                ),
              ),
              SizedBox(
                width: 96,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('custo',
                        style: TextStyle(
                            color: AppColors.textSec,
                            fontSize: AppTypography.caption)),
                    Text(
                        line.missing || line.inconvertible
                            ? '—'
                            : formatCurrencyAbs(line.lineCost),
                        style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          if (showShare) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: share,
                minHeight: 6,
                backgroundColor: AppColors.background,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Expanded(
                  child: Text('Participação no custo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.textSec,
                          fontSize: AppTypography.caption)),
                ),
                const SizedBox(width: 8),
                Text('${(share * 100).toStringAsFixed(1)}% do custo total',
                    style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: AppTypography.caption,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _costSummaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: bold
                      ? AppColors.textPrimary
                      : AppColors.textPrimary.withValues(alpha: 0.7),
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  color: bold ? AppColors.textPrimary : AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: bold ? AppTypography.section : AppTypography.body)),
        ],
      ),
    );
  }

  Widget _buildFinalVerdict(TicketResult t) {
    final isLucro = t.isLucro;
    final color = isLucro ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Veredito',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold)),
          Row(
            children: [
              Icon(isLucro ? Icons.trending_up : Icons.trending_down,
                  color: color, size: 20),
              const SizedBox(width: 6),
              Text(isLucro ? 'Lucro' : 'Prejuízo',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Excluir ficha técnica?',
            style: TextStyle(color: AppColors.textPrimary, fontSize: AppTypography.section)),
        content: Text(
            'A ficha técnica e o ticket serão removidos permanentemente.',
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
  }
}