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
    return UserRole.values.firstWhere(
      (e) => e.value == role || e.name == role,
      orElse: () => UserRole.zoneStaff,
    );
  }

  bool get isZoneHeadOrStaff =>
      this == UserRole.zoneIncharge || this == UserRole.zoneStaff;

  bool get isTechnician => this == UserRole.technician;

  bool get isAdmin =>
      this == UserRole.clientAdmin || this == UserRole.superAdmin;
}

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;

  final String? clientId;
  final String? assignedZoneId;
  final String? assignedZoneName;
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
    this.technicianId,
    this.accountStatus = 'active',
  });

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
          (json['assigned_zone_name'] ?? json['zone_name']) as String?,
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
      technicianId: technicianId ?? this.technicianId,
      accountStatus: accountStatus ?? this.accountStatus,
    );
  }
}
