import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final total = allDevices.length;
    final completedCount = allDevices.where((d) => todayLogsMap.containsKey(d.id)).length;
    final pendingCount = total - completedCount;
    final allDone = total > 0 && pendingCount == 0;
    final progress = total > 0 ? completedCount / total : 0.0;

    var displayedDevices = allDevices;
    if (checklistState.filterIndex == 1) {
      displayedDevices = allDevices.where((d) => !todayLogsMap.containsKey(d.id)).toList();
    } else if (checklistState.filterIndex == 2) {
      displayedDevices = allDevices.where((d) => todayLogsMap.containsKey(d.id)).toList();
    }

    return Column(
      children: [
        // Today's progress — the whole point of the staff role
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    allDone ? Icons.check_circle_rounded : Icons.checklist_rounded,
                    size: 20,
                    color: allDone ? AppColors.successText : AppColors.warningText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n?.staffCheckedTodayProgress(completedCount, total) ??
                          '$completedCount / $total checked today',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.border.withValues(alpha: 0.4),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    allDone ? AppColors.successText : AppColors.warningText,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Segmented Status Filter Bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.background,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                AppFilterChip(
                  label: l10n?.staffFilterAll(total) ?? 'All ($total)',
                  isSelected: checklistState.filterIndex == 0,
                  onTap: () => onFilterChanged(0),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: l10n?.staffFilterPending(pendingCount) ?? 'Pending ($pendingCount)',
                  isSelected: checklistState.filterIndex == 1,
                  activeColor: AppColors.warning,
                  badgeColor: pendingCount > 0 ? AppColors.warningText : null,
                  onTap: () => onFilterChanged(1),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: l10n?.staffFilterDone(completedCount) ?? 'Done ($completedCount)',
                  isSelected: checklistState.filterIndex == 2,
                  activeColor: AppColors.success,
                  badgeColor: completedCount > 0 ? AppColors.successText : null,
                  onTap: () => onFilterChanged(2),
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: AppColors.divider),

        // Device Check List
        Expanded(
          child: isLoading
              ? const StaffChecklistSkeleton()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: onRefresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 84),
                    itemCount: (hasError || displayedDevices.isEmpty) ? 1 : displayedDevices.length,
                    itemBuilder: (context, index) {
                      if (hasError) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: ErrorStateView(
                            title: l10n?.staffChecklistLoadFailed ?? "Couldn't load the checklist",
                            subtitle: l10n?.staffCheckConnectionRetry ??
                                'Check your connection and tap to retry',
                            onRetry: onRefresh,
                          ),
                        );
                      }

                if (displayedDevices.isEmpty) {
                  final isPendingFilter = checklistState.filterIndex == 1;
                  return Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: EmptyStateView(
                      icon: isPendingFilter
                          ? Icons.task_alt_rounded
                          : Icons.devices_outlined,
                      iconColor: isPendingFilter ? AppColors.successText : AppColors.icon,
                      iconBackgroundColor:
                          isPendingFilter ? AppColors.successLight : AppColors.cardAlt,
                      title: isPendingFilter
                          ? (l10n?.staffAllChecksDone ?? 'All checks done for today. Great work!')
                          : (l10n?.staffNoHardwareInFilter ?? 'No hardware in this filter'),
                      subtitle: l10n?.staffPullToRefresh ?? 'Pull down to refresh',
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
