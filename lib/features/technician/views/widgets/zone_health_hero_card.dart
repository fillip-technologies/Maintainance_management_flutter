import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
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
    var totalDevices = 0;
    var totalWorking = 0;
    var totalNotWorking = 0;
    var totalCritical = 0;
    var totalHigh = 0;
    var totalOpen = 0;

    for (final z in rootZones) {
      totalDevices += z.deviceCount;
      totalWorking += z.workingCount;
      totalNotWorking += z.unresolvedUnitsCount > 0 ? z.unresolvedUnitsCount : z.notWorkingCount;
      totalCritical += z.criticalIssuesCount;
      totalHigh += z.highIssuesCount;
      totalOpen += z.openIssuesCount;
    }

    final operationalRate = totalDevices > 0
        ? ((totalWorking / totalDevices) * 100).round().clamp(0, 100)
        : 100;

    final isCritical = totalCritical > 0;
    final isWarning = !isCritical && (totalHigh > 0 || totalOpen > 0 || totalNotWorking > 0);

    final statusColor = isCritical
        ? AppColors.error
        : isWarning
            ? AppColors.warning
            : AppColors.success;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Coverage Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${rootZones.length} Assigned Zones • $totalDevices Total Devices',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                      '$operationalRate% Online',
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

          // 4-Tile Stat Grid (Total, Online, Faulty, Defects)
          Row(
            children: [
              _StatTile(
                label: 'TOTAL',
                value: '$totalDevices',
                color: AppColors.textPrimary,
                bg: AppColors.cardAlt,
                icon: Icons.inventory_2_outlined,
              ),
              const SizedBox(width: 8),
              _StatTile(
                label: 'ONLINE',
                value: '$totalWorking',
                color: AppColors.success,
                bg: AppColors.success.withValues(alpha: 0.08),
                icon: Icons.check_circle_outline_rounded,
              ),
              const SizedBox(width: 8),
              _StatTile(
                label: 'FAULTY',
                value: '$totalNotWorking',
                color: totalNotWorking > 0 ? AppColors.error : AppColors.textSecondary,
                bg: totalNotWorking > 0
                    ? AppColors.error.withValues(alpha: 0.08)
                    : AppColors.cardAlt,
                icon: Icons.highlight_off_rounded,
              ),
              const SizedBox(width: 8),
              _StatTile(
                label: 'DEFECTS',
                value: '$totalOpen',
                color: totalOpen > 0 ? AppColors.warning : AppColors.textSecondary,
                bg: totalOpen > 0
                    ? AppColors.warning.withValues(alpha: 0.08)
                    : AppColors.cardAlt,
                icon: Icons.build_circle_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZoneHero(BuildContext context, TechnicianZoneNode zone) {
    final healthStatus = zone.healthStatus;
    final statusColor = healthStatus == ZoneHealthStatus.critical
        ? AppColors.error
        : healthStatus == ZoneHealthStatus.warning
            ? AppColors.warning
            : AppColors.success;

    final operationalRate = zone.operationalPercentage;
    final faultyCount = zone.unresolvedUnitsCount > 0 ? zone.unresolvedUnitsCount : zone.notWorkingCount;

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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
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
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      zone.clientName != null
                          ? '${zone.clientName} • Depth Level ${zone.depth}'
                          : 'Depth Level ${zone.depth} • Status: ${zone.status.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$operationalRate% Health',
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

          // 4-Tile Stat Grid (Total, Online, Faulty, Defects)
          Row(
            children: [
              _StatTile(
                label: 'TOTAL',
                value: '${zone.deviceCount}',
                color: AppColors.textPrimary,
                bg: AppColors.cardAlt,
                icon: Icons.inventory_2_outlined,
              ),
              const SizedBox(width: 8),
              _StatTile(
                label: 'ONLINE',
                value: '${zone.workingCount}',
                color: AppColors.success,
                bg: AppColors.success.withValues(alpha: 0.08),
                icon: Icons.check_circle_outline_rounded,
              ),
              const SizedBox(width: 8),
              _StatTile(
                label: 'FAULTY',
                value: '$faultyCount',
                color: faultyCount > 0 ? AppColors.error : AppColors.textSecondary,
                bg: faultyCount > 0
                    ? AppColors.error.withValues(alpha: 0.08)
                    : AppColors.cardAlt,
                icon: Icons.highlight_off_rounded,
              ),
              const SizedBox(width: 8),
              _StatTile(
                label: 'DEFECTS',
                value: '${zone.openIssuesCount}',
                color: zone.openIssuesCount > 0 ? AppColors.warning : AppColors.textSecondary,
                bg: zone.openIssuesCount > 0
                    ? AppColors.warning.withValues(alpha: 0.08)
                    : AppColors.cardAlt,
                icon: Icons.build_circle_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;
  final IconData icon;

  const _StatTile({
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
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: color.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
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

