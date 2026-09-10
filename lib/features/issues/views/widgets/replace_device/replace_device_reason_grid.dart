import 'package:flutter/material.dart';
import 'package:equipment_management_system/core/theme/colors.dart';
import 'package:equipment_management_system/l10n/app_localizations.dart';
import 'package:equipment_management_system/features/issues/controllers/replace_device_state.dart';

class ReplaceDeviceReasonGrid extends StatelessWidget {
  final DecommissionReason selectedReason;
  final ValueChanged<DecommissionReason> onReasonSelected;

  const ReplaceDeviceReasonGrid({
    super.key,
    required this.selectedReason,
    required this.onReasonSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Step 1: Reason / What happened?
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                shape: BoxShape.circle,
              ),
              child: Text(
                '1',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.stepWhatHappened,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2x2 Pictorial Tiles
        Row(
          children: [
            Expanded(
              child: _buildPictorialTile(
                reason: DecommissionReason.physicalDamage,
                icon: Icons.hardware_rounded,
                iconColor: AppColors.deepOrange,
                iconBgColor: AppColors.deepOrange.withValues(alpha: 0.12),
                label: l10n.reasonPhysicalDamage,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPictorialTile(
                reason: DecommissionReason.burntWater,
                icon: Icons.water_drop_rounded,
                iconColor: AppColors.blueAccent,
                iconBgColor: AppColors.blueAccent.withValues(alpha: 0.12),
                label: l10n.reasonBurntWater,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPictorialTile(
                reason: DecommissionReason.unrepairable,
                icon: Icons.cancel_rounded,
                iconColor: AppColors.error,
                iconBgColor: AppColors.errorLight,
                label: l10n.reasonUnrepairable,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPictorialTile(
                reason: DecommissionReason.obsolete,
                icon: Icons.delete_sweep_rounded,
                iconColor: AppColors.brown,
                iconBgColor: AppColors.brown.withValues(alpha: 0.12),
                label: l10n.reasonObsolete,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPictorialTile({
    required DecommissionReason reason,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
  }) {
    final isSelected = selectedReason == reason;

    return InkWell(
      onTap: () => onReasonSelected(reason),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBg : AppColors.cardAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2.2 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
