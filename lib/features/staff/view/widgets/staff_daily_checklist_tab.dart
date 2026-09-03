import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../data/models/daily_log_model.dart';
import '../../../../data/models/device_model.dart';
import '../../../../l10n/app_localizations.dart';
import 'staff_device_check_card.dart';

class StaffDailyChecklistTab extends StatefulWidget {
  final List<DeviceModel> allDevices;
  final Map<String, DailyStatusLogModel> todayLogsMap;
  final bool isLoading;
  final bool hasError;
  final Set<String> submittingDeviceLogIds;
  final Set<String> editingDeviceLogIds;
  final TextEditingController Function(String deviceId) getNoteController;
  final void Function(DeviceModel device, DailyLogStatus status) onLogStatus;
  final void Function(String deviceId) onToggleEdit;
  final void Function(String deviceId) onCancelEdit;
  final Future<void> Function() onRefresh;

  const StaffDailyChecklistTab({
    super.key,
    required this.allDevices,
    required this.todayLogsMap,
    required this.isLoading,
    required this.hasError,
    required this.submittingDeviceLogIds,
    required this.editingDeviceLogIds,
    required this.getNoteController,
    required this.onLogStatus,
    required this.onToggleEdit,
    required this.onCancelEdit,
    required this.onRefresh,
  });

  @override
  State<StaffDailyChecklistTab> createState() => _StaffDailyChecklistTabState();
}

class _StaffDailyChecklistTabState extends State<StaffDailyChecklistTab> {
  int _dailyCheckFilterIndex = 0; // 0: All, 1: Pending, 2: Checked Today

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final completedCount = widget.allDevices.where((d) => widget.todayLogsMap.containsKey(d.id)).length;
    final pendingCount = widget.allDevices.length - completedCount;

    var displayedDevices = widget.allDevices;
    if (_dailyCheckFilterIndex == 1) {
      displayedDevices = widget.allDevices.where((d) => !widget.todayLogsMap.containsKey(d.id)).toList();
    } else if (_dailyCheckFilterIndex == 2) {
      displayedDevices = widget.allDevices.where((d) => widget.todayLogsMap.containsKey(d.id)).toList();
    }

    return Column(
      children: [
        // Segmented Status Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surface,
          child: Row(
            children: [
              _buildFilterChip(
                label: 'All (${widget.allDevices.length})',
                index: 0,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Pending ($pendingCount)',
                index: 1,
                badgeColor: pendingCount > 0 ? AppColors.warningText : null,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Checked Today ($completedCount)',
                index: 2,
                badgeColor: completedCount > 0 ? AppColors.successText : null,
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
              itemCount: (widget.isLoading || widget.hasError || displayedDevices.isEmpty)
                  ? 1
                  : displayedDevices.length,
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
                            'Failed to load hardware devices',
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

                if (displayedDevices.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _dailyCheckFilterIndex == 1
                                ? Icons.task_alt_rounded
                                : Icons.checklist_rounded,
                            size: 48,
                            color: AppColors.iconLight,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _dailyCheckFilterIndex == 1
                                ? 'All hardware checked for today!'
                                : (_dailyCheckFilterIndex == 2
                                    ? 'No hardware checked today yet'
                                    : 'No hardware devices found'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final device = displayedDevices[index];
                final noteController = widget.getNoteController(device.id);
                final isSubmitting = widget.submittingDeviceLogIds.contains(device.id);
                final todayLog = widget.todayLogsMap[device.id];
                final isEditing = widget.editingDeviceLogIds.contains(device.id);

                return StaffDeviceCheckCard(
                  device: device,
                  todayLog: todayLog,
                  isEditing: isEditing,
                  isSubmitting: isSubmitting,
                  noteController: noteController,
                  onToggleEdit: () => widget.onToggleEdit(device.id),
                  onCancelEdit: () => widget.onCancelEdit(device.id),
                  onLogStatus: (status) => widget.onLogStatus(device, status),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int index,
    Color? badgeColor,
  }) {
    final isSelected = _dailyCheckFilterIndex == index;
    return Expanded(
      child: Material(
        color: isSelected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => setState(() => _dailyCheckFilterIndex = index),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (badgeColor != null && !isSelected) ...[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? AppColors.textWhite : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
