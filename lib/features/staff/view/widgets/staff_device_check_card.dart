import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/hardware_icon_helper.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../data/models/daily_log_model.dart';
import '../../../../data/models/device_model.dart';
import '../../../../l10n/app_localizations.dart';

class StaffDeviceCheckCard extends StatelessWidget {
  final DeviceModel device;
  final DailyStatusLogModel? todayLog;
  final bool isEditing;
  final bool isSubmitting;
  final TextEditingController noteController;
  final VoidCallback onToggleEdit;
  final VoidCallback onCancelEdit;
  final void Function(DailyLogStatus status) onLogStatus;

  const StaffDeviceCheckCard({
    super.key,
    required this.device,
    required this.todayLog,
    required this.isEditing,
    required this.isSubmitting,
    required this.noteController,
    required this.onToggleEdit,
    required this.onCancelEdit,
    required this.onLogStatus,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final workingLabel = l10n?.logStatusWorking ?? 'Working';
    final attentionLabel = l10n?.logStatusNeedsAttention ?? 'Needs Attention';
    final notWorkingLabel = l10n?.logStatusNotWorking ?? 'Not Working';

    return Container(
      key: ValueKey(device.id),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: todayLog != null
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.border,
          width: todayLog != null ? 1.4 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
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
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${device.hardwareTypeName} • ${device.zoneName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge.device(device.status),
              ],
            ),

            // Checked Today Confirmation Banner
            if (todayLog != null && !isEditing) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: (todayLog!.status == DailyLogStatus.working
                          ? AppColors.success
                          : (todayLog!.status == DailyLogStatus.needsAttention
                              ? AppColors.warning
                              : AppColors.error))
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (todayLog!.status == DailyLogStatus.working
                            ? AppColors.success
                            : (todayLog!.status == DailyLogStatus.needsAttention
                                ? AppColors.warning
                                : AppColors.error))
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      todayLog!.status == DailyLogStatus.working
                          ? Icons.check_circle_rounded
                          : (todayLog!.status == DailyLogStatus.needsAttention
                              ? Icons.warning_amber_rounded
                              : Icons.cancel_outlined),
                      size: 18,
                      color: todayLog!.status == DailyLogStatus.working
                          ? AppColors.success
                          : (todayLog!.status == DailyLogStatus.needsAttention
                              ? AppColors.warning
                              : AppColors.error),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Checked Today: ${todayLog!.status.label}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: todayLog!.status == DailyLogStatus.working
                                  ? AppColors.successText
                                  : (todayLog!.status == DailyLogStatus.needsAttention
                                      ? AppColors.warningText
                                      : AppColors.error),
                            ),
                          ),
                          if (todayLog!.notes != null && todayLog!.notes!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Note: "${todayLog!.notes}"',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: onToggleEdit,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_outlined, size: 13, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Pending Check or Actively Editing
              if (isEditing) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Updating today\'s check:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onCancelEdit,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: _buildChecklistButton(
                      label: workingLabel,
                      icon: Icons.check_circle_outline,
                      color: AppColors.success,
                      isSelected: todayLog?.status == DailyLogStatus.working,
                      isLoading: isSubmitting,
                      onTap: () => onLogStatus(DailyLogStatus.working),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildChecklistButton(
                      label: attentionLabel,
                      icon: Icons.warning_amber_outlined,
                      color: AppColors.warning,
                      isSelected: todayLog?.status == DailyLogStatus.needsAttention,
                      isLoading: isSubmitting,
                      onTap: () => onLogStatus(DailyLogStatus.needsAttention),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildChecklistButton(
                      label: notWorkingLabel,
                      icon: Icons.cancel_outlined,
                      color: AppColors.error,
                      isSelected: todayLog?.status == DailyLogStatus.notWorking,
                      isLoading: isSubmitting,
                      onTap: () => onLogStatus(DailyLogStatus.notWorking),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Add note (e.g. wire loose, lens dirty)...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: AppColors.cardAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? color : color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: isLoading
              ? SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isSelected ? AppColors.textWhite : color,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 13,
                      color: isSelected ? AppColors.textWhite : color,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.textWhite : color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
