import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_logger.dart';
import '../../devices/models/technician_zone_node.dart';
import '../../devices/repositories/zone_repository.dart';
import '../../issues/issues.dart';
import '../../realtime/realtime.dart';
import '../models/technician_zone_tree_state.dart';
import 'technician_view_mode_provider.dart';

/// Collapse a burst of realtime events into a single reload.
const _realtimeRefreshDebounce = Duration(milliseconds: 900);

class TechnicianZoneTreeViewModel extends AsyncNotifier<TechnicianZoneTreeState> {
  StreamSubscription? _issueCreatedSub;
  StreamSubscription? _issueUpdatedSub;
  Timer? _debounceTimer;

  /// Set when a realtime event arrives while the technician is in Work Queue
  /// mode. The (expensive) tree reload is deferred until they switch back to
  /// the Spatial Explorer so we never reload a view nobody is looking at.
  bool _pendingRealtimeRefresh = false;

  @override
  Future<TechnicianZoneTreeState> build() async {
    _listenToRealtimeEvents();

    // When the technician returns to the Spatial Explorer, apply any reload
    // that was deferred while they were in the Work Queue.
    ref.listen<TechnicianViewMode>(technicianViewModeProvider, (_, next) {
      if (next == TechnicianViewMode.spatialExplorer && _pendingRealtimeRefresh) {
        _pendingRealtimeRefresh = false;
        refresh();
      }
    });

    ref.onDispose(() {
      _issueCreatedSub?.cancel();
      _issueUpdatedSub?.cancel();
      _debounceTimer?.cancel();
    });

    return _loadRootZones();
  }

  void _listenToRealtimeEvents() {
    try {
      final socketService = ref.read(socketServiceProvider);
      _issueCreatedSub =
          socketService.onIssueCreated.listen((_) => _onRealtimeEvent());
      _issueUpdatedSub =
          socketService.onIssueUpdated.listen((_) => _onRealtimeEvent());
    } catch (e) {
      AppLogger.w('⚠️ [TechnicianZoneTreeViewModel] Could not subscribe to real-time events: $e');
    }
  }

  /// Debounced, mode-aware reaction to `issue:created` / `issue:updated`.
  void _onRealtimeEvent() {
    if (ref.read(technicianViewModeProvider) != TechnicianViewMode.spatialExplorer) {
      _pendingRealtimeRefresh = true;
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_realtimeRefreshDebounce, () {
      AppLogger.i('⚡ [TechnicianZoneTreeViewModel] Realtime event -> refreshing tree');
      refresh();
    });
  }

  /// Enriches a bare zone node with authoritative device counts (from the
  /// dashboard breakdown endpoint) and issue metrics (from the issues
  /// endpoint).
  ///
  /// The two data sources are kept strictly separate: device counts come only
  /// from the breakdown, issue metrics only from the issues list. Blending them
  /// (working from one source, "not working" from the other) produced totals
  /// that didn't add up and a health % that disagreed with the faulty tile.
  ///
  /// May throw — the caller marks the node `dataLoadFailed` so its card shows a
  /// neutral "unknown" state instead of a misleading all-clear green.
  Future<TechnicianZoneNode> _enrichZone(
    TechnicianZoneNode node, {
    int? subzoneCount,
  }) async {
    final zoneRepo = ref.read(zoneRepositoryProvider);
    final issueRepo = ref.read(issueRepositoryProvider);

    final breakdownMap = await zoneRepo.getZoneBreakdown(node.id);
    var total = 0, working = 0, faulty = 0, maintenance = 0;
    for (final entry in breakdownMap.values) {
      total += entry['total'] ?? 0;
      working += entry['working'] ?? 0;
      faulty += entry['faulty'] ?? 0;
      maintenance += entry['underMaintenance'] ?? 0;
    }

    final subtreeIssues = await issueRepo.getIssues(
      zoneId: node.id,
      includeSubzones: true,
      scope: 'technician',
    );
    final active = subtreeIssues
        .where((i) =>
            i.status != IssueStatus.resolved && i.status != IssueStatus.closed)
        .toList();

    // How many distinct hardware UNITS are affected — not the ticket count.
    // (A unit with 3 open tickets counts once; device-less area incidents are
    // shown separately as "facility incidents", not here.)
    final affectedUnits =
        active.map((i) => i.deviceId).where((id) => id.isNotEmpty).toSet().length;

    return node.copyWith(
      deviceCount: total,
      subzoneCount: subzoneCount ?? node.subzoneCount,
      workingCount: working,
      notWorkingCount: faulty,
      maintenanceCount: maintenance,
      openIssuesCount: active.length,
      unresolvedUnitsCount: affectedUnits,
      criticalIssuesCount:
          active.where((i) => i.priority == IssuePriority.critical).length,
      highIssuesCount:
          active.where((i) => i.priority == IssuePriority.high).length,
      dataLoadFailed: false,
    );
  }

  /// Enriches a list of sibling sub-zones, isolating per-zone failures.
  Future<List<TechnicianZoneNode>> _enrichSubzones(
    List<TechnicianZoneNode> rawSubzones,
  ) async {
    final result = <TechnicianZoneNode>[];
    for (final sz in rawSubzones) {
      try {
        result.add(await _enrichZone(sz));
      } catch (err) {
        AppLogger.w('⚠️ [TechnicianZoneTreeViewModel] Sub-zone enrich failed for ${sz.name}: $err');
        result.add(sz.copyWith(dataLoadFailed: true));
      }
    }
    return result;
  }

  /// Initial load: fetches assigned zones and enriches each with counts.
  Future<TechnicianZoneTreeState> _loadRootZones() async {
    final zoneRepo = ref.read(zoneRepositoryProvider);

    final rawRoots = await zoneRepo.getMyZones();
    final enhancedRoots = <TechnicianZoneNode>[];

    for (final root in rawRoots) {
      try {
        final subzones = await zoneRepo.getSubzones(root.id);
        enhancedRoots.add(await _enrichZone(root, subzoneCount: subzones.length));
      } catch (zoneErr) {
        AppLogger.w('⚠️ [TechnicianZoneTreeViewModel] Root zone enrich failed for ${root.name}: $zoneErr');
        enhancedRoots.add(root.copyWith(dataLoadFailed: true));
      }
    }

    return TechnicianZoneTreeState(
      rootZones: enhancedRoots,
      currentPath: const [],
      currentSubzones: const [],
      currentDevices: const [],
      currentIssues: const [],
      isLoading: false,
    );
  }

  /// Drills down into a specific zone node: updates breadcrumb path and fetches its
  /// child subzones, direct devices, and active issues.
  Future<void> drillDown(TechnicianZoneNode node) async {
    final current = state.value;
    if (current == null) return;

    state = AsyncValue.data(current.copyWith(isDrillingDown: true, clearError: true));

    final zoneRepo = ref.read(zoneRepositoryProvider);
    final issueRepo = ref.read(issueRepositoryProvider);

    try {
      final rawSubzones = await zoneRepo.getSubzones(node.id);
      final enhancedSubzones = await _enrichSubzones(rawSubzones);

      final devices = await zoneRepo.getZoneDevices(node.id);
      final rawIssues = await issueRepo.getIssues(
        zoneId: node.id,
        includeSubzones: true,
        scope: 'technician',
      );
      final activeIssues = rawIssues.where((i) =>
          i.status != IssueStatus.resolved &&
          i.status != IssueStatus.closed).toList();

      final newPath = [...current.currentPath, node];

      state = AsyncValue.data(current.copyWith(
        currentPath: newPath,
        currentSubzones: enhancedSubzones,
        currentDevices: devices,
        currentIssues: activeIssues,
        isDrillingDown: false,
      ));
    } catch (e, st) {
      AppLogger.e('❌ [TechnicianZoneTreeViewModel] Failed to drill down into ${node.name}: $e', e, st);
      state = AsyncValue.data(current.copyWith(
        isDrillingDown: false,
        errorMessage: 'Failed to open ${node.name}: $e',
      ));
    }
  }

  /// Flag indicating whether the current drill-down was initiated from the Zone Status table.
  bool _navigatedFromZoneStatus = false;

  /// Navigates directly into a zone by its ID (e.g. when tapping a row in the Zone Status table).
  Future<void> navigateToZone(
    String zoneId, {
    String? zoneName,
    String? imageUrl,
    bool fromZoneStatus = false,
  }) async {
    _navigatedFromZoneStatus = fromZoneStatus;
    final current = state.value ?? await future;

    final match = current.rootZones.where((z) => z.id == zoneId).firstOrNull;
    final targetNode = match ??
        TechnicianZoneNode(
          id: zoneId,
          name: zoneName ?? '',
          imageUrl: imageUrl,
        );

    // Reset path back to root first so drillDown constructs a clean 1-level path [targetNode]
    state = AsyncValue.data(current.copyWith(
      currentPath: const [],
      currentSubzones: const [],
      currentDevices: const [],
      currentIssues: const [],
      clearError: true,
    ));

    await drillDown(targetNode);
  }

  /// Navigates back up one level in the breadcrumb path.
  Future<void> navigateUp() async {
    final current = state.value;
    if (current == null || current.isAtRoot) return;

    if (current.currentPath.length <= 1) {
      if (_navigatedFromZoneStatus) {
        _navigatedFromZoneStatus = false;
        jumpToRoot();
        ref
            .read(technicianViewModeProvider.notifier)
            .setMode(TechnicianViewMode.zoneStatusTable);
        return;
      }
      jumpToRoot();
      return;
    }

    final newPath = current.currentPath.sublist(0, current.currentPath.length - 1);
    await _reloadForNode(newPath.last, newPath);
  }

  /// Jumps directly to any breadcrumb level.
  Future<void> jumpToBreadcrumb(int index) async {
    final current = state.value;
    if (current == null) return;

    if (index < 0 || index >= current.currentPath.length) {
      jumpToRoot();
      return;
    }

    if (index == current.currentPath.length - 1) return; // already there

    final targetNode = current.currentPath[index];
    final newPath = current.currentPath.sublist(0, index + 1);
    await _reloadForNode(targetNode, newPath);
  }

  /// Resets back to top-level root zones overview.
  void jumpToRoot() {
    _navigatedFromZoneStatus = false;
    final current = state.value;
    if (current == null) return;

    state = AsyncValue.data(current.copyWith(
      currentPath: const [],
      currentSubzones: const [],
      currentDevices: const [],
      currentIssues: const [],
      clearError: true,
    ));
  }

  /// Helper to reload subzones, devices, and issues when navigating to an ancestor node.
  Future<void> _reloadForNode(TechnicianZoneNode node, List<TechnicianZoneNode> path) async {
    final current = state.value;
    if (current == null) return;

    state = AsyncValue.data(current.copyWith(isDrillingDown: true, clearError: true));

    final zoneRepo = ref.read(zoneRepositoryProvider);
    final issueRepo = ref.read(issueRepositoryProvider);

    try {
      final rawSubzones = await zoneRepo.getSubzones(node.id);
      final enhancedSubzones = await _enrichSubzones(rawSubzones);

      final devices = await zoneRepo.getZoneDevices(node.id);
      final rawIssues = await issueRepo.getIssues(
        zoneId: node.id,
        includeSubzones: true,
        scope: 'technician',
      );
      final activeIssues = rawIssues.where((i) =>
          i.status != IssueStatus.resolved &&
          i.status != IssueStatus.closed).toList();

      state = AsyncValue.data(current.copyWith(
        currentPath: path,
        currentSubzones: enhancedSubzones,
        currentDevices: devices,
        currentIssues: activeIssues,
        isDrillingDown: false,
      ));
    } catch (e) {
      state = AsyncValue.data(current.copyWith(
        isDrillingDown: false,
        errorMessage: 'Failed to load: $e',
      ));
    }
  }

  /// Sets the filter search query.
  void setSearchQuery(String query) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(searchQuery: query));
  }

  /// Refreshes the active level.
  Future<void> refresh() async {
    final current = state.value;
    if (current == null) {
      state = await AsyncValue.guard(_loadRootZones);
      return;
    }

    if (current.isAtRoot) {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(_loadRootZones);
    } else {
      await _reloadForNode(current.currentZone!, current.currentPath);
    }
  }
}

final technicianZoneTreeViewModelProvider =
    AsyncNotifierProvider<TechnicianZoneTreeViewModel, TechnicianZoneTreeState>(
  TechnicianZoneTreeViewModel.new,
);
