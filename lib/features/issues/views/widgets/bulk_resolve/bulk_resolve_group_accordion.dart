import 'package:flutter/material.dart';
import 'package:equipment_management_system/core/theme/colors.dart';
import 'package:equipment_management_system/core/widgets/status_badge.dart';
import 'package:equipment_management_system/features/devices/views/helpers/hardware_icon_helper.dart';
import 'package:equipment_management_system/features/issues/models/issue_model.dart';
import 'package:equipment_management_system/l10n/app_localizations.dart';

class BulkResolveGroupAccordion extends StatelessWidget {
  final String groupName;
  final List<IssueModel> groupIssues;
  final Set<String> selectedIssueIds;
  final ValueChanged<String> onToggleIssue;
  final VoidCallback onToggleGroup;

  const BulkResolveGroupAccordion({
    super.key,
    required this.groupName,
    required this.groupIssues,
    required this.selectedIssueIds,
    required this.onToggleIssue,
    required this.onToggleGroup,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final groupIds = groupIssues.map((e) => e.id).toSet();
    final allGroupSelected = groupIds.every(selectedIssueIds.contains);
    final groupSelectedCount = groupIssues.where((i) => selectedIssueIds.contains(i.id)).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allGroupSelected
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: AppColors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              HardwareIconHelper.getIcon(groupName),
              size: 20,
              color: AppColors.primary,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  groupName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.cardAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$groupSelectedCount/${groupIssues.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          trailing: TextButton(
            onPressed: onToggleGroup,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              allGroupSelected
                  ? (l10n?.deselectGroup ?? 'Deselect')
                  : (l10n?.selectAllInGroup ?? 'Select Group'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: allGroupSelected ? AppColors.error : AppColors.primary,
              ),
            ),
          ),
          children: groupIssues.map((issue) {
            final isSelected = selectedIssueIds.contains(issue.id);
            final units = issue.unitsAffected;

            return InkWell(
              onTap: () => onToggleIssue(issue.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryBg.withValues(alpha: 0.2)
                      : AppColors.transparent,
                  border: Border(
                    top: BorderSide(color: AppColors.divider, width: 0.5),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (_) => onToggleIssue(issue.id),
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                issue.id.length > 8
                                    ? '#${issue.id.substring(0, 8)}'
                                    : '#${issue.id}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (units != null && units > 1) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.purpleLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '$units Units',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.purpleText,
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              StatusBadge.priority(issue.priority),
                              const SizedBox(width: 4),
                              StatusBadge.issue(issue.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${issue.deviceName} • ${issue.zoneName}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (issue.displayDescription.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              issue.displayDescription,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
