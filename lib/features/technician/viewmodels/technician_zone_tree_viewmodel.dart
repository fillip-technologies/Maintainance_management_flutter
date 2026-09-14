import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
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

    final breakdownFuture = zoneRepo.getZoneBreakdown(node.id);
    final issuesFuture = issueRepo.getIssues(
      zoneId: node.id,
      includeSubzones: true,
      scope: 'technician',
    );

    final breakdownMap = await breakdownFuture;
    var total = 0, working = 0, faulty = 0, maintenance = 0;
    for (final entry in breakdownMap.values) {
      total += entry['total'] ?? 0;
      working += entry['working'] ?? 0;
      faulty += entry['faulty'] ?? 0;
      maintenance += entry['underMaintenance'] ?? 0;
    }

    final subtreeIssues = await issuesFuture;
    final active = subtreeIssues
        .where((i) =>
            i.status != IssueStatus.resolved && i.status != IssueStatus.closed)
        .toList();

    // How many distinct hardware UNITS are affected — not the ticket count.
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
    return Future.wait(rawSubzones.map((sz) async {
      try {
        return await _enrichZone(sz);
      } catch (err) {
        AppLogger.w('⚠️ [TechnicianZoneTreeViewModel] Sub-zone enrich failed for ${sz.name}: $err');
        return sz.copyWith(dataLoadFailed: true);
      }
    }));
  }

  int _loadGeneration = 0;
  int _subzoneGeneration = 0;

  /// Initial load: immediately displays assigned zones and streams enrichment one-by-one.
  Future<TechnicianZoneTreeState> _loadRootZones() async {
    final zoneRepo = ref.read(zoneRepositoryProvider);

    final rawRoots = await zoneRepo.getMyZones();
    // Prioritize actual top-level zones (parentZoneId == null or depth == 0)
    final topLevelRoots = rawRoots.where((z) => z.isTopLevel).toList();
    final rootsToProcess = topLevelRoots.isNotEmpty ? topLevelRoots : rawRoots;

    // Immediately present all zones to user with isEnriching: true
    final initialNodes = rootsToProcess
        .map((r) => r.copyWith(isEnriching: true, dataLoadFailed: false))
        .toList();

    final generation = ++_loadGeneration;

    // Stream progressive updates zone-by-zone in background
    unawaited(_streamEnrichRootZones(rootsToProcess, generation));

    return TechnicianZoneTreeState(
      rootZones: initialNodes,
      currentPath: const [],
      currentSubzones: const [],
      currentDevices: const [],
      currentIssues: const [],
      isLoading: false,
    );
  }

  /// Sequentially enriches root zones with breakdown and defect metrics in real time.
  Future<void> _streamEnrichRootZones(
    List<TechnicianZoneNode> roots,
    int generation,
  ) async {
    final zoneRepo = ref.read(zoneRepositoryProvider);

    for (final root in roots) {
      if (_loadGeneration != generation) return;

      try {
        final subzones = await zoneRepo.getSubzones(root.id);
        if (_loadGeneration != generation) return;

        final enriched = await _enrichZone(root, subzoneCount: subzones.length);
        if (_loadGeneration != generation) return;

        final current = state.value;
        if (current != null && current.isAtRoot) {
          final updatedRoots = List<TechnicianZoneNode>.from(current.rootZones);
          final idx = updatedRoots.indexWhere((z) => z.id == root.id);
          if (idx != -1) {
            updatedRoots[idx] = enriched.copyWith(isEnriching: false, dataLoadFailed: false);
            state = AsyncValue.data(current.copyWith(rootZones: updatedRoots));
          }
        }
      } catch (zoneErr) {
        AppLogger.w('⚠️ [TechnicianZoneTreeViewModel] Progressive enrich failed for ${root.name}: $zoneErr');
        final current = state.value;
        if (current != null && current.isAtRoot) {
          final updatedRoots = List<TechnicianZoneNode>.from(current.rootZones);
          final idx = updatedRoots.indexWhere((z) => z.id == root.id);
          if (idx != -1) {
            updatedRoots[idx] = root.copyWith(isEnriching: false, dataLoadFailed: true);
            state = AsyncValue.data(current.copyWith(rootZones: updatedRoots));
          }
        }
      }

      // Courteous 60ms gap between zones to keep network smooth and avoid rate limits
      await Future.delayed(const Duration(milliseconds: 60));
    }
  }

  /// Drills down into a specific zone node: updates breadcrumb path and fetches its
  /// child subzones, direct devices, and active issues immediately.
  Future<void> drillDown(TechnicianZoneNode node) async {
    final current = state.value;
    if (current == null) return;

    // Cancel root streaming when drilling down to focus bandwidth on current zone
    _loadGeneration++;

    state = AsyncValue.data(current.copyWith(isDrillingDown: true, clearError: true));

    final zoneRepo = ref.read(zoneRepositoryProvider);
    final issueRepo = ref.read(issueRepositoryProvider);

    try {
      final subzonesFuture = zoneRepo.getSubzones(node.id);
      final devicesFuture = zoneRepo.getZoneDevices(node.id);
      final issuesFuture = issueRepo.getIssues(
        zoneId: node.id,
        includeSubzones: true,
        scope: 'technician',
        limit: 100,
      );

      final rawSubzones = await subzonesFuture;
      final devices = await devicesFuture;
      final rawIssues = await issuesFuture;
      final activeIssues = rawIssues.where((i) =>
          i.status != IssueStatus.resolved &&
          i.status != IssueStatus.closed).toList();

      final initialSubzones = rawSubzones
          .map((sz) => sz.copyWith(isEnriching: true, dataLoadFailed: false))
          .toList();

      final newPath = [...current.currentPath, node];

      state = AsyncValue.data(current.copyWith(
        currentPath: newPath,
        currentSubzones: initialSubzones,
        currentDevices: devices,
        currentIssues: activeIssues,
        isDrillingDown: false,
      ));

      // Progressively stream subzone enrichment in background
      final subzoneGen = ++_subzoneGeneration;
      unawaited(_streamEnrichSubzones(rawSubzones, newPath, subzoneGen));
    } catch (e, st) {
      AppLogger.e('❌ [TechnicianZoneTreeViewModel] Failed to drill down into ${node.name}: $e', e, st);
      final errorMsg = e is DioException
          ? e.extractErrorMessage('Failed to open ${node.name}')
          : e.toString().replaceFirst('Exception: ', '');
      state = AsyncValue.data(current.copyWith(
        isDrillingDown: false,
        errorMessage: errorMsg,
      ));
    }
  }

  /// Progressively streams subzone enrichment in background.
  Future<void> _streamEnrichSubzones(
    List<TechnicianZoneNode> subzones,
    List<TechnicianZoneNode> expectedPath,
    int generation,
  ) async {
    for (final sz in subzones) {
      if (_subzoneGeneration != generation) return;

      try {
        final enriched = await _enrichZone(sz);
        if (_subzoneGeneration != generation) return;

        final current = state.value;
        if (current != null && current.currentPath.length == expectedPath.length) {
          final updatedSubzones = List<TechnicianZoneNode>.from(current.currentSubzones);
          final idx = updatedSubzones.indexWhere((z) => z.id == sz.id);
          if (idx != -1) {
            updatedSubzones[idx] = enriched.copyWith(isEnriching: false, dataLoadFailed: false);
            state = AsyncValue.data(current.copyWith(currentSubzones: updatedSubzones));
          }
        }
      } catch (err) {
        AppLogger.w('⚠️ [TechnicianZoneTreeViewModel] Subzone progressive enrich failed for ${sz.name}: $err');
        final current = state.value;
        if (current != null && current.currentPath.length == expectedPath.length) {
          final updatedSubzones = List<TechnicianZoneNode>.from(current.currentSubzones);
          final idx = updatedSubzones.indexWhere((z) => z.id == sz.id);
          if (idx != -1) {
            updatedSubzones[idx] = sz.copyWith(isEnriching: false, dataLoadFailed: true);
            state = AsyncValue.data(current.copyWith(currentSubzones: updatedSubzones));
          }
        }
      }

      await Future.delayed(const Duration(milliseconds: 60));
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
        limit: 100,
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
