import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_logger.dart';
import '../../devices/models/technician_zone_node.dart';
import '../../devices/repositories/zone_repository.dart';
import '../../issues/issues.dart';
import '../../realtime/realtime.dart';
import '../models/technician_zone_tree_state.dart';

class TechnicianZoneTreeViewModel extends AsyncNotifier<TechnicianZoneTreeState> {
  StreamSubscription? _issueCreatedSub;
  StreamSubscription? _issueUpdatedSub;

  @override
  Future<TechnicianZoneTreeState> build() async {
    _listenToRealtimeEvents();

    ref.onDispose(() {
      _issueCreatedSub?.cancel();
      _issueUpdatedSub?.cancel();
    });

    return _loadRootZones();
  }

  void _listenToRealtimeEvents() {
    try {
      final socketService = ref.read(socketServiceProvider);
      _issueCreatedSub = socketService.onIssueCreated.listen((_) {
        AppLogger.i('⚡ [TechnicianZoneTreeViewModel] Issue created event received -> refreshing tree');
        refresh();
      });
      _issueUpdatedSub = socketService.onIssueUpdated.listen((_) {
        AppLogger.i('⚡ [TechnicianZoneTreeViewModel] Issue updated event received -> refreshing tree');
        refresh();
      });
    } catch (e) {
      AppLogger.w('⚠️ [TechnicianZoneTreeViewModel] Could not subscribe to real-time events: $e');
    }
  }

  /// Initial load: fetches assigned zones, subzone counts, breakdown, and defect severities.
  Future<TechnicianZoneTreeState> _loadRootZones() async {
    final zoneRepo = ref.read(zoneRepositoryProvider);
    final issueRepo = ref.read(issueRepositoryProvider);

    try {
      final rawRoots = await zoneRepo.getMyZones();
      final enhancedRoots = <TechnicianZoneNode>[];

      for (final root in rawRoots) {
        try {
          // Fetch subzones count
          final subzones = await zoneRepo.getSubzones(root.id);

          // Fetch device status breakdown
          final breakdownMap = await zoneRepo.getZoneBreakdown(root.id);
          int subtreeTotal = 0;
          int subtreeWorking = 0;
          int subtreeFaulty = 0;
          int subtreeMaintenance = 0;

          for (final entry in breakdownMap.values) {
            subtreeTotal += entry['total'] ?? 0;
            subtreeWorking += entry['working'] ?? 0;
            subtreeFaulty += entry['faulty'] ?? 0;
            subtreeMaintenance += entry['underMaintenance'] ?? 0;
          }

          // Fetch issues across this zone's entire subtree
          final subtreeIssues = await issueRepo.getIssues(
            zoneId: root.id,
            includeSubzones: true,
            scope: 'technician',
          );

          final activeIssues = subtreeIssues.where((i) =>
              i.status != IssueStatus.resolved &&
              i.status != IssueStatus.closed).toList();

          final unresolvedDeviceIds = activeIssues
              .map((i) => i.deviceId)
              .where((id) => id.isNotEmpty)
              .toSet();
          final areaIncidents = activeIssues.where((i) => i.deviceId.isEmpty).length;
          final notResolvedUnits = unresolvedDeviceIds.length + areaIncidents;

          final criticalCount = activeIssues.where((i) => i.priority == IssuePriority.critical).length;
          final highCount = activeIssues.where((i) => i.priority == IssuePriority.high).length;

          final totalDevices = subtreeTotal > 0 ? subtreeTotal : root.deviceCount;
          final notWorking = notResolvedUnits > 0 ? notResolvedUnits : subtreeFaulty;
          final maintenance = subtreeMaintenance;
          final working = subtreeWorking > 0
              ? subtreeWorking
              : (totalDevices - notWorking - maintenance > 0 ? totalDevices - notWorking - maintenance : 0);

          enhancedRoots.add(root.copyWith(
            deviceCount: totalDevices,
            subzoneCount: subzones.length,
            workingCount: working,
            notWorkingCount: notWorking,
            maintenanceCount: maintenance,
            openIssuesCount: activeIssues.length,
            unresolvedUnitsCount: notResolvedUnits,
            criticalIssuesCount: criticalCount,
            highIssuesCount: highCount,
          ));
        } catch (zoneErr) {
          AppLogger.w('⚠️ [TechnicianZoneTreeViewModel] Partial error enhancing zone ${root.name}: $zoneErr');
          enhancedRoots.add(root);
        }
      }

      return TechnicianZoneTreeState(
        rootZones: enhancedRoots,
        currentPath: const [],
        currentSubzones: const [],
        currentDevices: const [],
        currentIssues: const [],
        viewMode: TechnicianViewMode.spatialExplorer,
        isLoading: false,
      );
    } catch (e, st) {
      AppLogger.e('❌ [TechnicianZoneTreeViewModel] Failed to load root zones: $e', e, st);
      rethrow;
    }
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
      // 1. Fetch child sub-zones
      final rawSubzones = await zoneRepo.getSubzones(node.id);
      final enhancedSubzones = <TechnicianZoneNode>[];

      for (final sz in rawSubzones) {
        try {
          final breakdownMap = await zoneRepo.getZoneBreakdown(sz.id);
          int szTotal = 0;
          int szWorking = 0;
          int szFaulty = 0;
          int szMaintenance = 0;

          for (final entry in breakdownMap.values) {
            szTotal += entry['total'] ?? 0;
            szWorking += entry['working'] ?? 0;
            szFaulty += entry['faulty'] ?? 0;
            szMaintenance += entry['underMaintenance'] ?? 0;
          }

          final issues = await issueRepo.getIssues(
            zoneId: sz.id,
            includeSubzones: true,
            scope: 'technician',
          );

          final activeIssues = issues.where((i) =>
              i.status != IssueStatus.resolved &&
              i.status != IssueStatus.closed).toList();

          final szUnresolvedDeviceIds = activeIssues
              .map((i) => i.deviceId)
              .where((id) => id.isNotEmpty)
              .toSet();
          final szAreaIncidents = activeIssues.where((i) => i.deviceId.isEmpty).length;
          final szNotResolvedUnits = szUnresolvedDeviceIds.length + szAreaIncidents;

          final criticalCount = activeIssues.where((i) => i.priority == IssuePriority.critical).length;
          final highCount = activeIssues.where((i) => i.priority == IssuePriority.high).length;

          final total = szTotal > 0 ? szTotal : sz.deviceCount;
          final notWorking = szNotResolvedUnits > 0 ? szNotResolvedUnits : szFaulty;
          final working = szWorking > 0
              ? szWorking
              : (total - notWorking - szMaintenance > 0 ? total - notWorking - szMaintenance : 0);

          enhancedSubzones.add(sz.copyWith(
            deviceCount: total,
            workingCount: working,
            notWorkingCount: notWorking,
            maintenanceCount: szMaintenance,
            openIssuesCount: activeIssues.length,
            unresolvedUnitsCount: szNotResolvedUnits,
            criticalIssuesCount: criticalCount,
            highIssuesCount: highCount,
          ));
        } catch (szErr) {
          AppLogger.w('⚠️ [TechnicianZoneTreeViewModel] Subzone enhance failed: $szErr');
          enhancedSubzones.add(sz);
        }
      }

      // 2. Fetch direct devices situated in this zone
      final devices = await zoneRepo.getZoneDevices(node.id);

      // 3. Fetch active issues situated in this zone (subtree) - exclude resolved
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

  /// Navigates back up one level in the breadcrumb path.
  Future<void> navigateUp() async {
    final current = state.value;
    if (current == null || current.isAtRoot) return;

    if (current.currentPath.length <= 1) {
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
      final enhancedSubzones = <TechnicianZoneNode>[];

      for (final sz in rawSubzones) {
        try {
          final breakdownMap = await zoneRepo.getZoneBreakdown(sz.id);
          int szTotal = 0;
          int szWorking = 0;
          int szFaulty = 0;
          int szMaintenance = 0;

          for (final entry in breakdownMap.values) {
            szTotal += entry['total'] ?? 0;
            szWorking += entry['working'] ?? 0;
            szFaulty += entry['faulty'] ?? 0;
            szMaintenance += entry['underMaintenance'] ?? 0;
          }

          final issues = await issueRepo.getIssues(
            zoneId: sz.id,
            includeSubzones: true,
            scope: 'technician',
          );

          final activeIssues = issues.where((i) =>
              i.status != IssueStatus.resolved &&
              i.status != IssueStatus.closed).toList();

          final szUnresolvedDeviceIds = activeIssues
              .map((i) => i.deviceId)
              .where((id) => id.isNotEmpty)
              .toSet();
          final szAreaIncidents = activeIssues.where((i) => i.deviceId.isEmpty).length;
          final szNotResolvedUnits = szUnresolvedDeviceIds.length + szAreaIncidents;

          final criticalCount = activeIssues.where((i) => i.priority == IssuePriority.critical).length;
          final highCount = activeIssues.where((i) => i.priority == IssuePriority.high).length;

          final total = szTotal > 0 ? szTotal : sz.deviceCount;
          final notWorking = szNotResolvedUnits > 0 ? szNotResolvedUnits : szFaulty;
          final working = szWorking > 0
              ? szWorking
              : (total - notWorking - szMaintenance > 0 ? total - notWorking - szMaintenance : 0);

          enhancedSubzones.add(sz.copyWith(
            deviceCount: total,
            workingCount: working,
            notWorkingCount: notWorking,
            maintenanceCount: szMaintenance,
            openIssuesCount: activeIssues.length,
            unresolvedUnitsCount: szNotResolvedUnits,
            criticalIssuesCount: criticalCount,
            highIssuesCount: highCount,
          ));
        } catch (szErr) {
          AppLogger.w('⚠️ [TechnicianZoneTreeViewModel] Subzone enhance failed in reload: $szErr');
          enhancedSubzones.add(sz);
        }
      }

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

  /// Toggles between Spatial Explorer and Work Queue modes.
  void setViewMode(TechnicianViewMode mode) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(viewMode: mode));
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
