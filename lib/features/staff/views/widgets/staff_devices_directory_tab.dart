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
  DeviceStatus? _filterStatus;

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

    final hasActiveFilter = _searchQuery.isNotEmpty || _filterStatus != null;

    return Column(
      children: [
        // Search & Filter Box
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
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
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    AppFilterChip(
                      label: 'All Hardware',
                      isSelected: _filterStatus == null,
                      onTap: () => setState(() => _filterStatus = null),
                    ),
                    const SizedBox(width: 6),
                    AppFilterChip(
                      label: l10n?.deviceStatusActive ?? 'Active',
                      isSelected: _filterStatus == DeviceStatus.active,
                      activeColor: AppColors.success,
                      onTap: () => setState(() => _filterStatus = DeviceStatus.active),
                    ),
                    const SizedBox(width: 6),
                    AppFilterChip(
                      label: l10n?.deviceStatusMaintenance ?? 'Maintenance',
                      isSelected: _filterStatus == DeviceStatus.underMaintenance,
                      activeColor: AppColors.warning,
                      onTap: () => setState(() => _filterStatus = DeviceStatus.underMaintenance),
                    ),
                    const SizedBox(width: 6),
                    AppFilterChip(
                      label: l10n?.deviceStatusFaulty ?? 'Faulty',
                      isSelected: _filterStatus == DeviceStatus.faulty,
                      activeColor: AppColors.error,
                      onTap: () => setState(() => _filterStatus = DeviceStatus.faulty),
                    ),
                    const SizedBox(width: 6),
                    AppFilterChip(
                      label: l10n?.deviceStatusProvisioned ?? 'In Stock',
                      isSelected: _filterStatus == DeviceStatus.provisioned,
                      activeColor: AppColors.info,
                      onTap: () => setState(() => _filterStatus = DeviceStatus.provisioned),
                    ),
                    const SizedBox(width: 6),
                    AppFilterChip(
                      label: l10n?.deviceStatusRetired ?? 'Removed',
                      isSelected: _filterStatus == DeviceStatus.retired,
                      activeColor: AppColors.neutral,
                      onTap: () => setState(() => _filterStatus = DeviceStatus.retired),
                    ),
                  ],
                ),
              ),
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
              padding: const EdgeInsets.all(16),
              itemCount: (widget.isLoading || widget.hasError || list.isEmpty) ? 1 : list.length,
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
                final device = list[index];
                return Container(
                  key: ValueKey(device.id),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
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
                        AppSnackbar.warning('Cannot raise a defect on a retired or decommissioned unit.');
                        return;
                      }
                      widget.onOpenRaiseIssue(device);
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
