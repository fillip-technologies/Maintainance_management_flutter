import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../issues/models/issue_model.dart';
import '../../../issues/views/issue_detail_sheet.dart';
import '../../models/technician_zone_map_data.dart';
import 'technician_device_block.dart';
import 'technician_health_ring.dart';

/// Replicates TopLevelZoneCard from the web UI (http://localhost:5173/clientadmin/cameras).
/// Big Card for top-level facility zone showcasing:
/// - Colored left vertical accent bar (Red if issues exist, Blue/Emerald if nominal).
/// - Uppercase bold zone name and hardware telemetry stats.
/// - Circular health ring.
/// - Collapsible camera grid containing all descendant cameras.
/// - Status footer (Faulty callout + Alerts button or All Cameras Working banner).
class TechnicianTopLevelZoneCard extends StatefulWidget {
  final TechnicianTopLevelZoneItem zoneItem;
  final VoidCallback? onAlertTap;

  const TechnicianTopLevelZoneCard({
    super.key,
    required this.zoneItem,
    this.onAlertTap,
  });

  @override
  State<TechnicianTopLevelZoneCard> createState() =>
      _TechnicianTopLevelZoneCardState();
}

class _TechnicianTopLevelZoneCardState
    extends State<TechnicianTopLevelZoneCard> {
  late bool _isCollapsed;

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.zoneItem.isCollapsed;
  }

  @override
  void didUpdateWidget(covariant TechnicianTopLevelZoneCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zoneItem.isCollapsed != widget.zoneItem.isCollapsed) {
      _isCollapsed = widget.zoneItem.isCollapsed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.zoneItem;
    final hasIssues = item.hasIssues;
    final total = item.totalDevices;
    final online = item.onlineDevices;
    final offline = item.offlineDevices;
    final cameras = item.devices;
    final hasCameras = cameras.isNotEmpty;
    final offlineCams = item.offlineDeviceList;

    final borderColor = hasIssues
        ? AppColors.error.withValues(alpha: 0.5)
        : AppColors.border;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: hasIssues ? 1.5 : 1.0),
        boxShadow: [
          if (hasIssues)
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 3),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: hasCameras
                  ? () => setState(() => _isCollapsed = !_isCollapsed)
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: hasIssues
                      ? AppColors.error.withValues(alpha: 0.05)
                      : AppColors.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: hasIssues
                          ? AppColors.error.withValues(alpha: 0.2)
                          : AppColors.border.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Left vertical accent bar
                    Container(
                      width: 4,
                      height: 38,
                      decoration: BoxDecoration(
                        color: hasIssues ? AppColors.error : AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Expand / Collapse Chevron
                    if (hasCameras)
                      Icon(
                        _isCollapsed
                            ? Icons.chevron_right_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    const SizedBox(width: 4),

                    // Zone Name & Stats
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.zone.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: hasIssues
                                  ? AppColors.error
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              Text(
                                '$total ${total == 1 ? 'product' : 'products'}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '● $online',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                              if (offline > 0)
                                Text(
                                  '○ $offline',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.error,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Circular Health Ring
                    TechnicianHealthRing(
                      percentage: item.healthPercentage,
                      size: 34,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body (Collapsible) ───────────────────────────────────────────────
          if (!_isCollapsed) ...[
            if (hasCameras) ...[
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grid of camera blocks
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: cameras.map((d) {
                        final isDefective = item.isDeviceDefective(d);
                        final activeIssue = item.issues
                            .cast<IssueModel?>()
                            .firstWhere(
                              (i) =>
                                  i?.deviceId == d.id &&
                                  i?.status != IssueStatus.resolved &&
                                  i?.status != IssueStatus.closed,
                              orElse: () => null,
                            );
                        return TechnicianDeviceBlock(
                          device: d,
                          isDefective: isDefective,
                          activeIssue: activeIssue,
                        );
                      }).toList(),
                    ),

                    // Offline camera list summary
                    if (offlineCams.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 12,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${offlineCams.length} offline: ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              offlineCams
                                  .take(5)
                                  .map((c) => c.code.isNotEmpty ? c.code : c.name)
                                  .join(', ') +
                                  (offlineCams.length > 5
                                      ? ' +${offlineCams.length - 5}'
                                      : ''),
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                color: AppColors.error.withValues(alpha: 0.8),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // ── Status Footer ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: hasIssues
                      ? AppColors.error.withValues(alpha: 0.08)
                      : AppColors.success.withValues(alpha: 0.06),
                  border: Border(
                    top: BorderSide(
                      color: hasIssues
                          ? AppColors.error.withValues(alpha: 0.2)
                          : AppColors.success.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (hasIssues) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 13,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$offline Faulty',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          if (widget.onAlertTap != null) {
                            widget.onAlertTap!();
                            return;
                          }
                          // Open the first active defect ticket
                          final firstIssue = item.issues.firstOrNull;
                          if (firstIssue != null) {
                            IssueDetailSheet.show(context, firstIssue);
                          }
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notifications_active_outlined,
                                size: 10,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Alerts',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 13,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'All Cameras Working',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No equipment registered in this zone',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ] else ...[
            // ── Collapsed Label ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                '$total cameras hidden — click to expand',
                style: TextStyle(
                  fontSize: 10.5,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
