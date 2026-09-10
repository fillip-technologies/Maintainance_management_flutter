import 'package:flutter/material.dart';
import 'package:equipment_management_system/core/theme/colors.dart';
import 'package:equipment_management_system/core/widgets/status_badge.dart';
import 'package:equipment_management_system/features/issues/models/issue_model.dart';
import 'package:equipment_management_system/l10n/app_localizations.dart';

class RaiseBulkPrioritySelector extends StatelessWidget {
  final IssuePriority selectedPriority;
  final ValueChanged<IssuePriority> onPriorityChanged;

  const RaiseBulkPrioritySelector({
    super.key,
    required this.selectedPriority,
    required this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n?.severityPriority ?? 'Severity / Priority',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: IssuePriority.values.map((priority) {
            final isSelected = selectedPriority == priority;
            final (bg, textCol) = switch (priority) {
              IssuePriority.critical => isSelected
                  ? (AppColors.error, AppColors.textWhite)
                  : (AppColors.errorLight, AppColors.errorText),
              IssuePriority.high => isSelected
                  ? (AppColors.warning, AppColors.textWhite)
                  : (AppColors.warningLight, AppColors.warningText),
              IssuePriority.medium => isSelected
                  ? (AppColors.info, AppColors.textWhite)
                  : (AppColors.infoLight, AppColors.infoText),
              IssuePriority.low => isSelected
                  ? (AppColors.primary, AppColors.textWhite)
                  : (AppColors.surface, AppColors.textSecondary),
            };

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: () => onPriorityChanged(priority),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.transparent : AppColors.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      priority.localized(context),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
