import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../devices/views/helpers/hardware_icon_helper.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../models/issue_model.dart';

class IssueCard extends StatelessWidget {
  final IssueModel issue;
  final VoidCallback? onTap;
  final Widget? trailingAction;
  final bool isSelectable;
  final bool isSelected;
  final ValueChanged<bool?>? onSelect;

  const IssueCard({
    super.key,
    required this.issue,
    this.onTap,
    this.trailingAction,
    this.isSelectable = false,
    this.isSelected = false,
    this.onSelect,
  });

  int? get _unitsAffected => issue.unitsAffected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unitsCount = _unitsAffected;

    final isResolved = issue.status == IssueStatus.resolved || issue.status == IssueStatus.closed;
    final isRaisedOrCritical = !isResolved && (
        issue.status == IssueStatus.open ||
        issue.status == IssueStatus.assigned ||
        issue.status == IssueStatus.reopened ||
        issue.priority == IssuePriority.critical);

    final cardBg = isSelected
        ? AppColors.primaryBg.withValues(alpha: 0.25)
        : (isResolved
            ? const Color(0xFFF0FDF4)
            : (isRaisedOrCritical
                ? const Color(0xFFFEF2F2)
                : (issue.status == IssueStatus.inProgress
                    ? const Color(0xFFFFFBEB)
                    : (issue.status == IssueStatus.onHold
                        ? const Color(0xFFFAF5FF)
                        : AppColors.surface))));

    final borderColor = isSelected
        ? AppColors.primary
        : (isResolved
            ? AppColors.success
            : (isRaisedOrCritical
                ? AppColors.error
                : (issue.status == IssueStatus.inProgress
                    ? AppColors.warning
                    : (issue.status == IssueStatus.onHold
                        ? AppColors.purple
                        : AppColors.border))));

    return Container(
      key: ValueKey(issue.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: (isSelected || isRaisedOrCritical || issue.status == IssueStatus.inProgress || isResolved) ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Ticket ID & Badges
              Row(
                children: [
                  if (isSelectable) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: onSelect,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                    ),
                  ],
                  Text(
                    issue.id.length > 8 ? '#${issue.id.substring(0, 8)}' : '#${issue.id}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  if (unitsCount != null && unitsCount > 1) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.purpleLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.layers_outlined, size: 11, color: AppColors.purpleText),
                          const SizedBox(width: 3),
                          Text(
                            l10n?.unitsAffectedBadge(unitsCount) ?? '$unitsCount Units Affected',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.purpleText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (issue.priority == IssuePriority.critical ||
                      issue.priority == IssuePriority.high) ...[
                    StatusBadge.priority(issue.priority),
                    const SizedBox(width: 6),
                  ],
                  StatusBadge.issue(issue.status),
                ],
              ),
              const SizedBox(height: 10),

              // Title if available
              if (issue.title.isNotEmpty) ...[
                Text(
                  issue.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
              ],

              // Device & Category Info
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isResolved
                          ? const Color(0xFFDCFCE7)
                          : (isRaisedOrCritical
                              ? const Color(0xFFFEE2E2)
                              : AppColors.primaryBg),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (issue.primaryImageUrl != null && issue.primaryImageUrl!.isNotEmpty)
                        ? Image.network(
                            issue.primaryImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              HardwareIconHelper.getIcon(
                                issue.categoryName.isNotEmpty ? issue.categoryName : issue.deviceName,
                              ),
                              size: 20,
                              color: isResolved
                                  ? AppColors.success
                                  : (isRaisedOrCritical ? AppColors.error : AppColors.primary),
                            ),
                          )
                        : Icon(
                            HardwareIconHelper.getIcon(
                              issue.categoryName.isNotEmpty ? issue.categoryName : issue.deviceName,
                            ),
                            size: 20,
                            color: isResolved
                                ? AppColors.success
                                : (isRaisedOrCritical ? AppColors.error : AppColors.primary),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.deviceName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${issue.zoneName}${issue.categoryName.isNotEmpty ? " • ${issue.categoryName}" : ""}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Description Snippet
              if (issue.displayDescription.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  issue.displayDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],

              // Footer / Action Bar
              if (trailingAction != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: trailingAction!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
