import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../daily_logs/daily_logs.dart';
import '../../../devices/devices.dart';

class StaffDeviceCheckCard extends StatelessWidget {
  final DeviceModel device;
  final DailyStatusLogModel? todayLog;
  final bool isEditing;
  final bool isSubmitting;
  final String noteText;
  final ValueChanged<String> onNoteChanged;
  final VoidCallback onToggleEdit;
  final VoidCallback onCancelEdit;
  final void Function(DailyLogStatus status) onLogStatus;

  const StaffDeviceCheckCard({
    super.key,
    required this.device,
    required this.todayLog,
    required this.isEditing,
    required this.isSubmitting,
    required this.noteText,
    required this.onNoteChanged,
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
                      const SizedBox(height: 2),
                      Text(
                        '${device.hardwareTypeName} • ${device.zoneName} (${device.location})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (todayLog != null)
                  StatusBadge.dailyLog(todayLog!.status)
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'Pending Check',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warningText,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 10),

            if (todayLog != null && !isEditing) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recorded Today: ${todayLog!.status.label}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (todayLog!.notes != null && todayLog!.notes!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '"${todayLog!.notes}"',
                            style: const TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onToggleEdit,
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Change', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ] else ...[
              if (isEditing)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Text(
                        'Update status:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: onCancelEdit,
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        child: const Text('Cancel', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ),
                    ],
                  ),
                ),

              TextFormField(
                initialValue: noteText,
                onChanged: onNoteChanged,
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Add check note (optional)...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              if (isSubmitting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusButton(
                        label: workingLabel,
                        status: DailyLogStatus.working,
                        color: AppColors.success,
                        textColor: AppColors.textWhite,
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildStatusButton(
                        label: attentionLabel,
                        status: DailyLogStatus.needsAttention,
                        color: AppColors.warning,
                        textColor: AppColors.textWhite,
                        icon: Icons.warning_amber_rounded,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildStatusButton(
                        label: notWorkingLabel,
                        status: DailyLogStatus.notWorking,
                        color: AppColors.error,
                        textColor: AppColors.textWhite,
                        icon: Icons.error_outline,
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton({
    required String label,
    required DailyLogStatus status,
    required Color color,
    required Color textColor,
    required IconData icon,
  }) {
    return ElevatedButton(
      onPressed: () => onLogStatus(status),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
