import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/hardware_stat_row.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../devices/models/technician_zone_node.dart';

/// Top hero card visualizing overall operational health and prominent problem alerts.
class ZoneHealthHeroCard extends StatelessWidget {
  final TechnicianZoneNode? focusedZone;
  final List<TechnicianZoneNode> rootZones;

  const ZoneHealthHeroCard({
    super.key,
    this.focusedZone,
    required this.rootZones,
  });

  @override
  Widget build(BuildContext context) {
    if (focusedZone != null) {
      return _buildZoneHero(context, focusedZone!);
    }
    return _buildRootHero(context);
  }

  Widget _buildRootHero(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    var totalDevices = 0;
    var totalWorking = 0;
    var totalNeedsFix = 0;

    // Zones whose enrichment failed contribute no reliable counts — leaving
    // them in would drag the % down with phantom zeroes.
    final countedZones = rootZones.where((z) => !z.dataLoadFailed);
    for (final z in countedZones) {
      totalDevices += z.deviceCount;
      totalWorking += z.workingCount;
      // Distinct units with an UNRESOLVED issue (resolved/closed never count).
      totalNeedsFix += z.unresolvedUnitsCount;
    }

    final operationalRate = totalDevices > 0
        ? ((totalWorking / totalDevices) * 100).round().clamp(0, 100)
        : 100;

    final statusColor = _statusColor(totalWorking, totalDevices);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.radar_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.techCoverageOverview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            l10n.techZonesDevicesSummary(rootZones.length, totalDevices),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      l10n.techPercentOnline(operationalRate),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Visual health progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: totalDevices > 0 ? (totalWorking / totalDevices).clamp(0.0, 1.0) : 1.0,
              minHeight: 8,
              backgroundColor: AppColors.border.withValues(alpha: 0.4),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 12),

          // Headline: total units, active units, units with an unresolved issue.
          HardwareStatRow(
            total: totalDevices,
            active: totalWorking,
            problems: totalNeedsFix,
            totalLabel: l10n.techStatTotal,
            activeLabel: l10n.techStatOnline,
            problemLabel: l10n.techStatNeedsFix,
          ),
        ],
      ),
    );
  }

  /// Traffic-light colour from device health alone: all working → green,
  /// most working → amber, a lot down → red.
  static Color _statusColor(int working, int total) {
    if (total == 0 || working >= total) return AppColors.success;
    if (working < total * 0.75) return AppColors.error;
    return AppColors.warning;
  }

  Widget _buildZoneHero(BuildContext context, TechnicianZoneNode zone) {
    final l10n = AppLocalizations.of(context)!;
    if (zone.dataLoadFailed) {
      return _buildUnknownHero(l10n, zone);
    }

    final statusColor = _statusColor(zone.workingCount, zone.deviceCount);
    final operationalRate = zone.operationalPercentage;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: (zone.imageUrl != null && zone.imageUrl!.isNotEmpty)
                    ? Image.network(
                        zone.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.location_on_rounded,
                          size: 22,
                          color: statusColor,
                        ),
                      )
                    : Icon(
                        Icons.location_on_rounded,
                        size: 22,
                        color: statusColor,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      zone.clientName != null
                          ? l10n.techZoneClientDepth(zone.clientName!, zone.depth)
                          : l10n.techZoneDepthStatus(zone.depth, zone.status.toUpperCase()),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  l10n.techPercentHealth(operationalRate),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Operational progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: operationalRate / 100.0,
              minHeight: 8,
              backgroundColor: AppColors.border.withValues(alpha: 0.4),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 12),

          // Headline: total units, active units, units with an unresolved issue.
          HardwareStatRow(
            total: zone.deviceCount,
            active: zone.workingCount,
            problems: zone.unresolvedUnitsCount,
            totalLabel: l10n.techStatTotal,
            activeLabel: l10n.techStatOnline,
            problemLabel: l10n.techStatNeedsFix,
          ),
        ],
      ),
    );
  }

  Widget _buildUnknownHero(AppLocalizations l10n, TechnicianZoneNode zone) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.cloud_off_rounded, size: 22, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zone.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.techZoneHealthLoadFailed,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


