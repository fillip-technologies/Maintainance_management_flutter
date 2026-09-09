import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_logger.dart';
import '../../devices/repositories/zone_repository.dart';
import '../../issues/issues.dart';
import '../../realtime/realtime.dart';
import '../models/technician_zone_tree_state.dart';
import '../models/zone_status_row.dart';
import 'technician_view_mode_provider.dart';

/// Collapse burst of realtime events into a single refresh.
const _realtimeRefreshDebounce = Duration(milliseconds: 900);

/// Manages data loading and health aggregation for the Technician Zone Status table overview.
class TechnicianZoneStatusViewModel extends AsyncNotifier<List<ZoneStatusRow>> {
  StreamSubscription? _issueCreatedSub;
  StreamSubscription? _issueUpdatedSub;
  Timer? _debounceTimer;

  /// Deferred refresh flag if real-time events arrive while the technician is in another tab.
  bool _pendingRealtimeRefresh = false;

  @override
  Future<List<ZoneStatusRow>> build() async {
    _listenToRealtimeEvents();

    // When the technician switches to the Zone Status view, apply any pending refresh.
    ref.listen<TechnicianViewMode>(technicianViewModeProvider, (_, next) {
      if (next == TechnicianViewMode.zoneStatusTable && _pendingRealtimeRefresh) {
        _pendingRealtimeRefresh = false;
        refresh();
      }
    });

    ref.onDispose(() {
      _issueCreatedSub?.cancel();
      _issueUpdatedSub?.cancel();
      _debounceTimer?.cancel();
    });

    return _loadZoneStatuses();
  }

  void _listenToRealtimeEvents() {
    try {
      final socketService = ref.read(socketServiceProvider);
      _issueCreatedSub =
          socketService.onIssueCreated.listen((_) => _onRealtimeEvent());
      _issueUpdatedSub =
          socketService.onIssueUpdated.listen((_) => _onRealtimeEvent());
    } catch (e) {
      AppLogger.w('⚠️ [TechnicianZoneStatusViewModel] Could not subscribe to real-time events: $e');
    }
  }

  /// Debounced reaction to `issue:created` / `issue:updated`.
  void _onRealtimeEvent() {
    if (ref.read(technicianViewModeProvider) != TechnicianViewMode.zoneStatusTable) {
      _pendingRealtimeRefresh = true;
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_realtimeRefreshDebounce, () {
      AppLogger.i('⚡ [TechnicianZoneStatusViewModel] Realtime event -> refreshing zone status table');
      refresh();
    });
  }

  /// Loads root zones assigned to the technician and sums their sub-tree breakdown and issue counts.
  Future<List<ZoneStatusRow>> _loadZoneStatuses() async {
    final zoneRepo = ref.read(zoneRepositoryProvider);
    final issueRepo = ref.read(issueRepositoryProvider);
    final roots = await zoneRepo.getMyZones();
    final rows = <ZoneStatusRow>[];

    for (final root in roots) {
      try {
        final breakdownFuture = zoneRepo.getZoneBreakdown(root.id);
        final issuesFuture = issueRepo.getIssues(
          zoneId: root.id,
          includeSubzones: true,
          scope: 'technician',
          limit: 100,
        );

        final breakdownMap = await breakdownFuture;

        var unresolvedCount = 0;
        try {
          final issues = await issuesFuture;
          unresolvedCount = issues.where((i) =>
              i.status != IssueStatus.resolved && i.status != IssueStatus.closed).length;
        } catch (e) {
          AppLogger.w('⚠️ [TechnicianZoneStatusViewModel] Issues lookup failed for ${root.name}: $e');
        }

        rows.add(ZoneStatusRow.fromBreakdown(
          id: root.id,
          name: root.name,
          imageUrl: root.imageUrl,
          breakdownMap: breakdownMap,
          openIssuesCount: unresolvedCount,
        ));
      } catch (err) {
        AppLogger.w('⚠️ [TechnicianZoneStatusViewModel] Breakdown failed for ${root.name}: $err');
        rows.add(ZoneStatusRow(
          id: root.id,
          name: root.name,
          imageUrl: root.imageUrl,
          dataLoadFailed: true,
        ));
      }
    }

    return rows;
  }

  /// Triggers a full table reload (used by pull-to-refresh & retry button).
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_loadZoneStatuses);
  }
}

final technicianZoneStatusViewModelProvider =
    AsyncNotifierProvider<TechnicianZoneStatusViewModel, List<ZoneStatusRow>>(
  TechnicianZoneStatusViewModel.new,
);
