import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/colors.dart';
import '../../location/location_helper.dart';
import '../models/issue_model.dart';
import 'replace_device_sheet.dart';

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

  const UpdateStatusSheet({
    super.key,
    required this.issue,
    this.initialTargetStatus,
    required this.onStatusUpdated,
    this.locationHelper,
  });

  static Future<void> show(
    BuildContext context, {
    required IssueModel issue,
    IssueStatus? initialTargetStatus,
    required StatusUpdateCallback onStatusUpdated,
    LocationHelper? locationHelper,
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
      ),
    );
  }

  @override
  State<UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends State<UpdateStatusSheet> with WidgetsBindingObserver {
  late IssueStatus _selectedStatus;
  final _commentController = TextEditingController();

  File? _resolutionImage;
  final ImagePicker _picker = ImagePicker();
  bool _isPickingImage = false;
  String? _errorMessage;
  bool _isSubmitting = false;

  late final LocationHelper _locationHelper;
  LocationResult? _locationResult;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locationHelper = widget.locationHelper ?? LocationHelper();
    _selectedStatus = _resolveInitialStatus();
    _applyDefaultComment(_selectedStatus);
    _fetchLocation();
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
      if (_locationResult == null || !_locationResult!.isSuccess) {
        _fetchLocation();
      }
    }
  }

  Future<void> _fetchLocation() async {
    if (!mounted) return;
    setState(() => _isFetchingLocation = true);
    try {
      final res = await _locationHelper.getLocation();
      if (mounted) {
        setState(() {
          _locationResult = res;
          _isFetchingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationResult = LocationResult.failure(LocationErrorType.unknown, e.toString());
          _isFetchingLocation = false;
        });
      }
    }
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isPickingImage = true);
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (picked != null) {
        setState(() => _resolutionImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to pick photo: $e');
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
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
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    setState(() {
      _errorMessage = null;
    });

    // Mandatory GPS enforcement when resolving an issue
    if (_selectedStatus == IssueStatus.resolved) {
      if (_locationResult == null || !_locationResult!.isSuccess) {
        setState(() => _isFetchingLocation = true);
        final freshRes = await _locationHelper.getLocation();
        if (mounted) {
          setState(() {
            _locationResult = freshRes;
            _isFetchingLocation = false;
          });
        }

        if (!freshRes.isSuccess) {
          final explanation =
              freshRes.errorMessage ?? 'GPS coordinates are mandatory to mark an issue as Resolved.';
          setState(() {
            _errorMessage = 'GPS Required: $explanation Please turn on GPS to proceed.';
          });
          if (freshRes.error == LocationErrorType.serviceDisabled) {
            await _locationHelper.openLocationSettings();
          } else if (freshRes.error == LocationErrorType.permissionDeniedForever) {
            await _locationHelper.openAppSettings();
          }
          return;
        }
      }
    }

    // The work note is optional: a pre-filled default is offered, but a
    // technician who clears it can still submit.
    final comment = _commentController.text.trim();

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final lat = _locationResult?.latitude;
      final lng = _locationResult?.longitude;
      await widget.onStatusUpdated(_selectedStatus, comment, _resolutionImage, lat, lng);
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
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
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
                        icon: Icon(Icons.close, color: AppColors.icon),
                      ),
                    ],
                  ),

                  Divider(color: AppColors.divider),
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
                        style: TextStyle(fontSize: 13, color: AppColors.errorText),
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
                          latitude,
                          longitude,
                        }) async {
                          widget.onStatusUpdated(
                            IssueStatus.resolved,
                            notes,
                            null,
                            latitude ?? _locationResult?.latitude,
                            longitude ?? _locationResult?.longitude,
                          );
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
                          Icon(Icons.broken_image_outlined, color: AppColors.errorText, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
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
                          Icon(Icons.chevron_right, color: AppColors.errorText, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. Target Status Selection
                  Text(
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
                              if (s == IssueStatus.resolved &&
                                  (_locationResult == null || !_locationResult!.isSuccess)) {
                                _fetchLocation();
                              }
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

                  // 3. Verification / Proof Photo (Optional)
                  Text(
                    'Work Proof / Verification Photo (Optional)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_resolutionImage != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            _resolutionImage!,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: InkWell(
                            onTap: () => setState(() => _resolutionImage = null),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close, color: AppColors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    InkWell(
                      onTap: _isPickingImage ? null : _showImageSourceModal,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isPickingImage)
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              )
                            else ...[
                              Icon(Icons.add_a_photo_outlined, size: 20, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Add Proof Photo',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // GPS Location Status Indicator
                  _buildGpsSection(),

                  const SizedBox(height: 16),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedStatus == IssueStatus.resolved &&
                              (_locationResult == null || !_locationResult!.isSuccess)
                          ? AppColors.error
                          : AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Updating status...',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            _selectedStatus == IssueStatus.resolved &&
                                    (_locationResult == null || !_locationResult!.isSuccess)
                                ? 'Resolve Ticket (Turn On GPS)'
                                : 'Confirm & Transition to ${_selectedStatus.label}',
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

  Widget _buildGpsSection() {
    final isResolved = _selectedStatus == IssueStatus.resolved;

    // State 1: Currently fetching GPS coordinates
    if (_isFetchingLocation) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryBg.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isResolved
                    ? 'Acquiring GPS fix (required to resolve ticket)...'
                    : 'Acquiring GPS coordinates...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // State 2: GPS coordinates successfully acquired
    if (_locationResult != null && _locationResult!.isSuccess) {
      final lat = _locationResult!.latitude!;
      final lng = _locationResult!.longitude!;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on, size: 20, color: AppColors.success),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'GPS: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.successText,
                        ),
                      ),
                      if (isResolved) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Required ✓',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'On-site technician position recorded',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh, size: 18, color: AppColors.successText),
              tooltip: 'Re-acquire GPS',
              onPressed: _fetchLocation,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      );
    }

    // State 3: GPS missing & status is RESOLVED (MANDATORY REQUIREMENT)
    if (isResolved) {
      final errorType = _locationResult?.error;
      final errorMsg = _locationResult?.errorMessage;

      final (warningText, primaryBtnLabel, IconData primaryIcon, VoidCallback onPrimaryAction) =
          switch (errorType) {
        LocationErrorType.serviceDisabled => (
            'Location (GPS) is turned off on this device. You must turn on GPS to resolve this ticket.',
            'Open GPS Settings',
            Icons.location_on,
            () async {
              await _locationHelper.openLocationSettings();
              _fetchLocation();
            },
          ),
        LocationErrorType.permissionDeniedForever => (
            'Location permission is permanently denied. Please enable location permissions in device Settings.',
            'Open App Settings',
            Icons.settings,
            () async {
              await _locationHelper.openAppSettings();
              _fetchLocation();
            },
          ),
        LocationErrorType.permissionDenied => (
            'Location permission was denied. Location is mandatory to confirm on-site repair.',
            'Grant Permission',
            Icons.my_location,
            _fetchLocation,
          ),
        _ => (
            errorMsg ?? 'GPS coordinates are mandatory to mark an issue as Resolved.',
            'Turn On / Retry GPS',
            Icons.my_location,
            _fetchLocation,
          ),
      };

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.4), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_disabled_rounded, color: AppColors.errorText, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GPS Location Required to Resolve',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.errorText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        warningText,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: onPrimaryAction,
                  icon: Icon(primaryIcon, size: 14),
                  label: Text(
                    primaryBtnLabel,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.white,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    elevation: 0,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _fetchLocation,
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text(
                    'Retry',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorText,
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // State 4: GPS missing & status is NOT resolved (OPTIONAL)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.location_off_outlined, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'GPS location not acquired (optional for ${_selectedStatus.label})',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: _fetchLocation,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text(
              'Retry GPS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
