import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/technician_zone_tree_state.dart';

/// Holds the technician home view mode (Spatial Explorer vs Work Queue).
///
/// This is deliberately kept in its own lightweight provider rather than inside
/// [TechnicianZoneTreeState]: the zone tree goes through `AsyncValue.loading()`
/// on every refresh, and reading the mode off that async value made the toggle
/// snap back to Spatial Explorer mid-task whenever a realtime event triggered a
/// reload.
class TechnicianViewModeNotifier extends Notifier<TechnicianViewMode> {
  @override
  TechnicianViewMode build() => TechnicianViewMode.zoneStatusTable;

  void setMode(TechnicianViewMode mode) => state = mode;
}

final technicianViewModeProvider =
    NotifierProvider<TechnicianViewModeNotifier, TechnicianViewMode>(
  TechnicianViewModeNotifier.new,
);
