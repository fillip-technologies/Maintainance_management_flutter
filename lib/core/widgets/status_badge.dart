import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../../data/models/daily_log_model.dart';
import '../../data/models/device_model.dart';
import '../../data/models/issue_model.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory StatusBadge.device(DeviceStatus status) {
    return switch (status) {
      DeviceStatus.active => const StatusBadge(
          text: 'Active',
          backgroundColor: AppColors.successLight,
          textColor: AppColors.successText,
          icon: Icons.check_circle_outline,
        ),
      DeviceStatus.underMaintenance => const StatusBadge(
          text: 'Maintenance',
          backgroundColor: AppColors.warningLight,
          textColor: AppColors.warningText,
          icon: Icons.build_circle_outlined,
        ),
      DeviceStatus.faulty => const StatusBadge(
          text: 'Faulty',
          backgroundColor: AppColors.errorLight,
          textColor: AppColors.errorText,
          icon: Icons.error_outline,
        ),
      DeviceStatus.provisioned => const StatusBadge(
          text: 'Provisioned',
          backgroundColor: AppColors.infoLight,
          textColor: AppColors.infoText,
          icon: Icons.pending_outlined,
        ),
      DeviceStatus.retired => const StatusBadge(
          text: 'Retired',
          backgroundColor: AppColors.neutralLight,
          textColor: AppColors.neutralText,
          icon: Icons.archive_outlined,
        ),
    };
  }

  factory StatusBadge.issue(IssueStatus status) {
    return switch (status) {
      IssueStatus.open => const StatusBadge(
          text: 'Open',
          backgroundColor: AppColors.errorLight,
          textColor: AppColors.errorText,
          icon: Icons.fiber_new,
        ),
      IssueStatus.assigned => const StatusBadge(
          text: 'Assigned',
          backgroundColor: AppColors.infoLight,
          textColor: AppColors.infoText,
          icon: Icons.assignment_ind_outlined,
        ),
      IssueStatus.inProgress => const StatusBadge(
          text: 'In Progress',
          backgroundColor: AppColors.warningLight,
          textColor: AppColors.warningText,
          icon: Icons.sync,
        ),
      IssueStatus.onHold => const StatusBadge(
          text: 'On Hold',
          backgroundColor: AppColors.purpleLight,
          textColor: AppColors.purpleText,
          icon: Icons.pause_circle_outline,
        ),
      IssueStatus.resolved => const StatusBadge(
          text: 'Resolved',
          backgroundColor: AppColors.successLight,
          textColor: AppColors.successText,
          icon: Icons.check_circle_outline,
        ),
      IssueStatus.closed => const StatusBadge(
          text: 'Closed',
          backgroundColor: AppColors.neutralLight,
          textColor: AppColors.neutralText,
          icon: Icons.lock_outline,
        ),
      IssueStatus.reopened => const StatusBadge(
          text: 'Reopened',
          backgroundColor: AppColors.orangeLight,
          textColor: AppColors.orangeText,
          icon: Icons.replay,
        ),
    };
  }

  factory StatusBadge.priority(IssuePriority priority) {
    return switch (priority) {
      IssuePriority.critical => const StatusBadge(
          text: 'CRITICAL',
          backgroundColor: AppColors.errorText,
          textColor: AppColors.textWhite,
          icon: Icons.warning_amber_rounded,
        ),
      IssuePriority.high => const StatusBadge(
          text: 'High',
          backgroundColor: AppColors.errorLight,
          textColor: AppColors.errorText,
        ),
      IssuePriority.medium => const StatusBadge(
          text: 'Medium',
          backgroundColor: AppColors.warningLight,
          textColor: AppColors.warningText,
        ),
      IssuePriority.low => const StatusBadge(
          text: 'Low',
          backgroundColor: AppColors.neutralLight,
          textColor: AppColors.neutralText,
        ),
    };
  }

  factory StatusBadge.dailyLog(DailyLogStatus status) {
    return switch (status) {
      DailyLogStatus.working => const StatusBadge(
          text: 'Working',
          backgroundColor: AppColors.successLight,
          textColor: AppColors.successText,
          icon: Icons.check_circle,
        ),
      DailyLogStatus.notWorking => const StatusBadge(
          text: 'Not Working',
          backgroundColor: AppColors.errorLight,
          textColor: AppColors.errorText,
          icon: Icons.cancel,
        ),
      DailyLogStatus.needsAttention => const StatusBadge(
          text: 'Needs Attention',
          backgroundColor: AppColors.warningLight,
          textColor: AppColors.warningText,
          icon: Icons.warning,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
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
            text,
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
