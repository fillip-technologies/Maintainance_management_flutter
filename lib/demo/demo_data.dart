import '../data/models/daily_log_model.dart';
import '../data/models/dashboard_summary_model.dart';
import '../data/models/device_model.dart';
import '../data/models/hardware_type_model.dart';
import '../data/models/issue_model.dart';
import '../data/models/user_model.dart';
import '../data/models/zone_model.dart';

/// Centralized repository of realistic demo fixtures for offline testing, UI previews,
/// and functional verification of Fixly.
class DemoData {
  DemoData._();

  // ===========================================================================
  // 1. DEMO USERS
  // ===========================================================================

  static final UserModel userRavi = const UserModel(
    id: 'usr-incharge-ravi',
    name: 'Ravi Kumar',
    email: 'ravi@cityzoo.com',
    role: UserRole.zoneIncharge,
    clientId: 'cli-cityzoo-001',
    assignedZoneId: 'zone-north-wing',
    assignedZoneName: 'North Wing',
    accountStatus: 'active',
  );

  static final UserModel userPooja = const UserModel(
    id: 'usr-staff-pooja',
    name: 'Pooja Nair',
    email: 'pooja@cityzoo.com',
    role: UserRole.zoneStaff,
    clientId: 'cli-cityzoo-001',
    assignedZoneId: 'zone-south-plaza',
    assignedZoneName: 'South Plaza',
    accountStatus: 'active',
  );

  static final UserModel userAmit = const UserModel(
    id: 'usr-tech-amit',
    name: 'Amit Shah',
    email: 'amit@example.com',
    role: UserRole.technician,
    clientId: null,
    technicianId: 'tech-amit-001',
    accountStatus: 'active',
  );

  static final UserModel userRaju = const UserModel(
    id: 'usr-tech-raju',
    name: 'Raju Mistri',
    email: 'rajumistri@gmail.com',
    role: UserRole.technician,
    clientId: null,
    technicianId: 'tech-raju-002',
    accountStatus: 'active',
  );

  static final UserModel userAdmin = const UserModel(
    id: 'usr-admin-priya',
    name: 'Priya Singh',
    email: 'admin@cityzoo.com',
    role: UserRole.clientAdmin,
    clientId: 'cli-cityzoo-001',
    accountStatus: 'active',
  );

  static final List<UserModel> users = [
    userRavi,
    userPooja,
    userAmit,
    userRaju,
    userAdmin,
  ];

  // ===========================================================================
  // 2. DEMO ZONES
  // ===========================================================================

  static final ZoneModel zoneNorthWing = const ZoneModel(
    id: 'zone-north-wing',
    clientId: 'cli-cityzoo-001',
    parentZoneId: null,
    name: 'North Wing',
    status: ZoneStatus.active,
    depth: 0,
    deviceCount: 6,
    openIssuesCount: 2,
    subZones: [
      ZoneModel(
        id: 'zone-north-gate',
        clientId: 'cli-cityzoo-001',
        parentZoneId: 'zone-north-wing',
        name: 'North Gate & Turnstiles',
        status: ZoneStatus.active,
        depth: 1,
        deviceCount: 3,
        openIssuesCount: 1,
      ),
      ZoneModel(
        id: 'zone-north-corridor',
        clientId: 'cli-cityzoo-001',
        parentZoneId: 'zone-north-wing',
        name: 'North Exhibit Corridor',
        status: ZoneStatus.active,
        depth: 1,
        deviceCount: 3,
        openIssuesCount: 1,
      ),
    ],
  );

  static final ZoneModel zoneSouthPlaza = const ZoneModel(
    id: 'zone-south-plaza',
    clientId: 'cli-cityzoo-001',
    parentZoneId: null,
    name: 'South Plaza',
    status: ZoneStatus.active,
    depth: 0,
    deviceCount: 4,
    openIssuesCount: 1,
    subZones: [
      ZoneModel(
        id: 'zone-south-ticketing',
        clientId: 'cli-cityzoo-001',
        parentZoneId: 'zone-south-plaza',
        name: 'Ticketing & Entrance',
        status: ZoneStatus.active,
        depth: 1,
        deviceCount: 4,
        openIssuesCount: 1,
      ),
    ],
  );

  static final ZoneModel zoneServerRoom = const ZoneModel(
    id: 'zone-server-room',
    clientId: 'cli-cityzoo-001',
    parentZoneId: null,
    name: 'Central Server Room',
    status: ZoneStatus.active,
    depth: 0,
    deviceCount: 2,
    openIssuesCount: 0,
  );

  static final List<ZoneModel> zones = [
    zoneNorthWing,
    zoneSouthPlaza,
    zoneServerRoom,
  ];

  // ===========================================================================
  // 3. DEMO HARDWARE TYPES & ISSUE CATEGORIES
  // ===========================================================================

  static final HardwareTypeModel hwCctvCamera = const HardwareTypeModel(
    id: 'hw-cctv',
    name: 'CCTV Camera',
    specFields: {'resolution': '4K / 8MP', 'connectivity': 'PoE RJ45', 'storage': 'NVR Stream'},
    issueCategories: [
      IssueCategoryModel(id: 'cat-cctv-01', name: 'No Power / Video Signal Lost', hardwareTypeId: 'hw-cctv'),
      IssueCategoryModel(id: 'cat-cctv-02', name: 'Lens Blurry / Dirty / Fogged', hardwareTypeId: 'hw-cctv'),
      IssueCategoryModel(id: 'cat-cctv-03', name: 'PTZ Motor Stuck / Non-responsive', hardwareTypeId: 'hw-cctv'),
      IssueCategoryModel(id: 'cat-cctv-04', name: 'Night Vision IR LED Failure', hardwareTypeId: 'hw-cctv'),
    ],
  );

  static final HardwareTypeModel hwTurnstile = const HardwareTypeModel(
    id: 'hw-turnstile',
    name: 'Access Control Turnstile',
    specFields: {'throughput': '35 ppm', 'motorType': 'Brushless DC', 'cardProtocol': 'Mifare RFID'},
    issueCategories: [
      IssueCategoryModel(id: 'cat-turn-01', name: 'Flap Jammed / Motor Blocked', hardwareTypeId: 'hw-turnstile'),
      IssueCategoryModel(id: 'cat-turn-02', name: 'RFID Card Reader Failure', hardwareTypeId: 'hw-turnstile'),
      IssueCategoryModel(id: 'cat-turn-03', name: 'Display Screen Blank', hardwareTypeId: 'hw-turnstile'),
      IssueCategoryModel(id: 'cat-turn-04', name: 'Safety Optical Sensor Tripped', hardwareTypeId: 'hw-turnstile'),
    ],
  );

  static final HardwareTypeModel hwBiometric = const HardwareTypeModel(
    id: 'hw-biometric',
    name: 'Biometric Attendance Terminal',
    specFields: {'sensor': 'Optical 500 DPI', 'capacity': '3000 templates', 'relay': 'Door Strike Lock'},
    issueCategories: [
      IssueCategoryModel(id: 'cat-bio-01', name: 'Fingerprint Sensor Scratched / Unreadable', hardwareTypeId: 'hw-biometric'),
      IssueCategoryModel(id: 'cat-bio-02', name: 'Screen Touch Freezes', hardwareTypeId: 'hw-biometric'),
      IssueCategoryModel(id: 'cat-bio-03', name: 'Server Network Sync Failed', hardwareTypeId: 'hw-biometric'),
    ],
  );

  static final HardwareTypeModel hwEnvSensor = const HardwareTypeModel(
    id: 'hw-env-sensor',
    name: 'IoT Environment & Temp Sensor',
    specFields: {'range': '-20C to 80C', 'battery': 'CR2450 3V', 'wireless': 'Zigbee 3.0'},
    issueCategories: [
      IssueCategoryModel(id: 'cat-env-01', name: 'Abnormal Temp Reading Drift', hardwareTypeId: 'hw-env-sensor'),
      IssueCategoryModel(id: 'cat-env-02', name: 'Low Battery Warning (< 10%)', hardwareTypeId: 'hw-env-sensor'),
      IssueCategoryModel(id: 'cat-env-03', name: 'Gateway Wireless Packet Drop', hardwareTypeId: 'hw-env-sensor'),
    ],
  );

  static final List<HardwareTypeModel> hardwareTypes = [
    hwCctvCamera,
    hwTurnstile,
    hwBiometric,
    hwEnvSensor,
  ];

  // ===========================================================================
  // 4. DEMO DEVICES
  // ===========================================================================

  static final List<DeviceModel> devices = [
    DeviceModel(
      id: 'dev-cctv-01',
      zoneId: 'zone-north-wing',
      zoneName: 'North Wing',
      hardwareTypeId: 'hw-cctv',
      hardwareTypeName: 'CCTV Camera',
      name: 'North Gate Panoramic Cam',
      serialNumber: 'SN-CAM-9012',
      location: 'Gate 1 Pillar A',
      status: DeviceStatus.underMaintenance,
      specFields: {'ip': '192.168.10.101', 'fov': '180 deg'},
      installDate: DateTime(2025, 3, 15),
      lastCheckedAt: DateTime.now().subtract(const Duration(hours: 2)),
      consecutiveFailures: 1,
    ),
    DeviceModel(
      id: 'dev-turn-01',
      zoneId: 'zone-north-wing',
      zoneName: 'North Wing',
      hardwareTypeId: 'hw-turnstile',
      hardwareTypeName: 'Access Control Turnstile',
      name: 'Turnstile #1 (Entry)',
      serialNumber: 'SN-TRN-4411',
      location: 'Main North Turnstile Lane',
      status: DeviceStatus.faulty,
      specFields: {'ip': '192.168.10.105', 'lane': 'Lane 1'},
      installDate: DateTime(2025, 4, 10),
      lastCheckedAt: DateTime.now().subtract(const Duration(hours: 4)),
      consecutiveFailures: 2,
    ),
    DeviceModel(
      id: 'dev-cctv-02',
      zoneId: 'zone-north-wing',
      zoneName: 'North Wing',
      hardwareTypeId: 'hw-cctv',
      hardwareTypeName: 'CCTV Camera',
      name: 'Aviary Corridor Dome Cam',
      serialNumber: 'SN-CAM-9044',
      location: 'Ceiling Truss C3',
      status: DeviceStatus.active,
      specFields: {'ip': '192.168.10.102'},
      installDate: DateTime(2025, 3, 16),
      lastCheckedAt: DateTime.now().subtract(const Duration(hours: 1)),
      consecutiveFailures: 0,
    ),
    DeviceModel(
      id: 'dev-bio-01',
      zoneId: 'zone-north-wing',
      zoneName: 'North Wing',
      hardwareTypeId: 'hw-biometric',
      hardwareTypeName: 'Biometric Attendance Terminal',
      name: 'Staff Gate Biometric Terminal',
      serialNumber: 'SN-BIO-1088',
      location: 'Staff Locker Room Entrance',
      status: DeviceStatus.underMaintenance,
      specFields: {'ip': '192.168.10.109'},
      installDate: DateTime(2025, 5, 20),
      lastCheckedAt: DateTime.now().subtract(const Duration(hours: 5)),
      consecutiveFailures: 1,
    ),
    DeviceModel(
      id: 'dev-env-01',
      zoneId: 'zone-north-wing',
      zoneName: 'North Wing',
      hardwareTypeId: 'hw-env-sensor',
      hardwareTypeName: 'IoT Environment & Temp Sensor',
      name: 'Reptile House Temp Monitor',
      serialNumber: 'SN-ENV-3021',
      location: 'Terrarium Zone 4B',
      status: DeviceStatus.active,
      specFields: {'battery': '94%', 'temp': '28.4 C'},
      installDate: DateTime(2025, 6, 1),
      lastCheckedAt: DateTime.now().subtract(const Duration(hours: 3)),
      consecutiveFailures: 0,
    ),
    DeviceModel(
      id: 'dev-cctv-03',
      zoneId: 'zone-south-plaza',
      zoneName: 'South Plaza',
      hardwareTypeId: 'hw-cctv',
      hardwareTypeName: 'CCTV Camera',
      name: 'South Fountain PTZ Cam',
      serialNumber: 'SN-CAM-7721',
      location: 'Central Light Post',
      status: DeviceStatus.active,
      specFields: {'ip': '192.168.20.101'},
      installDate: DateTime(2025, 2, 10),
      lastCheckedAt: DateTime.now().subtract(const Duration(hours: 2)),
      consecutiveFailures: 0,
    ),
    DeviceModel(
      id: 'dev-turn-02',
      zoneId: 'zone-south-plaza',
      zoneName: 'South Plaza',
      hardwareTypeId: 'hw-turnstile',
      hardwareTypeName: 'Access Control Turnstile',
      name: 'South Ticket Scanner Turnstile',
      serialNumber: 'SN-TRN-8802',
      location: 'South Visitor Booth',
      status: DeviceStatus.active,
      specFields: {'ip': '192.168.20.105'},
      installDate: DateTime(2025, 4, 18),
      lastCheckedAt: DateTime.now().subtract(const Duration(hours: 6)),
      consecutiveFailures: 0,
    ),
    DeviceModel(
      id: 'dev-env-02',
      zoneId: 'zone-server-room',
      zoneName: 'Central Server Room',
      hardwareTypeId: 'hw-env-sensor',
      hardwareTypeName: 'IoT Environment & Temp Sensor',
      name: 'Server Rack Temperature Probe',
      serialNumber: 'SN-ENV-9912',
      location: 'Rack Unit 42 Exhaust',
      status: DeviceStatus.active,
      specFields: {'battery': '99%', 'temp': '21.2 C'},
      installDate: DateTime(2025, 1, 15),
      lastCheckedAt: DateTime.now().subtract(const Duration(hours: 1)),
      consecutiveFailures: 0,
    ),
  ];

  // ===========================================================================
  // 5. DEMO ISSUES & MAINTENANCE TICKETS
  // ===========================================================================

  static final List<IssueModel> issues = [
    IssueModel(
      id: 'iss-2026-001',
      title: 'Turnstile #1 - Flap Jammed / Motor Blocked',
      description: 'The right mechanical flap is not opening when valid RFID cards are tapped. Continuous buzzer sound.',
      deviceId: 'dev-turn-01',
      deviceName: 'Turnstile #1 (Entry)',
      zoneId: 'zone-north-wing',
      zoneName: 'North Wing',
      categoryId: 'cat-turn-01',
      categoryName: 'Flap Jammed / Motor Blocked',
      priority: IssuePriority.critical,
      status: IssueStatus.assigned,
      assignedTechnicianId: 'tech-raju-002',
      assignedTechnicianName: 'Raju Mistri',
      createdByUserId: 'usr-incharge-ravi',
      createdByUserName: 'Ravi Kumar',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      history: [
        IssueStatusHistoryModel(
          id: 'hist-001-a',
          issueId: 'iss-2026-001',
          fromStatus: null,
          toStatus: IssueStatus.open,
          changedByUserId: 'usr-incharge-ravi',
          changedByUserName: 'Ravi Kumar',
          comment: 'Raised ticket during morning entrance inspection.',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        IssueStatusHistoryModel(
          id: 'hist-001-b',
          issueId: 'iss-2026-001',
          fromStatus: IssueStatus.open,
          toStatus: IssueStatus.assigned,
          changedByUserId: 'usr-admin-priya',
          changedByUserName: 'Priya Singh',
          comment: 'Assigned to field technician Raju Mistri for immediate dispatch.',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ],
    ),
    IssueModel(
      id: 'iss-2026-002',
      title: 'North Gate Panoramic Cam - PTZ Motor Stuck',
      description: 'Camera cannot pan left towards gate barrier. Auto-patrol preset fails with position feedback error.',
      deviceId: 'dev-cctv-01',
      deviceName: 'North Gate Panoramic Cam',
      zoneId: 'zone-north-wing',
      zoneName: 'North Wing',
      categoryId: 'cat-cctv-03',
      categoryName: 'PTZ Motor Stuck / Non-responsive',
      priority: IssuePriority.high,
      status: IssueStatus.inProgress,
      assignedTechnicianId: 'tech-raju-002',
      assignedTechnicianName: 'Raju Mistri',
      createdByUserId: 'usr-incharge-ravi',
      createdByUserName: 'Ravi Kumar',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      history: [
        IssueStatusHistoryModel(
          id: 'hist-002-a',
          issueId: 'iss-2026-002',
          fromStatus: null,
          toStatus: IssueStatus.open,
          changedByUserId: 'usr-incharge-ravi',
          changedByUserName: 'Ravi Kumar',
          comment: 'Camera view frozen at fixed angle.',
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        ),
        IssueStatusHistoryModel(
          id: 'hist-002-b',
          issueId: 'iss-2026-002',
          fromStatus: IssueStatus.open,
          toStatus: IssueStatus.inProgress,
          changedByUserId: 'usr-tech-raju',
          changedByUserName: 'Raju Mistri',
          comment: 'Climbed ladder to inspect physical gear teeth and motor cabling.',
          createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        ),
      ],
    ),
    IssueModel(
      id: 'iss-2026-003',
      title: 'Staff Gate Terminal - Optical Glass Scratched',
      description: 'Sensor has deep scratch marks on optical glass causing high false rejection rate for staff fingerprint scans.',
      deviceId: 'dev-bio-01',
      deviceName: 'Staff Gate Biometric Terminal',
      zoneId: 'zone-north-wing',
      zoneName: 'North Wing',
      categoryId: 'cat-bio-01',
      categoryName: 'Fingerprint Sensor Scratched',
      priority: IssuePriority.medium,
      status: IssueStatus.onHold,
      assignedTechnicianId: 'tech-amit-001',
      assignedTechnicianName: 'Amit Shah',
      createdByUserId: 'usr-incharge-ravi',
      createdByUserName: 'Ravi Kumar',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
      history: [
        IssueStatusHistoryModel(
          id: 'hist-003-a',
          issueId: 'iss-2026-003',
          fromStatus: null,
          toStatus: IssueStatus.open,
          changedByUserId: 'usr-incharge-ravi',
          changedByUserName: 'Ravi Kumar',
          comment: 'Staff reporting 4-5 attempts needed per scan.',
          createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        ),
        IssueStatusHistoryModel(
          id: 'hist-003-b',
          issueId: 'iss-2026-003',
          fromStatus: IssueStatus.inProgress,
          toStatus: IssueStatus.onHold,
          changedByUserId: 'usr-tech-amit',
          changedByUserName: 'Amit Shah',
          comment: 'Awaiting replacement optical prism module from central vendor warehouse.',
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        ),
      ],
    ),
    IssueModel(
      id: 'iss-2026-004',
      title: 'Aviary Corridor Dome Cam - Lens Dirty',
      description: 'Heavy dust accumulation from nearby construction work causing night vision IR light flare.',
      deviceId: 'dev-cctv-02',
      deviceName: 'Aviary Corridor Dome Cam',
      zoneId: 'zone-north-wing',
      zoneName: 'North Wing',
      categoryId: 'cat-cctv-02',
      categoryName: 'Lens Blurry / Dirty',
      priority: IssuePriority.low,
      status: IssueStatus.resolved,
      assignedTechnicianId: 'tech-raju-002',
      assignedTechnicianName: 'Raju Mistri',
      createdByUserId: 'usr-incharge-ravi',
      createdByUserName: 'Ravi Kumar',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      resolvedAt: DateTime.now().subtract(const Duration(hours: 5)),
      history: [
        IssueStatusHistoryModel(
          id: 'hist-004-a',
          issueId: 'iss-2026-004',
          fromStatus: null,
          toStatus: IssueStatus.open,
          changedByUserId: 'usr-incharge-ravi',
          changedByUserName: 'Ravi Kumar',
          comment: 'Dirty dome cover causing glare.',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        IssueStatusHistoryModel(
          id: 'hist-004-b',
          issueId: 'iss-2026-004',
          fromStatus: IssueStatus.inProgress,
          toStatus: IssueStatus.resolved,
          changedByUserId: 'usr-tech-raju',
          changedByUserName: 'Raju Mistri',
          comment: 'Cleaned outer acrylic dome with anti-static solution and adjusted focus ring. Image crystal clear.',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ],
    ),
  ];

  // ===========================================================================
  // 6. DEMO DAILY STATUS LOGS (TODAY)
  // ===========================================================================

  static final List<DailyStatusLogModel> dailyLogs = [
    DailyStatusLogModel(
      id: 'log-2026-01',
      deviceId: 'dev-cctv-02',
      deviceName: 'Aviary Corridor Dome Cam',
      zoneId: 'zone-north-wing',
      zoneName: 'North Wing',
      loggedByUserId: 'usr-incharge-ravi',
      loggedByUserName: 'Ravi Kumar',
      status: DailyLogStatus.working,
      notes: 'Video feed clear, bitrate stable at 4 Mbps.',
      logDate: DateTime.now(),
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    DailyStatusLogModel(
      id: 'log-2026-02',
      deviceId: 'dev-turn-01',
      deviceName: 'Turnstile #1 (Entry)',
      zoneId: 'zone-north-wing',
      zoneName: 'North Wing',
      loggedByUserId: 'usr-incharge-ravi',
      loggedByUserName: 'Ravi Kumar',
      status: DailyLogStatus.notWorking,
      notes: 'Mechanical flap locked in closed position. Ticket raised.',
      logDate: DateTime.now(),
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    DailyStatusLogModel(
      id: 'log-2026-03',
      deviceId: 'dev-cctv-01',
      deviceName: 'North Gate Panoramic Cam',
      zoneId: 'zone-north-wing',
      zoneName: 'North Wing',
      loggedByUserId: 'usr-incharge-ravi',
      loggedByUserName: 'Ravi Kumar',
      status: DailyLogStatus.needsAttention,
      notes: 'PTZ auto-rotation stalled on position 3.',
      logDate: DateTime.now(),
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    DailyStatusLogModel(
      id: 'log-2026-04',
      deviceId: 'dev-env-01',
      deviceName: 'Reptile House Temp Monitor',
      zoneId: 'zone-north-wing',
      zoneName: 'North Wing',
      loggedByUserId: 'usr-incharge-ravi',
      loggedByUserName: 'Ravi Kumar',
      status: DailyLogStatus.working,
      notes: 'Telemetry reporting within normal threshold (28.4 C).',
      logDate: DateTime.now(),
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  // ===========================================================================
  // 7. DEMO DASHBOARD SUMMARY METRICS
  // ===========================================================================

  static final DashboardSummaryModel dashboardSummary = DashboardSummaryModel(
    totalDevices: devices.length,
    activeDevices: devices.where((d) => d.status == DeviceStatus.active).length,
    underMaintenanceDevices: devices.where((d) => d.status == DeviceStatus.underMaintenance).length,
    faultyDevices: devices.where((d) => d.status == DeviceStatus.faulty).length,
    provisionedDevices: 0,
    openIssues: issues.where((i) => i.status == IssueStatus.open || i.status == IssueStatus.assigned).length,
    inProgressIssues: issues.where((i) => i.status == IssueStatus.inProgress).length,
    resolvedIssues: issues.where((i) => i.status == IssueStatus.resolved || i.status == IssueStatus.closed).length,
    criticalIssues: issues.where((i) => i.priority == IssuePriority.critical).length,
    devicesMissingTodayLog: devices.length - dailyLogs.length,
    todayLogsCompleted: dailyLogs.length,
    todayLogsPending: devices.length - dailyLogs.length,
  );

  // ===========================================================================
  // 8. QUERY & STATE MUTATION HELPERS
  // ===========================================================================

  /// Returns devices belonging to a given zone (or all if zoneId is null/empty)
  static List<DeviceModel> getDevicesForZone(String? zoneId) {
    if (zoneId == null || zoneId.isEmpty) return List.unmodifiable(devices);
    return devices.where((d) => d.zoneId == zoneId).toList();
  }

  /// Returns issues assigned to a specific technician or unassigned active issues
  static List<IssueModel> getIssuesForTechnician(String? technicianId) {
    if (technicianId == null || technicianId.isEmpty) return List.unmodifiable(issues);
    return issues.where((i) => i.assignedTechnicianId == technicianId).toList();
  }

  /// Returns issues scoped to a specific zone
  static List<IssueModel> getIssuesForZone(String? zoneId) {
    if (zoneId == null || zoneId.isEmpty) return List.unmodifiable(issues);
    return issues.where((i) => i.zoneId == zoneId).toList();
  }

  /// Finds hardware type by its ID
  static HardwareTypeModel? getHardwareTypeById(String id) {
    return hardwareTypes.where((h) => h.id == id).firstOrNull;
  }

  /// Records or updates today's log in memory
  static DailyStatusLogModel recordDailyLog({
    required String deviceId,
    required DailyLogStatus status,
    String? notes,
    required String userId,
    required String userName,
  }) {
    final devIndex = devices.indexWhere((d) => d.id == deviceId);
    final dev = devIndex >= 0 ? devices[devIndex] : null;

    final existingIndex = dailyLogs.indexWhere((l) => l.deviceId == deviceId);
    final log = DailyStatusLogModel(
      id: existingIndex >= 0 ? dailyLogs[existingIndex].id : 'log-${DateTime.now().millisecondsSinceEpoch}',
      deviceId: deviceId,
      deviceName: dev?.name ?? 'Device #$deviceId',
      zoneId: dev?.zoneId ?? 'zone-north-wing',
      zoneName: dev?.zoneName ?? 'North Wing',
      loggedByUserId: userId,
      loggedByUserName: userName,
      status: status,
      notes: notes,
      logDate: DateTime.now(),
      createdAt: DateTime.now(),
    );

    if (existingIndex >= 0) {
      dailyLogs[existingIndex] = log;
    } else {
      dailyLogs.add(log);
    }

    // Update device status if not working
    if (devIndex >= 0) {
      devices[devIndex] = devices[devIndex].copyWith(
        status: status == DailyLogStatus.notWorking ? DeviceStatus.faulty : devices[devIndex].status,
        lastCheckedAt: DateTime.now(),
      );
    }

    return log;
  }

  /// Creates a new issue in memory
  static IssueModel createIssue({
    required String deviceId,
    required String categoryId,
    required IssuePriority priority,
    required String description,
    required String userId,
    required String userName,
  }) {
    final dev = devices.where((d) => d.id == deviceId).firstOrNull;
    final cat = hardwareTypes
        .expand((h) => h.issueCategories)
        .where((c) => c.id == categoryId)
        .firstOrNull;

    final newIssue = IssueModel(
      id: 'iss-2026-${(issues.length + 1).toString().padLeft(3, '0')}',
      title: '${dev?.name ?? "Device"} - ${cat?.name ?? "Hardware Issue"}',
      description: description,
      deviceId: deviceId,
      deviceName: dev?.name ?? 'Device',
      zoneId: dev?.zoneId ?? 'zone-north-wing',
      zoneName: dev?.zoneName ?? 'North Wing',
      categoryId: categoryId,
      categoryName: cat?.name ?? 'General Issue',
      priority: priority,
      status: IssueStatus.open,
      createdByUserId: userId,
      createdByUserName: userName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      history: [
        IssueStatusHistoryModel(
          id: 'hist-${DateTime.now().millisecondsSinceEpoch}',
          issueId: 'iss-2026-${(issues.length + 1).toString().padLeft(3, '0')}',
          fromStatus: null,
          toStatus: IssueStatus.open,
          changedByUserId: userId,
          changedByUserName: userName,
          comment: description,
          createdAt: DateTime.now(),
        ),
      ],
    );

    issues.insert(0, newIssue);

    // Automatically transition device to underMaintenance
    final devIndex = devices.indexWhere((d) => d.id == deviceId);
    if (devIndex >= 0) {
      devices[devIndex] = devices[devIndex].copyWith(
        status: DeviceStatus.underMaintenance,
      );
    }

    return newIssue;
  }

  /// Updates an issue status in memory
  static IssueModel updateIssueStatus({
    required String issueId,
    required IssueStatus toStatus,
    String? notes,
    required String userId,
    required String userName,
  }) {
    final index = issues.indexWhere((i) => i.id == issueId);
    if (index < 0) throw Exception('Issue $issueId not found in DemoData');

    final current = issues[index];
    final updatedHistory = List<IssueStatusHistoryModel>.from(current.history)
      ..add(
        IssueStatusHistoryModel(
          id: 'hist-${DateTime.now().millisecondsSinceEpoch}',
          issueId: issueId,
          fromStatus: current.status,
          toStatus: toStatus,
          changedByUserId: userId,
          changedByUserName: userName,
          comment: notes,
          createdAt: DateTime.now(),
        ),
      );

    final updated = current.copyWith(
      status: toStatus,
      updatedAt: DateTime.now(),
      resolvedAt: toStatus == IssueStatus.resolved ? DateTime.now() : current.resolvedAt,
      closedAt: toStatus == IssueStatus.closed ? DateTime.now() : current.closedAt,
      history: updatedHistory,
    );

    issues[index] = updated;

    // If resolved, restore device to active
    if (toStatus == IssueStatus.resolved || toStatus == IssueStatus.closed) {
      final devIndex = devices.indexWhere((d) => d.id == current.deviceId);
      if (devIndex >= 0) {
        devices[devIndex] = devices[devIndex].copyWith(status: DeviceStatus.active);
      }
    }

    return updated;
  }
}
