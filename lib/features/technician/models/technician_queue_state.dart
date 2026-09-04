import '../../issues/issues.dart';
import 'technician_queue_filter.dart';

/// Aggregated KPI metrics for technician ticket volume.
class TechnicianKpiStats {
  final int total;
  final int open;
  final int onHold;
  final int resolved;

  const TechnicianKpiStats({
    this.total = 0,
    this.open = 0,
    this.onHold = 0,
    this.resolved = 0,
  });
}

/// Comprehensive UI state representation for Technician Queue.
class TechnicianQueueState {
  final List<IssueModel> activeIssues;
  final List<IssueModel> onHoldIssues;
  final List<IssueModel> resolvedIssues;
  final TechnicianKpiStats kpiStats;
  final TechnicianQueueFilter filter;
  final bool isLoading;
  final String? errorMessage;

  const TechnicianQueueState({
    this.activeIssues = const [],
    this.onHoldIssues = const [],
    this.resolvedIssues = const [],
    this.kpiStats = const TechnicianKpiStats(),
    this.filter = const TechnicianQueueFilter(),
    this.isLoading = false,
    this.errorMessage,
  });

  TechnicianQueueState copyWith({
    List<IssueModel>? activeIssues,
    List<IssueModel>? onHoldIssues,
    List<IssueModel>? resolvedIssues,
    TechnicianKpiStats? kpiStats,
    TechnicianQueueFilter? filter,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TechnicianQueueState(
      activeIssues: activeIssues ?? this.activeIssues,
      onHoldIssues: onHoldIssues ?? this.onHoldIssues,
      resolvedIssues: resolvedIssues ?? this.resolvedIssues,
      kpiStats: kpiStats ?? this.kpiStats,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
