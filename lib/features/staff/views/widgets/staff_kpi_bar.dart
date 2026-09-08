import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/kpi_metric_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../devices/devices.dart';
import '../../../issues/issues.dart';

/// Top KPI strip for the staff home, built entirely from the device / daily-log
/// / issue lists the home page already holds. There is no separate summary
/// endpoint call: it could only ever describe one zone, which contradicts the
/// multi-zone scope staff now get.
class StaffKpiBar extends StatelessWidget {
  final List<DeviceModel> devices;
  final int checkedTodayCount;
  final List<IssueModel> issues;

  const StaffKpiBar({
    super.key,
    required this.devices,
    required this.checkedTodayCount,
    required this.issues,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final liveDevices = devices.where((d) => d.status != DeviceStatus.retired).toList();
    final total = liveDevices.length;
    final working = liveDevices.where((d) => d.status == DeviceStatus.active).length;
    final down = liveDevices.where((d) => d.status == DeviceStatus.faulty).length;
    final openProblems = issues
        .where((i) =>
            i.status != IssueStatus.resolved && i.status != IssueStatus.closed)
        .length;

    return KpiMetricBar(
      items: [
        KpiMetricItem(
          label: l10n?.staffKpiCheckedToday ?? 'Checked Today',
          value: '$checkedTodayCount/$total',
          color: checkedTodayCount >= total && total > 0
              ? AppColors.successText
              : AppColors.warningText,
          icon: Icons.checklist_rounded,
        ),
        KpiMetricItem(
          label: l10n?.staffKpiWorking ?? 'Working',
          value: '$working',
          color: AppColors.successText,
          icon: Icons.check_circle_outline,
        ),
        KpiMetricItem(
          label: l10n?.staffKpiProblems ?? 'Problems',
          value: '$openProblems',
          color: openProblems > 0 ? AppColors.warningText : AppColors.textSecondary,
          icon: Icons.build_circle_outlined,
        ),
        KpiMetricItem(
          label: l10n?.staffKpiDown ?? 'Down',
          value: '$down',
          color: down > 0 ? AppColors.errorText : AppColors.textSecondary,
          icon: Icons.error_outline,
        ),
      ],
    );
  }
}
