import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class ConfirmActionDialog extends StatelessWidget {
  final String title;
  final String body;
  final String? note;

  const ConfirmActionDialog({
    super.key,
    required this.title,
    required this.body,
    this.note,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String body,
    String? note,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmActionDialog(
        title: title,
        body: body,
        note: note,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final noteText = note;
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppTypography.title,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            body,
            style: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.7),
              fontSize: AppTypography.body,
            ),
          ),
          if (noteText != null) ...[
            const SizedBox(height: AppSpacing.m),
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                noteText,
                style: TextStyle(
                  color: AppColors.textSec,
                  fontSize: AppTypography.secondary,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            'Confirmar',
            style: TextStyle(
              color: AppColors.danger,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
