import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../devices/devices.dart';
import '../../../issues/issues.dart';
import 'staff_device_grid_card.dart';

/// Visual icon grid directory for staff equipment catalogue.
///
/// Key UX:
/// - Pure visual grid: no camera names on card face, zero text clutter.
/// - Status color-coding: Green for active, Red for issue raised / not solved.
/// - Top zone tabs when devices span multiple zones for 1-tap filtering.
/// - File-manager style multi-select with sticky bottom bulk action bar.
class StaffDevicesDirectoryTab extends StatefulWidget {
  final List<DeviceModel> devices;
  final List<IssueModel> issues;
  final bool isLoading;
  final bool hasError;
  final Future<void> Function() onRefresh;
  final void Function(DeviceModel device) onOpenRaiseIssue;
  final void Function(List<DeviceModel> devices)? onOpenRaiseBulkIssue;

  const StaffDevicesDirectoryTab({
    super.key,
    required this.devices,
    this.issues = const [],
    required this.isLoading,
    required this.hasError,
    required this.onRefresh,
    required this.onOpenRaiseIssue,
    this.onOpenRaiseBulkIssue,
  });

  @override
  State<StaffDevicesDirectoryTab> createState() => _StaffDevicesDirectoryTabState();
}

class _StaffDevicesDirectoryTabState extends State<StaffDevicesDirectoryTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedZoneId;
  bool? _filterProblemsOnly; // null = all, false = active only, true = problems only
  Set<String> _selectedDeviceIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedZoneId = null;
      _filterProblemsOnly = null;
    });
  }

  void _toggleDeviceSelection(String deviceId) {
    setState(() {
      if (_selectedDeviceIds.contains(deviceId)) {
        _selectedDeviceIds.remove(deviceId);
      } else {
        _selectedDeviceIds.add(deviceId);
      }
    });
  }

  void _selectAll(List<DeviceModel> currentVisibleList) {
    setState(() {
      _selectedDeviceIds = currentVisibleList.map((d) => d.id).toSet();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedDeviceIds.clear();
    });
  }

  bool _isDeviceProblem(DeviceModel d, Set<String> unresolvedIssueDeviceIds) {
    return unresolvedIssueDeviceIds.contains(d.id) ||
        d.status == DeviceStatus.faulty ||
        d.status == DeviceStatus.underMaintenance;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Identify units that currently have an unresolved issue
    final unresolvedIssueDeviceIds = widget.issues
        .where((i) => i.status != IssueStatus.resolved && i.status != IssueStatus.closed)
        .map((i) => i.deviceId)
        .where((id) => id.isNotEmpty)
        .toSet();

    // Extract unique zones present across hardware
    final Map<String, String> zonesMap = {};
    for (final d in widget.devices) {
      if (d.zoneId.isNotEmpty) {
        zonesMap[d.zoneId] = d.zoneName.isNotEmpty ? d.zoneName : 'Zone ${d.zoneId}';
      }
    }

    // Apply zone filter
    var filteredList = widget.devices;
    if (_selectedZoneId != null) {
      filteredList = filteredList.where((d) => d.zoneId == _selectedZoneId).toList();
    }

    // Calculate status counts for current zone scope
    final totalInScope = filteredList.length;
    final problemCount = filteredList.where((d) => _isDeviceProblem(d, unresolvedIssueDeviceIds)).length;
    final activeCount = filteredList.where((d) => !_isDeviceProblem(d, unresolvedIssueDeviceIds) && d.status == DeviceStatus.active).length;

    // Apply status filter
    if (_filterProblemsOnly == true) {
      filteredList = filteredList.where((d) => _isDeviceProblem(d, unresolvedIssueDeviceIds)).toList();
    } else if (_filterProblemsOnly == false) {
      filteredList = filteredList.where((d) => !_isDeviceProblem(d, unresolvedIssueDeviceIds) && d.status == DeviceStatus.active).toList();
    }

    // Apply text search
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filteredList = filteredList.where((d) {
        return d.name.toLowerCase().contains(q) ||
            d.hardwareTypeName.toLowerCase().contains(q) ||
            d.zoneName.toLowerCase().contains(q) ||
            d.location.toLowerCase().contains(q) ||
            d.serialNumber.toLowerCase().contains(q);
      }).toList();
    }

    final hasActiveFilter = _searchQuery.isNotEmpty || _selectedZoneId != null || _filterProblemsOnly != null;
    final isSelectionMode = _selectedDeviceIds.isNotEmpty;

    return Stack(
      children: [
        Column(
          children: [
            // Search & Filter Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Box
                  TextField(
                    controller: _searchController,
                    style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: l10n?.staffSearchHardware ?? 'Search hardware by type, code, or location',
                      prefixIcon: Icon(Icons.search, color: AppColors.icon, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 18, color: AppColors.icon),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),

                  // Top Zone Tabs (if more than 1 zone exists)
                  if (zonesMap.length > 1) ...[
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildZoneTab(
                            label: 'All Zones',
                            count: widget.devices.length,
                            isSelected: _selectedZoneId == null,
                            onTap: () => setState(() => _selectedZoneId = null),
                          ),
                          const SizedBox(width: 8),
                          ...zonesMap.entries.map((entry) {
                            final zoneCount = widget.devices.where((d) => d.zoneId == entry.key).length;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildZoneTab(
                                label: entry.value,
                                count: zoneCount,
                                isSelected: _selectedZoneId == entry.key,
                                onTap: () => setState(() => _selectedZoneId = entry.key),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Status Filter Chips (All, Green Active, Red Problems)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        AppFilterChip(
                          label: l10n?.allHardware ?? 'All Hardware',
                          badgeText: '$totalInScope',
                          isSelected: _filterProblemsOnly == null,
                          onTap: () => setState(() => _filterProblemsOnly = null),
                        ),
                        const SizedBox(width: 6),
                        AppFilterChip(
                          label: l10n?.deviceStatusActive ?? 'Active',
                          badgeText: '$activeCount',
                          isSelected: _filterProblemsOnly == false,
                          activeColor: AppColors.success,
                          onTap: () => setState(() => _filterProblemsOnly = false),
                        ),
                        const SizedBox(width: 6),
                        AppFilterChip(
                          label: l10n?.staffKpiProblems ?? 'Problems',
                          badgeText: problemCount > 0 ? '$problemCount' : null,
                          isSelected: _filterProblemsOnly == true,
                          activeColor: AppColors.error,
                          onTap: () => setState(() => _filterProblemsOnly = true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: AppColors.divider),

            // Visual Grid Body
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: widget.onRefresh,
                child: _buildBody(
                  context,
                  filteredList,
                  unresolvedIssueDeviceIds,
                  l10n,
                  hasActiveFilter,
                  isSelectionMode,
                ),
              ),
            ),
          ],
        ),

        // Sticky Bottom Multi-Select Bar
        if (isSelectionMode)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildSelectionBar(context, filteredList),
          ),
      ],
    );
  }

  Widget _buildZoneTab({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? AppColors.primary : AppColors.background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
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
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.textSecondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<DeviceModel> list,
    Set<String> unresolvedIssueDeviceIds,
    AppLocalizations? l10n,
    bool hasActiveFilter,
    bool isSelectionMode,
  ) {
    if (widget.isLoading) {
      return const _StaffDeviceGridSkeleton();
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

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 900 ? 6 : (screenWidth > 600 ? 4 : 3);

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: isSelectionMode ? 100 : 80,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final device = list[index];
        final isProblem = _isDeviceProblem(device, unresolvedIssueDeviceIds);
        final isSelected = _selectedDeviceIds.contains(device.id);

        return StaffDeviceGridCard(
          key: ValueKey('device_grid_${device.id}'),
          device: device,
          isProblem: isProblem,
          isSelected: isSelected,
          isSelectionMode: isSelectionMode,
          onTap: () {
            if (isSelectionMode) {
              _toggleDeviceSelection(device.id);
            } else {
              if (device.status == DeviceStatus.retired) {
                AppSnackbar.warning(
                  l10n?.errRetiredUnitSelected ?? 'Cannot raise defects on retired equipment',
                );
                return;
              }
              widget.onOpenRaiseIssue(device);
            }
          },
          onLongPress: () {
            _toggleDeviceSelection(device.id);
          },
          onToggleSelect: () {
            _toggleDeviceSelection(device.id);
          },
        );
      },
    );
  }

  Widget _buildSelectionBar(BuildContext context, List<DeviceModel> currentVisibleList) {
    final count = _selectedDeviceIds.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$count Selected',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => _selectAll(currentVisibleList),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Select All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: _clearSelection,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Clear',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.report_problem_rounded, size: 18),
                label: Text(
                  count == 1
                      ? 'Raise Defect Ticket (1 unit)'
                      : 'Raise Defect Ticket ($count units)',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final selectedDevices = widget.devices.where((d) => _selectedDeviceIds.contains(d.id)).toList();
                  if (widget.onOpenRaiseBulkIssue != null) {
                    widget.onOpenRaiseBulkIssue!(selectedDevices);
                  } else {
                    RaiseBulkIssueSheet.show(
                      context,
                      devices: widget.devices,
                      initialSelectedDevices: selectedDevices,
                    );
                  }
                  _clearSelection();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffDeviceGridSkeleton extends StatelessWidget {
  const _StaffDeviceGridSkeleton();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 900 ? 6 : (screenWidth > 600 ? 4 : 3);

    return AppShimmer(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
        ),
        itemCount: 15,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(
            child: ShimmerBox(width: 42, height: 42, borderRadius: 12),
          ),
        ),
      ),
    );
  }
}
