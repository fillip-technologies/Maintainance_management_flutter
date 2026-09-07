import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
import '../../../core/theme/colors.dart';
// import '../../../core/utils/app_snackbar.dart';
import '../models/issue_model.dart';
import 'replace_device_sheet.dart';

class UpdateStatusSheet extends StatefulWidget {
  final IssueModel issue;
  final IssueStatus? initialTargetStatus;
  final Function(IssueStatus newStatus, String comment, File? resolutionPhoto) onStatusUpdated;

  const UpdateStatusSheet({
    super.key,
    required this.issue,
    this.initialTargetStatus,
    required this.onStatusUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required IssueModel issue,
    IssueStatus? initialTargetStatus,
    required Function(IssueStatus newStatus, String comment, File? resolutionPhoto) onStatusUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpdateStatusSheet(
        issue: issue,
        initialTargetStatus: initialTargetStatus,
        onStatusUpdated: onStatusUpdated,
      ),
    );
  }

  @override
  State<UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends State<UpdateStatusSheet> {
  late IssueStatus _selectedStatus;
  final _commentController = TextEditingController();
  // =========================================================================
  // CAMERA PROOF CAPTURE (COMMENTED OUT FOR NOW - WILL BE ENABLED IN FUTURE)
  // =========================================================================
  // File? _resolutionImage;
  // final ImagePicker _picker = ImagePicker();
  // bool _isPickingImage = false;
  // =========================================================================
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = _resolveInitialStatus();
    _applyDefaultComment(_selectedStatus);
  }

  /// The caller can request a target status (e.g. from a card's "Resolve"
  /// button), but only statuses that are legal from the current state are
  /// offered as options. Clamp an out-of-range request to a safe default so the
  /// sheet never opens on a status with no matching button.
  IssueStatus _resolveInitialStatus() {
    final allowed = _getAllowedTransitions(widget.issue.status);
    final requested = widget.initialTargetStatus;
    if (requested != null && allowed.contains(requested)) {
      return requested;
    }
    final fallback = _getDefaultNextStatus(widget.issue.status);
    return allowed.contains(fallback) ? fallback : allowed.first;
  }

  void _applyDefaultComment(IssueStatus status) {
    if (status == IssueStatus.resolved) {
      _commentController.text = 'Repaired and tested equipment functionality.';
    } else if (status == IssueStatus.inProgress) {
      _commentController.text = 'Started diagnostic & on-site inspection.';
    } else if (status == IssueStatus.onHold) {
      _commentController.text = 'Waiting for replacement parts / access clearance.';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  IssueStatus _getDefaultNextStatus(IssueStatus current) {
    return switch (current) {
      IssueStatus.open || IssueStatus.assigned => IssueStatus.inProgress,
      IssueStatus.inProgress => IssueStatus.resolved,
      IssueStatus.onHold => IssueStatus.inProgress,
      IssueStatus.resolved => IssueStatus.closed,
      IssueStatus.closed || IssueStatus.reopened => IssueStatus.inProgress,
    };
  }

  List<IssueStatus> _getAllowedTransitions(IssueStatus current) {
    return switch (current) {
      IssueStatus.open || IssueStatus.assigned => [IssueStatus.inProgress, IssueStatus.onHold],
      IssueStatus.inProgress => [IssueStatus.resolved, IssueStatus.onHold],
      IssueStatus.onHold => [IssueStatus.inProgress],
      IssueStatus.resolved => [IssueStatus.closed, IssueStatus.reopened],
      IssueStatus.closed || IssueStatus.reopened => [IssueStatus.inProgress, IssueStatus.onHold],
    };
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    // The work note is optional: a pre-filled default is offered, but a
    // technician who clears it can still submit.
    final comment = _commentController.text.trim();

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onStatusUpdated(_selectedStatus, comment, null);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowedStatuses = _getAllowedTransitions(widget.issue.status);
    final maxHeight = MediaQuery.of(context).size.height * 0.90;

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
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.issue.id.length > 8 ? '#${widget.issue.id.substring(0, 8)}' : '#${widget.issue.id}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Update Work Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: AppColors.icon),
                      ),
                    ],
                  ),

                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 12),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 13, color: AppColors.errorText),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Decommission & Replacement Banner Button
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      ReplaceDeviceSheet.show(
                        context,
                        issue: widget.issue,
                        onConfirm: ({
                          required reason,
                          required notes,
                          required replacementChoice,
                          spareDeviceId,
                          newDeviceName,
                          newDeviceSerial,
                          proofPhoto,
                        }) async {
                          widget.onStatusUpdated(IssueStatus.resolved, notes, null);
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.broken_image_outlined, color: AppColors.errorText, size: 20),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Equipment Destroyed / Smashed?',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.errorText),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Tap here to decommission & replace hardware',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.errorText, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. Target Status Selection
                  const Text(
                    'Select Next Status',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: allowedStatuses.map((s) {
                      final isSelected = _selectedStatus == s;

                      final (bg, textCol) = switch (s) {
                        IssueStatus.inProgress =>
                          isSelected
                              ? (AppColors.warning, AppColors.textWhite)
                              : (AppColors.warningLight, AppColors.warningText),
                        IssueStatus.onHold =>
                          isSelected
                              ? (AppColors.purple, AppColors.textWhite)
                              : (AppColors.purpleLight, AppColors.purpleText),
                        IssueStatus.resolved =>
                          isSelected
                              ? (AppColors.success, AppColors.textWhite)
                              : (AppColors.successLight, AppColors.successText),
                        _ =>
                          isSelected
                              ? (AppColors.primary, AppColors.textWhite)
                              : (AppColors.surface, AppColors.textSecondary),
                      };

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedStatus = s;
                                _applyDefaultComment(s);
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.transparent : AppColors.border,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                s.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textCol,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // 2. Action Notes / Comments
                  const Text(
                    'Work Log / Comments',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Enter details of work performed, parts used, or blockers...',
                    ),
                  ),

                  const SizedBox(height: 14),

                  // =========================================================================
                  // CAMERA PROOF CAPTURE (COMMENTED OUT FOR NOW - WILL BE ENABLED IN FUTURE)
                  // =========================================================================
                  // const Text(
                  //   'Proof / Verification Photo (Optional)',
                  //   style: TextStyle(
                  //     fontSize: 13,
                  //     fontWeight: FontWeight.w600,
                  //     color: AppColors.textSecondary,
                  //   ),
                  // ),
                  // const SizedBox(height: 8),
                  // ... (Camera / Gallery Picker)
                  // =========================================================================

                  const SizedBox(height: 20),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Updating status...',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : Text('Confirm & Transition to ${_selectedStatus.label}'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
