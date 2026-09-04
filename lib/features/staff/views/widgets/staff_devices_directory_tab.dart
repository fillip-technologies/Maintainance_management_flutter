import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../devices/devices.dart';

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
  DeviceStatus? _filterStatus = DeviceStatus.active;
  bool _isGroupedView = true;
  final Set<String> _expandedGroups = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _filterStatus = DeviceStatus.active;
      _expandedGroups.clear();
    });
  }

  void _toggleGroup(String groupName) {
    setState(() {
      if (_expandedGroups.contains(groupName)) {
        _expandedGroups.remove(groupName);
      } else {
        _expandedGroups.add(groupName);
      }
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
    final retiredCount = widget.devices.where((d) => d.status == DeviceStatus.retired).length;

    var list = widget.devices;

    if (_filterStatus != null) {
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
    final hasActiveFilter = _searchQuery.isNotEmpty || _filterStatus != DeviceStatus.active;
    final isSearching = _searchQuery.trim().isNotEmpty;

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
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search hardware by name, type, or zone...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.icon),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18, color: AppColors.icon),
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
                        : (l10n?.viewGrouped ?? 'Grouped View'),
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
                              _isGroupedView ? Icons.category_outlined : Icons.list_alt_rounded,
                              size: 18,
                              color: _isGroupedView ? AppColors.primary : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isGroupedView
                                  ? (l10n?.viewGrouped ?? 'Grouped')
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
                    const SizedBox(width: 6),
                    AppFilterChip(
                      label: l10n?.deviceStatusRetired ?? 'Removed',
                      badgeText: retiredCount > 0 ? '$retiredCount' : null,
                      isSelected: _filterStatus == DeviceStatus.retired,
                      activeColor: AppColors.neutral,
                      onTap: () => setState(() => _filterStatus = DeviceStatus.retired),
                    ),
                  ],
                ),
              ),
              if (_isGroupedView && list.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      groups.length == 1
                          ? (l10n?.singleCategory ?? '1 Category')
                          : (l10n?.categoriesCount(groups.length) ?? '${groups.length} Categories'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (_expandedGroups.length == groups.length) {
                            _expandedGroups.clear();
                          } else {
                            _expandedGroups.addAll(groups.map((g) => g.hardwareTypeName));
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          _expandedGroups.length == groups.length
                              ? (l10n?.collapseAll ?? 'Collapse All')
                              : (l10n?.expandAll ?? 'Expand All'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: widget.onRefresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 84),
              itemCount: (widget.isLoading || widget.hasError || list.isEmpty)
                  ? 1
                  : (_isGroupedView ? groups.length : list.length),
              itemBuilder: (context, index) {
                if (widget.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }
                if (widget.hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: ErrorStateView(
                      title: 'Failed to load hardware directory',
                      subtitle: 'Please check your connection and try again',
                      onRetry: widget.onRefresh,
                    ),
                  );
                }
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: EmptyStateView(
                      icon: hasActiveFilter ? Icons.search_off_rounded : Icons.devices_other_rounded,
                      title: 'No matching hardware found',
                      subtitle: hasActiveFilter
                          ? 'Try adjusting your search keywords or status filter'
                          : 'No equipment units have been registered in this zone yet',
                      actionLabel: hasActiveFilter ? 'Clear Filters' : null,
                      actionIcon: Icons.filter_alt_off_rounded,
                      onAction: hasActiveFilter ? _clearFilters : null,
                    ),
                  );
                }

                // 1. Grouped View Accordion Card
                if (_isGroupedView) {
                  final group = groups[index];
                  final isExpanded = isSearching || _expandedGroups.contains(group.hardwareTypeName);

                  return Container(
                    key: ValueKey('group_${group.hardwareTypeName}'),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isExpanded ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Group Accordion Header
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _toggleGroup(group.hardwareTypeName),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBg,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      HardwareIconHelper.getIcon(group.hardwareTypeName),
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                group.hardwareTypeName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: AppColors.textPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.background,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: AppColors.border),
                                              ),
                                              child: Text(
                                                group.totalCount == 1
                                                    ? (l10n?.singleUnitCount ?? '1 Unit')
                                                    : (l10n?.unitsCount(group.totalCount) ?? '${group.totalCount} Units'),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        // Status mini badges
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            if (group.activeCount > 0)
                                              _buildMiniBadge(
                                                label: '${group.activeCount} ${l10n?.deviceStatusActive ?? "Active"}',
                                                bg: AppColors.successLight,
                                                textCol: AppColors.successText,
                                              ),
                                            if (group.faultyCount > 0)
                                              _buildMiniBadge(
                                                label: '${group.faultyCount} ${l10n?.deviceStatusFaulty ?? "Faulty"}',
                                                bg: AppColors.errorLight,
                                                textCol: AppColors.errorText,
                                              ),
                                            if (group.maintenanceCount > 0)
                                              _buildMiniBadge(
                                                label: '${group.maintenanceCount} ${l10n?.deviceStatusMaintenance ?? "Maint"}',
                                                bg: AppColors.warningLight,
                                                textCol: AppColors.warningText,
                                              ),
                                            if (group.inStockCount > 0)
                                              _buildMiniBadge(
                                                label: '${group.inStockCount} ${l10n?.deviceStatusProvisioned ?? "In Stock"}',
                                                bg: AppColors.infoLight,
                                                textCol: AppColors.infoText,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.icon,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Expanded Unit List inside Group
                        if (isExpanded) ...[
                          const Divider(height: 1, color: AppColors.divider),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: group.devices.length,
                            separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.divider, indent: 48),
                            itemBuilder: (context, devIdx) {
                              final device = group.devices[devIdx];
                              return Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                  dense: true,
                                  leading: const Icon(Icons.subdirectory_arrow_right_rounded, size: 18, color: AppColors.icon),
                                  title: Text(
                                    device.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                                  ),
                                  subtitle: Text(
                                    '${device.zoneName} • ${device.serialNumber.isNotEmpty ? device.serialNumber : device.location}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                }

                // 2. Flat List View
                final device = list[index];
                return Container(
                  key: ValueKey(device.id),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          HardwareIconHelper.getIcon(device.hardwareTypeName),
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        device.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        '${device.hardwareTypeName} • ${device.zoneName} • ${device.location.isNotEmpty ? device.location : "Active"}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBadge({required String label, required Color bg, required Color textCol}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textCol),
      ),
    );
  }
}
