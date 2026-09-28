import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../devices/models/device_model.dart';
import '../../../devices/views/helpers/hardware_icon_helper.dart';
import '../../../issues/models/issue_model.dart';
import '../../../issues/views/issue_detail_sheet.dart';
import '../../models/technician_zone_map_data.dart';
import '../../models/technician_zone_tree_state.dart';
import '../../models/zone_status_row.dart';
import '../../viewmodels/technician_view_mode_provider.dart';
import '../../viewmodels/technician_zone_tree_viewmodel.dart';
import 'technician_device_block.dart';
import 'technician_device_detail_sheet.dart';

/// Bottom sheet opened when tapping a zone row in the Zone Status table.
///
/// Behavior:
/// - If ONLY devices are present (no subzones): displays only the devices directly.
/// - If child zones (subzones) are present: displays them with zone name headings and visual
///   hardware blocks just like in the Zone Map.
class TechnicianZoneStatusSheet extends ConsumerWidget {
  final ZoneStatusRow row;
  final TechnicianTopLevelZoneItem? zoneSection;

  const TechnicianZoneStatusSheet({
    super.key,
    required this.row,
    this.zoneSection,
  });

  static Future<void> show(
    BuildContext context, {
    required ZoneStatusRow row,
    TechnicianTopLevelZoneItem? zoneSection,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TechnicianZoneStatusSheet(
        row: row,
        zoneSection: zoneSection,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeStateAsync = ref.watch(technicianZoneTreeViewModelProvider);
    final treeState = treeStateAsync.value;

    final sec = zoneSection ??
        treeState?.zoneSections
            .where((s) => s.zone.id == row.id)
            .firstOrNull;

    final devices = sec?.devices ?? const <DeviceModel>[];
    final hasIssues = row.isAlerted || (sec?.hasIssues ?? false);

    final totalHardware = sec?.totalDevices ?? row.hardwareCount;
    final totalOnline = sec?.onlineDevices ?? row.onlineCount;
    final totalOffline = sec?.offlineDevices ?? row.offlineCount;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: hasIssues
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 12, 12),
            child: Row(
              children: [
                // Left accent bar
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: hasIssues ? AppColors.error : AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),

                // Title & stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.displayName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 15,
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
                            '$totalHardware products',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '● $totalOnline',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                          if (totalOffline > 0)
                            Text(
                              '○ $totalOffline',
                              style: TextStyle(
                                fontSize: 11,
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

                // Explore in Zone Map Action Button
                IconButton(
                  tooltip: 'View in Zone Map',
                  icon: const Icon(Icons.account_tree_rounded, size: 20),
                  color: AppColors.primary,
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref
                        .read(technicianViewModeProvider.notifier)
                        .setMode(TechnicianViewMode.spatialExplorer);
                    ref
                        .read(technicianZoneTreeViewModelProvider.notifier)
                        .navigateToZone(
                          row.id,
                          zoneName: row.name,
                          imageUrl: row.imageUrl,
                          fromZoneStatus: true,
                        );
                  },
                ),

                // Close Button
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.textSecondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.border),

          // Body Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: _buildBody(context, sec, devices),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TechnicianTopLevelZoneItem? sec,
    List<DeviceModel> devices,
  ) {
    if (devices.isNotEmpty) {
      return _buildDevicesOnlyView(context, sec, devices);
    }

    // Empty zone (no devices)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 36,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 8),
            Text(
              'No products deployed in this zone',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds clean devices-only view when no child zones exist.
  Widget _buildDevicesOnlyView(
    BuildContext context,
    TechnicianTopLevelZoneItem? sec,
    List<DeviceModel> devices,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Quick visual blocks overview
        Text(
          'PRODUCTS OVERVIEW (${devices.length})',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: devices.map((d) {
            final isDefective = sec?.isDeviceDefective(d) ?? false;
            final activeIssue = sec?.issues
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

        const SizedBox(height: 16),
        Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 12),

        // Itemized Device List
        ...devices.map((device) {
          final isDefective = sec?.isDeviceDefective(device) ?? false;
          final activeIssue = sec?.issues
              .cast<IssueModel?>()
              .firstWhere(
                (i) =>
                    i?.deviceId == device.id &&
                    i?.status != IssueStatus.resolved &&
                    i?.status != IssueStatus.closed,
                orElse: () => null,
              );

          final statusColor = isDefective
              ? AppColors.error
              : (device.status == DeviceStatus.underMaintenance
                  ? AppColors.warning
                  : AppColors.success);

          final statusText = isDefective
              ? (activeIssue?.title ?? 'Defective')
              : (device.status == DeviceStatus.underMaintenance
                  ? 'Maintenance'
                  : 'Active');

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDefective
                    ? AppColors.error.withValues(alpha: 0.3)
                    : AppColors.border,
              ),
            ),
            child: Material(
              color: AppColors.cardAlt,
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  HardwareIconHelper.getIcon(device.hardwareTypeName),
                  size: 16,
                  color: statusColor,
                ),
              ),
              title: Text(
                device.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${device.serialNumber.isNotEmpty ? '${device.serialNumber} • ' : ''}${device.hardwareTypeName}',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              onTap: () {
                if (isDefective && activeIssue != null) {
                  IssueDetailSheet.show(context, activeIssue);
                } else {
                  TechnicianDeviceDetailSheet.show(context, device: device);
                }
              },
            ),
          ),
        );
      }),
    ],
  );
  }
}
