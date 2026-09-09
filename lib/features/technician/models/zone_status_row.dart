/// Visual health state for the overall zone status indicator pill.
enum ZoneOverallStatus {
  online,
  offline;

  bool get isOnline => this == ZoneOverallStatus.online;
  bool get isOffline => this == ZoneOverallStatus.offline;
}

/// Represents one row in the Technician Zone Status overview table.
class ZoneStatusRow {
  final String id;
  final String name;
  final String? imageUrl;
  final int hardwareCount;     // Summed `total` devices in zone subtree
  final int onlineCount;       // Summed `working` devices in zone subtree
  final int offlineCount;      // Summed `faulty` devices in zone subtree
  final int maintenanceCount;  // Summed `underMaintenance` devices in zone subtree
  final int openIssuesCount;   // Count of active/unresolved tickets in this zone subtree
  final bool dataLoadFailed;

  const ZoneStatusRow({
    required this.id,
    required this.name,
    this.imageUrl,
    this.hardwareCount = 0,
    this.onlineCount = 0,
    this.offlineCount = 0,
    this.maintenanceCount = 0,
    this.openIssuesCount = 0,
    this.dataLoadFailed = false,
  });

  /// Faithful to the mock: a zone reads "Online" unless it has hardware and none of it is up.
  ZoneOverallStatus get overallStatus =>
      (hardwareCount > 0 && onlineCount == 0)
          ? ZoneOverallStatus.offline
          : ZoneOverallStatus.online;

  /// True if there is at least one active issue raised that is not resolved/closed.
  bool get hasUnresolvedIssues => openIssuesCount > 0;

  /// True if the zone has hardware units but none are online.
  bool get hasNoOnlineDevices => hardwareCount > 0 && onlineCount == 0;

  /// True if the row should be flagged with red alert styling:
  /// - Has an issue raised and not solved (`hasUnresolvedIssues`)
  /// - OR has hardware but not any device online (`hasNoOnlineDevices`)
  bool get isAlerted => hasUnresolvedIssues || hasNoOnlineDevices;

  /// Returns the zone name formatted in Title Case (first letter capitalized, rest lowercase).
  String get displayName {
    if (name.trim().isEmpty) return name;
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      if (word.contains('/')) {
        return word.split('/').map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        }).join('/');
      }
      if (word.contains('-')) {
        return word.split('-').map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        }).join('-');
      }
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Folds a raw breakdown map (from GET /dashboard/zone-breakdown) into a row.
  factory ZoneStatusRow.fromBreakdown({
    required String id,
    required String name,
    String? imageUrl,
    required Map<String, Map<String, int>> breakdownMap,
    int openIssuesCount = 0,
  }) {
    var total = 0, working = 0, faulty = 0, maintenance = 0;
    for (final entry in breakdownMap.values) {
      total += entry['total'] ?? 0;
      working += entry['working'] ?? 0;
      faulty += entry['faulty'] ?? 0;
      maintenance += entry['underMaintenance'] ?? 0;
    }

    return ZoneStatusRow(
      id: id,
      name: name,
      imageUrl: imageUrl,
      hardwareCount: total,
      onlineCount: working,
      offlineCount: faulty,
      maintenanceCount: maintenance,
      openIssuesCount: openIssuesCount,
      dataLoadFailed: false,
    );
  }

  ZoneStatusRow copyWith({
    String? id,
    String? name,
    String? imageUrl,
    int? hardwareCount,
    int? onlineCount,
    int? offlineCount,
    int? maintenanceCount,
    int? openIssuesCount,
    bool? dataLoadFailed,
  }) {
    return ZoneStatusRow(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      hardwareCount: hardwareCount ?? this.hardwareCount,
      onlineCount: onlineCount ?? this.onlineCount,
      offlineCount: offlineCount ?? this.offlineCount,
      maintenanceCount: maintenanceCount ?? this.maintenanceCount,
      openIssuesCount: openIssuesCount ?? this.openIssuesCount,
      dataLoadFailed: dataLoadFailed ?? this.dataLoadFailed,
    );
  }
}
