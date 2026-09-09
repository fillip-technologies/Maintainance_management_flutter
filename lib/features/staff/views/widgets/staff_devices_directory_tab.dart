import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../devices/devices.dart';
import 'category_devices_sheet.dart';
import 'equipment_category_card.dart';

class StaffDevicesDirectoryTab extends StatefulWidget {
  final List<DeviceModel> devices;
  final bool isLoading;
  final bool hasError;
  final Future<void> Function() onRefresh;
  final void Function(DeviceModel device) onOpenRaiseIssue;

  const StaffDevicesDirectoryTab({
    super.key,
    required this.devices,
    required this.isLoading,
    required this.hasError,
    required this.onRefresh,
    required this.onOpenRaiseIssue,
  });

  @override
  State<StaffDevicesDirectoryTab> createState() => _StaffDevicesDirectoryTabState();
}

class _StaffDevicesDirectoryTabState extends State<StaffDevicesDirectoryTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DeviceStatus? _filterStatus;
  bool _isGroupedView = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _filterStatus = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalCount = widget.devices.length;
    final activeCount = widget.devices.where((d) => d.status == DeviceStatus.active).length;
    final maintCount = widget.devices.where((d) => d.status == DeviceStatus.underMaintenance).length;
    final faultyCount = widget.devices.where((d) => d.status == DeviceStatus.faulty).length;
    final provCount = widget.devices.where((d) => d.status == DeviceStatus.provisioned).length;

    var list = widget.devices;

    if (!_isGroupedView && _filterStatus != null) {
      list = list.where((d) => d.status == _filterStatus).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((d) {
        return d.name.toLowerCase().contains(q) ||
            d.hardwareTypeName.toLowerCase().contains(q) ||
            d.zoneName.toLowerCase().contains(q) ||
            d.location.toLowerCase().contains(q);
      }).toList();
    }

    final groups = DeviceGroup.fromDevices(list);
    final hasActiveFilter = _searchQuery.isNotEmpty || (!_isGroupedView && _filterStatus != null);

    return Column(
      children: [
        // Search & Filter Box
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: l10n?.staffSearchHardware ?? 'Search hardware by name, type, or zone',
                        prefixIcon: Icon(Icons.search, color: AppColors.icon),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, size: 18, color: AppColors.icon),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: _isGroupedView
                        ? (l10n?.viewFlat ?? 'List View')
                        : (l10n?.viewGrid ?? 'Grid View'),
                    child: InkWell(
                      onTap: () => setState(() => _isGroupedView = !_isGroupedView),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: _isGroupedView ? AppColors.primaryBg : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isGroupedView ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isGroupedView ? Icons.grid_view_rounded : Icons.list_alt_rounded,
                              size: 18,
                              color: _isGroupedView ? AppColors.primary : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isGroupedView
                                  ? (l10n?.viewGrid ?? 'Grid')
                                  : (l10n?.viewFlat ?? 'List'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _isGroupedView ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (!_isGroupedView) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      AppFilterChip(
                        label: l10n?.allHardware ?? 'All Hardware',
                        badgeText: '$totalCount',
                        isSelected: _filterStatus == null,
                        onTap: () => setState(() => _filterStatus = null),
                      ),
                      const SizedBox(width: 6),
                      AppFilterChip(
                        label: l10n?.deviceStatusActive ?? 'Active',
                        badgeText: '$activeCount',
                        isSelected: _filterStatus == DeviceStatus.active,
                        activeColor: AppColors.success,
                        onTap: () => setState(() => _filterStatus = DeviceStatus.active),
                      ),
                      const SizedBox(width: 6),
                      AppFilterChip(
                        label: l10n?.deviceStatusMaintenance ?? 'Maintenance',
                        badgeText: maintCount > 0 ? '$maintCount' : null,
                        isSelected: _filterStatus == DeviceStatus.underMaintenance,
                        activeColor: AppColors.warning,
                        onTap: () => setState(() => _filterStatus = DeviceStatus.underMaintenance),
                      ),
                      const SizedBox(width: 6),
                      AppFilterChip(
                        label: l10n?.deviceStatusFaulty ?? 'Faulty',
                        badgeText: faultyCount > 0 ? '$faultyCount' : null,
                        isSelected: _filterStatus == DeviceStatus.faulty,
                        activeColor: AppColors.error,
                        onTap: () => setState(() => _filterStatus = DeviceStatus.faulty),
                      ),
                      const SizedBox(width: 6),
                      AppFilterChip(
                        label: l10n?.deviceStatusProvisioned ?? 'In Stock',
                        badgeText: provCount > 0 ? '$provCount' : null,
                        isSelected: _filterStatus == DeviceStatus.provisioned,
                        activeColor: AppColors.info,
                        onTap: () => setState(() => _filterStatus = DeviceStatus.provisioned),
                      ),
                    ],
                  ),
                ),
              ],
              if (_isGroupedView && list.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      groups.length == 1
                          ? (l10n?.singleCategory ?? '1 Category')
                          : (l10n?.categoriesCount(groups.length) ?? '${groups.length} Categories'),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    Text(
                      l10n?.unitsCount(list.length) ?? '${list.length} Units',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Divider(height: 1, color: AppColors.divider),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: widget.onRefresh,
            child: _buildBody(context, list, groups, l10n, hasActiveFilter),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<DeviceModel> list,
    List<DeviceGroup> groups,
    AppLocalizations? l10n,
    bool hasActiveFilter,
  ) {
    if (widget.isLoading) {
      return _isGroupedView
          ? const EquipmentCategoryGridSkeleton()
          : const EquipmentListSkeleton();
    }
    if (widget.hasError) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: ErrorStateView(
              title: l10n?.staffDirectoryLoadFailed ?? "Couldn't load the hardware list",
              subtitle: l10n?.staffCheckConnectionRetry ??
                  'Check your connection and tap to retry',
              onRetry: widget.onRefresh,
            ),
          ),
        ],
      );
    }
    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: EmptyStateView(
              icon: hasActiveFilter ? Icons.search_off_rounded : Icons.devices_other_rounded,
              title: l10n?.staffNoMatchingHardware ?? 'No matching hardware',
              subtitle: hasActiveFilter
                  ? (l10n?.staffTryAdjustingFilter ?? 'Try a different search or filter')
                  : (l10n?.staffNoHardwareRegistered ?? 'No equipment registered here yet'),
              actionLabel: hasActiveFilter ? (l10n?.staffClearFilters ?? 'Clear Filters') : null,
              actionIcon: Icons.filter_alt_off_rounded,
              onAction: hasActiveFilter ? _clearFilters : null,
            ),
          ),
        ],
      );
    }

    if (_isGroupedView) {
      final screenWidth = MediaQuery.of(context).size.width;
      final crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);

      return GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 14, right: 14, top: 14, bottom: 84),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 126,
        ),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return EquipmentCategoryCard(
            key: ValueKey('cat_card_${group.hardwareTypeName}'),
            group: group,
            onTap: () {
              CategoryDevicesSheet.show(
                context,
                group: group,
                onOpenRaiseIssue: widget.onOpenRaiseIssue,
              );
            },
          );
        },
      );
    }

    // Flat List View
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 84),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final device = list[index];
        return _buildFlatDeviceCard(device, l10n);
      },
    );
  }

  Widget _buildFlatDeviceCard(DeviceModel device, AppLocalizations? l10n) {
    return Container(
      key: ValueKey(device.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: EquipmentGraphic(
                hardwareTypeName: device.hardwareTypeName,
                imageUrl: device.imageUrl,
                size: 26,
              ),
            ),
          ),
          title: Text(
            device.name,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${device.hardwareTypeName} • ${device.zoneName} • ${device.location.isNotEmpty ? device.location : "Active"}',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: StatusBadge.device(device.status),
          onTap: () {
            if (device.status == DeviceStatus.retired) {
              AppSnackbar.warning(l10n?.errRetiredUnitSelected ?? 'Cannot raise defects on retired equipment');
              return;
            }
            widget.onOpenRaiseIssue(device);
          },
        ),
      ),
    );
  }
}
