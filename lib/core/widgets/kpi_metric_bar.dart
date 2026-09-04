import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Single KPI metric item definition.
class KpiMetricItem {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const KpiMetricItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
}

/// Unified KPI metric header bar used across Staff and Technician views.
class KpiMetricBar extends StatelessWidget {
  final List<KpiMetricItem> items;

  const KpiMetricBar({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) _buildDivider(),
            _buildMetricTile(items[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile(KpiMetricItem item) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 14, color: item.color),
              const SizedBox(width: 4),
              Text(
                item.value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: item.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
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
