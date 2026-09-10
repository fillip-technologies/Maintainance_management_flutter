import 'package:flutter/material.dart';
import 'package:equipment_management_system/core/theme/colors.dart';
import 'package:equipment_management_system/features/issues/models/issue_model.dart';

class StatusChoiceChips extends StatelessWidget {
  final List<IssueStatus> allowedStatuses;
  final IssueStatus selectedStatus;
  final ValueChanged<IssueStatus> onStatusSelected;

  const StatusChoiceChips({
    super.key,
    required this.allowedStatuses,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select Next Status',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: allowedStatuses.map((s) {
            final isSelected = selectedStatus == s;

            final (bg, textCol) = switch (s) {
              IssueStatus.inProgress =>
                isSelected
                    ? (AppColors.warning, AppColors.textWhite)
                    : (AppColors.warningLight, AppColors.warningText),
              IssueStatus.onHold =>
                isSelected
                    ? (AppColors.purple, AppColors.textWhite)
                    : (AppColors.purpleLight, AppColors.purpleText),
              IssueStatus.resolved =>
                isSelected
                    ? (AppColors.success, AppColors.textWhite)
                    : (AppColors.successLight, AppColors.successText),
              _ =>
                isSelected
                    ? (AppColors.primary, AppColors.textWhite)
                    : (AppColors.surface, AppColors.textSecondary),
            };

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: () => onStatusSelected(s),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.transparent : AppColors.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      s.label,
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
