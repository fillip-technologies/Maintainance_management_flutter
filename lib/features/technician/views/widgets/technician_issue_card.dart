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
  final bool isSelectable;
  final bool isSelected;
  final ValueChanged<bool?>? onSelect;

  const TechnicianIssueCard({
    super.key,
    required this.issue,
    required this.onTap,
    required this.onUpdateStatus,
    required this.onOpenTimeline,
    this.isSelectable = false,
    this.isSelected = false,
    this.onSelect,
  });

  int? get _unitsAffected => issue.unitsAffected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unitsCount = _unitsAffected;
    final startWorkLabel = l10n?.btnStartWork ?? 'Start Work';
    final holdLabel = l10n?.btnHold ?? 'Hold';
    final resolveLabel = l10n?.btnResolve ?? 'Resolve';
    final timelineLabel = l10n?.timelineHistory ?? 'Timeline';

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
      margin: const EdgeInsets.only(bottom: 14),
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
        onTap: isSelectable ? () => onSelect?.call(!isSelected) : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Ticket ID, Priority, Status
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
                    issue.id.length > 8 ? '#${issue.id.substring(0, 8)}' : issue.id,
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
                  // Only surface priority when it actually demands attention —
                  // low/medium priority badges are noise on a small card.
                  if (issue.priority == IssuePriority.critical ||
                      issue.priority == IssuePriority.high) ...[
                    StatusBadge.priority(issue.priority),
                    const SizedBox(width: 6),
                  ],
                  StatusBadge.issue(issue.status),
                ],
              ),
              const SizedBox(height: 10),

              // Issue Title
              Text(
                issue.title.isNotEmpty
                    ? issue.title
                    : (issue.displayDescription.isNotEmpty ? issue.displayDescription : 'Maintenance Issue'),
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

              if (issue.displayDescription.isNotEmpty) ...[
                const SizedBox(height: 8),
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

              // In bulk-selection mode the whole card is a checkbox target, so
              // per-card action buttons would just get in the way.
              if (!isSelectable) ...[
                const SizedBox(height: 14),
                _buildActionArea(
                  startWorkLabel: startWorkLabel,
                  holdLabel: holdLabel,
                  resolveLabel: resolveLabel,
                  timelineLabel: timelineLabel,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// One prominent primary action per state, big enough to tap without reading.
  Widget _buildActionArea({
    required String startWorkLabel,
    required String holdLabel,
    required String resolveLabel,
    required String timelineLabel,
  }) {
    switch (issue.status) {
      case IssueStatus.open:
      case IssueStatus.assigned:
      case IssueStatus.reopened:
        return _primaryButton(
          label: startWorkLabel,
          icon: Icons.play_arrow_rounded,
          color: AppColors.warning,
          onPressed: () => onUpdateStatus(IssueStatus.inProgress),
        );
      case IssueStatus.inProgress:
        return Row(
          children: [
            Expanded(
              child: _primaryButton(
                label: resolveLabel,
                icon: Icons.check_rounded,
                color: AppColors.success,
                onPressed: () => onUpdateStatus(IssueStatus.resolved),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: () => onUpdateStatus(IssueStatus.onHold),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(holdLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      case IssueStatus.onHold:
        return _primaryButton(
          label: startWorkLabel,
          icon: Icons.play_arrow_rounded,
          color: AppColors.warning,
          onPressed: () => onUpdateStatus(IssueStatus.inProgress),
        );
      case IssueStatus.resolved:
      case IssueStatus.closed:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onOpenTimeline,
            icon: const Icon(Icons.history_rounded, size: 18),
            label: Text(timelineLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size(0, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );
    }
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          minimumSize: const Size(0, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
