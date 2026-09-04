import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: Row(
        children: [
          _buildSummaryItem(
            label: totalLabel,
            value: '${stats.total}',
            color: AppColors.primary,
            icon: Icons.assignment_outlined,
          ),
          _buildDivider(),
          _buildSummaryItem(
            label: openLabel,
            value: '${stats.open}',
            color: AppColors.warningText,
            icon: Icons.sync,
          ),
          _buildDivider(),
          _buildSummaryItem(
            label: onHoldLabel,
            value: '${stats.onHold}',
            color: AppColors.purpleText,
            icon: Icons.pause_circle_outline,
          ),
          _buildDivider(),
          _buildSummaryItem(
            label: resolvedLabel,
            value: '${stats.resolved}',
            color: AppColors.successText,
            icon: Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      color: AppColors.divider,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
