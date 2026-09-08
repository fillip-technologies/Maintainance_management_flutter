import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// A three-tile hardware headline shared by the technician zone map and the
/// staff dashboard: TOTAL units · ACTIVE units · PROBLEMS.
///
/// `problems` is supplied explicitly by the caller — it is the count of units
/// with an *unresolved* issue (resolved/closed tickets are never counted), not
/// simply `total - active`.
///
/// Labels are passed in so this stays free of `AppLocalizations`.
class HardwareStatRow extends StatelessWidget {
  final int total;
  final int active;
  final int problems;
  final String totalLabel;
  final String activeLabel;
  final String problemLabel;

  const HardwareStatRow({
    super.key,
    required this.total,
    required this.active,
    required this.problems,
    required this.totalLabel,
    required this.activeLabel,
    required this.problemLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HardwareStatTile(
          label: totalLabel,
          value: '$total',
          color: AppColors.textPrimary,
          bg: AppColors.cardAlt,
          icon: Icons.inventory_2_outlined,
        ),
        const SizedBox(width: 8),
        HardwareStatTile(
          label: activeLabel,
          value: '$active',
          color: AppColors.success,
          bg: AppColors.success.withValues(alpha: 0.08),
          icon: Icons.check_circle_outline_rounded,
        ),
        const SizedBox(width: 8),
        HardwareStatTile(
          label: problemLabel,
          value: '$problems',
          color: problems > 0 ? AppColors.error : AppColors.textSecondary,
          bg: problems > 0
              ? AppColors.error.withValues(alpha: 0.08)
              : AppColors.cardAlt,
          icon: Icons.build_circle_outlined,
        ),
      ],
    );
  }
}

class HardwareStatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;
  final IconData icon;

  const HardwareStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: color.withValues(alpha: 0.8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Icon(icon, size: 12, color: color),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
