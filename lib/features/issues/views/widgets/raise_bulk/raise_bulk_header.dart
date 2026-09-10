import 'package:flutter/material.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../l10n/app_localizations.dart';

class RaiseBulkHeader extends StatelessWidget {
  final VoidCallback onClose;

  const RaiseBulkHeader({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.playlist_add_rounded,
                color: AppColors.errorText,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.raiseBulkDefectTitle ?? 'Raise Bulk Defect',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n?.raiseBulkDefectSubtitle ?? 'Report identical issue on multiple units (1–50)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          onPressed: onClose,
          icon: Icon(Icons.close, color: AppColors.icon),
        ),
      ],
    );
  }
}
