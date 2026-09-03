import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';

class TechnicianKpiBar extends StatelessWidget {
  final int total;
  final int open;
  final int onHold;
  final int resolved;

  const TechnicianKpiBar({
    super.key,
    required this.total,
    required this.open,
    required this.onHold,
    required this.resolved,
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
            value: '$total',
            color: AppColors.primary,
            icon: Icons.assignment_outlined,
          ),
          _buildDivider(),
          _buildSummaryItem(
            label: openLabel,
            value: '$open',
            color: AppColors.warningText,
            icon: Icons.sync,
          ),
          _buildDivider(),
          _buildSummaryItem(
            label: onHoldLabel,
            value: '$onHold',
            color: AppColors.purpleText,
            icon: Icons.pause_circle_outline,
          ),
          _buildDivider(),
          _buildSummaryItem(
            label: resolvedLabel,
            value: '$resolved',
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
              Icon(icon, size: 14, color: color),
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
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
