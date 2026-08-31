enum UserRole {
  platformAdmin('platform_admin', 'Platform Admin'),
  companyAdmin('company_admin', 'Company Admin'),
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
      this == UserRole.clientAdmin ||
      this == UserRole.companyAdmin ||
      this == UserRole.platformAdmin;
}

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? companyId;
  final String? clientId;
  final String? assignedZoneId;
  final String? assignedZoneName;
  final String accountStatus;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.companyId,
    this.clientId,
    this.assignedZoneId,
    this.assignedZoneName,
    this.accountStatus = 'active',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String? ?? (json['email'] as String).split('@').first,
      role: UserRole.fromString(json['role'] as String?),
      companyId: json['company_id'] as String?,
      clientId: json['client_id'] as String?,
      assignedZoneId: json['assigned_zone_id'] as String?,
      assignedZoneName: json['assigned_zone_name'] as String?,
      accountStatus: json['account_status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.value,
      'company_id': companyId,
      'client_id': clientId,
      'assigned_zone_id': assignedZoneId,
      'assigned_zone_name': assignedZoneName,
      'account_status': accountStatus,
    };
  }
}
