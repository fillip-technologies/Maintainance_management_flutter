import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../issues/issues.dart';
import '../models/technician_queue_filter.dart';
import '../models/technician_queue_state.dart';

/// Manages filtering state for the technician queue.
class TechnicianQueueFilterNotifier extends Notifier<TechnicianQueueFilter> {
  @override
  TechnicianQueueFilter build() => const TechnicianQueueFilter();

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setPriority(IssuePriority? priority) {
    state = state.copyWith(priority: priority, clearPriority: priority == null);
  }

  void setTabIndex(int index) {
    state = state.copyWith(tabIndex: index);
  }

  void reset() {
    state = const TechnicianQueueFilter();
  }
}

final technicianQueueFilterProvider =
    NotifierProvider<TechnicianQueueFilterNotifier, TechnicianQueueFilter>(
  TechnicianQueueFilterNotifier.new,
);

/// Pure calculation function separating data transformation from UI actions.
List<IssueModel> filterIssues(
  List<IssueModel> issues,
  TechnicianQueueFilter filter,
) {
  var result = issues;

  if (filter.priority != null) {
    result = result.where((i) => i.priority == filter.priority).toList();
  }

  final query = filter.searchQuery.trim().toLowerCase();
  if (query.isNotEmpty) {
    result = result.where((i) {
      return i.title.toLowerCase().contains(query) ||
          i.deviceName.toLowerCase().contains(query) ||
          i.zoneName.toLowerCase().contains(query) ||
          i.id.toLowerCase().contains(query);
    }).toList();
  }

  return result;
}

/// Computes the complete UI state for the technician dashboard.
final technicianQueueStateProvider = Provider.autoDispose<TechnicianQueueState>((ref) {
  final issuesAsync = ref.watch(technicianIssuesProvider);
  final filter = ref.watch(technicianQueueFilterProvider);

  final allIssues = issuesAsync.value ?? const <IssueModel>[];

  // Pure categorization
  final rawActive = allIssues.where((i) =>
      i.status == IssueStatus.open ||
      i.status == IssueStatus.assigned ||
      i.status == IssueStatus.inProgress ||
      i.status == IssueStatus.reopened).toList();

  final rawOnHold =
      allIssues.where((i) => i.status == IssueStatus.onHold).toList();

  final rawResolved = allIssues
      .where((i) =>
          i.status == IssueStatus.resolved || i.status == IssueStatus.closed)
      .toList();

  final kpiStats = TechnicianKpiStats(
    total: allIssues.length,
    open: rawActive.length,
    onHold: rawOnHold.length,
    resolved: rawResolved.length,
  );

  final filteredActive = filterIssues(rawActive, filter);
  final filteredOnHold = filterIssues(rawOnHold, filter);
  final filteredResolved = filterIssues(rawResolved, filter);

  return TechnicianQueueState(
    activeIssues: filteredActive,
    onHoldIssues: filteredOnHold,
    resolvedIssues: filteredResolved,
    kpiStats: kpiStats,
    filter: filter,
    isLoading: issuesAsync.isLoading,
    errorMessage: issuesAsync.hasError ? issuesAsync.error.toString() : null,
  );
});
