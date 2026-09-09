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
      backgroundColor: AppColors.transparent,
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
      decoration: BoxDecoration(
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
                              style: TextStyle(
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
                              style: TextStyle(
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
                        icon: Icon(Icons.close, color: AppColors.icon),
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
                      // Hardware status badge commented out for now
                      // if (currentIssue.deviceStatus != null)
                      //   StatusBadge.device(currentIssue.deviceStatus!),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.infoLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          currentIssue.categoryName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.infoText,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Divider(color: AppColors.divider),
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
                  // Hardware status commented out for now
                  // if (currentIssue.deviceStatus != null) ...[
                  //   const SizedBox(height: 8),
                  //   _buildMetaWidget(
                  //     Icons.settings_suggest_outlined,
                  //     l10n.hardwareStatus,
                  //     StatusBadge.device(currentIssue.deviceStatus!),
                  //   ),
                  // ],
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
                      style: TextStyle(
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
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Evidence & Attachments Gallery
                  _buildAttachmentsGallery(context, currentIssue, l10n),

                  const SizedBox(height: 20),

                  // Chronological Status History & Timeline Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.timelineHistory,
                        style: TextStyle(
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
                              Icon(Icons.refresh, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                l10n.refresh,
                                style: TextStyle(
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
                        final actionController = ref.read(issueActionControllerProvider.notifier);
                        final sheetContext = context;
                        final issueId = currentIssue.id;

                        UpdateStatusSheet.show(
                          sheetContext,
                          issue: currentIssue,
                          onStatusUpdated: (newStatus, comment, resolutionPhoto) async {
                            try {
                              await actionController.updateStatus(
                                issueId: issueId,
                                toStatus: newStatus,
                                notes: comment,
                                attachments: resolutionPhoto != null ? [resolutionPhoto] : null,
                              );
                              AppSnackbar.success(
                                'Ticket moved to ${newStatus.label}',
                              );
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                            } catch (e) {
                              AppSnackbar.error('Failed to update status: $e');
                              rethrow;
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
                          final actionController = ref.read(issueActionControllerProvider.notifier);
                          final sheetContext = context;
                          final issueId = currentIssue.id;

                          ReplaceDeviceSheet.show(
                            sheetContext,
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
                              try {
                                await actionController.updateStatus(
                                  issueId: issueId,
                                  toStatus: IssueStatus.resolved,
                                  notes: fullComment,
                                  attachments: proofPhoto != null ? [proofPhoto] : null,
                                );
                                AppSnackbar.success(
                                  l10n.replacementSuccess,
                                );
                                if (sheetContext.mounted) {
                                  Navigator.of(sheetContext).pop();
                                }
                              } catch (e) {
                                AppSnackbar.error('Failed to update status: $e');
                                rethrow;
                              }
                            },
                          );
                        },
                        icon: Icon(Icons.broken_image_outlined, size: 18, color: AppColors.error),
                        label: Text(l10n.btnDecommissionReplace, style: TextStyle(color: AppColors.errorText)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.error),
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

  // Commented out with hardware status:
  // Widget _buildMetaWidget(IconData icon, String label, Widget trailing) {
  //   return Row(
  //     children: [
  //       Icon(icon, size: 16, color: AppColors.icon),
  //       const SizedBox(width: 8),
  //       Text(
  //         '$label: ',
  //         style: TextStyle(
  //           fontSize: 13,
  //           color: AppColors.textSecondary,
  //           fontWeight: FontWeight.w500,
  //         ),
  //       ),
  //       const Spacer(),
  //       trailing,
  //     ],
  //   );
  // }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.icon),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
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
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentsGallery(
    BuildContext context,
    IssueModel issue,
    AppLocalizations l10n,
  ) {
    final photoList = issue.photoAttachments;
    final items = photoList.isNotEmpty
        ? photoList
        : (issue.imagePath != null && issue.imagePath!.isNotEmpty)
            ? [
                IssueAttachmentModel(
                  url: issue.imagePath!,
                  filename: 'Evidence Photo',
                )
              ]
            : <IssueAttachmentModel>[];

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.evidencePhotos,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${items.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildThumbnailCard(context, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnailCard(BuildContext context, IssueAttachmentModel item) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(context, item.url, item.filename),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          color: AppColors.cardAlt,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              item.url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
              errorBuilder: (_, _, _) => Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 28,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.overlayScrimLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.zoom_in,
                  size: 14,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(
    BuildContext context,
    String imageUrl,
    String title,
  ) {
    showDialog(
      context: context,
      barrierColor: AppColors.black87,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: Icon(Icons.close, color: AppColors.white, size: 28),
                ),
              ),
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InteractiveViewer(
                    maxScale: 4.0,
                    minScale: 0.8,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                          ),
                        );
                      },
                      errorBuilder: (_, _, _) => Container(
                        padding: const EdgeInsets.all(24),
                        color: AppColors.card,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image, size: 48, color: AppColors.grey),
                            SizedBox(height: 8),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: AppColors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (title.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.white70,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

