import '../../devices/models/device_model.dart';
import '../../devices/models/technician_zone_node.dart';
import '../../issues/models/issue_model.dart';

/// Active viewing mode for the technician home interface.
///
/// The selected mode lives in `technicianViewModeProvider`, not in
/// [TechnicianZoneTreeState], so it survives the tree's async reloads.
enum TechnicianViewMode {
  spatialExplorer, // 🗺️ Zone-tree and spatial drill-down view
  zoneStatusTable, // 📊 Tabular zone hardware health overview
  workQueue;       // 📋 Flat ticket list (Active, On-Hold, Resolved)
}

/// Complete state for the technician zone hierarchy explorer.
class TechnicianZoneTreeState {
  /// Top-level zones assigned to this technician.
  final List<TechnicianZoneNode> rootZones;

  /// Navigation path trail (breadcrumbs). Empty list means at root overview.
  final List<TechnicianZoneNode> currentPath;

  /// Direct child sub-zones under the currently focused zone.
  final List<TechnicianZoneNode> currentSubzones;

  /// Devices installed directly in the currently focused zone.
  final List<DeviceModel> currentDevices;

  /// Active defects at the current zone level or its children.
  final List<IssueModel> currentIssues;

  /// Loading flags.
  final bool isLoading;
  final bool isDrillingDown;

  /// Error message if an operation failed.
  final String? errorMessage;

  /// Filter search query.
  final String searchQuery;

  const TechnicianZoneTreeState({
    this.rootZones = const [],
    this.currentPath = const [],
    this.currentSubzones = const [],
    this.currentDevices = const [],
    this.currentIssues = const [],
    this.isLoading = false,
    this.isDrillingDown = false,
    this.errorMessage,
    this.searchQuery = '',
  });

  /// Currently focused zone (top of navigation breadcrumbs), or null if at root.
  TechnicianZoneNode? get currentZone => currentPath.isNotEmpty ? currentPath.last : null;

  /// Whether currently at the root level.
  bool get isAtRoot => currentPath.isEmpty;

  /// Number of breadcrumb levels deep (0 = root overview).
  int get currentDepth => currentPath.length;

  TechnicianZoneTreeState copyWith({
    List<TechnicianZoneNode>? rootZones,
    List<TechnicianZoneNode>? currentPath,
    List<TechnicianZoneNode>? currentSubzones,
    List<DeviceModel>? currentDevices,
    List<IssueModel>? currentIssues,
    bool? isLoading,
    bool? isDrillingDown,
    String? errorMessage,
    bool clearError = false,
    String? searchQuery,
  }) {
    return TechnicianZoneTreeState(
      rootZones: rootZones ?? this.rootZones,
      currentPath: currentPath ?? this.currentPath,
      currentSubzones: currentSubzones ?? this.currentSubzones,
      currentDevices: currentDevices ?? this.currentDevices,
      currentIssues: currentIssues ?? this.currentIssues,
      isLoading: isLoading ?? this.isLoading,
      isDrillingDown: isDrillingDown ?? this.isDrillingDown,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
