enum UserRole {
  superAdmin('super_admin', 'Super Admin'),
  clientAdmin('client_admin', 'Client Admin'),
  zoneIncharge('zone_incharge', 'Zone Incharge / Head'),
  zoneStaff('zone_staff', 'Zone Staff'),
  technician('technician', 'Technician');

  final String value;
  final String label;

  const UserRole(this.value, this.label);

  static UserRole fromString(String? role) {
    if (role == null || role.trim().isEmpty) return UserRole.zoneStaff;
    final normalized = role
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    return UserRole.values.firstWhere(
      (e) =>
          e.value.toLowerCase() == normalized ||
          e.name.toLowerCase() == normalized ||
          (normalized.contains('tech') && e == UserRole.technician) ||
          (normalized.contains('incharge') && e == UserRole.zoneIncharge),
      orElse: () => UserRole.zoneStaff,
    );
  }

  bool get isZoneHeadOrStaff =>
      this == UserRole.zoneIncharge || this == UserRole.zoneStaff;

  bool get isTechnician => this == UserRole.technician;

  bool get isAdmin =>
      this == UserRole.clientAdmin || this == UserRole.superAdmin;
}

/// A zone a user is assigned to (an officer may hold several).
class AssignedZone {
  final String id;
  final String name;
  final String? logoUrl;

  const AssignedZone({required this.id, required this.name, this.logoUrl});

  factory AssignedZone.fromJson(Map<String, dynamic> json) => AssignedZone(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        logoUrl: (json['logoUrl'] ?? json['logo_url']) as String?,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'logo_url': logoUrl};
}

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;

  final String? clientId;
  final String? assignedZoneId;
  final String? assignedZoneName;
  final List<AssignedZone> assignedZones;
  final String? zoneLogoUrl;
  final String? technicianId;
  final String accountStatus;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.clientId,
    this.assignedZoneId,
    this.assignedZoneName,
    this.assignedZones = const [],
    this.zoneLogoUrl,
    this.technicianId,
    this.accountStatus = 'active',
  });

  /// Ids of every zone the user is assigned to (falls back to the primary zone).
  List<String> get assignedZoneIds => assignedZones.isNotEmpty
      ? assignedZones.map((z) => z.id).toList()
      : [?assignedZoneId];

  /// True when [zoneId] is one of the user's zones. A user with no zone
  /// assignment is unrestricted (matches the previous single-zone behaviour).
  bool isInAssignedZones(String? zoneId) {
    final ids = assignedZoneIds;
    return ids.isEmpty || (zoneId != null && ids.contains(zoneId));
  }

  /// Display label: all assigned zone names, comma-separated.
  String? get assignedZonesLabel {
    final names = assignedZones.map((z) => z.name).where((n) => n.isNotEmpty);
    if (names.isNotEmpty) return names.join(', ');
    return assignedZoneName;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final email = (json['email'] as String?) ?? '';
    final name =
        (json['name'] as String?) ??
        (email.isNotEmpty ? email.split('@').first : 'User');
    final role = UserRole.fromString(json['role'] as String?);

    return UserModel(
      id: (json['id'] as String?) ?? '',
      email: email,
      name: name,
      role: role,
      clientId: (json['clientId'] ?? json['client_id']) as String?,
      assignedZoneId:
          (json['zoneId'] ?? json['assigned_zone_id'] ?? json['zone_id'])
              as String?,
      assignedZoneName:
          (json['assigned_zone_name'] ?? json['zone_name'] ?? json['zoneName'])
              as String?,
      assignedZones: ((json['zones'] ?? json['assigned_zones']) as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(AssignedZone.fromJson)
              .where((z) => z.id.isNotEmpty)
              .toList() ??
          const [],
      zoneLogoUrl:
          (json['zoneLogoUrl'] ?? json['zone_logo_url']) as String?,
      technicianId: (json['technicianId'] ?? json['technician_id']) as String?,
      accountStatus:
          (json['accountStatus'] ?? json['account_status']) as String? ??
          'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.value,
      'client_id': clientId,
      'assigned_zone_id': assignedZoneId,
      'assigned_zone_name': assignedZoneName,
      'zones': assignedZones.map((z) => z.toJson()).toList(),
      'zone_logo_url': zoneLogoUrl,
      'technician_id': technicianId,
      'account_status': accountStatus,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? clientId,
    String? assignedZoneId,
    String? assignedZoneName,
    List<AssignedZone>? assignedZones,
    String? zoneLogoUrl,
    String? technicianId,
    String? accountStatus,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      clientId: clientId ?? this.clientId,
      assignedZoneId: assignedZoneId ?? this.assignedZoneId,
      assignedZoneName: assignedZoneName ?? this.assignedZoneName,
      assignedZones: assignedZones ?? this.assignedZones,
      zoneLogoUrl: zoneLogoUrl ?? this.zoneLogoUrl,
      technicianId: technicianId ?? this.technicianId,
      accountStatus: accountStatus ?? this.accountStatus,
    );
  }
}
