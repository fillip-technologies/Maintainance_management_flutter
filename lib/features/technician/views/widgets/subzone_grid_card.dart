import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../devices/models/technician_zone_node.dart';

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

    final gradientColors = AppColors.subzoneGradients[index % AppColors.subzoneGradients.length];
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
        ? AppColors.statusErrorBg
        : (isPartialIssue ? AppColors.statusWarningBg : AppColors.statusSuccessBg);

    final borderColor = isAllUnderIssue
        ? AppColors.error
        : (isPartialIssue ? AppColors.warning : AppColors.success);

    final badgeColor = isAllUnderIssue
        ? AppColors.error
        : (isPartialIssue ? AppColors.statusWarningTextDark : AppColors.success);

    final iconGradient = isAllUnderIssue
        ? AppColors.gradientError
        : (isPartialIssue
            ? AppColors.gradientWarning
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
                              color: AppColors.white,
                              size: 22,
                            ),
                          ),
                        )
                      : Icon(
                          hasIssues ? Icons.warning_amber_rounded : Icons.location_on_rounded,
                          color: AppColors.white,
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
                        color: AppColors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        needsFix > 0
                            ? '$needsFix'
                            : (hasIssues ? '${zone.openIssuesCount}' : l10n.techBadgeOk),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.white,
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
              style: TextStyle(
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
                Icon(Icons.inventory_2_outlined, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 3),
                Text(
                  '${zone.deviceCount}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (zone.subzoneCount > 0) ...[
                  const SizedBox(width: 10),
                  Icon(Icons.account_tree_outlined, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 3),
                  Text(
                    '${zone.subzoneCount}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
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
              child: Icon(
                Icons.cloud_off_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              zone.name,
              style: TextStyle(
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
                Icon(Icons.refresh_rounded, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    l10n.techCouldntLoadRetry,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
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
