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
      (e) => e.value == status,
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
      (e) => e.value == priority,
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
      id: json['id'] as String,
      name: json['name'] as String,
      hardwareTypeId: json['hardware_type_id'] as String?,
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
    return IssueStatusHistoryModel(
      id: json['id'] as String,
      issueId: json['issue_id'] as String,
      fromStatus: json['from_status'] != null
          ? IssueStatus.fromString(json['from_status'] as String)
          : null,
      toStatus: IssueStatus.fromString(json['to_status'] as String),
      changedByUserId: json['changed_by_user_id'] as String,
      changedByUserName: json['changed_by_user_name'] as String? ?? 'System',
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
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
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
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
  final List<IssueStatusHistoryModel> history;

  const IssueModel({
    required this.id,
    required this.title,
    required this.description,
    required this.deviceId,
    required this.deviceName,
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
    this.history = const [],
  });

  factory IssueModel.fromJson(Map<String, dynamic> json) {
    return IssueModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Maintenance Request',
      description: json['description'] as String? ?? '',
      deviceId: json['device_id'] as String,
      deviceName: json['device_name'] as String? ?? 'Unknown Device',
      zoneId: json['zone_id'] as String? ?? '',
      zoneName: json['zone_name'] as String? ?? 'Unknown Zone',
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String? ?? 'General Fault',
      priority: IssuePriority.fromString(json['priority'] as String?),
      status: IssueStatus.fromString(json['status'] as String?),
      assignedTechnicianId: json['assigned_technician_id'] as String?,
      assignedTechnicianName: json['assigned_technician_name'] as String?,
      createdByUserId: json['created_by_user_id'] as String? ?? '',
      createdByUserName: json['created_by_user_name'] as String? ?? 'Staff',
      imagePath: json['image_path'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      history: (json['history'] as List<dynamic>?)
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
      'zone_id': zoneId,
      'zone_name': zoneName,
      'category_id': categoryId,
      'category_name': categoryName,
      'priority': priority.value,
      'status': status.value,
      'assigned_technician_id': assignedTechnicianId,
      'assigned_technician_name': assignedTechnicianName,
      'created_by_user_id': createdByUserId,
      'created_by_user_name': createdByUserName,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
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
      history: history ?? this.history,
    );
  }
}
