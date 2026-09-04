// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:image_picker/image_picker.dart';
import '../../../core/providers/device_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/device_model.dart';
import '../../../data/models/issue_model.dart';
// import '../../../l10n/app_localizations.dart';
import '../controller/issue_controller.dart';
import '../controller/issue_providers.dart';

class RaiseIssueSheet extends ConsumerStatefulWidget {
  final List<DeviceModel> devices;
  final DeviceModel? initialDevice;
  final Function(IssueModel newIssue)? onIssueCreated;

  const RaiseIssueSheet({
    super.key,
    required this.devices,
    this.initialDevice,
    this.onIssueCreated,
  });

  static Future<void> show(
    BuildContext context, {
    required List<DeviceModel> devices,
    DeviceModel? initialDevice,
    Function(IssueModel newIssue)? onIssueCreated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => RaiseIssueSheet(
        devices: devices,
        initialDevice: initialDevice,
        onIssueCreated: onIssueCreated,
      ),
    );
  }

  @override
  ConsumerState<RaiseIssueSheet> createState() => _RaiseIssueSheetState();
}

class _RaiseIssueSheetState extends ConsumerState<RaiseIssueSheet> {
  DeviceModel? _selectedDevice;
  IssueCategoryModel? _selectedCategory;
  List<IssueCategoryModel> _categories = [];
  bool _isLoadingCategories = false;
  bool _isSubmitting = false;

  IssuePriority _selectedPriority = IssuePriority.medium;
  final _descriptionController = TextEditingController();
  // =========================================================================
  // CAMERA PROOF CAPTURE (COMMENTED OUT FOR NOW - WILL BE ENABLED IN FUTURE)
  // =========================================================================
  // File? _attachedImage;
  // final ImagePicker _picker = ImagePicker();
  // bool _isPickingImage = false;
  // =========================================================================
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDevice = widget.initialDevice;
    if (_selectedDevice != null) {
      _loadCategoriesForDevice(_selectedDevice!);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoriesForDevice(DeviceModel device) async {
    setState(() {
      _isLoadingCategories = true;
      _categories = [];
      _selectedCategory = null;
    });

    try {
      final issueRepo = ref.read(issueRepositoryProvider);
      final categories = await issueRepo.getCategoriesForHardwareType(device.hardwareTypeId);
      if (mounted) {
        setState(() {
          _categories = categories;
          if (categories.isNotEmpty) {
            _selectedCategory = categories.first;
          }
        });
      }
    } catch (_) {
      // Empty fallback
    } finally {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  // =========================================================================
  // CAMERA PROOF CAPTURE (COMMENTED OUT FOR NOW - WILL BE ENABLED IN FUTURE)
  // =========================================================================
  // Future<void> _pickImage(ImageSource source) async {
  //   Navigator.pop(context);
  //   setState(() => _isPickingImage = true);
  //   try {
  //     final XFile? pickedFile = await _picker.pickImage(
  //       source: source,
  //       maxWidth: 1800,
  //       maxHeight: 1800,
  //       imageQuality: 85,
  //     );
  //     if (pickedFile != null) {
  //       setState(() {
  //         _attachedImage = File(pickedFile.path);
  //       });
  //     }
  //   } catch (e) {
  //     AppSnackbar.error('Failed to capture photo: $e');
  //   } finally {
  //     if (mounted) {
  //       setState(() => _isPickingImage = false);
  //     }
  //   }
  // }
  //
  // void _showImageSourceModal() {
  //   ...
  // }
  // =========================================================================

  Future<void> _handleSubmit() async {
    if (_selectedDevice == null) {
      setState(() => _errorMessage = 'Please select a piece of equipment');
      return;
    }
    if (_selectedCategory == null) {
      setState(() => _errorMessage = 'Please select an issue defect category');
      return;
    }
    final desc = _descriptionController.text.trim();
    if (desc.isEmpty) {
      setState(() => _errorMessage = 'Please provide a clear description of the defect');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final newIssue = await ref.read(issueActionControllerProvider.notifier).createIssue(
            deviceId: _selectedDevice!.id,
            categoryId: _selectedCategory!.id,
            priority: _selectedPriority,
            description: desc,
          );

      if (newIssue != null) {
        ref.invalidate(staffDevicesProvider);
        ref.invalidate(staffDashboardSummaryProvider);

        if (mounted) {
          Navigator.pop(context);
          AppSnackbar.success('Defect ticket raised successfully for ${_selectedDevice!.name}');
          widget.onIssueCreated?.call(newIssue);
        }
      } else {
        final err = ref.read(issueActionControllerProvider).errorMessage ?? 'Failed to raise issue';
        setState(() => _errorMessage = err);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                const Row(
                  children: [
                    Icon(Icons.report_problem_outlined, color: AppColors.error, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Raise Equipment Defect',
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
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.errorText, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 13, color: AppColors.errorText),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 1. Device Selection Dropdown
            const Text(
              'Equipment Unit',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<DeviceModel>(
                  value: _selectedDevice,
                  isExpanded: true,
                  hint: const Text('Select Equipment Unit'),
                  items: widget.devices.map((device) {
                    return DropdownMenuItem<DeviceModel>(
                      value: device,
                      child: Text(
                        '${device.name} (${device.location.isNotEmpty ? device.location : "No Location"})',
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (DeviceModel? newDevice) {
                    if (newDevice != null) {
                      setState(() {
                        _selectedDevice = newDevice;
                      });
                      _loadCategoriesForDevice(newDevice);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 2. Defect Category Selection
            const Text(
              'Defect Category',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            if (_isLoadingCategories)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Loading categories...',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            else if (_categories.isEmpty && _selectedDevice != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'No categories defined for this hardware. General failure will be reported.',
                  style: TextStyle(fontSize: 12, color: AppColors.warningText),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<IssueCategoryModel>(
                    value: _selectedCategory,
                    isExpanded: true,
                    hint: const Text('Select Defect Type'),
                    items: _categories.map((cat) {
                      return DropdownMenuItem<IssueCategoryModel>(
                        value: cat,
                        child: Text(
                          cat.name,
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (IssueCategoryModel? newCat) {
                      setState(() {
                        _selectedCategory = newCat;
                      });
                    },
                  ),
                ),
              ),
            const SizedBox(height: 14),

            // 3. Priority Selector
            const Text(
              'Severity / Priority',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: IssuePriority.values.map((priority) {
                final isSelected = _selectedPriority == priority;
                final (bg, textCol) = switch (priority) {
                  IssuePriority.critical => isSelected
                      ? (AppColors.error, AppColors.textWhite)
                      : (AppColors.errorLight, AppColors.errorText),
                  IssuePriority.high => isSelected
                      ? (AppColors.warning, AppColors.textWhite)
                      : (AppColors.warningLight, AppColors.warningText),
                  IssuePriority.medium => isSelected
                      ? (AppColors.info, AppColors.textWhite)
                      : (AppColors.infoLight, AppColors.infoText),
                  IssuePriority.low => isSelected
                      ? (AppColors.primary, AppColors.textWhite)
                      : (AppColors.surface, AppColors.textSecondary),
                };

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => setState(() => _selectedPriority = priority),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.transparent : AppColors.border,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          priority.localized(context),
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
            const SizedBox(height: 14),

            // 4. Description Field
            const Text(
              'Defect Details & Symptoms',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Describe the symptoms, error codes, physical damage...',
              ),
            ),
            const SizedBox(height: 14),

            // =========================================================================
            // CAMERA PROOF CAPTURE (COMMENTED OUT FOR NOW - WILL BE ENABLED IN FUTURE)
            // =========================================================================
            // const Text(
            //   'Proof Photo (Optional)',
            //   style: TextStyle(
            //     fontSize: 13,
            //     fontWeight: FontWeight.w600,
            //     color: AppColors.textSecondary,
            //   ),
            // ),
            // const SizedBox(height: 8),
            // ... (Camera / Gallery Picker)
            // =========================================================================

            const SizedBox(height: 22),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.textWhite,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textWhite),
                    )
                  : const Text('Submit & Raise Maintenance Ticket'),
            ),
          ],
        ),
      ),
    );
  }
}
