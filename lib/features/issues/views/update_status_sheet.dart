import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/colors.dart';
import '../../location/location_helper.dart';
import '../controllers/update_status_controller.dart';
import '../controllers/update_status_state.dart';
import '../models/issue_model.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets/awaiting_replacement_banner.dart';
import 'widgets/update_status/decommission_shortcut_banner.dart';
import 'widgets/update_status/proof_photo_box.dart';
import 'widgets/update_status/status_choice_chips.dart';
import 'widgets/update_status/status_gps_section.dart';
import 'widgets/update_status/submit_status_button.dart';
import 'widgets/update_status/update_status_header.dart';

typedef StatusUpdateCallback = Future<void> Function(
  IssueStatus newStatus,
  String comment,
  File? resolutionPhoto, [
  double? latitude,
  double? longitude,
]);

class UpdateStatusSheet extends StatefulWidget {
  final IssueModel issue;
  final IssueStatus? initialTargetStatus;
  final StatusUpdateCallback onStatusUpdated;
  final LocationHelper? locationHelper;

  /// Invoked when the technician taps the "equipment destroyed" shortcut. The
  /// caller starts the approval-gated replacement request flow; when null the
  /// shortcut is hidden (a replacement can never bypass approval from here).
  final VoidCallback? onRequestReplacement;

  const UpdateStatusSheet({
    super.key,
    required this.issue,
    this.initialTargetStatus,
    required this.onStatusUpdated,
    this.locationHelper,
    this.onRequestReplacement,
  });

  static Future<void> show(
    BuildContext context, {
    required IssueModel issue,
    IssueStatus? initialTargetStatus,
    required StatusUpdateCallback onStatusUpdated,
    LocationHelper? locationHelper,
    VoidCallback? onRequestReplacement,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => UpdateStatusSheet(
        issue: issue,
        initialTargetStatus: initialTargetStatus,
        onStatusUpdated: onStatusUpdated,
        locationHelper: locationHelper,
        onRequestReplacement: onRequestReplacement,
      ),
    );
  }

  @override
  State<UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends State<UpdateStatusSheet> with WidgetsBindingObserver {
  late final UpdateStatusController _controller;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = UpdateStatusController(
      issue: widget.issue,
      initialTargetStatus: widget.initialTargetStatus,
      locationHelper: widget.locationHelper,
      onStateChanged: _onStateChanged,
    );
    _commentController.text = _controller.state.comment;
    _commentController.addListener(() {
      _controller.setComment(_commentController.text);
    });
  }

  void _onStateChanged(UpdateStatusState state) {
    if (!mounted) return;
    if (_commentController.text != state.comment) {
      _commentController.text = state.comment;
    }
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _commentController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_controller.state.hasValidGps) {
        _controller.fetchLocation();
      }
    }
  }

  void _showImageSourceModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Verification Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _controller.pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _controller.pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final success = await _controller.submit(widget.onStatusUpdated);
    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final allowedStatuses = UpdateStatusController.allowedTransitionsFor(widget.issue);
    final maxHeight = MediaQuery.of(context).size.height * 0.90;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
                  UpdateStatusHeader(
                    issueId: widget.issue.id,
                    onClose: () => Navigator.pop(context),
                  ),

                  Divider(color: AppColors.divider),
                  const SizedBox(height: 12),

                  if (state.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        state.errorMessage!,
                        style: TextStyle(fontSize: 13, color: AppColors.errorText),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (widget.issue.awaitingReplacementApproval)
                    AwaitingReplacementBanner(
                      message: AppLocalizations.of(context)!.replacementPendingCannotClose,
                    )
                  else if (widget.onRequestReplacement != null)
                    DecommissionShortcutBanner(
                      onTap: () {
                        Navigator.pop(context);
                        widget.onRequestReplacement!();
                      },
                    ),
                  const SizedBox(height: 16),

                  StatusChoiceChips(
                    allowedStatuses: allowedStatuses,
                    selectedStatus: state.selectedStatus,
                    onStatusSelected: _controller.setStatus,
                  ),

                  const SizedBox(height: 16),

                  // Work Log / Comments
                  Text(
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
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Enter details of work performed, parts used, or blockers...',
                    ),
                  ),

                  const SizedBox(height: 14),

                  ProofPhotoBox(
                    resolutionImage: state.resolutionImage,
                    isPickingImage: state.isPickingImage,
                    onAddPhoto: _showImageSourceModal,
                    onRemovePhoto: _controller.clearImage,
                  ),

                  const SizedBox(height: 16),

                  StatusGpsSection(
                    selectedStatus: state.selectedStatus,
                    isFetchingLocation: state.isFetchingLocation,
                    locationResult: state.locationResult,
                    onRetryLocation: _controller.fetchLocation,
                    onOpenLocationSettings: _controller.openLocationSettings,
                    onOpenAppSettings: _controller.openAppSettings,
                  ),

                  const SizedBox(height: 16),

                  SubmitStatusButton(
                    isSubmitting: state.isSubmitting,
                    selectedStatus: state.selectedStatus,
                    hasValidGps: state.hasValidGps,
                    onSubmit: _handleSubmit,
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
