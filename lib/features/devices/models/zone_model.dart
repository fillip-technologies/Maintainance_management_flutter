enum ZoneStatus {
  draft('draft', 'Draft'),
  active('active', 'Active'),
  inactive('inactive', 'Inactive');

  final String value;
  final String label;
  const ZoneStatus(this.value, this.label);

  static ZoneStatus fromString(String? status) {
    return ZoneStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => ZoneStatus.active,
    );
  }
}

class ZoneModel {
  final String id;
  final String clientId;
  final String? parentZoneId;
  final String name;
  final ZoneStatus status;
  final int depth;
  final int deviceCount;
  final int openIssuesCount;
  final List<ZoneModel> subZones;

  const ZoneModel({
    required this.id,
    required this.clientId,
    this.parentZoneId,
    required this.name,
    this.status = ZoneStatus.active,
    this.depth = 0,
    this.deviceCount = 0,
    this.openIssuesCount = 0,
    this.subZones = const [],
  });

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    return ZoneModel(
      id: (json['id'] as String?) ?? '',
      clientId: (json['clientId'] ?? json['client_id']) as String? ?? '',
      parentZoneId: (json['parentZoneId'] ?? json['parent_zone_id']) as String?,
      name: (json['name'] as String?) ?? 'Unknown Zone',
      status: ZoneStatus.fromString(json['status'] as String?),
      depth: (json['depth'] as num?)?.toInt() ?? 0,
      deviceCount: (json['device_count'] ?? json['deviceCount'] as num?)?.toInt() ?? 0,
      openIssuesCount: (json['open_issues_count'] ?? json['openIssuesCount'] as num?)?.toInt() ?? 0,
      subZones: (json['sub_zones'] ?? json['subZones'] as List<dynamic>?)
              ?.map((e) => ZoneModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'parent_zone_id': parentZoneId,
      'name': name,
      'status': status.value,
      'depth': depth,
      'device_count': deviceCount,
      'open_issues_count': openIssuesCount,
      'sub_zones': subZones.map((e) => e.toJson()).toList(),
    };
  }

  ZoneModel copyWith({
    String? id,
    String? clientId,
    String? parentZoneId,
    String? name,
    ZoneStatus? status,
    int? depth,
    int? deviceCount,
    int? openIssuesCount,
    List<ZoneModel>? subZones,
  }) {
    return ZoneModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      parentZoneId: parentZoneId ?? this.parentZoneId,
      name: name ?? this.name,
      status: status ?? this.status,
      depth: depth ?? this.depth,
      deviceCount: deviceCount ?? this.deviceCount,
      openIssuesCount: openIssuesCount ?? this.openIssuesCount,
      subZones: subZones ?? this.subZones,
    );
  }
}
