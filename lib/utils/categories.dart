import 'package:flutter/material.dart';

class CategoryDef {
  final String name;
  final IconData icon;
  final int colorValue;

  const CategoryDef(this.name, this.icon, this.colorValue);

  Color get color => Color(colorValue);
}

const List<CategoryDef> kExpenseCategories = [
  CategoryDef('Insumos', Icons.inventory_2_outlined, 0xFFB89775),
  CategoryDef('Mão de Obra', Icons.badge_outlined, 0xFF5DBB63),
  CategoryDef('Aluguel/Ocupação', Icons.home_work_outlined, 0xFF4A90D9),
  CategoryDef('Energia/Água', Icons.bolt_outlined, 0xFFE0913A),
  CategoryDef('Embalagens', Icons.shopping_bag_outlined, 0xFF46C7B3),
  CategoryDef('Taxas/Plataformas', Icons.percent, 0xFF9C6BD6),
  CategoryDef('Manutenção', Icons.build_outlined, 0xFF7A8B83),
  CategoryDef('Marketing', Icons.campaign_outlined, 0xFFE086B8),
  CategoryDef('Impostos', Icons.receipt_long_outlined, 0xFFD64A4A),
  CategoryDef('Transporte/Delivery', Icons.delivery_dining, 0xFFE05A5A),
  CategoryDef('Outros', Icons.category_outlined, 0xFF7A8B83),
];

const List<CategoryDef> kIncomeCategories = [
  CategoryDef('Vendas', Icons.point_of_sale_outlined, 0xFF5DBB63),
  CategoryDef('Delivery/Encomendas', Icons.delivery_dining_outlined, 0xFF46C7B3),
  CategoryDef('Outros', Icons.category_outlined, 0xFF7A8B83),
];

const Map<String, CategoryDef> _legacyCategories = {
  'Moradia': CategoryDef('Moradia', Icons.home_outlined, 0xFF4A90D9),
  'Alimentação': CategoryDef('Alimentação', Icons.restaurant_outlined, 0xFFE0913A),
  'Transporte': CategoryDef('Transporte', Icons.directions_car_outlined, 0xFFE05A5A),
  'Lazer': CategoryDef('Lazer', Icons.sports_esports_outlined, 0xFF9C6BD6),
  'Saúde': CategoryDef('Saúde', Icons.medical_services_outlined, 0xFF46C7B3),
  'Educação': CategoryDef('Educação', Icons.school_outlined, 0xFF6BA3E0),
  'Tecnologia': CategoryDef('Tecnologia', Icons.computer_outlined, 0xFF7A8B83),
  'Salários': CategoryDef('Salários', Icons.badge_outlined, 0xFF5DBB63),
  'Salário': CategoryDef('Salário', Icons.account_balance_wallet_outlined, 0xFF5DBB63),
  'Investimentos': CategoryDef('Investimentos', Icons.trending_up, 0xFF4A90D9),
  'Freelance': CategoryDef('Freelance', Icons.work_outline, 0xFFB89775),
  'Reembolso': CategoryDef('Reembolso', Icons.replay, 0xFF9C6BD6),
};

CategoryDef findCategory(String name, {bool isIncome = false}) {
  final list = isIncome ? kIncomeCategories : kExpenseCategories;
  return list.firstWhere(
    (c) => c.name == name,
    orElse: () =>
        _legacyCategories[name] ??
        const CategoryDef('Outros', Icons.category_outlined, 0xFF7A8B83),
  );
}
