import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/kpi_metric_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../daily_logs/daily_logs.dart';

class StaffKpiBar extends StatelessWidget {
  final AsyncValue<DashboardSummaryModel> summaryAsync;

  const StaffKpiBar({super.key, required this.summaryAsync});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalLabel = l10n?.kpiTotalDevices ?? 'Total Hardware';
    final activeLabel = l10n?.deviceStatusActive ?? 'Active';
    final openIssuesLabel = l10n?.kpiActiveIssues ?? 'Open Issues';
    final faultyLabel = l10n?.deviceStatusFaulty ?? 'Faulty';

    return summaryAsync.when(
      loading: () => KpiMetricBar(
        items: [
          KpiMetricItem(label: totalLabel, value: '...', color: AppColors.primary, icon: Icons.devices),
          KpiMetricItem(label: activeLabel, value: '...', color: AppColors.successText, icon: Icons.check_circle_outline),
          KpiMetricItem(label: openIssuesLabel, value: '...', color: AppColors.warningText, icon: Icons.build_circle_outlined),
          KpiMetricItem(label: faultyLabel, value: '...', color: AppColors.errorText, icon: Icons.error_outline),
        ],
      ),
      error: (_, _) => KpiMetricBar(
        items: [
          KpiMetricItem(label: totalLabel, value: '-', color: AppColors.primary, icon: Icons.devices),
          KpiMetricItem(label: activeLabel, value: '-', color: AppColors.successText, icon: Icons.check_circle_outline),
          KpiMetricItem(label: openIssuesLabel, value: '-', color: AppColors.warningText, icon: Icons.build_circle_outlined),
          KpiMetricItem(label: faultyLabel, value: '-', color: AppColors.errorText, icon: Icons.error_outline),
        ],
      ),
      data: (summary) => KpiMetricBar(
        items: [
          KpiMetricItem(label: totalLabel, value: '${summary.totalDevices}', color: AppColors.primary, icon: Icons.devices),
          KpiMetricItem(label: activeLabel, value: '${summary.activeDevices}', color: AppColors.successText, icon: Icons.check_circle_outline),
          KpiMetricItem(label: openIssuesLabel, value: '${summary.openIssues}', color: AppColors.warningText, icon: Icons.build_circle_outlined),
          KpiMetricItem(label: faultyLabel, value: '${summary.faultyDevices}', color: AppColors.errorText, icon: Icons.error_outline),
        ],
      ),
    );
  }
}
