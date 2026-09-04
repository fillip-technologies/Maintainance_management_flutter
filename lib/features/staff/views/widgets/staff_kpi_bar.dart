import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/kpi_metric_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../daily_logs/daily_logs.dart';
import '../../../devices/devices.dart';

class StaffKpiBar extends StatelessWidget {
  final AsyncValue<DashboardSummaryModel> summaryAsync;
  final List<DeviceModel>? devices;

  const StaffKpiBar({
    super.key,
    required this.summaryAsync,
    this.devices,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalLabel = l10n?.kpiTotalDevices ?? 'Total Hardware';
    final activeLabel = l10n?.deviceStatusActive ?? 'Active';
    final openIssuesLabel = l10n?.kpiActiveIssues ?? 'Open Issues';
    final faultyLabel = l10n?.deviceStatusFaulty ?? 'Faulty';

    final hasDevices = devices != null && devices!.isNotEmpty;
    final liveActive = hasDevices ? devices!.where((d) => d.status == DeviceStatus.active).length : null;
    final liveTotal = hasDevices ? devices!.where((d) => d.status != DeviceStatus.retired).length : null;
    final liveFaulty = hasDevices ? devices!.where((d) => d.status == DeviceStatus.faulty).length : null;

    return summaryAsync.when(
      loading: () => KpiMetricBar(
        items: [
          KpiMetricItem(label: totalLabel, value: liveTotal != null ? '$liveTotal' : '...', color: AppColors.primary, icon: Icons.devices),
          KpiMetricItem(label: activeLabel, value: liveActive != null ? '$liveActive' : '...', color: AppColors.successText, icon: Icons.check_circle_outline),
          KpiMetricItem(label: openIssuesLabel, value: '...', color: AppColors.warningText, icon: Icons.build_circle_outlined),
          KpiMetricItem(label: faultyLabel, value: liveFaulty != null ? '$liveFaulty' : '...', color: AppColors.errorText, icon: Icons.error_outline),
        ],
      ),
      error: (_, _) => KpiMetricBar(
        items: [
          KpiMetricItem(label: totalLabel, value: liveTotal != null ? '$liveTotal' : '-', color: AppColors.primary, icon: Icons.devices),
          KpiMetricItem(label: activeLabel, value: liveActive != null ? '$liveActive' : '-', color: AppColors.successText, icon: Icons.check_circle_outline),
          KpiMetricItem(label: openIssuesLabel, value: '-', color: AppColors.warningText, icon: Icons.build_circle_outlined),
          KpiMetricItem(label: faultyLabel, value: liveFaulty != null ? '$liveFaulty' : '-', color: AppColors.errorText, icon: Icons.error_outline),
        ],
      ),
      data: (summary) {
        final activeVal = (liveActive != null) ? liveActive : summary.activeDevices;
        final totalVal = (liveTotal != null && liveTotal > 0) ? liveTotal : summary.totalDevices;
        final faultyVal = (liveFaulty != null) ? liveFaulty : summary.faultyDevices;

        return KpiMetricBar(
          items: [
            KpiMetricItem(label: totalLabel, value: '$totalVal', color: AppColors.primary, icon: Icons.devices),
            KpiMetricItem(label: activeLabel, value: '$activeVal', color: AppColors.successText, icon: Icons.check_circle_outline),
            KpiMetricItem(label: openIssuesLabel, value: '${summary.openIssues}', color: AppColors.warningText, icon: Icons.build_circle_outlined),
            KpiMetricItem(label: faultyLabel, value: '$faultyVal', color: AppColors.errorText, icon: Icons.error_outline),
          ],
        );
      },
    );
  }
}
