import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/hardware_icon_helper.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../data/models/device_model.dart';
import '../../../../l10n/app_localizations.dart';

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
  String _searchQuery = '';
  DeviceStatus? _filterStatus;

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

    return Column(
      children: [
        // Search & Filter Box
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surface,
          child: Column(
            children: [
              TextField(
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search hardware by name, type, or zone...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.icon),
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
                    _buildFilterChip('All Hardware', null),
                    _buildFilterChip(l10n?.deviceStatusActive ?? 'Active', DeviceStatus.active),
                    _buildFilterChip(l10n?.deviceStatusMaintenance ?? 'Maintenance', DeviceStatus.underMaintenance),
                    _buildFilterChip(l10n?.deviceStatusFaulty ?? 'Faulty', DeviceStatus.faulty),
                    _buildFilterChip(l10n?.deviceStatusProvisioned ?? 'In Stock', DeviceStatus.provisioned),
                    _buildFilterChip(l10n?.deviceStatusRetired ?? 'Removed', DeviceStatus.retired),
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
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.icon),
                          const SizedBox(height: 12),
                          const Text(
                            'Failed to load hardware directory',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: widget.onRefresh,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: Text(
                        'No matching hardware found',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }
                final device = list[index];
                return Container(
                  key: ValueKey(device.id),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
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

  Widget _buildFilterChip(String label, DeviceStatus? status) {
    final isSelected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primaryBg,
        backgroundColor: AppColors.surface,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
        onSelected: (_) => setState(() => _filterStatus = status),
      ),
    );
  }
}
