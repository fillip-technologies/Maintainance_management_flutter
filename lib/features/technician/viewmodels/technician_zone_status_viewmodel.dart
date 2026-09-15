import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/zone_status_row.dart';
import 'technician_zone_tree_viewmodel.dart';

/// Manages data loading and health aggregation for the Technician Zone Status table overview.
///
/// Fully unified with the Zone Map ([TechnicianZoneTreeViewModel]): shares the exact same
/// loaded dataset (zones, subzones, devices, and defects) so that switching between
/// Zone Status and Zone Map is instantaneous with zero duplicate API calls.
class TechnicianZoneStatusViewModel extends AsyncNotifier<List<ZoneStatusRow>> {
  @override
  Future<List<ZoneStatusRow>> build() async {
    // Watch the zone tree viewmodel so any updates or reloads automatically cascade here
    final treeState = await ref.watch(technicianZoneTreeViewModelProvider.future);

    if (treeState.zoneSections.isEmpty) {
      // If tree is still loading or fell back to bare roots
      if (treeState.rootZones.isNotEmpty) {
        return treeState.rootZones
            .map((r) => ZoneStatusRow.fromBareNode(
                  id: r.id,
                  name: r.name,
                  imageUrl: r.imageUrl,
                  isEnriching: treeState.isLoading,
                ))
            .toList();
      }
      return const <ZoneStatusRow>[];
    }

    // Fast in-memory transformation: maps zoneSections directly to ZoneStatusRow!
    return treeState.zoneSections
        .map((sec) => ZoneStatusRow.fromTopLevelZoneItem(sec))
        .toList();
  }

  /// Triggers a full reload of the shared data source (used by pull-to-refresh & retry button).
  Future<void> refresh() async {
    await ref.read(technicianZoneTreeViewModelProvider.notifier).refresh();
  }
}

final technicianZoneStatusViewModelProvider =
    AsyncNotifierProvider<TechnicianZoneStatusViewModel, List<ZoneStatusRow>>(
  TechnicianZoneStatusViewModel.new,
);
