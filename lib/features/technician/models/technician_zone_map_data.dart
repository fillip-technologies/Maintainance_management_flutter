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
  final List<DeviceModel> directDevices;
  final List<TechnicianSubzoneItem> subzones;
  final List<IssueModel> issues;
  final bool isCollapsed;

  const TechnicianTopLevelZoneItem({
    required this.zone,
    this.directDevices = const [],
    this.subzones = const [],
    this.issues = const [],
    this.isCollapsed = false,
  });

  bool isDeviceDefective(DeviceModel d) {
    return issues.any((i) =>
            i.deviceId == d.id &&
            i.status != IssueStatus.resolved &&
            i.status != IssueStatus.closed) ||
        d.status == DeviceStatus.faulty ||
        d.status == DeviceStatus.underMaintenance;
  }

  int get totalDevices =>
      directDevices.length +
      subzones.fold<int>(0, (sum, s) => sum + s.totalDevices);

  int get onlineDevices =>
      directDevices
          .where((d) => !isDeviceDefective(d) && d.status == DeviceStatus.active)
          .length +
      subzones.fold<int>(0, (sum, s) => sum + s.onlineDevices);

  int get offlineDevices =>
      directDevices.where(isDeviceDefective).length +
      subzones.fold<int>(0, (sum, s) => sum + s.offlineDevices);

  int get unresolvedIssuesCount => issues
      .where((i) => i.status != IssueStatus.resolved && i.status != IssueStatus.closed)
      .length;

  double get healthPercentage =>
      totalDevices > 0 ? (onlineDevices / totalDevices) * 100.0 : 100.0;

  bool get hasIssues => offlineDevices > 0 || unresolvedIssuesCount > 0;

  int get problemScore => unresolvedIssuesCount + offlineDevices;

  TechnicianTopLevelZoneItem copyWith({
    TechnicianZoneNode? zone,
    List<DeviceModel>? directDevices,
    List<TechnicianSubzoneItem>? subzones,
    List<IssueModel>? issues,
    bool? isCollapsed,
  }) {
    return TechnicianTopLevelZoneItem(
      zone: zone ?? this.zone,
      directDevices: directDevices ?? this.directDevices,
      subzones: subzones ?? this.subzones,
      issues: issues ?? this.issues,
      isCollapsed: isCollapsed ?? this.isCollapsed,
    );
  }

  /// Sorts zones and their nested subzones issue-first (zones with active problems float to the top).
  static void sortIssueFirst(List<TechnicianTopLevelZoneItem> items) {
    items.sort((a, b) {
      final aProb = a.problemScore;
      final bProb = b.problemScore;
      if (aProb > 0 && bProb == 0) return -1;
      if (aProb == 0 && bProb > 0) return 1;
      if (aProb != bProb) return bProb.compareTo(aProb);
      return a.zone.name.toLowerCase().compareTo(b.zone.name.toLowerCase());
    });

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.subzones.length > 1) {
        final sortedSubzones = List<TechnicianSubzoneItem>.from(item.subzones);
        sortedSubzones.sort((a, b) {
          final aProb = a.problemScore;
          final bProb = b.problemScore;
          if (aProb > 0 && bProb == 0) return -1;
          if (aProb == 0 && bProb > 0) return 1;
          if (aProb != bProb) return bProb.compareTo(aProb);
          return a.zone.name.toLowerCase().compareTo(b.zone.name.toLowerCase());
        });
        items[i] = item.copyWith(subzones: sortedSubzones);
      }
    }
  }
}
