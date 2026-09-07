import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../devices/models/device_model.dart';
import '../../../devices/views/helpers/hardware_icon_helper.dart';
import '../../../issues/models/issue_model.dart';

/// High-contrast visual hardware card designed for non-literate and low-literacy users.
/// Prominently uses RED for defective equipment (issue raised) and GREEN for operational units.
class ZoneDeviceCard extends StatelessWidget {
  final DeviceModel device;
  final List<IssueModel> activeIssues;
  final VoidCallback? onTap;
  final ValueChanged<IssueModel>? onInspectIssue;
  final void Function(IssueModel issue, IssueStatus newStatus)? onUpdateIssueStatus;

  const ZoneDeviceCard({
    super.key,
    required this.device,
    this.activeIssues = const [],
    this.onTap,
    this.onInspectIssue,
    this.onUpdateIssueStatus,
  });

  List<IssueModel> get _unresolvedIssues => activeIssues
      .where((i) =>
          i.status != IssueStatus.resolved &&
          i.status != IssueStatus.closed)
      .toList();

  List<IssueModel> get _resolvedIssues => activeIssues
      .where((i) =>
          i.status == IssueStatus.resolved ||
          i.status == IssueStatus.closed)
      .toList();

  bool get hasActiveIssues => _unresolvedIssues.isNotEmpty;
  bool get isAllResolved => !hasActiveIssues && _resolvedIssues.isNotEmpty;

  IssueModel? get _highestPriorityIssue {
    final list = _unresolvedIssues.isNotEmpty ? _unresolvedIssues : _resolvedIssues;
    if (list.isEmpty) return null;
    final sorted = List<IssueModel>.from(list)
      ..sort((a, b) {
        const priorityOrder = {
          IssuePriority.critical: 4,
          IssuePriority.high: 3,
          IssuePriority.medium: 2,
          IssuePriority.low: 1,
        };
        final pa = priorityOrder[a.priority] ?? 0;
        final pb = priorityOrder[b.priority] ?? 0;
        return pb.compareTo(pa);
      });
    return sorted.first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topIssue = _highestPriorityIssue;
    final isDefective = hasActiveIssues;

    // High visual contrast: Solid soft RED ONLY for active defects, Solid soft GREEN for resolved or healthy
    final cardBg = isDefective ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);
    final borderColor = isDefective ? AppColors.error : AppColors.success;
    final iconColor = isDefective ? AppColors.error : AppColors.success;
    final iconBoxBg = isDefective ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7);

    return InkWell(
      onTap: onTap ?? (topIssue != null ? () => onInspectIssue?.call(topIssue) : null),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: isDefective ? 2.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDefective ? AppColors.error : AppColors.success).withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Big Visual Hardware Icon + Status Chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 44x44 Visual Hardware Icon with status badge overlay
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: iconBoxBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor.withValues(alpha: 0.3)),
                      ),
                      child: Icon(
                        HardwareIconHelper.getIcon(
                          device.hardwareTypeName.isNotEmpty
                              ? device.hardwareTypeName
                              : device.name,
                        ),
                        size: 24,
                        color: iconColor,
                      ),
                    ),
                    // Visual status indicator dot/badge
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isDefective ? AppColors.error : AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Icon(
                          isDefective ? Icons.error_outline : Icons.check,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                // Operational Status
                StatusBadge.device(
                  isAllResolved && device.status == DeviceStatus.faulty
                      ? DeviceStatus.active
                      : device.status,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Device Name
            Text(
              device.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),

            // Code Tag + Hardware Type
            Row(
              children: [
                if (device.code.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      device.code,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                if (device.hardwareTypeName.isNotEmpty)
                  Expanded(
                    child: Text(
                      device.hardwareTypeName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Bottom Action Area
            if (isDefective && topIssue != null) ...[
              // BOLD RED ISSUE CALLOUT BANNER (Universal for non-literate workers)
              InkWell(
                onTap: () => onInspectIssue?.call(topIssue),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              topIssue.priority.name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              topIssue.title.isNotEmpty ? topIssue.title : topIssue.categoryName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Tactile Wrench Action Button
                      InkWell(
                        onTap: () => onUpdateIssueStatus?.call(
                          topIssue,
                          // in_progress is the only issue that can go straight
                          // to resolved; everything else must be picked up
                          // (-> in_progress) first.
                          topIssue.status == IssueStatus.inProgress
                              ? IssueStatus.resolved
                              : IssueStatus.inProgress,
                        ),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.build_rounded,
                            size: 14,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Open status pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusBadge.issue(topIssue.status),
                  if (_unresolvedIssues.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.purpleLight,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '+${_unresolvedIssues.length - 1}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.purpleText,
                        ),
                      ),
                    ),
                ],
              ),
            ] else if (isAllResolved) ...[
              // BOLD GREEN RESOLVED BANNER (Universal for non-literate workers)
              InkWell(
                onTap: topIssue != null ? () => onInspectIssue?.call(topIssue) : null,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.successText),
                      const SizedBox(width: 6),
                      Text(
                        l10n.techBadgeResolved,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.successText,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // BOLD GREEN HEALTHY BANNER
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.successText),
                    const SizedBox(width: 6),
                    Text(
                      l10n.techBadgeAllOk,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.successText,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
