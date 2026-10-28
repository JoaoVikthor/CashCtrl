import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_branded_header.dart';

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppBrandedHeader(
        title: 'Termos e Privacidade',
        showBack: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          _card(
            'Termos de Uso',
            'Ao usar o CashCtrl, você concorda em fornecer informações verdadeiras sobre o seu negócio e manter a segurança da sua conta.\n\n'
                'O app destina-se ao controle financeiro, cálculo de custos, ticket médio e ficha técnica de produtos. Você é responsável pelos dados que cadastrar, incluindo valores, produtos, fichas técnicas e fotos.\n\n'
                'Não nos responsabilizamos por decisões comerciais tomadas com base nos cálculos do aplicativo. Recomendamos conferir os valores antes de usar em processos fiscais ou contábeis.\n\n'
                'Podemos atualizar estes termos a qualquer momento. O uso contínuo do app significa aceitação da versão mais recente.',
          ),
          const SizedBox(height: AppSpacing.l),
          _card(
            'Política de Privacidade',
            'Coletamos apenas os dados necessários para o funcionamento do CashCtrl:\n\n'
                '• Nome, e-mail e telefone da conta;\n'
                '• Nome da empresa, CNPJ, segmento e endereço;\n'
                '• Transações, orçamentos, produtos, fichas técnicas e fotos cadastradas por você.\n\n'
                'Usamos essas informações exclusivamente para operar o app, organizar seus registros e calcular custos. Não vendemos, alugamos ou compartilhamos seus dados com terceiros para fins publicitários.\n\n'
                'Suas imagens e registros ficam vinculados à sua conta e podem ser excluídos permanentemente quando você escolhe apagar sua conta.\n\n'
                'Dúvidas? Entre em contato pelo e-mail suporte@ctrlcash.app.',
          ),
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Text(
              'CashCtrl - ${DateTime.now().year}',
              style: const TextStyle(
                color: AppColors.textSec,
                fontSize: AppTypography.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppTypography.section,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.textSec,
              fontSize: AppTypography.body,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
