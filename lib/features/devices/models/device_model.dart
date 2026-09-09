enum DeviceStatus {
  provisioned('provisioned', 'Provisioned'),
  active('active', 'Active'),
  underMaintenance('under_maintenance', 'Under Maintenance'),
  faulty('faulty', 'Faulty'),
  retired('retired', 'Removed / Retired');

  final String value;
  final String label;
  const DeviceStatus(this.value, this.label);

  static DeviceStatus fromString(String? status) {
    return DeviceStatus.values.firstWhere(
      (e) => e.value == status || e.name == status,
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
  final String? productTypeId;
  final String name;
  final String serialNumber;
  final String location;
  final DeviceStatus status;
  final bool isManualEntry;
  final Map<String, dynamic> specFields;
  final DateTime? installDate;
  final DateTime? lastCheckedAt;
  final int consecutiveFailures;
  final String? imageUrl;
  final String? zoneLogoUrl;

  String get code => serialNumber;
  String get categoryName => hardwareTypeName;

  const DeviceModel({
    required this.id,
    required this.zoneId,
    required this.zoneName,
    this.hardwareTypeId,
    required this.hardwareTypeName,
    this.productTypeId,
    required this.name,
    this.serialNumber = '',
    this.location = '',
    this.status = DeviceStatus.active,
    this.isManualEntry = false,
    this.specFields = const {},
    this.installDate,
    this.lastCheckedAt,
    this.consecutiveFailures = 0,
    this.imageUrl,
    this.zoneLogoUrl,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    final zoneObj = json['zone'] as Map<String, dynamic>?;
    final categoryObj = json['category'] as Map<String, dynamic>?;
    final productTypeObj = json['productType'] as Map<String, dynamic>?;
    final hwTypeObj = (json['hardwareType'] ?? json['hardware_type'] ?? categoryObj) as Map<String, dynamic>?;

    final rawImageUrl = (json['imageUrl'] ?? json['image_url']) as String?;
    final ptImageUrl = (productTypeObj?['imageUrl'] ?? productTypeObj?['image_url']) as String?;
    final catImageUrl = (categoryObj?['imageUrl'] ??
            categoryObj?['image_url'] ??
            json['categoryImageUrl'] ??
            json['category_image_url'] ??
            hwTypeObj?['imageUrl'] ??
            hwTypeObj?['image_url']) as String?;

    final resolvedImageUrl = (rawImageUrl != null && rawImageUrl.trim().isNotEmpty)
        ? rawImageUrl.trim()
        : (ptImageUrl != null && ptImageUrl.trim().isNotEmpty)
            ? ptImageUrl.trim()
            : (catImageUrl != null && catImageUrl.trim().isNotEmpty)
                ? catImageUrl.trim()
                : null;

    return DeviceModel(
      id: (json['id'] as String?) ?? '',
      zoneId: (json['zoneId'] ?? json['zone_id'] ?? zoneObj?['id']) as String? ?? '',
      zoneName: (json['zoneName'] ?? json['zone_name'] ?? zoneObj?['name']) as String? ?? 'Unknown Zone',
      hardwareTypeId: (json['hardwareTypeId'] ??
              json['hardware_type_id'] ??
              json['categoryId'] ??
              json['category_id'] ??
              categoryObj?['id'] ??
              hwTypeObj?['id']) as String?,
      hardwareTypeName: (json['hardwareTypeName'] ??
              json['hardware_type_name'] ??
              json['categoryName'] ??
              categoryObj?['name'] ??
              hwTypeObj?['name']) as String? ??
          'CCTV Camera',
      productTypeId: (json['productTypeId'] ?? json['product_type_id'] ?? productTypeObj?['id']) as String?,
      name: (json['name'] as String?) ?? 'Unknown Device',
      serialNumber: (json['serialNumber'] ?? json['serial_number'] ?? json['code']) as String? ?? '',
      location: (json['location'] as String?) ?? '',
      status: DeviceStatus.fromString(json['status'] as String?),
      isManualEntry: (json['isManualEntry'] ?? json['is_manual_entry']) as bool? ?? false,
      specFields: (json['specFields'] ?? json['spec_fields'] ?? json['customSpec'] ?? json['custom_spec']) as Map<String, dynamic>? ?? const {},
      installDate: json['installDate'] != null
          ? DateTime.tryParse(json['installDate'] as String)
          : json['install_date'] != null
              ? DateTime.tryParse(json['install_date'] as String)
              : null,
      lastCheckedAt: json['lastCheckedAt'] != null
          ? DateTime.tryParse(json['lastCheckedAt'] as String)
          : json['last_checked_at'] != null
              ? DateTime.tryParse(json['last_checked_at'] as String)
              : null,
      consecutiveFailures: (json['consecutiveFailures'] ?? json['consecutive_failures'] as num?)?.toInt() ?? 0,
      imageUrl: resolvedImageUrl,
      zoneLogoUrl: (json['zoneLogoUrl'] ??
              json['zone_logo_url'] ??
              zoneObj?['logoUrl'] ??
              zoneObj?['logo_url']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'zone_id': zoneId,
      'zone_name': zoneName,
      'hardware_type_id': hardwareTypeId,
      'hardware_type_name': hardwareTypeName,
      'product_type_id': productTypeId,
      'name': name,
      'serial_number': serialNumber,
      'location': location,
      'status': status.value,
      'is_manual_entry': isManualEntry,
      'spec_fields': specFields,
      'install_date': installDate?.toIso8601String(),
      'last_checked_at': lastCheckedAt?.toIso8601String(),
      'consecutive_failures': consecutiveFailures,
      'image_url': imageUrl,
      'zone_logo_url': zoneLogoUrl,
    };
  }

  DeviceModel copyWith({
    String? id,
    String? zoneId,
    String? zoneName,
    String? hardwareTypeId,
    String? hardwareTypeName,
    String? productTypeId,
    String? name,
    String? serialNumber,
    String? location,
    DeviceStatus? status,
    bool? isManualEntry,
    Map<String, dynamic>? specFields,
    DateTime? installDate,
    DateTime? lastCheckedAt,
    int? consecutiveFailures,
    String? imageUrl,
    String? zoneLogoUrl,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      zoneName: zoneName ?? this.zoneName,
      hardwareTypeId: hardwareTypeId ?? this.hardwareTypeId,
      hardwareTypeName: hardwareTypeName ?? this.hardwareTypeName,
      productTypeId: productTypeId ?? this.productTypeId,
      name: name ?? this.name,
      serialNumber: serialNumber ?? this.serialNumber,
      location: location ?? this.location,
      status: status ?? this.status,
      isManualEntry: isManualEntry ?? this.isManualEntry,
      specFields: specFields ?? this.specFields,
      installDate: installDate ?? this.installDate,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      imageUrl: imageUrl ?? this.imageUrl,
      zoneLogoUrl: zoneLogoUrl ?? this.zoneLogoUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
