import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../devices/models/device_model.dart';
import '../../../devices/views/helpers/hardware_icon_helper.dart';

/// Minimalist, visual-first equipment card for the Staff Equipment Catalog.
///
/// Per requirements:
/// - No camera/device text name on the face of the card.
/// - Status is represented purely via colors:
///   - Green for Active (healthy, no unresolved tickets).
///   - Red for Issue Raised and not solved (or faulty/under maintenance).
/// - Displays device PNG/image if present, else fallback contextual hardware icon.
/// - Circular selection tick button in top-left for file-manager style multi-selection.
class StaffDeviceGridCard extends StatelessWidget {
  final DeviceModel device;
  final bool isProblem;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleSelect;

  const StaffDeviceGridCard({
    super.key,
    required this.device,
    required this.isProblem,
    required this.isSelected,
    this.isSelectionMode = false,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isProblem ? AppColors.error : AppColors.success;

    Border border;
    Color bgColor;

    if (isSelected) {
      border = Border.all(color: AppColors.primary, width: 2.2);
      bgColor = AppColors.primary.withValues(alpha: 0.08);
    } else if (isProblem) {
      border = Border.all(color: AppColors.error.withValues(alpha: 0.65), width: 1.6);
      bgColor = AppColors.error.withValues(alpha: 0.04);
    } else {
      border = Border.all(color: AppColors.success.withValues(alpha: 0.35), width: 1.2);
      bgColor = AppColors.surface;
    }

    final tooltipText = '${device.name}${device.location.isNotEmpty ? ' • ${device.location}' : (device.zoneName.isNotEmpty ? ' • ${device.zoneName}' : '')}';

    return Tooltip(
      message: tooltipText,
      waitDuration: const Duration(milliseconds: 400),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: border,
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                else if (isProblem)
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
              ],
            ),
            child: Stack(
              children: [
                // Top-left: Selection Checkmark/Tick button
                Positioned(
                  top: 6,
                  left: 6,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onToggleSelect,
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.primary
                            : (isSelectionMode
                                ? AppColors.surface
                                : Colors.transparent),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isSelectionMode
                                  ? AppColors.border
                                  : AppColors.textSecondary.withValues(alpha: 0.25)),
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : (isSelectionMode
                              ? null
                              : Icon(
                                  Icons.circle_outlined,
                                  size: 13,
                                  color: AppColors.textSecondary.withValues(alpha: 0.25),
                                )),
                    ),
                  ),
                ),

                // Top-right: Status indicator dot (Green for active, Red for problem)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.5),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),

                // Center: Icon or PNG Image
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: _buildGraphic(statusColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGraphic(Color statusColor) {
    final rawUrl = device.imageUrl?.trim();
    if (rawUrl != null && rawUrl.isNotEmpty) {
      return Image.network(
        rawUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(statusColor),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: statusColor,
              ),
            ),
          );
        },
      );
    }
    return _buildFallbackIcon(statusColor);
  }

  Widget _buildFallbackIcon(Color statusColor) {
    final iconData = HardwareIconHelper.getIcon(device.hardwareTypeName);
    return Icon(
      iconData,
      size: 42,
      color: statusColor.withValues(alpha: 0.85),
    );
  }
}
