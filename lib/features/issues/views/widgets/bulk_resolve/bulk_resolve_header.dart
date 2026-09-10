import 'package:flutter/material.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../l10n/app_localizations.dart';

class BulkResolveHeader extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onClose;

  const BulkResolveHeader({
    super.key,
    required this.selectedCount,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.task_alt_rounded,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.bulkResolveTitle ?? 'Bulk Resolve Issues',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n?.bulkResolveSubtitle ?? 'Batch update status for multiple tickets (1–50)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Counter Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: selectedCount > 0
                  ? AppColors.primary
                  : AppColors.cardAlt,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$selectedCount/50',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: selectedCount > 0
                    ? AppColors.textWhite
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close, color: AppColors.icon),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
