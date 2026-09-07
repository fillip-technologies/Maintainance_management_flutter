import 'device_model.dart';
import '../../issues/models/issue_model.dart';

/// Visual health status of a zone in the hierarchy tree.
enum ZoneHealthStatus {
  critical, // 🔴 At least 1 critical defect present at this level or below
  warning,  // 🟠 High/medium defects or faulty units present
  healthy;  // 🟢 All devices operational, 0 open issues

  String get label {
    switch (this) {
      case ZoneHealthStatus.critical:
        return 'Critical Attention Required';
      case ZoneHealthStatus.warning:
        return 'Needs Attention';
      case ZoneHealthStatus.healthy:
        return 'All Systems Nominal';
    }
  }
}

/// Represents a node in the technician's spatial zone hierarchy tree.
class TechnicianZoneNode {
  final String id;
  final String name;
  final String? parentZoneId;
  final int depth;
  final String status;
  final String? clientName;

  // Inventory & operational counts
  final int deviceCount;
  final int subzoneCount;
  final int workingCount;
  final int notWorkingCount;
  final int maintenanceCount;

  // Defect metrics (bubbled up from this zone and all descendants)
  final int openIssuesCount;
  final int criticalIssuesCount;
  final int highIssuesCount;
  final int unresolvedUnitsCount;

  // Children & leaf collections
  final List<TechnicianZoneNode> subzones;
  final List<DeviceModel> devices;
  final List<IssueModel> openIssues;

  const TechnicianZoneNode({
    required this.id,
    required this.name,
    this.parentZoneId,
    this.depth = 0,
    this.status = 'active',
    this.clientName,
    this.deviceCount = 0,
    this.subzoneCount = 0,
    this.workingCount = 0,
    this.notWorkingCount = 0,
    this.maintenanceCount = 0,
    this.openIssuesCount = 0,
    this.criticalIssuesCount = 0,
    this.highIssuesCount = 0,
    this.unresolvedUnitsCount = 0,
    this.subzones = const [],
    this.devices = const [],
    this.openIssues = const [],
  });

  /// Computed visual health status based on defect severity and device faultiness.
  ZoneHealthStatus get healthStatus {
    if (criticalIssuesCount > 0) {
      return ZoneHealthStatus.critical;
    }
    if (highIssuesCount > 0 || unresolvedUnitsCount > 0 || openIssuesCount > 0 || notWorkingCount > 0) {
      return ZoneHealthStatus.warning;
    }
    return ZoneHealthStatus.healthy;
  }

  /// Operational percentage (e.g. 85%).
  int get operationalPercentage {
    final total = deviceCount > 0 ? deviceCount : devices.length;
    if (total == 0) return 100;
    final working = workingCount > 0 ? workingCount : (total - notWorkingCount);
    final clampedWorking = working < 0 ? 0 : working;
    return ((clampedWorking / total) * 100).round().clamp(0, 100);
  }

  bool get isTopLevel => depth == 0 || parentZoneId == null;
  bool get hasSubzones => subzones.isNotEmpty || subzoneCount > 0;
  bool get hasDevices => devices.isNotEmpty || deviceCount > 0;
  bool get hasIssues => unresolvedUnitsCount > 0 || openIssuesCount > 0 || openIssues.isNotEmpty;

  TechnicianZoneNode copyWith({
    String? id,
    String? name,
    String? parentZoneId,
    int? depth,
    String? status,
    String? clientName,
    int? deviceCount,
    int? subzoneCount,
    int? workingCount,
    int? notWorkingCount,
    int? maintenanceCount,
    int? openIssuesCount,
    int? criticalIssuesCount,
    int? highIssuesCount,
    int? unresolvedUnitsCount,
    List<TechnicianZoneNode>? subzones,
    List<DeviceModel>? devices,
    List<IssueModel>? openIssues,
  }) {
    return TechnicianZoneNode(
      id: id ?? this.id,
      name: name ?? this.name,
      parentZoneId: parentZoneId ?? this.parentZoneId,
      depth: depth ?? this.depth,
      status: status ?? this.status,
      clientName: clientName ?? this.clientName,
      deviceCount: deviceCount ?? this.deviceCount,
      subzoneCount: subzoneCount ?? this.subzoneCount,
      workingCount: workingCount ?? this.workingCount,
      notWorkingCount: notWorkingCount ?? this.notWorkingCount,
      maintenanceCount: maintenanceCount ?? this.maintenanceCount,
      openIssuesCount: openIssuesCount ?? this.openIssuesCount,
      criticalIssuesCount: criticalIssuesCount ?? this.criticalIssuesCount,
      highIssuesCount: highIssuesCount ?? this.highIssuesCount,
      unresolvedUnitsCount: unresolvedUnitsCount ?? this.unresolvedUnitsCount,
      subzones: subzones ?? this.subzones,
      devices: devices ?? this.devices,
      openIssues: openIssues ?? this.openIssues,
    );
  }

  factory TechnicianZoneNode.fromJson(Map<String, dynamic> json) {
    final clientObj = json['client'] as Map<String, dynamic>?;
    final countObj = json['_count'] as Map<String, dynamic>?;

    final subzonesRaw = json['subzones'] is List
        ? (json['subzones'] as List)
        : (json['children'] is List ? (json['children'] as List) : const []);

    final devicesRaw = json['devices'] is List
        ? (json['devices'] as List)
        : const [];

    final issuesRaw = json['issues'] is List
        ? (json['issues'] as List)
        : (json['openIssues'] is List ? (json['openIssues'] as List) : const []);

    final openIssuesCount = (json['openIssuesCount'] as num?)?.toInt() ??
        (json['openIssues'] is num ? (json['openIssues'] as num).toInt() : null) ??
        issuesRaw.length;

    final deviceCount = (json['deviceCount'] as num?)?.toInt() ??
        (countObj?['devices'] as num?)?.toInt() ??
        devicesRaw.length;

    final subzoneCount = (json['subzoneCount'] as num?)?.toInt() ??
        (countObj?['children'] as num?)?.toInt() ??
        subzonesRaw.length;

    final unresolvedUnitsCount = (json['unresolvedUnitsCount'] as num?)?.toInt() ??
        (json['unresolvedUnits'] as num?)?.toInt() ??
        openIssuesCount;

    return TechnicianZoneNode(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Unknown Zone',
      parentZoneId: (json['parentZoneId'] ?? json['parent_zone_id']) as String?,
      depth: (json['depth'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? 'active',
      clientName: (json['clientName'] as String?) ?? (clientObj?['name'] as String?),
      deviceCount: deviceCount,
      subzoneCount: subzoneCount,
      workingCount: (json['workingCount'] ?? json['working'] as num?)?.toInt() ?? 0,
      notWorkingCount: (json['notWorkingCount'] ?? json['faulty'] as num?)?.toInt() ?? 0,
      maintenanceCount: (json['maintenanceCount'] ?? json['underMaintenance'] as num?)?.toInt() ?? 0,
      openIssuesCount: openIssuesCount,
      criticalIssuesCount: (json['criticalIssuesCount'] as num?)?.toInt() ?? 0,
      highIssuesCount: (json['highIssuesCount'] as num?)?.toInt() ?? 0,
      unresolvedUnitsCount: unresolvedUnitsCount,
      subzones: subzonesRaw
          .whereType<Map<String, dynamic>>()
          .map<TechnicianZoneNode>((e) => TechnicianZoneNode.fromJson(e))
          .toList(),
      devices: devicesRaw
          .whereType<Map<String, dynamic>>()
          .map<DeviceModel>((e) => DeviceModel.fromJson(e))
          .toList(),
      openIssues: issuesRaw
          .whereType<Map<String, dynamic>>()
          .map<IssueModel>((e) => IssueModel.fromJson(e))
          .toList(),
    );
  }
}
