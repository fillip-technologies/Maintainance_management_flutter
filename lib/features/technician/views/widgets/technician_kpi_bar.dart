import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/kpi_metric_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/technician_queue_state.dart';

class TechnicianKpiBar extends StatelessWidget {
  final TechnicianKpiStats stats;

  const TechnicianKpiBar({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalLabel = l10n?.kpiTotal ?? 'Total';
    final openLabel = l10n?.kpiOpen ?? 'Open';
    final onHoldLabel = l10n?.kpiOnHold ?? 'On Hold';
    final resolvedLabel = l10n?.kpiResolved ?? 'Resolved';

    return KpiMetricBar(
      items: [
        KpiMetricItem(
          label: totalLabel,
          value: '${stats.total}',
          color: AppColors.primary,
          icon: Icons.assignment_outlined,
        ),
        KpiMetricItem(
          label: openLabel,
          value: '${stats.open}',
          color: AppColors.warningText,
          icon: Icons.sync,
        ),
        KpiMetricItem(
          label: onHoldLabel,
          value: '${stats.onHold}',
          color: AppColors.purpleText,
          icon: Icons.pause_circle_outline,
        ),
        KpiMetricItem(
          label: resolvedLabel,
          value: '${stats.resolved}',
          color: AppColors.successText,
          icon: Icons.check_circle_outline,
        ),
      ],
    );
  }
}
