enum DailyLogStatus {
  working('working', 'Working', 'Operational and performing normally'),
  notWorking('not_working', 'Not Working', 'Device is down or non-responsive'),
  needsAttention('needs_attention', 'Needs Attention', 'Partially working / early warning signs');

  final String value;
  final String label;
  final String description;
  const DailyLogStatus(this.value, this.label, this.description);

  static DailyLogStatus fromString(String? status) {
    return DailyLogStatus.values.firstWhere(
      (e) => e.value == status || e.name == status,
      orElse: () => DailyLogStatus.working,
    );
  }
}

class DailyStatusLogModel {
  final String id;
  final String deviceId;
  final String deviceName;
  final String zoneId;
  final String zoneName;
  final String loggedByUserId;
  final String loggedByUserName;
  final DailyLogStatus status;
  final String? notes;
  final DateTime logDate;
  final DateTime createdAt;

  const DailyStatusLogModel({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    this.zoneId = '',
    this.zoneName = '',
    required this.loggedByUserId,
    required this.loggedByUserName,
    required this.status,
    this.notes,
    required this.logDate,
    required this.createdAt,
  });

  factory DailyStatusLogModel.fromJson(Map<String, dynamic> json) {
    final devObj = json['device'] as Map<String, dynamic>?;
    final loggedByObj = (json['loggedBy'] ?? json['logged_by']) as Map<String, dynamic>?;

    final logDateStr = (json['logDate'] ?? json['log_date']) as String?;
    final createdDateStr = (json['createdAt'] ?? json['created_at']) as String?;

    return DailyStatusLogModel(
      id: (json['id'] as String?) ?? '',
      deviceId: (json['deviceId'] ?? json['device_id'] ?? devObj?['id']) as String? ?? '',
      deviceName: (json['deviceName'] ?? json['device_name'] ?? devObj?['name']) as String? ?? 'Device',
      zoneId: (json['zoneId'] ?? json['zone_id'] ?? devObj?['zoneId']) as String? ?? '',
      zoneName: (json['zoneName'] ?? json['zone_name']) as String? ?? 'Zone',
      loggedByUserId: (json['loggedByUserId'] ?? json['logged_by_user_id'] ?? loggedByObj?['id']) as String? ?? '',
      loggedByUserName: (json['loggedByName'] ?? json['logged_by_name'] ?? json['loggedByUserName'] ?? loggedByObj?['name']) as String? ?? 'Staff',
      status: DailyLogStatus.fromString(json['status'] as String?),
      notes: json['notes'] as String?,
      logDate: logDateStr != null ? (DateTime.tryParse(logDateStr) ?? DateTime.now()) : DateTime.now(),
      createdAt: createdDateStr != null ? (DateTime.tryParse(createdDateStr) ?? DateTime.now()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'device_name': deviceName,
      'zone_id': zoneId,
      'zone_name': zoneName,
      'logged_by_user_id': loggedByUserId,
      'logged_by_user_name': loggedByUserName,
      'status': status.value,
      'notes': notes,
      'log_date': logDate.toIso8601String().split('T').first,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
