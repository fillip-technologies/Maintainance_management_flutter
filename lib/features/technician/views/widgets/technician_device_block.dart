import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../devices/models/device_model.dart';
import '../../../devices/views/helpers/hardware_icon_helper.dart';
import '../../../issues/models/issue_model.dart';
import '../../../issues/views/issue_detail_sheet.dart';
import 'technician_device_detail_sheet.dart';

/// Replicates CamBlock from the web UI (http://localhost:5173/clientadmin/products).
/// Compact, high-visibility hardware icon block:
/// - Green: Active / nominal unit.
/// - Red: Defective, offline, or has active unresolved issue ticket.
/// - Tapping a defective unit opens IssueDetailSheet; tapping nominal opens TechnicianDeviceDetailSheet.
class TechnicianDeviceBlock extends StatelessWidget {
  final DeviceModel device;
  final bool isDefective;
  final IssueModel? activeIssue;
  final VoidCallback? onTap;

  const TechnicianDeviceBlock({
    super.key,
    required this.device,
    required this.isDefective,
    this.activeIssue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isDefective ? AppColors.error : AppColors.success;
    final iconData = HardwareIconHelper.getIcon(device.hardwareTypeName);

    final tooltipMsg =
        '${device.code.isNotEmpty ? '${device.code} • ' : ''}${device.name}\n${isDefective ? (activeIssue?.title ?? 'Defective / Offline') : 'Active'}';

    return Tooltip(
      message: tooltipMsg,
      waitDuration: const Duration(milliseconds: 350),
      child: Material(
        color: statusColor,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          onTap: () {
            if (onTap != null) {
              onTap!();
              return;
            }
            if (isDefective && activeIssue != null) {
              IssueDetailSheet.show(context, activeIssue!);
            } else {
              TechnicianDeviceDetailSheet.show(context, device: device);
            }
          },
          borderRadius: BorderRadius.circular(5),
          child: Container(
            width: 28,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: isDefective ? 0.6 : 0.35),
                  blurRadius: isDefective ? 6 : 3,
                  spreadRadius: isDefective ? 0.5 : 0,
                ),
              ],
            ),
            child: Icon(
              iconData,
              size: 11,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
