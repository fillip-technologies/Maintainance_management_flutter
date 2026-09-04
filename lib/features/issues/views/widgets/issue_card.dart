import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../devices/views/helpers/hardware_icon_helper.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../models/issue_model.dart';

class IssueCard extends StatelessWidget {
  final IssueModel issue;
  final VoidCallback? onTap;
  final Widget? trailingAction;

  const IssueCard({
    super.key,
    required this.issue,
    this.onTap,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: issue.priority == IssuePriority.critical
              ? AppColors.error.withValues(alpha: 0.5)
              : AppColors.border,
          width: issue.priority == IssuePriority.critical ? 1.5 : 1,
        ),
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
                  Text(
                    issue.id.length > 8 ? '#${issue.id.substring(0, 8)}' : '#${issue.id}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  StatusBadge.priority(issue.priority),
                  const SizedBox(width: 6),
                  StatusBadge.issue(issue.status),
                ],
              ),
              const SizedBox(height: 10),

              // Device & Category Info
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      HardwareIconHelper.getIcon(issue.deviceName),
                      size: 20,
                      color: AppColors.primary,
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
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${issue.zoneName} • ${issue.categoryName}',
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
              if (issue.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  issue.description,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${issue.history.length} events',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    trailingAction!,
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
