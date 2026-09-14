import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dark_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../devices/models/device_model.dart';
import '../../../devices/views/helpers/hardware_icon_helper.dart';

/// Modal bottom sheet displaying detailed hardware information when a technician
/// taps on a working or defective device card in the Spatial Explorer.
class TechnicianDeviceDetailSheet extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback? onReportIssue;

  const TechnicianDeviceDetailSheet({
    super.key,
    required this.device,
    this.onReportIssue,
  });

  static Future<void> show(
    BuildContext context, {
    required DeviceModel device,
    VoidCallback? onReportIssue,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => TechnicianDeviceDetailSheet(
        device: device,
        onReportIssue: onReportIssue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || AppColors.isDark;
    final isFaulty = device.status == DeviceStatus.faulty ||
        device.status == DeviceStatus.underMaintenance;

    final primaryText = isDark ? AppDarkColors.textPrimary : AppLightColors.textPrimary;
    final secondaryText = isDark ? AppDarkColors.textSecondary : AppLightColors.textSecondary;
    final cardBg = isDark ? AppDarkColors.surface : AppLightColors.white;
    final borderColor = isDark ? AppDarkColors.border : AppLightColors.border;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 4,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Device Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Device Graphic
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isFaulty
                              ? AppColors.error.withValues(alpha: 0.12)
                              : AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isFaulty
                                ? AppColors.error.withValues(alpha: 0.3)
                                : AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: (device.imageUrl != null && device.imageUrl!.isNotEmpty)
                            ? Image.network(
                                device.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Icon(
                                  HardwareIconHelper.getIcon(
                                    device.hardwareTypeName.isNotEmpty
                                        ? device.hardwareTypeName
                                        : device.name,
                                  ),
                                  size: 28,
                                  color: isFaulty ? AppColors.error : AppColors.success,
                                ),
                              )
                            : Icon(
                                HardwareIconHelper.getIcon(
                                  device.hardwareTypeName.isNotEmpty
                                      ? device.hardwareTypeName
                                      : device.name,
                                ),
                                size: 28,
                                color: isFaulty ? AppColors.error : AppColors.success,
                              ),
                      ),
                      const SizedBox(width: 14),

                      // Name + Hardware Type + Code
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: primaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (device.code.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppDarkColors.cardAlt : AppLightColors.cardAlt,
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Text(
                                      device.code,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                        color: primaryText,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                if (device.hardwareTypeName.isNotEmpty)
                                  Flexible(
                                    child: Text(
                                      device.hardwareTypeName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, color: secondaryText),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Close button
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, size: 20, color: secondaryText),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? AppDarkColors.cardAlt : AppLightColors.cardAlt,
                          padding: const EdgeInsets.all(6),
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Status & Health Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isFaulty
                          ? AppColors.error.withValues(alpha: 0.1)
                          : AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isFaulty
                            ? AppColors.error.withValues(alpha: 0.25)
                            : AppColors.success.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isFaulty ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                          color: isFaulty ? AppColors.error : AppColors.successText,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isFaulty ? 'Defect / Attention Required' : 'Operational Condition',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isFaulty ? AppColors.error : AppColors.successText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isFaulty
                                    ? 'This unit is marked with an active issue or faulty state.'
                                    : 'All diagnostic checks nominal. Unit is in active service.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge.device(device.status),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location & Info Details
                  _buildSectionHeader('DEPLOYMENT DETAILS', secondaryText),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppDarkColors.cardAlt : AppLightColors.cardAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('Zone', device.zoneName.isNotEmpty ? device.zoneName : '—', primaryText, secondaryText),
                        if (device.location.isNotEmpty) ...[
                          const Divider(height: 16),
                          _buildInfoRow('Location', device.location, primaryText, secondaryText),
                        ],
                        if (device.installDate != null) ...[
                          const Divider(height: 16),
                          _buildInfoRow(
                            'Installed',
                            '${device.installDate!.year}-${device.installDate!.month.toString().padLeft(2, '0')}-${device.installDate!.day.toString().padLeft(2, '0')}',
                            primaryText,
                            secondaryText,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Custom Specs (if any)
                  if (device.specFields.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSectionHeader('TECHNICAL SPECIFICATIONS', secondaryText),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? AppDarkColors.cardAlt : AppLightColors.cardAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < device.specFields.entries.length; i++) ...[
                            if (i > 0) const Divider(height: 16),
                            _buildInfoRow(
                              device.specFields.entries.elementAt(i).key,
                              '${device.specFields.entries.elementAt(i).value}',
                              primaryText,
                              secondaryText,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Action: Report Defect / Issue
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onReportIssue?.call();
                    },
                    icon: const Icon(Icons.report_problem_outlined, size: 18),
                    label: Text(
                      isFaulty ? 'View or Log Additional Defect' : 'Report Issue on this Device',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
        color: color,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color primaryText, Color secondaryText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: secondaryText)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primaryText),
          ),
        ),
      ],
    );
  }
}
