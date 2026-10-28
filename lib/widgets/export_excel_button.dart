import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import '../utils/report_export.dart';
import 'app_toast.dart';

class ExportExcelButton extends StatefulWidget {
  const ExportExcelButton({
    super.key,
    required this.transactions,
    required this.periodLabel,
    this.fileName = 'cashctrl_relatorio.xlsx',
  });

  final List<AppTransaction> transactions;
  final String periodLabel;
  final String fileName;

  @override
  State<ExportExcelButton> createState() => _ExportExcelButtonState();
}

class _ExportExcelButtonState extends State<ExportExcelButton> {
  bool _exporting = false;

  String _short(String message) {
    final oneLine = message.replaceAll('\n', ' ').trim();
    if (oneLine.length <= 160) return oneLine;
    return '${oneLine.substring(0, 157)}...';
  }

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final bytes = buildReportWorkbook(
        transactions: widget.transactions,
        periodLabel: widget.periodLabel,
      );
      final error = await saveAndShareXlsx(bytes, widget.fileName);
      if (!mounted) return;
      if (error == null) {
        AppToast.success(context, 'Relatório Excel exportado');
      } else {
        AppToast.error(context, _short(error));
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, _short('Falha ao gerar o Excel: $e'));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool disabled = _exporting || widget.transactions.isEmpty;
    return FilledButton.tonalIcon(
      onPressed: disabled ? null : _export,
      icon: _exporting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gold,
              ),
            )
          : const Icon(Icons.download_outlined, size: 18),
      label: Text(_exporting ? 'Exportando...' : 'Exportar Excel'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.gold,
        disabledBackgroundColor: AppColors.card.withValues(alpha: 0.5),
        disabledForegroundColor: AppColors.textTertiary,
        side: const BorderSide(color: AppColors.border),
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
    );
  }
}
