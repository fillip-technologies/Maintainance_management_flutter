import 'package:flutter/material.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../devices/devices.dart';
import '../../../../../l10n/app_localizations.dart';

class RaiseBulkDeviceSelector extends StatelessWidget {
  final List<DeviceModel> allDevices;
  final List<DeviceModel> filteredDevices;
  final List<String> allHardwareTypes;
  final Set<String> selectedDeviceIds;
  final String? selectedHardwareType;
  final Set<String> collapsedGroupNames;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String?> onHardwareTypeSelected;
  final VoidCallback? onSelectAll;
  final VoidCallback? onClearSelection;
  final ValueChanged<DeviceModel> onToggleDevice;
  final ValueChanged<DeviceGroup> onToggleGroupSelection;
  final ValueChanged<String> onToggleGroupCollapse;
  final ValueChanged<DeviceGroup> onIncreaseGroupQuantity;
  final ValueChanged<DeviceGroup> onDecreaseGroupQuantity;

  const RaiseBulkDeviceSelector({
    super.key,
    required this.allDevices,
    required this.filteredDevices,
    required this.allHardwareTypes,
    required this.selectedDeviceIds,
    required this.selectedHardwareType,
    required this.collapsedGroupNames,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onHardwareTypeSelected,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onToggleDevice,
    required this.onToggleGroupSelection,
    required this.onToggleGroupCollapse,
    required this.onIncreaseGroupQuantity,
    required this.onDecreaseGroupQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final groups = DeviceGroup.fromDevices(filteredDevices);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Equipment Selection Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n?.selectEquipmentUnits(selectedDeviceIds.length) ??
                  'Select Equipment (${selectedDeviceIds.length}/50)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: allDevices.isEmpty ? null : onSelectAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n?.selectAll ?? 'Select All',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: selectedDeviceIds.isEmpty ? null : onClearSelection,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: Text(
                    l10n?.clearSelection ?? 'Clear',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Search Filter
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: l10n?.searchUnitsHint ?? 'Search unit by name, serial number or type...',
            hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
            prefixIcon: Icon(Icons.search, size: 20, color: AppColors.icon),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: onClearSearch,
                  )
                : null,
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
          ),
        ),

        // Hardware Type Horizontal Filter Chips
        if (allHardwareTypes.length > 1) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTypeChip(
                  label: l10n?.allTypes ?? 'All Types',
                  count: allDevices.length,
                  isSelected: selectedHardwareType == null,
                  onTap: () => onHardwareTypeSelected(null),
                ),
                ...allHardwareTypes.map((type) {
                  final typeCount = allDevices.where((d) => d.hardwareTypeName.trim() == type).length;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _buildTypeChip(
                      label: type,
                      count: typeCount,
                      isSelected: selectedHardwareType == type,
                      onTap: () => onHardwareTypeSelected(type),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),

        // Devices Scrollable List Grouped by Type
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: filteredDevices.isEmpty
              ? Center(
                  child: Text(
                    l10n?.noMatchingUnits ?? 'No matching equipment units found',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemCount: groups.length,
                  itemBuilder: (context, groupIdx) {
                    final group = groups[groupIdx];
                    final nonRetired = group.devices.where((d) => d.status != DeviceStatus.retired).toList();
                    final selectedInGroup = group.devices.where((d) => selectedDeviceIds.contains(d.id)).length;
                    final allGroupSelected = nonRetired.isNotEmpty && nonRetired.every((d) => selectedDeviceIds.contains(d.id));
                    final isExpanded = searchQuery.isNotEmpty || !collapsedGroupNames.contains(group.hardwareTypeName);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedInGroup > 0
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : AppColors.border,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Group Header Row
                          InkWell(
                            onTap: () => onToggleGroupCollapse(group.hardwareTypeName),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    HardwareIconHelper.getIcon(group.hardwareTypeName),
                                    size: 18,
                                    color: selectedInGroup > 0 ? AppColors.primary : AppColors.icon,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            group.hardwareTypeName,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: selectedInGroup > 0
                                            ? AppColors.primary.withValues(alpha: 0.5)
                                            : AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: selectedInGroup > 0
                                              ? () => onDecreaseGroupQuantity(group)
                                              : null,
                                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                            child: Icon(
                                              Icons.remove,
                                              size: 13,
                                              color: selectedInGroup > 0 ? AppColors.textPrimary : AppColors.iconLight,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          color: AppColors.surface,
                                          child: Text(
                                            '$selectedInGroup/${nonRetired.length}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: selectedInGroup > 0 ? AppColors.primary : AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: (selectedInGroup < nonRetired.length && selectedDeviceIds.length < 50)
                                              ? () => onIncreaseGroupQuantity(group)
                                              : null,
                                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                            child: Icon(
                                              Icons.add,
                                              size: 13,
                                              color: (selectedInGroup < nonRetired.length && selectedDeviceIds.length < 50)
                                                  ? AppColors.primary
                                                  : AppColors.iconLight,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  TextButton(
                                    onPressed: nonRetired.isEmpty ? null : () => onToggleGroupSelection(group),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      foregroundColor: allGroupSelected ? AppColors.textSecondary : AppColors.primary,
                                    ),
                                    child: Text(
                                      allGroupSelected
                                          ? (l10n?.deselectGroup ?? 'Deselect')
                                          : (l10n?.selectAllInGroup ?? 'Select Group'),
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                    size: 20,
                                    color: AppColors.icon,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Units inside group
                          if (isExpanded) ...[
                            Divider(height: 1, color: AppColors.divider),
                            ...group.devices.map((device) {
                              final isSelected = selectedDeviceIds.contains(device.id);
                              final isRetired = device.status == DeviceStatus.retired;

                              return Material(
                                color: isSelected ? AppColors.primaryBg.withValues(alpha: 0.25) : AppColors.transparent,
                                child: InkWell(
                                  onTap: isRetired ? null : () => onToggleDevice(device),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: isSelected,
                                          activeColor: AppColors.primary,
                                          onChanged: isRetired ? null : (_) => onToggleDevice(device),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                device.name,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: isRetired ? AppColors.textMuted : AppColors.textPrimary,
                                                  decoration: isRetired ? TextDecoration.lineThrough : null,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                device.serialNumber.isNotEmpty
                                                    ? '${device.serialNumber} • ${device.location}'
                                                    : device.location,
                                                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        StatusBadge.device(device.status),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTypeChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBg : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.textWhite : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
