import 'package:flutter/material.dart';
import '../../../../../core/theme/colors.dart';
import '../../../models/issue_model.dart';
import '../../../../../l10n/app_localizations.dart';

class BulkResolveTargetStatusChips extends StatelessWidget {
  final IssueStatus targetStatus;
  final ValueChanged<IssueStatus> onTargetStatusChanged;

  const BulkResolveTargetStatusChips({
    super.key,
    required this.targetStatus,
    required this.onTargetStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n?.applyToSelected ?? 'Apply to Selected',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatusChip(
              status: IssueStatus.resolved,
              label: l10n?.actionMarkResolved ?? 'Mark Resolved',
              icon: Icons.check_circle_outline,
              color: AppColors.success,
              bgColor: AppColors.successLight,
            ),
            const SizedBox(width: 8),
            _buildStatusChip(
              status: IssueStatus.inProgress,
              label: l10n?.actionStartWork ?? 'Start Work',
              icon: Icons.play_circle_outline,
              color: AppColors.info,
              bgColor: AppColors.infoLight,
            ),
            const SizedBox(width: 8),
            _buildStatusChip(
              status: IssueStatus.onHold,
              label: l10n?.actionHold ?? 'Hold',
              icon: Icons.pause_circle_outline,
              color: AppColors.warning,
              bgColor: AppColors.warningLight,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip({
    required IssueStatus status,
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    final isSelected = targetStatus == status;

    return Expanded(
      child: InkWell(
        onTap: () => onTargetStatusChanged(status),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? bgColor : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? color : AppColors.icon),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? color : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
