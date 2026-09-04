import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/issue_model.dart';
import '../../../l10n/app_localizations.dart';
import '../viewmodels/issue_action_viewmodel.dart';
import '../viewmodels/issue_query_viewmodel.dart';
import 'widgets/issue_timeline_view.dart';
import 'replace_device_sheet.dart';
import 'update_status_sheet.dart';

class IssueDetailSheet extends ConsumerWidget {
  final IssueModel issue;

  const IssueDetailSheet({super.key, required this.issue});

  static Future<void> show(BuildContext context, IssueModel issue) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IssueDetailSheet(issue: issue),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authStateProvider).value;
    final isTechnician = user?.role == UserRole.technician;
    final liveIssueAsync = ref.watch(issueDetailProvider(issue.id));
    final currentIssue = liveIssueAsync.value ?? issue;
    final maxHeight = MediaQuery.of(context).size.height * 0.92;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Adaptive Scrollable Body (hugs short content, scrolls smoothly on long history)
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 6,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Bar
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentIssue.id.length > 8
                                  ? '#${currentIssue.id.substring(0, 8)} • ${currentIssue.deviceName}'
                                  : '#${currentIssue.id}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentIssue.title.isNotEmpty
                                  ? currentIssue.title
                                  : (currentIssue.description.isNotEmpty
                                      ? currentIssue.description
                                      : 'Maintenance Issue'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: AppColors.icon),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Badges row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusBadge.issue(currentIssue.status),
                      StatusBadge.priority(currentIssue.priority),
                      if (currentIssue.deviceStatus != null)
                        StatusBadge.device(currentIssue.deviceStatus!),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.infoLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          currentIssue.categoryName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.infoText,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 12),

                  // Equipment & Location Metadata
                  _buildMetaRow(
                    Icons.place_outlined,
                    l10n.zoneLocation,
                    currentIssue.zoneName,
                  ),
                  const SizedBox(height: 8),
                  _buildMetaRow(
                    Icons.devices_other_outlined,
                    l10n.equipmentUnit,
                    '${currentIssue.deviceName}${currentIssue.deviceCode != null ? " (${currentIssue.deviceCode})" : ""}',
                  ),
                  if (currentIssue.deviceStatus != null) ...[
                    const SizedBox(height: 8),
                    _buildMetaWidget(
                      Icons.settings_suggest_outlined,
                      l10n.hardwareStatus,
                      StatusBadge.device(currentIssue.deviceStatus!),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildMetaRow(
                    Icons.person_outline,
                    l10n.reportedBy,
                    currentIssue.raisedByName.isNotEmpty
                        ? currentIssue.raisedByName
                        : 'Staff Member',
                  ),
                  const SizedBox(height: 8),
                  _buildMetaRow(
                    Icons.engineering_outlined,
                    l10n.assignedTech,
                    (currentIssue.assignedTechnicianName != null &&
                            currentIssue.assignedTechnicianName!.isNotEmpty)
                        ? currentIssue.assignedTechnicianName!
                        : l10n.unassignedQueue,
                  ),

                  const SizedBox(height: 14),

                  // Defect Description
                  if (currentIssue.description.isNotEmpty) ...[
                    Text(
                      l10n.defectDescription,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        currentIssue.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Chronological Status History & Timeline Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.timelineHistory,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      InkWell(
                        onTap: () =>
                            ref.invalidate(issueHistoryProvider(currentIssue.id)),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              const Icon(Icons.refresh, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                l10n.refresh,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Embedded Live Timeline Stepper
                  IssueTimelineView(
                    issueId: currentIssue.id,
                    initialHistory: currentIssue.history,
                  ),

                  const SizedBox(height: 20),

                  // Quick Status Transition Button for Technicians
                  if (isTechnician) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        UpdateStatusSheet.show(
                          context,
                          issue: currentIssue,
                          onStatusUpdated: (newStatus, comment, _) async {
                            try {
                              await ref
                                  .read(issueActionControllerProvider.notifier)
                                  .updateStatus(
                                    issueId: currentIssue.id,
                                    toStatus: newStatus,
                                    notes: comment,
                                  );
                              AppSnackbar.success(
                                'Ticket moved to ${newStatus.label}',
                              );
                            } catch (e) {
                              AppSnackbar.error('Failed to update status: $e');
                            }
                          },
                        );
                      },
                      icon: const Icon(Icons.edit_note, size: 18),
                      label: Text(l10n.btnUpdateStatus),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textWhite,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (currentIssue.status != IssueStatus.closed && currentIssue.status != IssueStatus.resolved) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () {
                          ReplaceDeviceSheet.show(
                            context,
                            issue: currentIssue,
                            onConfirm: ({
                              required reason,
                              required notes,
                              required replacementChoice,
                              spareDeviceId,
                              newDeviceName,
                              newDeviceSerial,
                              proofPhoto,
                            }) async {
                              final replacementText = switch (replacementChoice) {
                                ReplacementChoice.inStock => 'Installed in-stock spare unit ($spareDeviceId).',
                                ReplacementChoice.newDevice => 'Installed new hardware unit: $newDeviceName ($newDeviceSerial).',
                                ReplacementChoice.none => 'No replacement installed; slot left vacant.',
                              };
                              final fullComment = '[HARDWARE DECOMMISSIONED - ${reason.name.toUpperCase()}] $notes. $replacementText';
                              await ref
                                  .read(issueActionControllerProvider.notifier)
                                  .updateStatus(
                                    issueId: currentIssue.id,
                                    toStatus: IssueStatus.resolved,
                                    notes: fullComment,
                                  );
                              AppSnackbar.success(
                                l10n.replacementSuccess,
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.broken_image_outlined, size: 18, color: AppColors.error),
                        label: Text(l10n.btnDecommissionReplace, style: const TextStyle(color: AppColors.errorText)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaWidget(IconData icon, String label, Widget trailing) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.icon),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        trailing,
      ],
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.icon),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
