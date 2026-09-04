import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: summaryAsync.when(
        loading: () => Row(
          children: [
            _buildSummaryItem(label: totalLabel, value: '...', color: AppColors.primary, icon: Icons.devices),
            _buildDivider(),
            _buildSummaryItem(label: activeLabel, value: '...', color: AppColors.successText, icon: Icons.check_circle_outline),
            _buildDivider(),
            _buildSummaryItem(label: openIssuesLabel, value: '...', color: AppColors.warningText, icon: Icons.build_circle_outlined),
            _buildDivider(),
            _buildSummaryItem(label: faultyLabel, value: '...', color: AppColors.errorText, icon: Icons.error_outline),
          ],
        ),
        error: (_, _) => Row(
          children: [
            _buildSummaryItem(label: totalLabel, value: '-', color: AppColors.primary, icon: Icons.devices),
            _buildDivider(),
            _buildSummaryItem(label: activeLabel, value: '-', color: AppColors.successText, icon: Icons.check_circle_outline),
            _buildDivider(),
            _buildSummaryItem(label: openIssuesLabel, value: '-', color: AppColors.warningText, icon: Icons.build_circle_outlined),
            _buildDivider(),
            _buildSummaryItem(label: faultyLabel, value: '-', color: AppColors.errorText, icon: Icons.error_outline),
          ],
        ),
        data: (summary) => Row(
          children: [
            _buildSummaryItem(
              label: totalLabel,
              value: '${summary.totalDevices}',
              color: AppColors.primary,
              icon: Icons.devices,
            ),
            _buildDivider(),
            _buildSummaryItem(
              label: activeLabel,
              value: '${summary.activeDevices}',
              color: AppColors.successText,
              icon: Icons.check_circle_outline,
            ),
            _buildDivider(),
            _buildSummaryItem(
              label: openIssuesLabel,
              value: '${summary.openIssues}',
              color: AppColors.warningText,
              icon: Icons.build_circle_outlined,
            ),
            _buildDivider(),
            _buildSummaryItem(
              label: faultyLabel,
              value: '${summary.faultyDevices}',
              color: AppColors.errorText,
              icon: Icons.error_outline,
            ),
          ],
        ),
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
