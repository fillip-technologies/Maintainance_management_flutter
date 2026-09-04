import '../../issues/issues.dart';

/// Immutable filter criteria for the technician issue queue.
class TechnicianQueueFilter {
  final String searchQuery;
  final IssuePriority? priority;
  final int tabIndex; // 0: Active, 1: On Hold, 2: Resolved

  const TechnicianQueueFilter({
    this.searchQuery = '',
    this.priority,
    this.tabIndex = 0,
  });

  TechnicianQueueFilter copyWith({
    String? searchQuery,
    IssuePriority? priority,
    bool clearPriority = false,
    int? tabIndex,
  }) {
    return TechnicianQueueFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      priority: clearPriority ? null : (priority ?? this.priority),
      tabIndex: tabIndex ?? this.tabIndex,
    );
  }
}
