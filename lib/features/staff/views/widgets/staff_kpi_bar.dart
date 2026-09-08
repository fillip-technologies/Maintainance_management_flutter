import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/hardware_stat_row.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../devices/devices.dart';
import '../../../issues/issues.dart';

/// Top hardware headline for the staff home — the same three coloured tiles as
/// the technician zone map: TOTAL HARDWARE / ACTIVE / PROBLEMS.
///
///  * TOTAL   = non-retired units
///  * ACTIVE  = units with status `active`
///  * PROBLEMS = distinct units with an UNRESOLVED issue (resolved / closed
///    tickets are never counted)
///
/// Built from the lists the home page already holds — no summary endpoint.
class StaffKpiBar extends StatelessWidget {
  final List<DeviceModel> devices;
  final List<IssueModel> issues;

  const StaffKpiBar({
    super.key,
    required this.devices,
    required this.issues,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final live = devices.where((d) => d.status != DeviceStatus.retired).toList();
    final total = live.length;
    final active = live.where((d) => d.status == DeviceStatus.active).length;

    final problemUnits = issues
        .where((i) =>
            i.status != IssueStatus.resolved && i.status != IssueStatus.closed)
        .map((i) => i.deviceId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .length;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: HardwareStatRow(
        total: total,
        active: active,
        problems: problemUnits,
        totalLabel: l10n?.kpiTotalDevices ?? 'Total Hardware',
        activeLabel: l10n?.deviceStatusActive ?? 'Active',
        problemLabel: l10n?.staffKpiProblems ?? 'Problems',
      ),
    );
  }
}
