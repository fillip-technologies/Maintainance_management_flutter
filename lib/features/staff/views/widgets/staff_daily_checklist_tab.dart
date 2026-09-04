import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../daily_logs/daily_logs.dart';
import '../../../devices/devices.dart';
import '../../models/staff_checklist_state.dart';
import 'staff_device_check_card.dart';

class StaffDailyChecklistTab extends StatelessWidget {
  final List<DeviceModel> allDevices;
  final Map<String, DailyStatusLogModel> todayLogsMap;
  final bool isLoading;
  final bool hasError;
  final StaffChecklistState checklistState;
  final ValueChanged<int> onFilterChanged;
  final void Function(String deviceId, String note) onNoteChanged;
  final void Function(DeviceModel device, DailyLogStatus status) onLogStatus;
  final void Function(String deviceId, String? initialNote) onToggleEdit;
  final void Function(String deviceId) onCancelEdit;
  final Future<void> Function() onRefresh;

  const StaffDailyChecklistTab({
    super.key,
    required this.allDevices,
    required this.todayLogsMap,
    required this.isLoading,
    required this.hasError,
    required this.checklistState,
    required this.onFilterChanged,
    required this.onNoteChanged,
    required this.onLogStatus,
    required this.onToggleEdit,
    required this.onCancelEdit,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = allDevices.where((d) => todayLogsMap.containsKey(d.id)).length;
    final pendingCount = allDevices.length - completedCount;

    var displayedDevices = allDevices;
    if (checklistState.filterIndex == 1) {
      displayedDevices = allDevices.where((d) => !todayLogsMap.containsKey(d.id)).toList();
    } else if (checklistState.filterIndex == 2) {
      displayedDevices = allDevices.where((d) => todayLogsMap.containsKey(d.id)).toList();
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
                label: 'All (${allDevices.length})',
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
                label: 'Done ($completedCount)',
                index: 2,
                badgeColor: completedCount > 0 ? AppColors.successText : null,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),

        // Device Check List
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: onRefresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: (isLoading || hasError || displayedDevices.isEmpty) ? 1 : displayedDevices.length,
              itemBuilder: (context, index) {
                if (isLoading) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }

                if (hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.icon),
                          const SizedBox(height: 12),
                          const Text(
                            'Failed to load hardware checklist',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: onRefresh,
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
                            checklistState.filterIndex == 1 ? Icons.task_alt_rounded : Icons.devices_outlined,
                            size: 48,
                            color: checklistState.filterIndex == 1 ? AppColors.success : AppColors.iconLight,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            checklistState.filterIndex == 1
                                ? 'All checks complete for today! Great work.'
                                : 'No devices found in this filter',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Pull down to refresh catalogue',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final device = displayedDevices[index];
                final todayLog = todayLogsMap[device.id];
                final isSubmitting = checklistState.isSubmitting(device.id);
                final isEditing = checklistState.isEditing(device.id);
                final noteDraft = checklistState.getDraftNote(device.id);

                return StaffDeviceCheckCard(
                  key: ValueKey(device.id),
                  device: device,
                  todayLog: todayLog,
                  isEditing: isEditing,
                  isSubmitting: isSubmitting,
                  noteText: noteDraft,
                  onNoteChanged: (val) => onNoteChanged(device.id, val),
                  onToggleEdit: () => onToggleEdit(device.id, todayLog?.notes),
                  onCancelEdit: () => onCancelEdit(device.id),
                  onLogStatus: (status) => onLogStatus(device, status),
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
    final isSelected = checklistState.filterIndex == index;
    return InkWell(
      onTap: () => onFilterChanged(index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? AppColors.textWhite
                : (badgeColor ?? AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
