import '../../devices/devices.dart';
import '../models/issue_model.dart';
import '../repositories/issue_repository.dart';
import 'raise_bulk_issue_state.dart';

enum DeviceToggleResult {
  toggled,
  retired,
  limitReached,
}

class RaiseBulkIssueController {
  final void Function(RaiseBulkIssueState state) onStateChanged;

  RaiseBulkIssueState _state;
  RaiseBulkIssueState get state => _state;

  RaiseBulkIssueController({
    RaiseBulkIssueState initialState = const RaiseBulkIssueState(),
    required this.onStateChanged,
  }) : _state = initialState;

  void _update(RaiseBulkIssueState newState) {
    _state = newState;
    onStateChanged(_state);
  }

  Future<void> loadCategories(IssueRepository issueRepo) async {
    _update(_state.copyWith(
      isLoadingCategories: true,
      clearErrorMessage: true,
    ));

    try {
      final categories = await issueRepo.getCategoriesForHardwareType(null);
      _update(_state.copyWith(
        categories: categories,
        selectedCategory: categories.isNotEmpty ? categories.first : null,
        isLoadingCategories: false,
      ));
    } catch (e) {
      _update(_state.copyWith(
        isLoadingCategories: false,
        errorMessage: 'Failed to load defect categories: $e',
      ));
    }
  }

  DeviceToggleResult toggleDevice(DeviceModel device) {
    if (device.status == DeviceStatus.retired) {
      return DeviceToggleResult.retired;
    }

    final ids = Set<String>.from(_state.selectedDeviceIds);
    if (ids.contains(device.id)) {
      ids.remove(device.id);
      _update(_state.copyWith(
        selectedDeviceIds: ids,
        clearErrorMessage: true,
      ));
      return DeviceToggleResult.toggled;
    } else {
      if (ids.length >= 50) {
        return DeviceToggleResult.limitReached;
      }
      ids.add(device.id);
      _update(_state.copyWith(
        selectedDeviceIds: ids,
        clearErrorMessage: true,
      ));
      return DeviceToggleResult.toggled;
    }
  }

  void toggleGroupSelection(DeviceGroup group) {
    final nonRetired = group.devices.where((d) => d.status != DeviceStatus.retired).toList();
    final allSelected = nonRetired.isNotEmpty && nonRetired.every((d) => _state.selectedDeviceIds.contains(d.id));
    final ids = Set<String>.from(_state.selectedDeviceIds);

    if (allSelected) {
      for (final d in nonRetired) {
        ids.remove(d.id);
      }
    } else {
      for (final d in nonRetired) {
        if (!ids.contains(d.id)) {
          if (ids.length >= 50) {
            _update(_state.copyWith(
              selectedDeviceIds: ids,
              errorMessage: 'Maximum limit of 50 units reached for a single bulk ticket',
            ));
            return;
          }
          ids.add(d.id);
        }
      }
    }
    _update(_state.copyWith(
      selectedDeviceIds: ids,
      clearErrorMessage: true,
    ));
  }

  void toggleGroupCollapse(String groupName) {
    final collapsed = Set<String>.from(_state.collapsedGroupNames);
    if (collapsed.contains(groupName)) {
      collapsed.remove(groupName);
    } else {
      collapsed.add(groupName);
    }
    _update(_state.copyWith(collapsedGroupNames: collapsed));
  }

  void selectAllActive(List<DeviceModel> devices) {
    final active = devices
        .where((d) => d.status != DeviceStatus.retired)
        .take(50)
        .map((d) => d.id)
        .toSet();

    _update(_state.copyWith(
      selectedDeviceIds: active,
      clearErrorMessage: true,
    ));
  }

  void increaseGroupQuantity(DeviceGroup group) {
    final nonRetired = group.devices.where((d) => d.status != DeviceStatus.retired).toList();
    final unselected = nonRetired.where((d) => !_state.selectedDeviceIds.contains(d.id)).toList();
    if (unselected.isEmpty) return;

    if (_state.selectedDeviceIds.length >= 50) {
      _update(_state.copyWith(
        errorMessage: 'Maximum limit of 50 units reached for a single bulk ticket',
      ));
      return;
    }

    final ids = Set<String>.from(_state.selectedDeviceIds)..add(unselected.first.id);
    _update(_state.copyWith(
      selectedDeviceIds: ids,
      clearErrorMessage: true,
    ));
  }

  void decreaseGroupQuantity(DeviceGroup group) {
    final nonRetired = group.devices.where((d) => d.status != DeviceStatus.retired).toList();
    final selected = nonRetired.where((d) => _state.selectedDeviceIds.contains(d.id)).toList();
    if (selected.isEmpty) return;

    final ids = Set<String>.from(_state.selectedDeviceIds)..remove(selected.last.id);
    _update(_state.copyWith(
      selectedDeviceIds: ids,
      clearErrorMessage: true,
    ));
  }

  void clearSelection() {
    _update(_state.copyWith(
      selectedDeviceIds: const {},
      clearErrorMessage: true,
    ));
  }

  void setSelectedCategory(IssueCategoryModel? category) {
    _update(_state.copyWith(selectedCategory: category));
  }

  void setSelectedPriority(IssuePriority priority) {
    _update(_state.copyWith(selectedPriority: priority));
  }

  void setDescription(String description) {
    _update(_state.copyWith(description: description));
  }

  void setSearchQuery(String query) {
    _update(_state.copyWith(searchQuery: query));
  }

  void setSelectedHardwareType(String? type) {
    if (_state.selectedHardwareType == type) {
      _update(_state.copyWith(clearSelectedHardwareType: true));
    } else {
      _update(_state.copyWith(selectedHardwareType: type));
    }
  }

  void setErrorMessage(String? error) {
    if (error == null) {
      _update(_state.copyWith(clearErrorMessage: true));
    } else {
      _update(_state.copyWith(errorMessage: error));
    }
  }

  void setSubmitting(bool isSubmitting) {
    _update(_state.copyWith(isSubmitting: isSubmitting));
  }

  static List<String> extractHardwareTypes(List<DeviceModel> allDevices) {
    return allDevices
        .map((d) => d.hardwareTypeName.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  static List<DeviceModel> filterDevices({
    required List<DeviceModel> allDevices,
    required String? selectedHardwareType,
    required String searchQuery,
  }) {
    return allDevices.where((d) {
      if (selectedHardwareType != null && d.hardwareTypeName.trim() != selectedHardwareType) {
        return false;
      }
      if (searchQuery.isEmpty) return true;
      final query = searchQuery.toLowerCase();
      return d.name.toLowerCase().contains(query) ||
          d.serialNumber.toLowerCase().contains(query) ||
          d.hardwareTypeName.toLowerCase().contains(query) ||
          d.location.toLowerCase().contains(query);
    }).toList();
  }
}
