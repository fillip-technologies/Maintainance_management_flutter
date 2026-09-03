import 'package:flutter/material.dart';
import '../../data/models/daily_log_model.dart';
import '../../data/models/device_model.dart';
import '../../data/models/issue_model.dart';
import '../../l10n/app_localizations.dart';
import '../theme/colors.dart';

class StatusBadge extends StatelessWidget {
  final String? text;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final IssuePriority? priority;
  final IssueStatus? issueStatus;
  final DailyLogStatus? dailyLogStatus;
  final DeviceStatus? deviceStatus;

  const StatusBadge({
    super.key,
    required String this.text,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  })  : priority = null,
        issueStatus = null,
        dailyLogStatus = null,
        deviceStatus = null;

  const StatusBadge._internal({
    super.key,
    this.text,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
    this.priority,
    this.issueStatus,
    this.dailyLogStatus,
    this.deviceStatus,
  });

  factory StatusBadge.device(DeviceStatus status) {
    final (bg, textCol, icon) = switch (status) {
      DeviceStatus.active => (
          AppColors.successLight,
          AppColors.successText,
          Icons.check_circle_outline
        ),
      DeviceStatus.underMaintenance => (
          AppColors.warningLight,
          AppColors.warningText,
          Icons.build_circle_outlined
        ),
      DeviceStatus.faulty => (
          AppColors.errorLight,
          AppColors.errorText,
          Icons.error_outline
        ),
      DeviceStatus.provisioned => (
          AppColors.infoLight,
          AppColors.infoText,
          Icons.pending_outlined
        ),
      DeviceStatus.retired => (
          AppColors.neutralLight,
          AppColors.neutralText,
          Icons.archive_outlined
        ),
    };

    return StatusBadge._internal(
      deviceStatus: status,
      backgroundColor: bg,
      textColor: textCol,
      icon: icon,
    );
  }

  factory StatusBadge.issue(IssueStatus status) {
    final (bg, textCol, icon) = switch (status) {
      IssueStatus.open => (
          AppColors.errorLight,
          AppColors.errorText,
          Icons.fiber_new
        ),
      IssueStatus.assigned => (
          AppColors.infoLight,
          AppColors.infoText,
          Icons.assignment_ind_outlined
        ),
      IssueStatus.inProgress => (
          AppColors.warningLight,
          AppColors.warningText,
          Icons.sync
        ),
      IssueStatus.onHold => (
          AppColors.purpleLight,
          AppColors.purpleText,
          Icons.pause_circle_outline
        ),
      IssueStatus.resolved => (
          AppColors.successLight,
          AppColors.successText,
          Icons.check_circle_outline
        ),
      IssueStatus.closed => (
          AppColors.neutralLight,
          AppColors.neutralText,
          Icons.lock_outline
        ),
      IssueStatus.reopened => (
          AppColors.orangeLight,
          AppColors.orangeText,
          Icons.replay
        ),
    };

    return StatusBadge._internal(
      issueStatus: status,
      backgroundColor: bg,
      textColor: textCol,
      icon: icon,
    );
  }

  factory StatusBadge.priority(IssuePriority priority) {
    final (bg, textCol, icon) = switch (priority) {
      IssuePriority.critical => (
          AppColors.errorText,
          AppColors.textWhite,
          Icons.warning_amber_rounded
        ),
      IssuePriority.high => (
          AppColors.errorLight,
          AppColors.errorText,
          null
        ),
      IssuePriority.medium => (
          AppColors.warningLight,
          AppColors.warningText,
          null
        ),
      IssuePriority.low => (
          AppColors.neutralLight,
          AppColors.neutralText,
          null
        ),
    };

    return StatusBadge._internal(
      priority: priority,
      backgroundColor: bg,
      textColor: textCol,
      icon: icon,
    );
  }

  factory StatusBadge.dailyLog(DailyLogStatus status) {
    final (bg, textCol, icon) = switch (status) {
      DailyLogStatus.working => (
          AppColors.successLight,
          AppColors.successText,
          Icons.check_circle
        ),
      DailyLogStatus.notWorking => (
          AppColors.errorLight,
          AppColors.errorText,
          Icons.cancel
        ),
      DailyLogStatus.needsAttention => (
          AppColors.warningLight,
          AppColors.warningText,
          Icons.warning
        ),
    };

    return StatusBadge._internal(
      dailyLogStatus: status,
      backgroundColor: bg,
      textColor: textCol,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    String labelText = text ?? '';
    if (priority != null) {
      labelText = switch (priority!) {
        IssuePriority.critical => l10n?.priorityCritical ?? 'CRITICAL',
        IssuePriority.high => l10n?.priorityHigh ?? 'High',
        IssuePriority.medium => l10n?.priorityMedium ?? 'Medium',
        IssuePriority.low => l10n?.priorityLow ?? 'Low',
      };
    } else if (issueStatus != null) {
      labelText = switch (issueStatus!) {
        IssueStatus.open => l10n?.statusOpen ?? 'Open',
        IssueStatus.assigned => l10n?.statusAssigned ?? 'Assigned',
        IssueStatus.inProgress => l10n?.statusInProgress ?? 'In Progress',
        IssueStatus.onHold => l10n?.statusOnHold ?? 'On Hold',
        IssueStatus.resolved => l10n?.statusResolved ?? 'Resolved',
        IssueStatus.closed => l10n?.statusClosed ?? 'Closed',
        IssueStatus.reopened => l10n?.statusReopened ?? 'Reopened',
      };
    } else if (dailyLogStatus != null) {
      labelText = switch (dailyLogStatus!) {
        DailyLogStatus.working => l10n?.logStatusWorking ?? 'Working',
        DailyLogStatus.notWorking => l10n?.logStatusNotWorking ?? 'Not Working',
        DailyLogStatus.needsAttention => l10n?.logStatusNeedsAttention ?? 'Needs Attention',
      };
    } else if (deviceStatus != null) {
      labelText = switch (deviceStatus!) {
        DeviceStatus.active => l10n?.deviceStatusActive ?? 'Active',
        DeviceStatus.underMaintenance => l10n?.deviceStatusMaintenance ?? 'Maintenance',
        DeviceStatus.faulty => l10n?.deviceStatusFaulty ?? 'Faulty',
        DeviceStatus.provisioned => l10n?.deviceStatusProvisioned ?? 'Provisioned',
        DeviceStatus.retired => l10n?.deviceStatusRetired ?? 'Retired',
      };
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            labelText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

extension IssuePriorityLocalization on IssuePriority {
  String localized(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return label;
    return switch (this) {
      IssuePriority.critical => l10n.priorityCritical,
      IssuePriority.high => l10n.priorityHigh,
      IssuePriority.medium => l10n.priorityMedium,
      IssuePriority.low => l10n.priorityLow,
    };
  }
}

extension IssueStatusLocalization on IssueStatus {
  String localized(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return label;
    return switch (this) {
      IssueStatus.open => l10n.statusOpen,
      IssueStatus.assigned => l10n.statusAssigned,
      IssueStatus.inProgress => l10n.statusInProgress,
      IssueStatus.onHold => l10n.statusOnHold,
      IssueStatus.resolved => l10n.statusResolved,
      IssueStatus.closed => l10n.statusClosed,
      IssueStatus.reopened => l10n.statusReopened,
    };
  }
}
