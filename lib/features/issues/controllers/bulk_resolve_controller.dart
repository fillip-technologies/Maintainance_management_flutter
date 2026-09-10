import 'package:equipment_management_system/features/issues/models/issue_model.dart';
import 'package:equipment_management_system/features/location/location_helper.dart';
import 'bulk_resolve_state.dart';

class BulkResolveController {
  final LocationHelper locationHelper;
  final void Function(BulkResolveState state) onStateChanged;

  BulkResolveState _state;
  BulkResolveState get state => _state;

  BulkResolveController({
    LocationHelper? locationHelper,
    BulkResolveState initialState = const BulkResolveState(),
    required this.onStateChanged,
  })  : locationHelper = locationHelper ?? LocationHelper(),
        _state = initialState;

  void _update(BulkResolveState newState) {
    _state = newState;
    onStateChanged(_state);
  }

  bool toggleIssue(String issueId) {
    final ids = Set<String>.from(_state.selectedIssueIds);
    if (ids.contains(issueId)) {
      ids.remove(issueId);
      _update(_state.copyWith(selectedIssueIds: ids));
      return true;
    } else {
      if (ids.length >= 50) {
        return false; // Max limit reached
      }
      ids.add(issueId);
      _update(_state.copyWith(selectedIssueIds: ids));
      return true;
    }
  }

  void toggleGroup(List<IssueModel> groupIssues) {
    final groupIds = groupIssues.map((e) => e.id).toSet();
    final allSelected = groupIds.every(_state.selectedIssueIds.contains);
    final ids = Set<String>.from(_state.selectedIssueIds);

    if (allSelected) {
      ids.removeAll(groupIds);
    } else {
      for (final id in groupIds) {
        if (ids.length >= 50) break;
        ids.add(id);
      }
    }
    _update(_state.copyWith(selectedIssueIds: ids));
  }

  void selectAll(List<IssueModel> issues) {
    final ids = <String>{};
    for (final issue in issues) {
      if (ids.length >= 50) break;
      ids.add(issue.id);
    }
    _update(_state.copyWith(selectedIssueIds: ids));
  }

  void clearSelection() {
    _update(_state.copyWith(selectedIssueIds: const {}));
  }

  void setTargetStatus(IssueStatus status) {
    _update(_state.copyWith(targetStatus: status));
  }

  void setSelectedTypeFilter(String filter) {
    _update(_state.copyWith(selectedTypeFilter: filter));
  }

  void setSearchQuery(String query) {
    _update(_state.copyWith(searchQuery: query));
  }

  void setNotes(String notes) {
    _update(_state.copyWith(notes: notes));
  }

  void setSubmitting(bool isSubmitting) {
    _update(_state.copyWith(isSubmitting: isSubmitting));
  }

  static List<IssueModel> filterIssues({
    required List<IssueModel> candidateIssues,
    required String selectedTypeFilter,
    required String searchQuery,
  }) {
    var filtered = candidateIssues;
    if (selectedTypeFilter != 'all') {
      filtered = filtered.where((i) {
        final typeName = i.categoryName.isNotEmpty ? i.categoryName : i.deviceName;
        return typeName.toLowerCase() == selectedTypeFilter.toLowerCase();
      }).toList();
    }

    final query = searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((i) {
        return i.id.toLowerCase().contains(query) ||
            i.deviceName.toLowerCase().contains(query) ||
            i.categoryName.toLowerCase().contains(query) ||
            i.zoneName.toLowerCase().contains(query) ||
            i.displayDescription.toLowerCase().contains(query);
      }).toList();
    }
    return filtered;
  }

  static Set<String> extractAvailableTypes(List<IssueModel> candidateIssues) {
    final types = <String>{};
    for (final issue in candidateIssues) {
      final name = issue.categoryName.isNotEmpty ? issue.categoryName : issue.deviceName;
      if (name.isNotEmpty) types.add(name);
    }
    return types;
  }

  static Map<String, List<IssueModel>> groupIssues(List<IssueModel> filteredIssues) {
    final grouped = <String, List<IssueModel>>{};
    for (final issue in filteredIssues) {
      final groupKey = issue.categoryName.isNotEmpty ? issue.categoryName : issue.deviceName;
      grouped.putIfAbsent(groupKey, () => []).add(issue);
    }
    return grouped;
  }
}
