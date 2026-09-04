import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../devices/devices.dart';
import '../../../issues/issues.dart';

class TechnicianIssueCard extends StatelessWidget {
  final IssueModel issue;
  final VoidCallback onTap;
  final void Function(IssueStatus newStatus) onUpdateStatus;
  final VoidCallback onOpenTimeline;

  const TechnicianIssueCard({
    super.key,
    required this.issue,
    required this.onTap,
    required this.onUpdateStatus,
    required this.onOpenTimeline,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final startWorkLabel = l10n?.btnStartWork ?? 'Start Work';
    final holdLabel = l10n?.btnHold ?? 'Hold';
    final resolveLabel = l10n?.btnResolve ?? 'Resolve';
    final timelineLabel = l10n?.timelineHistory ?? 'Timeline';

    return Container(
      key: ValueKey(issue.id),
      margin: const EdgeInsets.only(bottom: 14),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Ticket ID, Priority, Status
              Row(
                children: [
                  Text(
                    issue.id.length > 8 ? '#${issue.id.substring(0, 8)}' : issue.id,
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

              // Issue Title
              Text(
                issue.title.isNotEmpty
                    ? issue.title
                    : (issue.description.isNotEmpty ? issue.description : 'Maintenance Issue'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Equipment Info, Zone & Hardware State with 36x36 Icon Badge
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      HardwareIconHelper.getIcon(
                        issue.categoryName.isNotEmpty ? issue.categoryName : issue.deviceName,
                      ),
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
                          '${issue.deviceName}${issue.deviceCode != null ? " (${issue.deviceCode})" : ""}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${issue.zoneName}${issue.categoryName.isNotEmpty ? " • ${issue.categoryName}" : ""}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (issue.deviceStatus != null) ...[
                    const SizedBox(width: 6),
                    StatusBadge.device(issue.deviceStatus!),
                  ],
                ],
              ),

              if (issue.description.isNotEmpty) ...[
                const SizedBox(height: 8),
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

              const SizedBox(height: 12),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 10),

              // Technician Workflow Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${issue.history.length} timeline events',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Row(
                    children: [
                      if (issue.status == IssueStatus.open ||
                          issue.status == IssueStatus.assigned ||
                          issue.status == IssueStatus.reopened) ...[
                        ElevatedButton.icon(
                          onPressed: () => onUpdateStatus(IssueStatus.inProgress),
                          icon: const Icon(Icons.play_arrow_rounded, size: 15),
                          label: Text(startWorkLabel, style: const TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            foregroundColor: AppColors.textWhite,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ] else if (issue.status == IssueStatus.inProgress) ...[
                        OutlinedButton(
                          onPressed: () => onUpdateStatus(IssueStatus.onHold),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: AppColors.purpleText,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(holdLabel, style: const TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => onUpdateStatus(IssueStatus.resolved),
                          icon: const Icon(Icons.check, size: 15),
                          label: Text(resolveLabel, style: const TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: AppColors.textWhite,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ] else if (issue.status == IssueStatus.onHold) ...[
                        ElevatedButton.icon(
                          onPressed: () => onUpdateStatus(IssueStatus.inProgress),
                          icon: const Icon(Icons.play_arrow_rounded, size: 15),
                          label: Text(startWorkLabel, style: const TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textWhite,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ] else ...[
                        OutlinedButton.icon(
                          onPressed: onOpenTimeline,
                          icon: const Icon(Icons.history, size: 14),
                          label: Text(timelineLabel, style: const TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
