import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../devices/models/device_group_model.dart';
import '../../../devices/models/device_model.dart';
import '../../../devices/views/helpers/equipment_graphic.dart';

/// Modal bottom sheet displaying individual units in an equipment category.
/// Allows filtering by status, searching by serial number or location,
/// and one-tap defect raising for staff members.
class CategoryDevicesSheet extends StatefulWidget {
  final DeviceGroup group;
  final void Function(DeviceModel device) onOpenRaiseIssue;

  const CategoryDevicesSheet({
    super.key,
    required this.group,
    required this.onOpenRaiseIssue,
  });

  static Future<void> show(
    BuildContext context, {
    required DeviceGroup group,
    required void Function(DeviceModel device) onOpenRaiseIssue,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryDevicesSheet(
        group: group,
        onOpenRaiseIssue: onOpenRaiseIssue,
      ),
    );
  }

  @override
  State<CategoryDevicesSheet> createState() => _CategoryDevicesSheetState();
}

class _CategoryDevicesSheetState extends State<CategoryDevicesSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DeviceStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLink = EquipmentVisualType.isLink(widget.group.hardwareTypeName);
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    final sampleImageUrl = widget.group.devices
        .where((d) => d.imageUrl != null && d.imageUrl!.trim().isNotEmpty)
        .firstOrNull
        ?.imageUrl;

    var filtered = widget.group.devices;
    if (_statusFilter != null) {
      filtered = filtered.where((d) => d.status == _statusFilter).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((d) {
        return d.name.toLowerCase().contains(q) ||
            d.serialNumber.toLowerCase().contains(q) ||
            d.zoneName.toLowerCase().contains(q) ||
            d.location.toLowerCase().contains(q);
      }).toList();
    }

    final onlineLabel = isLink
        ? (l10n?.statusActive ?? 'Active')
        : (l10n?.statusOnline ?? 'Online');
    final offlineLabel = isLink
        ? (l10n?.statusDown ?? 'Down')
        : (l10n?.statusOffline ?? 'Offline');
    final maintenanceLabel = l10n?.statusMaintenance ?? 'Maintenance';

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlayScrimLight,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                EquipmentGraphic(
                  hardwareTypeName: widget.group.hardwareTypeName,
                  imageUrl: sampleImageUrl,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.group.hardwareTypeName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n?.unitsCount(widget.group.totalCount) ??
                            '${widget.group.totalCount} Units Total',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.icon),
                  onPressed: () => Navigator.pop(context),
                  tooltip: l10n?.close ?? 'Close',
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Filter chips row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  AppFilterChip(
                    label: l10n?.allHardware ?? 'All',
                    badgeText: '${widget.group.totalCount}',
                    isSelected: _statusFilter == null,
                    onTap: () => setState(() => _statusFilter = null),
                  ),
                  const SizedBox(width: 6),
                  AppFilterChip(
                    label: onlineLabel,
                    badgeText: '${widget.group.activeCount}',
                    isSelected: _statusFilter == DeviceStatus.active,
                    activeColor: AppColors.success,
                    onTap: () => setState(() => _statusFilter = DeviceStatus.active),
                  ),
                  const SizedBox(width: 6),
                  AppFilterChip(
                    label: offlineLabel,
                    badgeText: '${widget.group.faultyCount}',
                    isSelected: _statusFilter == DeviceStatus.faulty,
                    activeColor: AppColors.error,
                    onTap: () => setState(() => _statusFilter = DeviceStatus.faulty),
                  ),
                  const SizedBox(width: 6),
                  AppFilterChip(
                    label: maintenanceLabel,
                    badgeText: '${widget.group.maintenanceCount}',
                    isSelected: _statusFilter == DeviceStatus.underMaintenance,
                    activeColor: AppColors.warning,
                    onTap: () => setState(() => _statusFilter = DeviceStatus.underMaintenance),
                  ),
                ],
              ),
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: l10n?.searchWithinCategory ??
                    'Search by serial number or location...',
                prefixIcon: Icon(Icons.search, size: 18, color: AppColors.icon),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 16, color: AppColors.icon),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          const SizedBox(height: 8),

          // Units List
          Flexible(
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: EmptyStateView(
                      icon: Icons.search_off_rounded,
                      title: l10n?.noEquipmentInCategory ??
                          'No equipment found in this category',
                      subtitle: _searchQuery.isNotEmpty
                          ? (l10n?.staffTryAdjustingFilter ??
                              'Try adjusting your search query or filter')
                          : (l10n?.staffNoHardwareRegistered ?? 'No equipment registered here yet'),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final device = filtered[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              if (device.status == DeviceStatus.retired) {
                                AppSnackbar.warning(
                                  l10n?.errRetiredUnitSelected ??
                                      'Cannot raise defects on retired equipment',
                                );
                                return;
                              }
                              Navigator.pop(context);
                              widget.onOpenRaiseIssue(device);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: EquipmentGraphic(
                                        hardwareTypeName: device.hardwareTypeName,
                                        imageUrl: device.imageUrl,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          device.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13.5,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${device.zoneName} • ${device.serialNumber.isNotEmpty ? device.serialNumber : device.location}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      StatusBadge.device(device.status),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.report_problem_outlined,
                                            size: 13,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            l10n?.btnRaiseIssue ?? 'Report',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
