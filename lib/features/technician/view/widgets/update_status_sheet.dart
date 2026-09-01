import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/utils/app_snackbar.dart';
import '../../../../../data/models/issue_model.dart';

class UpdateStatusSheet extends StatefulWidget {
  final IssueModel issue;
  final IssueStatus? initialTargetStatus;
  final Function(IssueStatus newStatus, String comment, File? resolutionPhoto)
  onStatusUpdated;

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
    required Function(
      IssueStatus newStatus,
      String comment,
      File? resolutionPhoto,
    )
    onStatusUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
  File? _resolutionImage;
  final ImagePicker _picker = ImagePicker();
  bool _isPickingImage = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedStatus =
        widget.initialTargetStatus ??
        _getDefaultNextStatus(widget.issue.status);
    if (_selectedStatus == IssueStatus.resolved) {
      _commentController.text = 'Repaired and tested device functionality.';
    } else if (_selectedStatus == IssueStatus.inProgress) {
      _commentController.text = 'Started diagnostic & on-site inspection.';
    } else if (_selectedStatus == IssueStatus.onHold) {
      _commentController.text =
          'Waiting for replacement parts / access clearance.';
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
      IssueStatus.open ||
      IssueStatus.assigned => [IssueStatus.inProgress, IssueStatus.onHold],
      IssueStatus.inProgress => [IssueStatus.resolved, IssueStatus.onHold],
      IssueStatus.onHold => [IssueStatus.inProgress, IssueStatus.resolved],
      IssueStatus.resolved => [IssueStatus.closed, IssueStatus.inProgress],
      IssueStatus.closed ||
      IssueStatus.reopened => [IssueStatus.inProgress, IssueStatus.onHold],
    };
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    setState(() => _isPickingImage = true);

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _resolutionImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      AppSnackbar.error('Failed to take photo: $e');
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  void _showImageSourceModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Proof / Resolution Photo',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Attach a photo of the repaired equipment',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSourceOption(
                  icon: Icons.camera_alt_rounded,
                  iconColor: AppColors.primary,
                  iconBgColor: AppColors.primaryBg,
                  title: 'Take Photo (Camera)',
                  subtitle: 'Capture current device status',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                const SizedBox(height: 10),
                _buildSourceOption(
                  icon: Icons.photo_library_rounded,
                  iconColor: AppColors.purple,
                  iconBgColor: AppColors.purpleLight,
                  title: 'Choose from Gallery',
                  subtitle: 'Select from photos library',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.iconLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      setState(
        () =>
            _errorMessage = 'Please provide a work note or transition comment',
      );
      return;
    }

    widget.onStatusUpdated(_selectedStatus, comment, _resolutionImage);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final allowedStatuses = _getAllowedTransitions(widget.issue.status);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
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
                      widget.issue.id,
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.errorText,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

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
                        ? (AppColors.successText, AppColors.textWhite)
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
                          if (s == IssueStatus.resolved) {
                            _commentController.text =
                                'Issue resolved and equipment verified operational.';
                          } else if (s == IssueStatus.onHold) {
                            _commentController.text =
                                'Waiting on spare parts or area clearance.';
                          } else if (s == IssueStatus.inProgress) {
                            _commentController.text =
                                'Inspection and repair in progress.';
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.transparent
                                : AppColors.border,
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
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: const InputDecoration(
                hintText:
                    'Enter details of work performed, parts used, or blockers...',
              ),
            ),

            const SizedBox(height: 14),

            // 3. Optional Resolution Photo
            const Text(
              'Proof / Resolution Photo (Optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),

            if (_isPickingImage)
              Container(
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.cardAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_resolutionImage != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cardAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _resolutionImage!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Resolution Photo Added',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Will be attached to update log',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                      ),
                      onPressed: () => setState(() => _resolutionImage = null),
                    ),
                  ],
                ),
              )
            else
              InkWell(
                onTap: _showImageSourceModal,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Attach Verification Photo (Camera / Gallery)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
              ),
              child: Text('Confirm & Transition to ${_selectedStatus.label}'),
            ),
          ],
        ),
      ),
    );
  }
}
