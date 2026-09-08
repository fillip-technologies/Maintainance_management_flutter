// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:image_picker/image_picker.dart';
import '../../devices/devices.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../models/issue_model.dart';
import '../viewmodels/issue_action_viewmodel.dart';
import '../viewmodels/issue_query_viewmodel.dart';

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
      enableDrag: true,
      backgroundColor: Colors.transparent,
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
    _loadCategoriesForDevice(_selectedDevice);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoriesForDevice(DeviceModel? device) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isLoadingCategories = true;
      _categories = [];
      _selectedCategory = null;
    });

    try {
      final issueRepo = ref.read(issueRepositoryProvider);
      final categories = await issueRepo.getCategoriesForHardwareType(
        device?.hardwareTypeId,
        deviceId: device?.id,
      );
      if (mounted) {
        setState(() {
          _categories = categories;
          if (categories.isNotEmpty) {
            _selectedCategory = categories.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage =
            l10n?.raiseErrLoadCategories ?? 'Failed to load defect categories');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  // =========================================================================
  // CAMERA PROOF CAPTURE HELPERS (COMMENTED OUT FOR NOW)
  // =========================================================================
  // Future<void> _pickImage(ImageSource source) async {
  //   try {
  //     setState(() => _isPickingImage = true);
  //     final picked = await _picker.pickImage(
  //       source: source,
  //       imageQuality: 70,
  //       maxWidth: 1024,
  //     );
  //     if (picked != null) {
  //       setState(() => _attachedImage = File(picked.path));
  //     }
  //   } catch (e) {
  //     AppSnackbar.error('Failed to capture photo: $e');
  //   } finally {
  //     if (mounted) setState(() => _isPickingImage = false);
  //   }
  // }
  //
  // void _showImageSourceModal() {
  //   showModalBottomSheet(
  //     context: context,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (ctx) => SafeArea(
  //       child: Wrap(
  //         children: [
  //           ListTile(
  //             leading: const Icon(Icons.camera_alt, color: AppColors.primary),
  //             title: const Text('Take Defect Photo'),
  //             onTap: () {
  //               Navigator.pop(ctx);
  //               _pickImage(ImageSource.camera);
  //             },
  //           ),
  //           ListTile(
  //             leading: const Icon(Icons.photo_library, color: AppColors.primary),
  //             title: const Text('Choose from Gallery'),
  //             onTap: () {
  //               Navigator.pop(ctx);
  //               _pickImage(ImageSource.gallery);
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  // =========================================================================

  Future<void> _handleSubmit() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedDevice == null) {
      setState(() => _errorMessage = l10n?.raiseErrSelectEquipment ?? 'Please select a piece of equipment');
      return;
    }
    if (_selectedCategory == null) {
      setState(() => _errorMessage = l10n?.raiseErrSelectCategory ?? 'Please select what is wrong');
      return;
    }
    final desc = _descriptionController.text.trim();
    if (desc.isEmpty) {
      setState(() => _errorMessage = l10n?.raiseErrDescription ?? 'Please describe the problem');
      return;
    }

    final deviceName = _selectedDevice!.name;
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

        if (mounted) {
          Navigator.pop(context);
          AppSnackbar.success(l10n?.raiseSuccess(deviceName) ?? 'Ticket raised for $deviceName');
          widget.onIssueCreated?.call(newIssue);
        }
      } else {
        final err = ref.read(issueActionControllerProvider).errorMessage ??
            (l10n?.raiseErrGeneric ?? 'Failed to raise issue');
        setState(() => _errorMessage = err);
      }
    } catch (e) {
      setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.errorLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.report_problem_outlined, color: AppColors.errorText, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n?.raiseIssueTitle ?? 'Report a Problem',
                            style: const TextStyle(
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
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
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
                  Text(
                    l10n?.raiseSelectEquipment ?? 'Which equipment?',
                    style: const TextStyle(
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
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<DeviceModel>(
                        value: _selectedDevice,
                        isExpanded: true,
                        hint: Text(l10n?.raiseSelectUnitHint ?? 'Choose a unit'),
                        items: widget.devices.map((d) {
                          return DropdownMenuItem<DeviceModel>(
                            value: d,
                            child: Row(
                              children: [
                                Icon(
                                  HardwareIconHelper.getIcon(d.hardwareTypeName),
                                  size: 16,
                                  color: AppColors.icon,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${d.name} (${d.zoneName})',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                                  ),
                                ),
                              ],
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

                  // 2. Defect Category Selection — visual chip grid
                  Text(
                    l10n?.raiseDefectCategory ?? 'What is wrong?',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isLoadingCategories)
                    Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n?.raiseLoadingCategories ?? 'Loading types...',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    )
                  else if (_categories.isEmpty && _selectedDevice != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        l10n?.raiseNoCategoriesInfo ??
                            'No types listed — a general problem will be reported.',
                        style: const TextStyle(fontSize: 12, color: AppColors.warningText),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final selected = _selectedCategory?.id == cat.id;
                        return InkWell(
                          onTap: () => setState(() => _selectedCategory = cat),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected ? AppColors.primary : AppColors.border,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: selected ? AppColors.textWhite : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 14),

                  // 3. Priority Selector
                  Text(
                    l10n?.raisePriority ?? 'How urgent?',
                    style: const TextStyle(
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
                  Text(
                    l10n?.raiseDetails ?? 'Describe the problem',
                    style: const TextStyle(
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
                    decoration: InputDecoration(
                      hintText: l10n?.raiseDetailsHint ??
                          'What is happening? Any sounds, errors, damage...',
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Submit Button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.textWhite,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textWhite),
                            )
                          : Text(
                              l10n?.raiseSubmit ?? 'Send Ticket',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
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
}
