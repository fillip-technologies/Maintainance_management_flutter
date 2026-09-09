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

  ({Color color, IconData icon}) _statusStyle(DailyLogStatus status) {
    return switch (status) {
      DailyLogStatus.working => (color: AppColors.success, icon: Icons.check_circle_rounded),
      DailyLogStatus.needsAttention => (color: AppColors.warning, icon: Icons.warning_amber_rounded),
      DailyLogStatus.notWorking => (color: AppColors.error, icon: Icons.error_rounded),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final logged = todayLog;

    // Backend soft-flips a device to `faulty` after several consecutive
    // "not working" logs — warn before that silent status change happens.
    final repeatedlyDown = device.consecutiveFailures > 1 &&
        device.status != DeviceStatus.faulty &&
        device.status != DeviceStatus.retired;

    return Container(
      key: ValueKey(device.id),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: logged != null
              ? _statusStyle(logged.status).color.withValues(alpha: 0.45)
              : AppColors.border,
          width: logged != null ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: icon, name, location, today's status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (device.imageUrl != null && device.imageUrl!.isNotEmpty)
                      ? Image.network(
                          device.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Center(
                            child: Icon(
                              HardwareIconHelper.getIcon(device.hardwareTypeName),
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            HardwareIconHelper.getIcon(device.hardwareTypeName),
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${device.hardwareTypeName} • ${device.zoneName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (logged != null)
                  StatusBadge.dailyLog(logged.status)
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      l10n?.staffPendingCheck ?? 'Pending',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warningText,
                      ),
                    ),
                  ),
              ],
            ),

            if (repeatedlyDown) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.report_gmailerrorred_rounded, size: 15, color: AppColors.warningText),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n?.staffRepeatedlyDown(device.consecutiveFailures) ??
                          'Reported down ${device.consecutiveFailures} times — may be marked faulty',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warningText,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),

            if (isSubmitting)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
              )
            else if (logged != null && !isEditing)
              _RecordedStrip(
                status: logged.status,
                style: _statusStyle(logged.status),
                note: logged.notes,
                changeLabel: l10n?.staffChange ?? 'Change',
                onChange: onToggleEdit,
              )
            else ...[
              if (isEditing)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onCancelEdit,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    child: Text(
                      l10n?.staffCancel ?? 'Cancel',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: _BigStatusButton(
                      label: l10n?.logStatusWorking ?? 'Working',
                      style: _statusStyle(DailyLogStatus.working),
                      onTap: () => onLogStatus(DailyLogStatus.working),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _BigStatusButton(
                      label: l10n?.logStatusNeedsAttention ?? 'Attention',
                      style: _statusStyle(DailyLogStatus.needsAttention),
                      onTap: () => onLogStatus(DailyLogStatus.needsAttention),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _BigStatusButton(
                      label: l10n?.logStatusNotWorking ?? 'Not Working',
                      style: _statusStyle(DailyLogStatus.notWorking),
                      onTap: () => onLogStatus(DailyLogStatus.notWorking),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: noteText,
                onChanged: onNoteChanged,
                style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: l10n?.staffAddNote ?? 'Add a note (optional)',
                  hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BigStatusButton extends StatelessWidget {
  final String label;
  final ({Color color, IconData icon}) style;
  final VoidCallback onTap;

  const _BigStatusButton({
    required this.label,
    required this.style,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: style.color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(style.icon, size: 20, color: AppColors.textWhite),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textWhite,
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordedStrip extends StatelessWidget {
  final DailyLogStatus status;
  final ({Color color, IconData icon}) style;
  final String? note;
  final String changeLabel;
  final VoidCallback onChange;

  const _RecordedStrip({
    required this.status,
    required this.style,
    required this.note,
    required this.changeLabel,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: style.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: style.color.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(style.icon, size: 20, color: style.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status.localized(context),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: style.color,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onChange,
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: Text(changeLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
        if (note != null && note!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '"$note"',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
