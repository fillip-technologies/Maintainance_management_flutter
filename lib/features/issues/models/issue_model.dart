import '../../devices/devices.dart';

enum IssueStatus {
  open('open', 'Open'),
  assigned('assigned', 'Assigned'),
  inProgress('in_progress', 'In Progress'),
  onHold('on_hold', 'On Hold'),
  resolved('resolved', 'Resolved'),
  closed('closed', 'Closed'),
  reopened('reopened', 'Reopened');

  final String value;
  final String label;
  const IssueStatus(this.value, this.label);

  static IssueStatus fromString(String? status) {
    return IssueStatus.values.firstWhere(
      (e) => e.value == status || e.name == status,
      orElse: () => IssueStatus.open,
    );
  }
}

enum IssuePriority {
  low('low', 'Low'),
  medium('medium', 'Medium'),
  high('high', 'High'),
  critical('critical', 'Critical');

  final String value;
  final String label;
  const IssuePriority(this.value, this.label);

  static IssuePriority fromString(String? priority) {
    return IssuePriority.values.firstWhere(
      (e) => e.value == priority || e.name == priority,
      orElse: () => IssuePriority.medium,
    );
  }
}

class IssueCategoryModel {
  final String id;
  final String name;
  final String? hardwareTypeId;

  const IssueCategoryModel({
    required this.id,
    required this.name,
    this.hardwareTypeId,
  });

  factory IssueCategoryModel.fromJson(Map<String, dynamic> json) {
    return IssueCategoryModel(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'General Issue',
      hardwareTypeId: (json['hardwareTypeId'] ?? json['hardware_type_id']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hardware_type_id': hardwareTypeId,
    };
  }
}

class IssueStatusHistoryModel {
  final String id;
  final String issueId;
  final IssueStatus? fromStatus;
  final IssueStatus toStatus;
  final String changedByUserId;
  final String changedByUserName;
  final String? comment;
  final DateTime createdAt;

  const IssueStatusHistoryModel({
    required this.id,
    required this.issueId,
    this.fromStatus,
    required this.toStatus,
    required this.changedByUserId,
    required this.changedByUserName,
    this.comment,
    required this.createdAt,
  });

  factory IssueStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    final changedByObj = json['changedBy'] as Map<String, dynamic>?;

    final dateStr = (json['changedAt'] ?? json['changed_at'] ?? json['createdAt'] ?? json['created_at']) as String?;
    final date = dateStr != null ? (DateTime.tryParse(dateStr) ?? DateTime.now()) : DateTime.now();

    return IssueStatusHistoryModel(
      id: (json['id'] as String?) ?? '',
      issueId: (json['issueId'] ?? json['issue_id']) as String? ?? '',
      fromStatus: json['fromStatus'] != null
          ? IssueStatus.fromString(json['fromStatus'] as String)
          : json['from_status'] != null
              ? IssueStatus.fromString(json['from_status'] as String)
              : null,
      toStatus: IssueStatus.fromString((json['toStatus'] ?? json['to_status']) as String?),
      changedByUserId: (json['changedByUserId'] ?? json['changed_by_user_id'] ?? changedByObj?['id']) as String? ?? '',
      changedByUserName: (json['changedByUserName'] ?? json['changed_by_user_name'] ?? changedByObj?['name']) as String? ?? 'System',
      comment: (json['notes'] ?? json['comment']) as String?,
      createdAt: date,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'issue_id': issueId,
      'from_status': fromStatus?.value,
      'to_status': toStatus.value,
      'changed_by_user_id': changedByUserId,
      'changed_by_user_name': changedByUserName,
      'notes': comment,
      'changed_at': createdAt.toIso8601String(),
    };
  }
}

class IssueModel {
  final String id;
  final String title;
  final String description;
  final String deviceId;
  final String deviceName;
  final String zoneId;
  final String zoneName;
  final String categoryId;
  final String categoryName;
  final IssuePriority priority;
  final IssueStatus status;
  final String? assignedTechnicianId;
  final String? assignedTechnicianName;
  final String createdByUserId;
  final String createdByUserName;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DeviceStatus? deviceStatus;
  final String? deviceCode;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final List<IssueStatusHistoryModel> history;

  const IssueModel({
    required this.id,
    required this.title,
    required this.description,
    required this.deviceId,
    required this.deviceName,
    this.deviceStatus,
    this.deviceCode,
    required this.zoneId,
    required this.zoneName,
    required this.categoryId,
    required this.categoryName,
    this.priority = IssuePriority.medium,
    this.status = IssueStatus.open,
    this.assignedTechnicianId,
    this.assignedTechnicianName,
    required this.createdByUserId,
    required this.createdByUserName,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.closedAt,
    this.history = const [],
  });

  factory IssueModel.fromJson(Map<String, dynamic> json) {
    final deviceObj = json['device'] as Map<String, dynamic>?;
    final zoneObj = deviceObj?['zone'] as Map<String, dynamic>?;
    final categoryObj = json['category'] as Map<String, dynamic>?;
    final raisedByObj = (json['raisedBy'] ?? json['raised_by']) as Map<String, dynamic>?;
    final techObj = (json['assignedTechnician'] ?? json['assigned_technician']) as Map<String, dynamic>?;
    final techUserObj = techObj?['user'] as Map<String, dynamic>?;

    final createdDateStr = (json['createdAt'] ?? json['created_at']) as String?;
    final updatedDateStr = (json['updatedAt'] ?? json['updated_at']) as String?;
    final resolvedDateStr = (json['resolvedAt'] ?? json['resolved_at']) as String?;
    final closedDateStr = (json['closedAt'] ?? json['closed_at']) as String?;

    final historyList = (json['statusHistory'] ?? json['history']) as List<dynamic>?;

    final catName = (json['categoryName'] ?? json['category_name'] ?? categoryObj?['name']) as String? ?? 'General Fault';
    final devName = (json['deviceName'] ?? json['device_name'] ?? deviceObj?['name']) as String? ?? 'Unknown Device';
    final defaultTitle = (json['title'] as String?) ?? '$devName - $catName';

    return IssueModel(
      id: (json['id'] as String?) ?? '',
      title: defaultTitle,
      description: (json['description'] as String?) ?? '',
      deviceId: (json['deviceId'] ?? json['device_id'] ?? deviceObj?['id']) as String? ?? '',
      deviceName: devName,
      deviceStatus: DeviceStatus.fromString((json['deviceStatus'] ?? json['device_status'] ?? deviceObj?['status']) as String?),
      deviceCode: (json['deviceCode'] ?? json['device_code'] ?? deviceObj?['code']) as String?,
      zoneId: (json['zoneId'] ?? json['zone_id'] ?? deviceObj?['zoneId'] ?? zoneObj?['id']) as String? ?? '',
      zoneName: (json['zoneName'] ?? json['zone_name'] ?? zoneObj?['name']) as String? ?? 'Unknown Zone',
      categoryId: (json['categoryId'] ?? json['category_id'] ?? categoryObj?['id']) as String? ?? '',
      categoryName: catName,
      priority: IssuePriority.fromString((json['priority']) as String?),
      status: IssueStatus.fromString((json['status']) as String?),
      assignedTechnicianId: (json['assignedTechnicianId'] ?? json['assigned_technician_id'] ?? techObj?['id']) as String?,
      assignedTechnicianName: (json['assignedTechnicianName'] ?? json['assigned_technician_name'] ?? techUserObj?['name']) as String?,
      createdByUserId: (json['raisedByUserId'] ?? json['raised_by_user_id'] ?? json['createdByUserId'] ?? raisedByObj?['id']) as String? ?? '',
      createdByUserName: (json['raisedByUserName'] ?? json['raised_by_user_name'] ?? json['createdByUserName'] ?? raisedByObj?['name']) as String? ?? 'Staff',
      imagePath: (json['imagePath'] ?? json['image_path']) as String?,
      createdAt: createdDateStr != null ? (DateTime.tryParse(createdDateStr) ?? DateTime.now()) : DateTime.now(),
      updatedAt: updatedDateStr != null ? (DateTime.tryParse(updatedDateStr) ?? DateTime.now()) : DateTime.now(),
      resolvedAt: resolvedDateStr != null ? DateTime.tryParse(resolvedDateStr) : null,
      closedAt: closedDateStr != null ? DateTime.tryParse(closedDateStr) : null,
      history: historyList
              ?.map((e) => IssueStatusHistoryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'device_id': deviceId,
      'device_name': deviceName,
      'device_status': deviceStatus?.value,
      'device_code': deviceCode,
      'zone_id': zoneId,
      'zone_name': zoneName,
      'category_id': categoryId,
      'category_name': categoryName,
      'priority': priority.value,
      'status': status.value,
      'assigned_technician_id': assignedTechnicianId,
      'assigned_technician_name': assignedTechnicianName,
      'raised_by_user_id': createdByUserId,
      'raised_by_user_name': createdByUserName,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'history': history.map((e) => e.toJson()).toList(),
    };
  }

  IssueModel copyWith({
    String? id,
    String? title,
    String? description,
    String? deviceId,
    String? deviceName,
    String? zoneId,
    String? zoneName,
    String? categoryId,
    String? categoryName,
    IssuePriority? priority,
    IssueStatus? status,
    String? assignedTechnicianId,
    String? assignedTechnicianName,
    String? createdByUserId,
    String? createdByUserName,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    DateTime? closedAt,
    List<IssueStatusHistoryModel>? history,
  }) {
    return IssueModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      zoneId: zoneId ?? this.zoneId,
      zoneName: zoneName ?? this.zoneName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assignedTechnicianId: assignedTechnicianId ?? this.assignedTechnicianId,
      assignedTechnicianName:
          assignedTechnicianName ?? this.assignedTechnicianName,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByUserName: createdByUserName ?? this.createdByUserName,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      closedAt: closedAt ?? this.closedAt,
      history: history ?? this.history,
    );
  }

  String get raisedByName => createdByUserName;
}
