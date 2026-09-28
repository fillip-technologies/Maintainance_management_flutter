import '../../devices/models/device_model.dart';
import '../../devices/models/technician_zone_node.dart';
import '../../issues/models/issue_model.dart';

/// Represents a child subzone inside a top-level zone Big Card.
class TechnicianSubzoneItem {
  final TechnicianZoneNode zone;
  final List<DeviceModel> devices;
  final List<IssueModel> issues;

  const TechnicianSubzoneItem({
    required this.zone,
    required this.devices,
    this.issues = const [],
  });

  bool isDeviceDefective(DeviceModel d) {
    return issues.any((i) =>
            i.deviceId == d.id &&
            i.status != IssueStatus.resolved &&
            i.status != IssueStatus.closed) ||
        d.status == DeviceStatus.faulty ||
        d.status == DeviceStatus.underMaintenance;
  }

  int get totalDevices => devices.length;

  int get onlineDevices =>
      devices.where((d) => !isDeviceDefective(d) && d.status == DeviceStatus.active).length;

  int get offlineDevices => devices.where(isDeviceDefective).length;

  int get unresolvedIssuesCount => issues
      .where((i) => i.status != IssueStatus.resolved && i.status != IssueStatus.closed)
      .length;

  double get healthPercentage =>
      totalDevices > 0 ? (onlineDevices / totalDevices) * 100.0 : 100.0;

  bool get hasIssues => offlineDevices > 0 || unresolvedIssuesCount > 0;

  int get problemScore => unresolvedIssuesCount + offlineDevices;

  TechnicianSubzoneItem copyWith({
    TechnicianZoneNode? zone,
    List<DeviceModel>? devices,
    List<IssueModel>? issues,
  }) {
    return TechnicianSubzoneItem(
      zone: zone ?? this.zone,
      devices: devices ?? this.devices,
      issues: issues ?? this.issues,
    );
  }
}

/// Represents a top-level facility zone rendered as a Big Card.
class TechnicianTopLevelZoneItem {
  final TechnicianZoneNode zone;
  final List<DeviceModel> devices;
  final List<IssueModel> issues;
  final bool isCollapsed;

  const TechnicianTopLevelZoneItem({
    required this.zone,
    List<DeviceModel>? devices,
    List<DeviceModel>? directDevices,
    this.issues = const [],
    this.isCollapsed = false,
  }) : devices = devices ?? directDevices ?? const [];

  /// Backward-compatibility alias for [devices].
  List<DeviceModel> get directDevices => devices;

  /// Returns all defective / offline devices in this zone.
  List<DeviceModel> get offlineDeviceList => devices.where(isDeviceDefective).toList();

  bool isDeviceDefective(DeviceModel d) {
    return issues.any((i) =>
            i.deviceId == d.id &&
            i.status != IssueStatus.resolved &&
            i.status != IssueStatus.closed) ||
        d.status == DeviceStatus.faulty ||
        d.status == DeviceStatus.underMaintenance;
  }

  int get totalDevices => devices.length;

  int get onlineDevices =>
      devices.where((d) => !isDeviceDefective(d) && d.status == DeviceStatus.active).length;

  int get offlineDevices => devices.where(isDeviceDefective).length;

  int get unresolvedIssuesCount => issues
      .where((i) => i.status != IssueStatus.resolved && i.status != IssueStatus.closed)
      .length;

  double get healthPercentage =>
      totalDevices > 0 ? (onlineDevices / totalDevices) * 100.0 : 100.0;

  bool get hasIssues => offlineDevices > 0 || unresolvedIssuesCount > 0;

  int get problemScore => unresolvedIssuesCount + offlineDevices;

  TechnicianTopLevelZoneItem copyWith({
    TechnicianZoneNode? zone,
    List<DeviceModel>? devices,
    List<DeviceModel>? directDevices,
    List<IssueModel>? issues,
    bool? isCollapsed,
  }) {
    return TechnicianTopLevelZoneItem(
      zone: zone ?? this.zone,
      devices: devices ?? directDevices ?? this.devices,
      issues: issues ?? this.issues,
      isCollapsed: isCollapsed ?? this.isCollapsed,
    );
  }

  /// Sorts zones issue-first (zones with active problems float to the top).
  static void sortIssueFirst(List<TechnicianTopLevelZoneItem> items) {
    items.sort((a, b) {
      final aProb = a.problemScore;
      final bProb = b.problemScore;
      if (aProb > 0 && bProb == 0) return -1;
      if (aProb == 0 && bProb > 0) return 1;
      if (aProb != bProb) return bProb.compareTo(aProb);
      return a.zone.name.toLowerCase().compareTo(b.zone.name.toLowerCase());
    });
  }
}
