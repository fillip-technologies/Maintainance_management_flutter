enum DeviceStatus {
  provisioned('provisioned', 'Provisioned'),
  active('active', 'Active'),
  underMaintenance('under_maintenance', 'Under Maintenance'),
  faulty('faulty', 'Faulty'),
  retired('retired', 'Retired');

  final String value;
  final String label;
  const DeviceStatus(this.value, this.label);

  static DeviceStatus fromString(String? status) {
    return DeviceStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => DeviceStatus.active,
    );
  }
}

class DeviceModel {
  final String id;
  final String zoneId;
  final String zoneName;
  final String? hardwareTypeId;
  final String hardwareTypeName;
  final String name;
  final String serialNumber;
  final String location;
  final DeviceStatus status;
  final bool isManualEntry;
  final Map<String, dynamic> specFields;
  final DateTime? lastCheckedAt;
  final int consecutiveFailures;

  const DeviceModel({
    required this.id,
    required this.zoneId,
    required this.zoneName,
    this.hardwareTypeId,
    required this.hardwareTypeName,
    required this.name,
    required this.serialNumber,
    required this.location,
    this.status = DeviceStatus.active,
    this.isManualEntry = false,
    this.specFields = const {},
    this.lastCheckedAt,
    this.consecutiveFailures = 0,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String,
      zoneId: json['zone_id'] as String,
      zoneName: json['zone_name'] as String? ?? 'Unknown Zone',
      hardwareTypeId: json['hardware_type_id'] as String?,
      hardwareTypeName: json['hardware_type_name'] as String? ?? 'CCTV Camera',
      name: json['name'] as String,
      serialNumber: json['serial_number'] as String? ?? '',
      location: json['location'] as String? ?? '',
      status: DeviceStatus.fromString(json['status'] as String?),
      isManualEntry: json['is_manual_entry'] as bool? ?? false,
      specFields: json['spec_fields'] as Map<String, dynamic>? ?? const {},
      lastCheckedAt: json['last_checked_at'] != null
          ? DateTime.tryParse(json['last_checked_at'] as String)
          : null,
      consecutiveFailures: (json['consecutive_failures'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'zone_id': zoneId,
      'zone_name': zoneName,
      'hardware_type_id': hardwareTypeId,
      'hardware_type_name': hardwareTypeName,
      'name': name,
      'serial_number': serialNumber,
      'location': location,
      'status': status.value,
      'is_manual_entry': isManualEntry,
      'spec_fields': specFields,
      'last_checked_at': lastCheckedAt?.toIso8601String(),
      'consecutive_failures': consecutiveFailures,
    };
  }

  DeviceModel copyWith({
    String? id,
    String? zoneId,
    String? zoneName,
    String? hardwareTypeId,
    String? hardwareTypeName,
    String? name,
    String? serialNumber,
    String? location,
    DeviceStatus? status,
    bool? isManualEntry,
    Map<String, dynamic>? specFields,
    DateTime? lastCheckedAt,
    int? consecutiveFailures,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      zoneName: zoneName ?? this.zoneName,
      hardwareTypeId: hardwareTypeId ?? this.hardwareTypeId,
      hardwareTypeName: hardwareTypeName ?? this.hardwareTypeName,
      name: name ?? this.name,
      serialNumber: serialNumber ?? this.serialNumber,
      location: location ?? this.location,
      status: status ?? this.status,
      isManualEntry: isManualEntry ?? this.isManualEntry,
      specFields: specFields ?? this.specFields,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
    );
  }
}
