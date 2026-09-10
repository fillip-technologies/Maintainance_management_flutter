import '../models/issue_model.dart';

class BulkResolveState {
  final Set<String> selectedIssueIds;
  final IssueStatus targetStatus;
  final String selectedTypeFilter;
  final String searchQuery;
  final String notes;
  final bool isSubmitting;

  const BulkResolveState({
    this.selectedIssueIds = const {},
    this.targetStatus = IssueStatus.resolved,
    this.selectedTypeFilter = 'all',
    this.searchQuery = '',
    this.notes = '',
    this.isSubmitting = false,
  });

  int get selectedCount => selectedIssueIds.length;
  bool get isMaxLimitReached => selectedIssueIds.length >= 50;

  BulkResolveState copyWith({
    Set<String>? selectedIssueIds,
    IssueStatus? targetStatus,
    String? selectedTypeFilter,
    String? searchQuery,
    String? notes,
    bool? isSubmitting,
  }) {
    return BulkResolveState(
      selectedIssueIds: selectedIssueIds ?? this.selectedIssueIds,
      targetStatus: targetStatus ?? this.targetStatus,
      selectedTypeFilter: selectedTypeFilter ?? this.selectedTypeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      notes: notes ?? this.notes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
