import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../issues/models/issue_model.dart';
import '../../models/technician_zone_map_data.dart';
import 'technician_device_block.dart';
import 'technician_subzone_card.dart';

/// Replicates TopLevelZoneCard from the web UI (http://localhost:5173/clientadmin/products).
/// Big Card for top-level facility zone with:
/// - Colored left vertical accent bar (Red if issues exist, Blue/Green if nominal).
/// - Bold uppercase zone name and summary stats.
/// - Expand/collapse toggle.
/// - Direct device blocks + 2-column grid of TechnicianSubzoneCards.
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
    final subzones = item.subzones;
    final directDevices = item.directDevices;
    final hasDirect = directDevices.isNotEmpty;
    final hasSubzones = subzones.isNotEmpty;

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
              blurRadius: 12,
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
          // Header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (hasDirect || hasSubzones)
                  ? () => setState(() => _isCollapsed = !_isCollapsed)
                  : null,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasIssues
                      ? AppColors.error.withValues(alpha: 0.04)
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
                    const SizedBox(width: 10),

                    // Zone Name & Stats
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.zone.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 13.5,
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
                                '$total products',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (hasSubzones)
                                Text(
                                  '${subzones.length} subzone${subzones.length != 1 ? 's' : ''}',
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

                    // Expand / Collapse Chevron
                    if (hasDirect || hasSubzones)
                      Icon(
                        _isCollapsed
                            ? Icons.chevron_right_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: AppColors.textSecondary,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Body (Collapsible)
          if (!_isCollapsed) ...[
            // Direct equipment (if any)
            if (hasDirect) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DIRECT PRODUCTS',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: directDevices.map((d) {
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
                  ],
                ),
              ),
              if (hasSubzones)
                Divider(height: 1, color: AppColors.divider),
            ],

            // Nested subzones (2-column grid)
            if (hasSubzones)
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    for (var i = 0; i < subzones.length; i += 2) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TechnicianSubzoneCard(
                              subzoneItem: subzones[i],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (i + 1 < subzones.length)
                            Expanded(
                              child: TechnicianSubzoneCard(
                                subzoneItem: subzones[i + 1],
                              ),
                            )
                          else
                            const Expanded(child: SizedBox.shrink()),
                        ],
                      ),
                      if (i + 2 < subzones.length) const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),

            if (!hasDirect && !hasSubzones)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No equipment registered in this zone',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
