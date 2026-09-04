import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/empty_state_view.dart';
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
              AppFilterChip(
                label: 'All (${allDevices.length})',
                isSelected: checklistState.filterIndex == 0,
                onTap: () => onFilterChanged(0),
              ),
              const SizedBox(width: 8),
              AppFilterChip(
                label: 'Pending ($pendingCount)',
                isSelected: checklistState.filterIndex == 1,
                badgeColor: pendingCount > 0 ? AppColors.warningText : null,
                onTap: () => onFilterChanged(1),
              ),
              const SizedBox(width: 8),
              AppFilterChip(
                label: 'Done ($completedCount)',
                isSelected: checklistState.filterIndex == 2,
                badgeColor: completedCount > 0 ? AppColors.successText : null,
                onTap: () => onFilterChanged(2),
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
                    padding: const EdgeInsets.only(top: 40),
                    child: ErrorStateView(
                      title: 'Failed to load hardware checklist',
                      subtitle: 'Please check your connection and tap to retry',
                      onRetry: onRefresh,
                    ),
                  );
                }

                if (displayedDevices.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: EmptyStateView(
                      icon: checklistState.filterIndex == 1
                          ? Icons.task_alt_rounded
                          : Icons.devices_outlined,
                      iconColor: checklistState.filterIndex == 1
                          ? AppColors.successText
                          : AppColors.icon,
                      iconBackgroundColor: checklistState.filterIndex == 1
                          ? AppColors.successLight
                          : AppColors.cardAlt,
                      title: checklistState.filterIndex == 1
                          ? 'All checks complete for today! Great work.'
                          : 'No hardware found in this filter',
                      subtitle: 'Pull down to refresh the catalogue',
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
}
