import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equipment_management_system/core/theme/colors.dart';
import 'package:equipment_management_system/core/utils/app_snackbar.dart';
import 'package:equipment_management_system/features/devices/devices.dart';
import 'package:equipment_management_system/l10n/app_localizations.dart';
import '../controllers/raise_bulk_issue_controller.dart';
import '../controllers/raise_bulk_issue_state.dart';
import '../models/issue_model.dart';
import '../viewmodels/issue_action_viewmodel.dart';
import '../viewmodels/issue_query_viewmodel.dart';
import 'widgets/raise_bulk/raise_bulk_category_dropdown.dart';
import 'widgets/raise_bulk/raise_bulk_device_selector.dart';
import 'widgets/raise_bulk/raise_bulk_header.dart';
import 'widgets/raise_bulk/raise_bulk_priority_selector.dart';
import 'widgets/raise_bulk/raise_bulk_submit_button.dart';

/// Modal bottom sheet that enables staff members to select multiple equipment units
/// (from 1 up to 50) and submit an identical defect ticket in a single request
/// using the backend `POST /api/v1/issues/bulk` endpoint.
class RaiseBulkIssueSheet extends ConsumerStatefulWidget {
  final List<DeviceModel>? devices;
  final Function(List<IssueModel> newIssues)? onIssuesCreated;

  const RaiseBulkIssueSheet({
    super.key,
    this.devices,
    this.onIssuesCreated,
  });

  /// Displays the [RaiseBulkIssueSheet] modal bottom sheet.
  static Future<List<IssueModel>?> show(
    BuildContext context, {
    List<DeviceModel>? devices,
    Function(List<IssueModel> newIssues)? onIssuesCreated,
  }) {
    return showModalBottomSheet<List<IssueModel>>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => RaiseBulkIssueSheet(
        devices: devices,
        onIssuesCreated: onIssuesCreated,
      ),
    );
  }

  @override
  ConsumerState<RaiseBulkIssueSheet> createState() => _RaiseBulkIssueSheetState();
}

class _RaiseBulkIssueSheetState extends ConsumerState<RaiseBulkIssueSheet> {
  late final RaiseBulkIssueController _controller;
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = RaiseBulkIssueController(
      onStateChanged: _onStateChanged,
    );
    _descriptionController.addListener(() {
      _controller.setDescription(_descriptionController.text);
    });
    _controller.loadCategories(ref.read(issueRepositoryProvider));
  }

  void _onStateChanged(RaiseBulkIssueState state) {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleDevice(DeviceModel device) {
    final res = _controller.toggleDevice(device);
    final l10n = AppLocalizations.of(context);
    if (res == DeviceToggleResult.retired) {
      AppSnackbar.warning(l10n?.errRetiredUnitSelected ?? 'Cannot raise defects on retired equipment');
    } else if (res == DeviceToggleResult.limitReached) {
      _controller.setErrorMessage(l10n?.errMaxUnitsLimit ?? 'Maximum limit of 50 units reached for a single bulk ticket');
    }
  }

  void _increaseGroupQuantity(DeviceGroup group) {
    if (_controller.state.selectedDeviceIds.length >= 50) {
      final l10n = AppLocalizations.of(context);
      _controller.setErrorMessage(l10n?.errMaxUnitsLimit ?? 'Maximum limit of 50 units reached for a single bulk ticket');
      return;
    }
    _controller.increaseGroupQuantity(group);
  }

  Future<void> _handleSubmit() async {
    final l10n = AppLocalizations.of(context);
    final state = _controller.state;

    if (state.selectedDeviceIds.isEmpty) {
      _controller.setErrorMessage(l10n?.errSelectAtLeastOneUnit ?? 'Please select at least 1 equipment unit');
      return;
    }
    if (state.selectedDeviceIds.length > 50) {
      _controller.setErrorMessage(l10n?.errMaxUnitsLimit ?? 'Cannot select more than 50 units at once');
      return;
    }
    if (state.selectedCategory == null) {
      _controller.setErrorMessage(l10n?.errSelectCategory ?? 'Please select a defect category');
      return;
    }
    final desc = _descriptionController.text.trim();
    if (desc.isEmpty) {
      _controller.setErrorMessage(l10n?.errProvideDescription ?? 'Please provide a clear description of the defect');
      return;
    }

    _controller.setSubmitting(true);
    _controller.setErrorMessage(null);

    try {
      final allDevices = widget.devices ?? ref.read(staffDevicesProvider).value ?? [];
      final selectedDevices = allDevices.where((d) => state.selectedDeviceIds.contains(d.id)).toList();
      final productNames = selectedDevices
          .map((d) => d.hardwareTypeName.trim())
          .where((n) => n.isNotEmpty)
          .toSet()
          .join(', ');
      final effectiveProductName = productNames.isNotEmpty ? productNames : 'Equipment';
      final unitsCount = state.selectedDeviceIds.length;
      final categoryLabel = state.selectedCategory?.name ?? '';
      final header = [
        'Product: $effectiveProductName · Units affected: $unitsCount',
        if (categoryLabel.isNotEmpty) 'Defect type: $categoryLabel',
      ].join('\n');
      final fullDescription = '$header\n$desc';

      final newIssues = await ref.read(issueActionControllerProvider.notifier).createBulkIssues(
            deviceIds: state.selectedDeviceIds.toList(),
            categoryId: state.selectedCategory!.id,
            priority: state.selectedPriority,
            description: fullDescription,
          );

      if (newIssues != null && newIssues.isNotEmpty) {
        ref.invalidate(staffDevicesProvider);

        if (mounted) {
          Navigator.pop(context, newIssues);
          AppSnackbar.success(l10n?.bulkDefectSuccessMsg(newIssues.length) ?? '${newIssues.length} bulk defect tickets raised successfully');
          widget.onIssuesCreated?.call(newIssues);
        }
      } else {
        final err = ref.read(issueActionControllerProvider).errorMessage ?? l10n?.errFailedToRaiseBulk ?? 'Failed to raise bulk issues';
        _controller.setErrorMessage(err);
      }
    } catch (e) {
      _controller.setErrorMessage('Error: $e');
    } finally {
      if (mounted) {
        _controller.setSubmitting(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final allDevices = widget.devices ?? ref.watch(staffDevicesProvider).value ?? [];
    final allHardwareTypes = RaiseBulkIssueController.extractHardwareTypes(allDevices);

    final filteredDevices = RaiseBulkIssueController.filterDevices(
      allDevices: allDevices,
      selectedHardwareType: state.selectedHardwareType,
      searchQuery: state.searchQuery,
    );

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
          // Drag Handle
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
          const SizedBox(height: 8),

          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 4,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RaiseBulkHeader(
                    onClose: () => Navigator.pop(context),
                  ),
                  Divider(color: AppColors.divider),
                  const SizedBox(height: 10),

                  // Error Banner
                  if (state.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: AppColors.errorText, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: TextStyle(fontSize: 13, color: AppColors.errorText),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 1. Equipment Selection Section
                  RaiseBulkDeviceSelector(
                    allDevices: allDevices,
                    filteredDevices: filteredDevices,
                    allHardwareTypes: allHardwareTypes,
                    selectedDeviceIds: state.selectedDeviceIds,
                    selectedHardwareType: state.selectedHardwareType,
                    collapsedGroupNames: state.collapsedGroupNames,
                    searchController: _searchController,
                    searchQuery: state.searchQuery,
                    onSearchChanged: (val) {
                      _controller.setSearchQuery(val.trim());
                    },
                    onClearSearch: () {
                      _searchController.clear();
                      _controller.setSearchQuery('');
                    },
                    onHardwareTypeSelected: _controller.setSelectedHardwareType,
                    onSelectAll: () => _controller.selectAllActive(allDevices),
                    onClearSelection: _controller.clearSelection,
                    onToggleDevice: _toggleDevice,
                    onToggleGroupSelection: _controller.toggleGroupSelection,
                    onToggleGroupCollapse: _controller.toggleGroupCollapse,
                    onIncreaseGroupQuantity: _increaseGroupQuantity,
                    onDecreaseGroupQuantity: _controller.decreaseGroupQuantity,
                  ),

                  const SizedBox(height: 14),

                  // 2. Defect Category Selection
                  RaiseBulkCategoryDropdown(
                    isLoading: state.isLoadingCategories,
                    categories: state.categories,
                    selectedCategory: state.selectedCategory,
                    onCategoryChanged: _controller.setSelectedCategory,
                  ),

                  const SizedBox(height: 14),

                  // 3. Priority Selector
                  RaiseBulkPrioritySelector(
                    selectedPriority: state.selectedPriority,
                    onPriorityChanged: _controller.setSelectedPriority,
                  ),

                  const SizedBox(height: 14),

                  // 4. Shared Description Field
                  Text(
                    AppLocalizations.of(context)?.bulkDefectDescriptionLabel ?? 'Defect Description & Shared Symptoms',
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
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)?.bulkDefectDescriptionHint ?? 'Describe common symptoms, power failure, batch damage, network outage...',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Submit Button
                  RaiseBulkSubmitButton(
                    isSubmitting: state.isSubmitting,
                    selectedCount: state.selectedCount,
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
