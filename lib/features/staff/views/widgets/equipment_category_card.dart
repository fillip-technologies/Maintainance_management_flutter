import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../devices/models/device_group_model.dart';
import '../../../devices/views/helpers/equipment_graphic.dart';

/// An individual equipment category card matching the requested side-by-side layout:
/// - One side: Equipment icon / graphic
/// - Other side: Left-aligned column containing:
///     1. Total quantity
///     2. Category name
///     3. Colored dot + count + online
///     4. Colored dot + count + offline
///     5. Colored dot + count + maintenance
class EquipmentCategoryCard extends StatelessWidget {
  final DeviceGroup group;
  final VoidCallback onTap;

  const EquipmentCategoryCard({
    super.key,
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLink = EquipmentVisualType.isLink(group.hardwareTypeName);

    // Look for first available image URL among devices in this group
    final sampleImageUrl = group.devices
        .where((d) => d.imageUrl != null && d.imageUrl!.trim().isNotEmpty)
        .firstOrNull
        ?.imageUrl;

    final onlineLabel = isLink
        ? (l10n?.statusActive ?? 'Active')
        : (l10n?.statusOnline ?? 'Online');
    final offlineLabel = isLink
        ? (l10n?.statusDown ?? 'Down')
        : (l10n?.statusOffline ?? 'Offline');
    final maintenanceLabel = l10n?.statusMaintenance ?? 'Maintenance';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // One side: Equipment icon as it is now
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: EquipmentGraphic(
                  hardwareTypeName: group.hardwareTypeName,
                  imageUrl: sampleImageUrl,
                  size: 38,
                ),
              ),
              const SizedBox(width: 8),

              // Other side: Column with total quantity, name, and status rows
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Total quantity
                    Text(
                      '${group.totalCount}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),

                    // Category / Device name
                    Text(
                      group.hardwareTypeName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 5),

                    // Status rows: colored dot + count + label
                    _StatusDotRow(
                      dotColor: AppColors.success,
                      count: group.activeCount,
                      label: onlineLabel,
                    ),
                    const SizedBox(height: 2.5),
                    _StatusDotRow(
                      dotColor: AppColors.error,
                      count: group.faultyCount,
                      label: offlineLabel,
                    ),
                    const SizedBox(height: 2.5),
                    _StatusDotRow(
                      dotColor: AppColors.warning,
                      count: group.maintenanceCount,
                      label: maintenanceLabel,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusDotRow extends StatelessWidget {
  final Color dotColor;
  final int count;
  final String label;

  const _StatusDotRow({
    required this.dotColor,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
