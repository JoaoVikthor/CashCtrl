import 'package:flutter/material.dart';

import '../models/price_audit_log.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/format.dart';

class AuditEntryTile extends StatelessWidget {
  final PriceAuditLog log;

  const AuditEntryTile({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final destructive = _isDestructive(log.action);
    final icon = _iconFor(log.action);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: destructive ? AppColors.danger : AppColors.gold,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.summary,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppTypography.body,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _detail(),
                  style: TextStyle(
                    color: AppColors.textSec,
                    fontSize: AppTypography.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _time(),
                  style: TextStyle(
                    color: AppColors.textSec,
                    fontSize: AppTypography.caption,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isDestructive(String action) => action.contains('.delete');

  IconData _iconFor(String action) {
    if (action.contains('.create')) return Icons.add_circle_outline;
    if (action.contains('.update')) return Icons.edit_outlined;
    if (action.contains('.delete')) return Icons.delete_outline;
    if (action.contains('setActive') || action.contains('toggleActive')) {
      return Icons.check_circle_outline;
    }
    if (action.contains('migration')) return Icons.sync;
    return Icons.receipt_long;
  }

  String _detail() {
    final previous = log.previousPrice;
    final next = log.newPrice;
    final supplier = log.supplier;

    if (previous != null && next != null) {
      return 'de ${formatCurrencyAbs(previous)} para ${formatCurrencyAbs(next)}';
    }
    if (next != null) {
      return 'novo valor: ${formatCurrencyAbs(next)}';
    }
    if (supplier != null && supplier.isNotEmpty) {
      return supplier;
    }
    return '';
  }

  String _time() {
    final timestamp = log.timestamp;
    if (timestamp == null) return '';
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '${formatDateShort(timestamp)} · $hour:$minute';
  }
}
