import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../issues/models/issue_model.dart';
import '../../models/technician_zone_map_data.dart';
import 'technician_device_block.dart';

/// Replicates NestedZoneCard from the web UI (http://localhost:5173/clientadmin/products).
/// Nested subzone card with subzone header, visual device blocks, offline callout, and status footer.
class TechnicianSubzoneCard extends StatelessWidget {
  final TechnicianSubzoneItem subzoneItem;
  final VoidCallback? onAlertTap;

  const TechnicianSubzoneCard({
    super.key,
    required this.subzoneItem,
    this.onAlertTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasIssues = subzoneItem.hasIssues;
    final devices = subzoneItem.devices;
    final total = subzoneItem.totalDevices;
    final online = subzoneItem.onlineDevices;
    final offline = subzoneItem.offlineDevices;

    final borderColor = hasIssues
        ? AppColors.error.withValues(alpha: 0.45)
        : AppColors.border.withValues(alpha: 0.6);

    final cardBg = AppColors.surface;
    final defectiveDevices = devices.where(subzoneItem.isDeviceDefective).toList();

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: hasIssues ? 1.4 : 1.0),
        boxShadow: [
          if (hasIssues)
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sub-card header
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: hasIssues
                        ? AppColors.error.withValues(alpha: 0.12)
                        : AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    hasIssues ? Icons.error_outline_rounded : Icons.videocam_rounded,
                    size: 13,
                    color: hasIssues ? AppColors.error : AppColors.success,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    subzoneItem.zone.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$online/$total',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Device blocks grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: devices.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No equipment',
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  )
                : Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: devices.map((d) {
                      final isDefective = subzoneItem.isDeviceDefective(d);
                      final activeIssue = subzoneItem.issues.cast<IssueModel?>().firstWhere(
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
          ),

          // Offline names callout if any
          if (defectiveDevices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 11, color: AppColors.error),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${defectiveDevices.length} offline: ${defectiveDevices.take(3).map((d) => d.code.isNotEmpty ? d.code : d.name).join(", ")}${defectiveDevices.length > 3 ? " +${defectiveDevices.length - 3}" : ""}',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 4),

          // Status footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: hasIssues
                  ? AppColors.error.withValues(alpha: 0.08)
                  : AppColors.success.withValues(alpha: 0.08),
              border: Border(
                top: BorderSide(
                  color: hasIssues
                      ? AppColors.error.withValues(alpha: 0.2)
                      : AppColors.success.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasIssues ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                  size: 11,
                  color: hasIssues ? AppColors.error : AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  hasIssues ? '$offline Defective / Issues' : 'All Active',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: hasIssues ? AppColors.error : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
