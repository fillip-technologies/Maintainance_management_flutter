import 'package:flutter/material.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../l10n/app_localizations.dart';

class BulkResolveNotesInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onPresetSelected;

  const BulkResolveNotesInput({
    super.key,
    required this.controller,
    required this.onPresetSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n?.resolutionNotesLabel ?? 'Technician Resolution / Work Notes',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 2,
          style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: l10n?.resolutionNotesHint ??
                'Explain steps taken, repairs made, or reason for status update...',
            hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Quick-fill chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPresetChip(l10n?.presetPowerRestored ?? 'Main power supply restored'),
              const SizedBox(width: 6),
              _buildPresetChip(l10n?.presetBatchRepaired ?? 'Batch repair completed and verified'),
              const SizedBox(width: 6),
              _buildPresetChip(l10n?.presetFirmwareUpdated ?? 'Firmware updated & rebooted'),
              const SizedBox(width: 6),
              _buildPresetChip(l10n?.presetCablesTested ?? 'Cables re-seated & tested'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String text) {
    return ActionChip(
      label: Text(text),
      labelStyle: TextStyle(fontSize: 11, color: AppColors.textSecondary),
      backgroundColor: AppColors.surface,
      side: BorderSide(color: AppColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      onPressed: () => onPresetSelected(text),
    );
  }
}
