import 'package:equipment_management_system/features/issues/models/issue_model.dart';

class RaiseBulkIssueState {
  final Set<String> selectedDeviceIds;
  final IssueCategoryModel? selectedCategory;
  final List<IssueCategoryModel> categories;
  final bool isLoadingCategories;
  final bool isSubmitting;
  final IssuePriority selectedPriority;
  final String description;
  final String searchQuery;
  final String? selectedHardwareType;
  final Set<String> collapsedGroupNames;
  final String? errorMessage;

  const RaiseBulkIssueState({
    this.selectedDeviceIds = const {},
    this.selectedCategory,
    this.categories = const [],
    this.isLoadingCategories = false,
    this.isSubmitting = false,
    this.selectedPriority = IssuePriority.medium,
    this.description = '',
    this.searchQuery = '',
    this.selectedHardwareType,
    this.collapsedGroupNames = const {},
    this.errorMessage,
  });

  int get selectedCount => selectedDeviceIds.length;
  bool get isMaxLimitReached => selectedDeviceIds.length >= 50;

  RaiseBulkIssueState copyWith({
    Set<String>? selectedDeviceIds,
    IssueCategoryModel? selectedCategory,
    bool clearSelectedCategory = false,
    List<IssueCategoryModel>? categories,
    bool? isLoadingCategories,
    bool? isSubmitting,
    IssuePriority? selectedPriority,
    String? description,
    String? searchQuery,
    String? selectedHardwareType,
    bool clearSelectedHardwareType = false,
    Set<String>? collapsedGroupNames,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return RaiseBulkIssueState(
      selectedDeviceIds: selectedDeviceIds ?? this.selectedDeviceIds,
      selectedCategory: clearSelectedCategory ? null : (selectedCategory ?? this.selectedCategory),
      categories: categories ?? this.categories,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      selectedPriority: selectedPriority ?? this.selectedPriority,
      description: description ?? this.description,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedHardwareType: clearSelectedHardwareType ? null : (selectedHardwareType ?? this.selectedHardwareType),
      collapsedGroupNames: collapsedGroupNames ?? this.collapsedGroupNames,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
