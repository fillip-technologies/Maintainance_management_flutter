import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;

    // Health enrichment failed for this zone: show a neutral "unknown" card,
    // never a misleading all-clear green.
    if (zone.dataLoadFailed) {
      return _buildUnknownCard(l10n);
    }

    final gradientColors = _gradients[index % _gradients.length];
    final totalDevices = zone.deviceCount;
    final needsFix = (totalDevices - zone.workingCount).clamp(0, totalDevices);
    final hasIssues = needsFix > 0 || zone.hasIssues;

    // 1. RED: ALL units in this zone are under issue (100% outage)
    final isAllUnderIssue = totalDevices > 0 && (needsFix >= totalDevices || zone.workingCount == 0);

    // 2. YELLOW: Partial issues (at least 1 device broken, but NOT all)
    final isPartialIssue = hasIssues && !isAllUnderIssue;

    // High visual contrast:
    // - Red border & tint if ALL devices under issue
    // - Yellow border & warm amber tint if SOME devices under issue
    // - Green border & clean tint if all nominal
    final cardBg = isAllUnderIssue
        ? const Color(0xFFFEF2F2)
        : (isPartialIssue ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4));

    final borderColor = isAllUnderIssue
        ? AppColors.error
        : (isPartialIssue ? AppColors.warning : AppColors.success);

    final badgeColor = isAllUnderIssue
        ? AppColors.error
        : (isPartialIssue ? const Color(0xFFD97706) : AppColors.success);

    final iconGradient = isAllUnderIssue
        ? const [Color(0xFFEF4444), Color(0xFFDC2626)]
        : (isPartialIssue
            ? const [Color(0xFFF59E0B), Color(0xFFD97706)]
            : gradientColors);

    final hasZoneImage = zone.imageUrl != null && zone.imageUrl!.isNotEmpty;

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
            // Top: Zone Image / Gradient Icon + Defect / Health Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: hasZoneImage ? borderColor.withValues(alpha: 0.1) : null,
                    gradient: hasZoneImage
                        ? null
                        : LinearGradient(
                            colors: iconGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: borderColor.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasZoneImage
                      ? Image.network(
                          zone.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: iconGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Icon(
                              hasIssues ? Icons.warning_amber_rounded : Icons.location_on_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        )
                      : Icon(
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
                        needsFix > 0
                            ? '$needsFix'
                            : (hasIssues ? '${zone.openIssuesCount}' : l10n.techBadgeOk),
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
                height: 1.15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // The red number / green OK badge above already carries the health
            // signal — this row is a compact "what's inside" summary + drill-in hint.
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 3),
                Text(
                  '${zone.deviceCount}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (zone.subzoneCount > 0) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.account_tree_outlined, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 3),
                  Text(
                    '${zone.subzoneCount}',
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

  Widget _buildUnknownCard(AppLocalizations l10n) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardAlt,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(height: 10),
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
            Row(
              children: [
                const Icon(Icons.refresh_rounded, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    l10n.techCouldntLoadRetry,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
