import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../devices/models/device_model.dart';
import '../../../devices/views/helpers/hardware_icon_helper.dart';
import '../../../issues/models/issue_model.dart';

/// High-contrast hardware card for the Spatial Explorer's 2-column grid.
///
/// The explorer only ever passes devices that have an *unresolved* issue, so the
/// card is built around that one state: a red defect callout with a one-tap
/// wrench action. A green fallback is kept only as a safety net.
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
          i.status != IssueStatus.resolved && i.status != IssueStatus.closed)
      .toList();

  IssueModel? get _topIssue {
    final list = _unresolvedIssues;
    if (list.isEmpty) return null;
    const order = {
      IssuePriority.critical: 4,
      IssuePriority.high: 3,
      IssuePriority.medium: 2,
      IssuePriority.low: 1,
    };
    final sorted = [...list]
      ..sort((a, b) => (order[b.priority] ?? 0).compareTo(order[a.priority] ?? 0));
    return sorted.first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topIssue = _topIssue;
    final isDefective = topIssue != null;

    final borderColor = isDefective ? AppColors.error : AppColors.success;
    final cardBg = isDefective ? AppColors.statusErrorBg : AppColors.statusSuccessBg;
    final iconBoxBg = isDefective ? AppColors.statusErrorTagBg : AppColors.statusSuccessTagBg;

    return InkWell(
      onTap: onTap ??
          (topIssue != null ? () => onInspectIssue?.call(topIssue) : null),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: isDefective ? 2.0 : 1.5),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon + device status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: iconBoxBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor.withValues(alpha: 0.3)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: (device.imageUrl != null && device.imageUrl!.isNotEmpty)
                          ? Image.network(
                              device.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Icon(
                                HardwareIconHelper.getIcon(
                                  device.hardwareTypeName.isNotEmpty
                                      ? device.hardwareTypeName
                                      : device.name,
                                ),
                                size: 23,
                                color: borderColor,
                              ),
                            )
                          : Icon(
                              HardwareIconHelper.getIcon(
                                device.hardwareTypeName.isNotEmpty
                                    ? device.hardwareTypeName
                                    : device.name,
                              ),
                              size: 23,
                              color: borderColor,
                            ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: borderColor,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: AppColors.white, width: 1.5),
                        ),
                        child: topIssue != null
                            ? Text(
                                // How many units this issue affects (bulk defects
                                // hit several); a normal issue is just 1.
                                '${topIssue.unitsAffected ?? 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.white,
                                  height: 1,
                                ),
                              )
                            : Icon(Icons.check, size: 10, color: AppColors.white),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                StatusBadge.device(device.status),
              ],
            ),
            const SizedBox(height: 8),

            // Device name
            Text(
              device.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Code + hardware type
            if (device.code.isNotEmpty || device.hardwareTypeName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (device.code.isNotEmpty) ...[
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          device.code,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (device.hardwareTypeName.isNotEmpty)
                    Expanded(
                      child: Text(
                        device.hardwareTypeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 10),

            if (topIssue != null)
              _DefectCallout(
                issue: topIssue,
                onInspect: () => onInspectIssue?.call(topIssue),
                onAction: () => onUpdateIssueStatus?.call(
                  topIssue,
                  topIssue.status == IssueStatus.inProgress
                      ? IssueStatus.resolved
                      : IssueStatus.inProgress,
                ),
              )
            else
              _OkStrip(label: l10n.techBadgeAllOk),
          ],
        ),
      ),
    );
  }
}

class _DefectCallout extends StatelessWidget {
  final IssueModel issue;
  final VoidCallback onInspect;
  final VoidCallback onAction;

  const _DefectCallout({
    required this.issue,
    required this.onInspect,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onInspect,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 7, 6, 7),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 15, color: AppColors.white),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    issue.title.isNotEmpty ? issue.title : issue.categoryName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: onAction,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.build_rounded, size: 15, color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: StatusBadge.issue(issue.status),
        ),
      ],
    );
  }
}

class _OkStrip extends StatelessWidget {
  final String label;
  const _OkStrip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, size: 15, color: AppColors.successText),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.successText,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
