import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_logger.dart';
import '../../devices/devices.dart';
import '../../issues/issues.dart';
import '../../realtime/realtime.dart';
import '../models/technician_zone_map_data.dart';
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

    // When the technician returns to Spatial Explorer or Zone Status table, apply any reload
    // that was deferred while they were in the Work Queue.
    ref.listen<TechnicianViewMode>(technicianViewModeProvider, (_, next) {
      if ((next == TechnicianViewMode.spatialExplorer ||
              next == TechnicianViewMode.zoneStatusTable) &&
          _pendingRealtimeRefresh) {
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
    final currentMode = ref.read(technicianViewModeProvider);
    if (currentMode != TechnicianViewMode.spatialExplorer &&
        currentMode != TechnicianViewMode.zoneStatusTable) {
      _pendingRealtimeRefresh = true;
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_realtimeRefreshDebounce, () {
      AppLogger.i('⚡ [TechnicianZoneTreeViewModel] Realtime event -> refreshing shared tree');
      refresh();
    });
  }

  /// Enriches a bare zone node with authoritative device counts (from the
  /// dashboard breakdown endpoint) and issue metrics (from the issues
  /// endpoint).
  Future<TechnicianZoneNode> _enrichZone(
    TechnicianZoneNode node, {
    int? subzoneCount,
  }) async {
    final zoneRepo = ref.read(zoneRepositoryProvider);
    final issueRepo = ref.read(issueRepositoryProvider);

    final breakdownFuture = zoneRepo.getZoneBreakdown(node.id).catchError((e) {
      AppLogger.w('⚠️ [TechnicianZoneTreeViewModel] Failed to get breakdown for ${node.id}: $e');
      return <String, Map<String, int>>{};
    });
    final issuesFuture = issueRepo.getIssues(
      zoneId: node.id,
      includeSubzones: true,
      scope: 'technician',
    ).catchError((e) {
      AppLogger.w('⚠️ [TechnicianZoneTreeViewModel] Failed to get issues for ${node.id}: $e');
      return const <IssueModel>[];
    });

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

  int _subzoneGeneration = 0;

  /// Initial load: loads top-level zones, subzones, devices, and defects to build web-parity Big Card sections.
  Future<TechnicianZoneTreeState> _loadRootZones() async {
    final zoneRepo = ref.read(zoneRepositoryProvider);
    final deviceRepo = ref.read(deviceRepositoryProvider);
    final issueRepo = ref.read(issueRepositoryProvider);

    try {
      final results = await Future.wait([
        zoneRepo.getAllZones().catchError((e, st) {
          AppLogger.w('⚠️ [TechnicianZoneTreeViewModel] Failed to load all zones: $e');
          return const <TechnicianZoneNode>[];
        }),
        zoneRepo.getMyZones().catchError((e, st) {
          AppLogger.w('⚠️ [TechnicianZoneTreeViewModel] Failed to load my zones: $e');
          return const <TechnicianZoneNode>[];
        }),
        deviceRepo.getAllDevices().catchError((e, st) {
          AppLogger.w('⚠️ [TechnicianZoneTreeViewModel] Failed to load all devices: $e');
          return const <DeviceModel>[];
        }),
        issueRepo.getIssues(scope: 'technician', limit: 100, allPages: true).catchError((e, st) {
          AppLogger.w('⚠️ [TechnicianZoneTreeViewModel] Failed to load issues (server/DB error): $e');
          return const <IssueModel>[];
        }),
      ]);

      final allApiZones = results[0] as List<TechnicianZoneNode>;
      final rawMyZones = results[1] as List<TechnicianZoneNode>;
      final allDevices = results[2] as List<DeviceModel>;
      final allIssues = results[3] as List<IssueModel>;

      // Build authoritative zone lookup, prioritizing zones with parentZoneId from getAllZones
      final zoneMap = <String, TechnicianZoneNode>{};
      for (final z in allApiZones) {
        zoneMap[z.id] = z;
      }
      for (final z in rawMyZones) {
        if (!zoneMap.containsKey(z.id)) {
          zoneMap[z.id] = z;
        } else if (zoneMap[z.id]!.parentZoneId == null && z.parentZoneId != null) {
          zoneMap[z.id] = zoneMap[z.id]!.copyWith(parentZoneId: z.parentZoneId);
        }
      }
      final allZones = zoneMap.values.toList();

      // Helper to climb parentZoneId hierarchy up to the top-level root zone
      String? getRootZoneId(String? zId) {
        if (zId == null || zId.isEmpty) return null;
        var curr = zoneMap[zId];
        if (curr == null) return null;
        final visited = <String>{};
        while (curr!.parentZoneId != null &&
            curr.parentZoneId!.isNotEmpty &&
            visited.add(curr.id)) {
          final parent = zoneMap[curr.parentZoneId!];
          if (parent == null) break;
          curr = parent;
        }
        return curr.id;
      }

      // 3. Top-level zones: zones with no parent or whose parent is not among loaded zones
      var rootsToProcess = allZones.where((z) =>
          z.parentZoneId == null ||
          z.parentZoneId!.isEmpty ||
          !zoneMap.containsKey(z.parentZoneId)).toList();
      if (rootsToProcess.isEmpty && allZones.isNotEmpty) {
        rootsToProcess = allZones;
      }

      // 4. Map devices to their root top-level zone
      final devicesByRootZone = <String, List<DeviceModel>>{};
      for (final d in allDevices) {
        final rootId = getRootZoneId(d.zoneId) ?? d.zoneId;
        devicesByRootZone.putIfAbsent(rootId, () => []).add(d);
      }

      // 5. Build TopLevelZoneItems aggregating all descendant cameras directly
      final sections = <TechnicianTopLevelZoneItem>[];
      for (final root in rootsToProcess) {
        final rootDevices = devicesByRootZone[root.id] ?? <DeviceModel>[];
        final rootDeviceIds = rootDevices.map((d) => d.id).toSet();

        // Collect all descendant subzone IDs for this root to capture relevant zone-level issues
        final descendantZoneIds = <String>{root.id};
        for (final z in allZones) {
          if (getRootZoneId(z.id) == root.id) {
            descendantZoneIds.add(z.id);
          }
        }

        final rootIssues = allIssues.where((iss) =>
            descendantZoneIds.contains(iss.zoneId) ||
            rootDeviceIds.contains(iss.deviceId)).toList();

        // Sort devices inside root zone: defective/offline first, then by name
        rootDevices.sort((a, b) {
          final aDef = rootIssues.any((iss) =>
                  iss.deviceId == a.id &&
                  iss.status != IssueStatus.resolved &&
                  iss.status != IssueStatus.closed) ||
              a.status == DeviceStatus.faulty ||
              a.status == DeviceStatus.underMaintenance;
          final bDef = rootIssues.any((iss) =>
                  iss.deviceId == b.id &&
                  iss.status != IssueStatus.resolved &&
                  iss.status != IssueStatus.closed) ||
              b.status == DeviceStatus.faulty ||
              b.status == DeviceStatus.underMaintenance;
          if (aDef && !bDef) return -1;
          if (!aDef && bDef) return 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

        sections.add(TechnicianTopLevelZoneItem(
          zone: root,
          devices: rootDevices,
          issues: rootIssues,
        ));
      }

      // 6. Handle unassigned or orphan devices
      final assignedDeviceIds = {
        for (final sec in sections)
          for (final d in sec.devices) d.id,
      };
      final orphanDevices = allDevices.where((d) => !assignedDeviceIds.contains(d.id)).toList();
      if (orphanDevices.isNotEmpty) {
        final orphanDeviceIds = orphanDevices.map((d) => d.id).toSet();
        final orphanIssues = allIssues.where((iss) => orphanDeviceIds.contains(iss.deviceId)).toList();
        sections.add(TechnicianTopLevelZoneItem(
          zone: const TechnicianZoneNode(
            id: 'unassigned',
            name: 'General / Unassigned',
          ),
          devices: orphanDevices,
          issues: orphanIssues,
        ));
      }

      // 7. ISSUE-FIRST SORTING: zones with issues/problems at the top first!
      TechnicianTopLevelZoneItem.sortIssueFirst(sections);

      // Legacy rootNodes enriched with real counts from sections
      final initialNodes = sections.map((sec) {
        return sec.zone.copyWith(
          deviceCount: sec.totalDevices,
          subzoneCount: 0,
          workingCount: sec.onlineDevices,
          notWorkingCount: sec.offlineDevices,
          openIssuesCount: sec.unresolvedIssuesCount,
          isEnriching: false,
          dataLoadFailed: false,
        );
      }).toList();

      return TechnicianZoneTreeState(
        rootZones: initialNodes,
        zoneSections: sections,
        currentPath: const [],
        currentSubzones: const [],
        currentDevices: const [],
        currentIssues: const [],
        isLoading: false,
      );
    } catch (e, st) {
      AppLogger.e('❌ [TechnicianZoneTreeViewModel] Failed to load root zones: $e', e, st);
      List<TechnicianZoneNode> rawRoots = const [];
      try {
        rawRoots = await zoneRepo.getMyZones();
      } catch (err) {
        AppLogger.w('⚠️ [TechnicianZoneTreeViewModel] Fallback getMyZones failed: $err');
      }
      final initialNodes = rawRoots.map((r) => r.copyWith(isEnriching: false, dataLoadFailed: true)).toList();
      return TechnicianZoneTreeState(
        rootZones: initialNodes,
        zoneSections: const [],
        currentPath: const [],
        currentSubzones: const [],
        currentDevices: const [],
        currentIssues: const [],
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }



  /// Drills down into a specific zone node: updates breadcrumb path and fetches its
  /// child subzones, direct devices, and active issues immediately.
  Future<void> drillDown(TechnicianZoneNode node) async {
    final current = state.value;
    if (current == null) return;


    state = AsyncValue.data(current.copyWith(isDrillingDown: true, clearError: true));

    final zoneRepo = ref.read(zoneRepositoryProvider);
    final issueRepo = ref.read(issueRepositoryProvider);

    try {
      final subzonesFuture = zoneRepo.getSubzones(node.id).catchError((e) {
        AppLogger.w('⚠️ [TechnicianZoneTreeViewModel] Failed to get subzones: $e');
        return const <TechnicianZoneNode>[];
      });
      final devicesFuture = zoneRepo.getZoneDevices(node.id).catchError((e) {
        AppLogger.w('⚠️ [TechnicianZoneTreeViewModel] Failed to get zone devices: $e');
        return const <DeviceModel>[];
      });
      final issuesFuture = issueRepo.getIssues(
        zoneId: node.id,
        includeSubzones: true,
        scope: 'technician',
        limit: 100,
      ).catchError((e) {
        AppLogger.w('⚠️ [TechnicianZoneTreeViewModel] Failed to get issues: $e');
        return const <IssueModel>[];
      });

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
      final rawSubzones = await zoneRepo.getSubzones(node.id).catchError((e) {
        AppLogger.w('⚠️ [TechnicianZoneTreeViewModel] Failed to get subzones: $e');
        return const <TechnicianZoneNode>[];
      });
      final enhancedSubzones = await _enrichSubzones(rawSubzones);

      final devices = await zoneRepo.getZoneDevices(node.id).catchError((e) {
        AppLogger.w('⚠️ [TechnicianZoneTreeViewModel] Failed to get zone devices: $e');
        return const <DeviceModel>[];
      });
      final rawIssues = await issueRepo.getIssues(
        zoneId: node.id,
        includeSubzones: true,
        scope: 'technician',
        limit: 100,
      ).catchError((e) {
        AppLogger.w('⚠️ [TechnicianZoneTreeViewModel] Failed to get issues: $e');
        return const <IssueModel>[];
      });
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
