import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../devices/devices.dart';
import '../models/issue_model.dart';
import '../viewmodels/issue_action_viewmodel.dart';
import '../viewmodels/issue_query_viewmodel.dart';

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
      backgroundColor: Colors.transparent,
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
  final Set<String> _selectedDeviceIds = {};
  IssueCategoryModel? _selectedCategory;
  List<IssueCategoryModel> _categories = [];
  bool _isLoadingCategories = false;
  bool _isSubmitting = false;

  IssuePriority _selectedPriority = IssuePriority.medium;
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedHardwareType;
  final Set<String> _collapsedGroupNames = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _errorMessage = null;
    });

    try {
      final issueRepo = ref.read(issueRepositoryProvider);
      final categories = await issueRepo.getCategoriesForHardwareType(null);
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
        final l10n = AppLocalizations.of(context);
        setState(() => _errorMessage = l10n?.errFailedToLoadCategories ?? 'Failed to load defect categories');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  void _toggleDevice(DeviceModel device) {
    final l10n = AppLocalizations.of(context);
    if (device.status == DeviceStatus.retired) {
      AppSnackbar.warning(l10n?.errRetiredUnitSelected ?? 'Cannot raise defects on retired equipment');
      return;
    }

    setState(() {
      _errorMessage = null;
      if (_selectedDeviceIds.contains(device.id)) {
        _selectedDeviceIds.remove(device.id);
      } else {
        if (_selectedDeviceIds.length >= 50) {
          _errorMessage = l10n?.errMaxUnitsLimit ?? 'Maximum limit of 50 units reached for a single bulk ticket';
          return;
        }
        _selectedDeviceIds.add(device.id);
      }
    });
  }

  void _toggleGroupSelection(DeviceGroup group) {
    final l10n = AppLocalizations.of(context);
    final nonRetired = group.devices.where((d) => d.status != DeviceStatus.retired).toList();
    final allSelected = nonRetired.isNotEmpty && nonRetired.every((d) => _selectedDeviceIds.contains(d.id));

    setState(() {
      _errorMessage = null;
      if (allSelected) {
        for (final d in nonRetired) {
          _selectedDeviceIds.remove(d.id);
        }
      } else {
        for (final d in nonRetired) {
          if (!_selectedDeviceIds.contains(d.id)) {
            if (_selectedDeviceIds.length >= 50) {
              _errorMessage = l10n?.errMaxUnitsLimit ?? 'Maximum limit of 50 units reached for a single bulk ticket';
              break;
            }
            _selectedDeviceIds.add(d.id);
          }
        }
      }
    });
  }

  void _toggleGroupCollapse(String groupName) {
    setState(() {
      if (_collapsedGroupNames.contains(groupName)) {
        _collapsedGroupNames.remove(groupName);
      } else {
        _collapsedGroupNames.add(groupName);
      }
    });
  }

  void _selectAllActive(List<DeviceModel> devices) {
    final active = devices
        .where((d) => d.status != DeviceStatus.retired)
        .take(50)
        .map((d) => d.id);

    setState(() {
      _errorMessage = null;
      _selectedDeviceIds.clear();
      _selectedDeviceIds.addAll(active);
    });
  }

  void _increaseGroupQuantity(DeviceGroup group) {
    final l10n = AppLocalizations.of(context);
    final nonRetired = group.devices.where((d) => d.status != DeviceStatus.retired).toList();
    final unselected = nonRetired.where((d) => !_selectedDeviceIds.contains(d.id)).toList();
    if (unselected.isEmpty) return;

    if (_selectedDeviceIds.length >= 50) {
      setState(() => _errorMessage = l10n?.errMaxUnitsLimit ?? 'Maximum limit of 50 units reached for a single bulk ticket');
      return;
    }

    setState(() {
      _errorMessage = null;
      _selectedDeviceIds.add(unselected.first.id);
    });
  }

  void _decreaseGroupQuantity(DeviceGroup group) {
    final nonRetired = group.devices.where((d) => d.status != DeviceStatus.retired).toList();
    final selected = nonRetired.where((d) => _selectedDeviceIds.contains(d.id)).toList();
    if (selected.isEmpty) return;

    setState(() {
      _errorMessage = null;
      _selectedDeviceIds.remove(selected.last.id);
    });
  }

  void _clearSelection() {
    setState(() {
      _errorMessage = null;
      _selectedDeviceIds.clear();
    });
  }

  Future<void> _handleSubmit() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedDeviceIds.isEmpty) {
      setState(() => _errorMessage = l10n?.errSelectAtLeastOneUnit ?? 'Please select at least 1 equipment unit');
      return;
    }
    if (_selectedDeviceIds.length > 50) {
      setState(() => _errorMessage = l10n?.errMaxUnitsLimit ?? 'Cannot select more than 50 units at once');
      return;
    }
    if (_selectedCategory == null) {
      setState(() => _errorMessage = l10n?.errSelectCategory ?? 'Please select a defect category');
      return;
    }
    final desc = _descriptionController.text.trim();
    if (desc.isEmpty) {
      setState(() => _errorMessage = l10n?.errProvideDescription ?? 'Please provide a clear description of the defect');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final allDevices = widget.devices ?? ref.read(staffDevicesProvider).value ?? [];
      final selectedDevices = allDevices.where((d) => _selectedDeviceIds.contains(d.id)).toList();
      final productNames = selectedDevices
          .map((d) => d.hardwareTypeName.trim())
          .where((n) => n.isNotEmpty)
          .toSet()
          .join(', ');
      final effectiveProductName = productNames.isNotEmpty ? productNames : 'Equipment';
      final unitsCount = _selectedDeviceIds.length;
      final categoryLabel = _selectedCategory?.name ?? '';
      final header = [
        'Product: $effectiveProductName · Units affected: $unitsCount',
        if (categoryLabel.isNotEmpty) 'Defect type: $categoryLabel',
      ].join('\n');
      final fullDescription = '$header\n$desc';

      final newIssues = await ref.read(issueActionControllerProvider.notifier).createBulkIssues(
            deviceIds: _selectedDeviceIds.toList(),
            categoryId: _selectedCategory!.id,
            priority: _selectedPriority,
            description: fullDescription,
          );

      if (newIssues != null && newIssues.isNotEmpty) {
        ref.invalidate(staffDevicesProvider);
        ref.invalidate(staffDashboardSummaryProvider);

        if (mounted) {
          Navigator.pop(context, newIssues);
          AppSnackbar.success(l10n?.bulkDefectSuccessMsg(newIssues.length) ?? '${newIssues.length} bulk defect tickets raised successfully');
          widget.onIssuesCreated?.call(newIssues);
        }
      } else {
        final err = ref.read(issueActionControllerProvider).errorMessage ?? l10n?.errFailedToRaiseBulk ?? 'Failed to raise bulk issues';
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
    final l10n = AppLocalizations.of(context);
    final allDevices = widget.devices ?? ref.watch(staffDevicesProvider).value ?? [];
    final allHardwareTypes = allDevices
        .map((d) => d.hardwareTypeName.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final filteredDevices = allDevices.where((d) {
      if (_selectedHardwareType != null && d.hardwareTypeName.trim() != _selectedHardwareType) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return d.name.toLowerCase().contains(query) ||
          d.serialNumber.toLowerCase().contains(query) ||
          d.hardwareTypeName.toLowerCase().contains(query) ||
          d.location.toLowerCase().contains(query);
    }).toList();

    final groups = DeviceGroup.fromDevices(filteredDevices);

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
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.errorLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.playlist_add_rounded,
                              color: AppColors.errorText,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.raiseBulkDefectTitle ?? 'Raise Bulk Defect',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n?.raiseBulkDefectSubtitle ?? 'Report identical issue on multiple units (1–50)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
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
                  const SizedBox(height: 10),

                  // Error Banner
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

                  // 1. Equipment Selection Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n?.selectEquipmentUnits(_selectedDeviceIds.length) ??
                            'Select Equipment (${_selectedDeviceIds.length}/50)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: allDevices.isEmpty
                                ? null
                                : () => _selectAllActive(allDevices),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              l10n?.selectAll ?? 'Select All',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _selectedDeviceIds.isEmpty ? null : _clearSelection,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: AppColors.textSecondary,
                            ),
                            child: Text(
                              l10n?.clearSelection ?? 'Clear',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Search Filter
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: l10n?.searchUnitsHint ?? 'Search unit by name, serial number or type...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.icon),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),

                  // Hardware Type Horizontal Filter Chips
                  if (allHardwareTypes.length > 1) ...[
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTypeChip(
                            label: l10n?.allTypes ?? 'All Types',
                            count: allDevices.length,
                            isSelected: _selectedHardwareType == null,
                            onTap: () => setState(() => _selectedHardwareType = null),
                          ),
                          ...allHardwareTypes.map((type) {
                            final typeCount = allDevices.where((d) => d.hardwareTypeName.trim() == type).length;
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: _buildTypeChip(
                                label: type,
                                count: typeCount,
                                isSelected: _selectedHardwareType == type,
                                onTap: () => setState(() {
                                  if (_selectedHardwareType == type) {
                                    _selectedHardwareType = null;
                                  } else {
                                    _selectedHardwareType = type;
                                  }
                                }),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),

                  // Devices Scrollable List Grouped by Type
                  Container(
                    height: 240,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: filteredDevices.isEmpty
                        ? Center(
                            child: Text(
                              l10n?.noMatchingUnits ?? 'No matching equipment units found',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            itemCount: groups.length,
                            itemBuilder: (context, groupIdx) {
                              final group = groups[groupIdx];
                              final nonRetired = group.devices.where((d) => d.status != DeviceStatus.retired).toList();
                              final selectedInGroup = group.devices.where((d) => _selectedDeviceIds.contains(d.id)).length;
                              final allGroupSelected = nonRetired.isNotEmpty && nonRetired.every((d) => _selectedDeviceIds.contains(d.id));
                              final isExpanded = _searchQuery.isNotEmpty || !_collapsedGroupNames.contains(group.hardwareTypeName);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedInGroup > 0
                                        ? AppColors.primary.withValues(alpha: 0.4)
                                        : AppColors.border,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Group Header Row
                                    InkWell(
                                      onTap: () => _toggleGroupCollapse(group.hardwareTypeName),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        child: Row(
                                          children: [
                                            Icon(
                                              HardwareIconHelper.getIcon(group.hardwareTypeName),
                                              size: 18,
                                              color: selectedInGroup > 0 ? AppColors.primary : AppColors.icon,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      group.hardwareTypeName,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.textPrimary,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: AppColors.background,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: selectedInGroup > 0
                                                      ? AppColors.primary.withValues(alpha: 0.5)
                                                      : AppColors.border,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  InkWell(
                                                    onTap: selectedInGroup > 0
                                                        ? () => _decreaseGroupQuantity(group)
                                                        : null,
                                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                                      child: Icon(
                                                        Icons.remove,
                                                        size: 13,
                                                        color: selectedInGroup > 0 ? AppColors.textPrimary : AppColors.iconLight,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    color: AppColors.surface,
                                                    child: Text(
                                                      '$selectedInGroup/${nonRetired.length}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: selectedInGroup > 0 ? AppColors.primary : AppColors.textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                  InkWell(
                                                    onTap: (selectedInGroup < nonRetired.length && _selectedDeviceIds.length < 50)
                                                        ? () => _increaseGroupQuantity(group)
                                                        : null,
                                                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                                      child: Icon(
                                                        Icons.add,
                                                        size: 13,
                                                        color: (selectedInGroup < nonRetired.length && _selectedDeviceIds.length < 50)
                                                            ? AppColors.primary
                                                            : AppColors.iconLight,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            TextButton(
                                              onPressed: nonRetired.isEmpty ? null : () => _toggleGroupSelection(group),
                                              style: TextButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                foregroundColor: allGroupSelected ? AppColors.textSecondary : AppColors.primary,
                                              ),
                                              child: Text(
                                                allGroupSelected
                                                    ? (l10n?.deselectGroup ?? 'Deselect')
                                                    : (l10n?.selectAllInGroup ?? 'Select Group'),
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                              size: 20,
                                              color: AppColors.icon,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Units inside group
                                    if (isExpanded) ...[
                                      const Divider(height: 1, color: AppColors.divider),
                                      ...group.devices.map((device) {
                                        final isSelected = _selectedDeviceIds.contains(device.id);
                                        final isRetired = device.status == DeviceStatus.retired;

                                        return Material(
                                          color: isSelected ? AppColors.primaryBg.withValues(alpha: 0.25) : Colors.transparent,
                                          child: InkWell(
                                            onTap: isRetired ? null : () => _toggleDevice(device),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              child: Row(
                                                children: [
                                                  Checkbox(
                                                    value: isSelected,
                                                    activeColor: AppColors.primary,
                                                    onChanged: isRetired ? null : (_) => _toggleDevice(device),
                                                    visualDensity: VisualDensity.compact,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          device.name,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w600,
                                                            color: isRetired ? AppColors.textMuted : AppColors.textPrimary,
                                                            decoration: isRetired ? TextDecoration.lineThrough : null,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        Text(
                                                          device.serialNumber.isNotEmpty
                                                              ? '${device.serialNumber} • ${device.location}'
                                                              : device.location,
                                                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  StatusBadge.device(device.status),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Defect Category Selection
                  Text(
                    l10n?.defectCategory ?? 'Defect Category',
                    style: const TextStyle(
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
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n?.loadingCategories ?? 'Loading defect categories...',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  else if (_categories.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        l10n?.noCategoriesFound ?? 'No defect categories found. Please contact an administrator.',
                        style: const TextStyle(fontSize: 12, color: AppColors.warningText),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<IssueCategoryModel>(
                          value: _selectedCategory,
                          isExpanded: true,
                          hint: Text(l10n?.selectCategoryHint ?? 'Select Defect Category'),
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
                  Text(
                    l10n?.severityPriority ?? 'Severity / Priority',
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

                  // 4. Shared Description Field
                  Text(
                    l10n?.bulkDefectDescriptionLabel ?? 'Defect Description & Shared Symptoms',
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
                      hintText: l10n?.bulkDefectDescriptionHint ?? 'Describe common symptoms, power failure, batch damage, network outage...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
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
                      onPressed: (_isSubmitting || _selectedDeviceIds.isEmpty) ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.textWhite,
                        elevation: 1,
                        disabledBackgroundColor: AppColors.error.withValues(alpha: 0.4),
                        disabledForegroundColor: AppColors.textWhite.withValues(alpha: 0.7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSubmitting
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textWhite),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  l10n?.submittingBulkDefect ?? 'Raising Defects...',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          : Text(
                              _selectedDeviceIds.isEmpty
                                  ? (l10n?.btnSelectUnitsFirst ?? 'Select Units Above to Report Defect')
                                  : (l10n?.btnRaiseBulkDefect(_selectedDeviceIds.length) ??
                                      'Raise Defect Ticket on ${_selectedDeviceIds.length} Unit(s)'),
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

  Widget _buildTypeChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBg : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.textWhite : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
