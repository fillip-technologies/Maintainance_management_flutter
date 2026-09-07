import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../devices/models/technician_zone_node.dart';

const _gradients = [
  [Color(0xFF4F46E5), Color(0xFF0EA5E9)], // Indigo -> Sky
  [Color(0xFF7C3AED), Color(0xFFA855F7)], // Violet -> Purple
  [Color(0xFF059669), Color(0xFF14B8A6)], // Emerald -> Teal
  [Color(0xFFE11D48), Color(0xFFF43F5E)], // Rose -> Pink
  [Color(0xFFD97706), Color(0xFFF59E0B)], // Amber -> Orange
  [Color(0xFF0284C7), Color(0xFF38BDF8)], // Cyan -> Blue
];

/// Tactile visual zone card designed for non-literate and low-literacy technicians.
/// Displays RED background when defects exist, GREEN when all clear.
class SubzoneGridCard extends StatelessWidget {
  final TechnicianZoneNode zone;
  final int index;
  final VoidCallback onTap;

  const SubzoneGridCard({
    super.key,
    required this.zone,
    this.index = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = _gradients[index % _gradients.length];
    final unresolvedUnits = zone.unresolvedUnitsCount > 0
        ? zone.unresolvedUnitsCount
        : (zone.notWorkingCount > 0 ? zone.notWorkingCount : zone.openIssuesCount);
    final hasIssues = unresolvedUnits > 0;

    // High visual contrast: Bold Red if has unresolved units, Clean Green if all resolved
    final cardBg = hasIssues ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);
    final borderColor = hasIssues ? AppColors.error : AppColors.success;
    final badgeColor = hasIssues ? AppColors.error : AppColors.success;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: hasIssues ? 2.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top: Gradient Icon + Defect / Health Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: hasIssues
                          ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                          : gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (hasIssues ? AppColors.error : gradientColors[0]).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    hasIssues ? Icons.warning_amber_rounded : Icons.location_on_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),

                // Bold visual status badge for non-literate recognition
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasIssues ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasIssues ? '$unresolvedUnits' : 'OK',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Zone Title
            Text(
              zone.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Not Resolved Units Counter & Nested Sub-zones Indicator
            Row(
              children: [
                Icon(
                  hasIssues ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                  size: 13,
                  color: hasIssues ? AppColors.error : AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  hasIssues ? '$unresolvedUnits not resolved' : 'All resolved',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: hasIssues ? AppColors.error : AppColors.success,
                  ),
                ),
                if (zone.subzoneCount > 0) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.account_tree_outlined, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${zone.subzoneCount} ${zone.subzoneCount == 1 ? 'zone' : 'zones'}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
