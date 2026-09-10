import 'package:flutter/material.dart';
import '../../../../../core/theme/colors.dart';
import '../../../models/issue_model.dart';
import '../../../../../l10n/app_localizations.dart';

class ReplaceDeviceHeader extends StatelessWidget {
  final IssueModel issue;
  final VoidCallback onClose;

  const ReplaceDeviceHeader({
    super.key,
    required this.issue,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.broken_image_rounded, color: AppColors.errorText, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.decommissionHeading,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  '${issue.deviceName} • ${issue.zoneName}',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close, color: AppColors.icon),
          ),
        ],
      ),
    );
  }
}
