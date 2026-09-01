import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/daily_log_model.dart';
import '../../../data/models/device_model.dart';
import '../../../data/models/issue_model.dart';
import 'widgets/issue_detail_sheet.dart';
import 'widgets/raise_issue_sheet.dart';

class StaffHomePage extends ConsumerStatefulWidget {
  const StaffHomePage({super.key});

  @override
  ConsumerState<StaffHomePage> createState() => _StaffHomePageState();
}

class _StaffHomePageState extends ConsumerState<StaffHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, TextEditingController> _logNoteControllers = {};

  String _deviceSearchQuery = '';
  DeviceStatus? _deviceFilterStatus;
  bool _isLoggingOut = false;

  final List<DeviceModel> _devices = [
    DeviceModel(
      id: 'dev-cam-01',
      zoneId: 'zone-lion-03',
      zoneName: 'Lion Enclosure (A1.1)',
      hardwareTypeName: '4K PTZ Dome Camera',
      name: 'Lion Feed Area Cam #1',
      serialNumber: 'SN-PTZ-88901',
      location: 'North Tower - Post 4',
      status: DeviceStatus.underMaintenance,
      lastCheckedAt: DateTime.now().subtract(const Duration(hours: 4)),
      specFields: const {
        'ip': '192.168.10.21',
        'model': 'Hikvision DS-2DF8442',
      },
    ),
    DeviceModel(
      id: 'dev-cam-02',
      zoneId: 'zone-lion-03',
      zoneName: 'Lion Enclosure (A1.1)',
      hardwareTypeName: 'Fixed Bullet Camera',
      name: 'Lion Den Night-Vision Cam #2',
      serialNumber: 'SN-BLT-55120',
      location: 'Cave Entrance Overhang',
      status: DeviceStatus.active,
      lastCheckedAt: DateTime.now().subtract(const Duration(hours: 3)),
      specFields: const {'ip': '192.168.10.22', 'model': 'Dahua IPC-HFW5842'},
    ),
    DeviceModel(
      id: 'dev-cam-03',
      zoneId: 'zone-lion-03',
      zoneName: 'Lion Enclosure (A1.1)',
      hardwareTypeName: 'Thermal Sensor Camera',
      name: 'Perimeter Fence Thermal Cam',
      serialNumber: 'SN-THM-99104',
      location: 'East Perimeter Fence',
      status: DeviceStatus.faulty,
      consecutiveFailures: 3,
      lastCheckedAt: DateTime.now().subtract(const Duration(hours: 1)),
      specFields: const {'ip': '192.168.10.23', 'model': 'FLIR FC-Series'},
    ),
    DeviceModel(
      id: 'dev-cam-04',
      zoneId: 'zone-tiger-04',
      zoneName: 'Tiger Den (A1.2)',
      hardwareTypeName: '4K PTZ Dome Camera',
      name: 'Tiger Water Pool Cam #1',
      serialNumber: 'SN-PTZ-88905',
      location: 'Watering Hole Tree Mount',
      status: DeviceStatus.underMaintenance,
      lastCheckedAt: DateTime.now().subtract(const Duration(hours: 6)),
      specFields: const {'ip': '192.168.10.31'},
    ),
    DeviceModel(
      id: 'dev-cam-05',
      zoneId: 'zone-tiger-04',
      zoneName: 'Tiger Den (A1.2)',
      hardwareTypeName: 'Panoramic 180 Cam',
      name: 'Tiger Habitat Overview',
      serialNumber: 'SN-PAN-33100',
      location: 'Central Mast A',
      status: DeviceStatus.active,
      lastCheckedAt: DateTime.now().subtract(const Duration(hours: 5)),
      specFields: const {'ip': '192.168.10.32'},
    ),
    DeviceModel(
      id: 'dev-cam-06',
      zoneId: 'zone-herbivore-05',
      zoneName: 'Herbivore Sector (A2)',
      hardwareTypeName: 'Fixed Bullet Camera',
      name: 'Giraffe Meadow South',
      serialNumber: 'SN-BLT-11092',
      location: 'South Observation Deck',
      status: DeviceStatus.active,
      lastCheckedAt: DateTime.now().subtract(const Duration(hours: 2)),
      specFields: const {'ip': '192.168.10.41'},
    ),
    DeviceModel(
      id: 'dev-cam-07',
      zoneId: 'zone-herbivore-05',
      zoneName: 'Herbivore Sector (A2)',
      hardwareTypeName: 'Fixed Bullet Camera',
      name: 'Elephant Bathing Area',
      serialNumber: 'SN-BLT-11095',
      location: 'River Bank Canopy',
      status: DeviceStatus.active,
      lastCheckedAt: DateTime.now().subtract(const Duration(hours: 2)),
      specFields: const {'ip': '192.168.10.42'},
    ),
    DeviceModel(
      id: 'dev-cam-08',
      zoneId: 'zone-aviary-06',
      zoneName: 'Bird Sanctuary (A3)',
      hardwareTypeName: 'Micro Dome Cam',
      name: 'Tropical Dome Top Deck',
      serialNumber: 'SN-MIC-66023',
      location: 'Aviary Suspension Bridge',
      status: DeviceStatus.underMaintenance,
      lastCheckedAt: DateTime.now().subtract(const Duration(hours: 8)),
      specFields: const {'ip': '192.168.10.51'},
    ),
  ];

  final List<IssueModel> _issues = [
    IssueModel(
      id: 'ISSUE-1001',
      title: 'PTZ Vertical Motor Jammed',
      description:
          'Camera will not tilt vertically beyond 45 degrees. Squeaking noise heard from gear mechanism.',
      deviceId: 'dev-cam-01',
      deviceName: 'Lion Feed Area Cam #1',
      zoneId: 'zone-lion-03',
      zoneName: 'Lion Enclosure (A1.1)',
      categoryId: 'cat-02',
      categoryName: 'PTZ Motor & Rotation Stuck',
      priority: IssuePriority.critical,
      status: IssueStatus.inProgress,
      assignedTechnicianId: 'usr-tech-003',
      assignedTechnicianName: 'Marcus Vance',
      createdByUserId: 'usr-staff-002',
      createdByUserName: 'Sarah Connor',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      history: [
        IssueStatusHistoryModel(
          id: 'hist-01',
          issueId: 'ISSUE-1001',
          fromStatus: null,
          toStatus: IssueStatus.open,
          changedByUserId: 'usr-staff-002',
          changedByUserName: 'Sarah Connor',
          comment: 'Issue raised after morning status round',
          createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
        ),
        IssueStatusHistoryModel(
          id: 'hist-02',
          issueId: 'ISSUE-1001',
          fromStatus: IssueStatus.open,
          toStatus: IssueStatus.assigned,
          changedByUserId: 'usr-admin-004',
          changedByUserName: 'Director Vance',
          comment: 'Assigned to Senior Tech Marcus Vance',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        IssueStatusHistoryModel(
          id: 'hist-03',
          issueId: 'ISSUE-1001',
          fromStatus: IssueStatus.assigned,
          toStatus: IssueStatus.inProgress,
          changedByUserId: 'usr-tech-003',
          changedByUserName: 'Marcus Vance',
          comment: 'Arrived at Lion Enclosure post with spare gear module',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ],
    ),
    IssueModel(
      id: 'ISSUE-1002',
      title: 'Water Droplets / Lens Condensation',
      description: 'Heavy fogging on interior lens glass after monsoon rain.',
      deviceId: 'dev-cam-04',
      deviceName: 'Tiger Water Pool Cam #1',
      zoneId: 'zone-tiger-04',
      zoneName: 'Tiger Den (A1.2)',
      categoryId: 'cat-06',
      categoryName: 'Water Ingress / Enclosure Condensation',
      priority: IssuePriority.high,
      status: IssueStatus.assigned,
      assignedTechnicianId: 'usr-tech-003',
      assignedTechnicianName: 'Marcus Vance',
      createdByUserId: 'usr-staff-002',
      createdByUserName: 'Sarah Connor',
      createdAt: DateTime.now().subtract(const Duration(hours: 9)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      history: [
        IssueStatusHistoryModel(
          id: 'hist-04',
          issueId: 'ISSUE-1002',
          fromStatus: null,
          toStatus: IssueStatus.open,
          changedByUserId: 'usr-staff-002',
          changedByUserName: 'Sarah Connor',
          comment: 'Reported during 9:00 AM status round',
          createdAt: DateTime.now().subtract(const Duration(hours: 9)),
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _logNoteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getNoteController(String deviceId) {
    return _logNoteControllers.putIfAbsent(
      deviceId,
      () => TextEditingController(),
    );
  }

  void _handleDeviceStatusLog(DeviceModel device, DailyLogStatus status) {
    setState(() {
      final index = _devices.indexWhere((d) => d.id == device.id);
      if (index != -1) {
        DeviceStatus newDeviceStatus = _devices[index].status;
        if (status == DailyLogStatus.notWorking) {
          newDeviceStatus = DeviceStatus.faulty;
        } else if (status == DailyLogStatus.working &&
            newDeviceStatus == DeviceStatus.faulty) {
          newDeviceStatus = DeviceStatus.active;
        }

        _devices[index] = _devices[index].copyWith(
          status: newDeviceStatus,
          lastCheckedAt: DateTime.now(),
        );
      }
    });

    final msg = 'Marked ${device.name} as ${status.label}';
    if (status == DailyLogStatus.working) {
      AppSnackbar.success(msg);
    } else if (status == DailyLogStatus.needsAttention) {
      AppSnackbar.warning(msg);
    } else {
      AppSnackbar.error(msg);
    }

    if (status == DailyLogStatus.notWorking) {
      _promptRaiseIssue(device);
    }
  }

  void _promptRaiseIssue(DeviceModel device) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text(
              'Device Down',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'You marked "${device.name}" as Not Working. Would you like to raise a maintenance ticket for technicians to inspect it now?',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Not Now',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openRaiseIssueSheet(device);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              minimumSize: const Size(120, 42),
            ),
            child: const Text('Raise Issue'),
          ),
        ],
      ),
    );
  }

  void _openRaiseIssueSheet([DeviceModel? initialDevice]) {
    RaiseIssueSheet.show(
      context,
      devices: _devices,
      initialDevice: initialDevice,
      onIssueCreated: (newIssue) {
        setState(() {
          _issues.insert(0, newIssue);
          // Set device status to under maintenance
          final devIdx = _devices.indexWhere((d) => d.id == newIssue.deviceId);
          if (devIdx != -1) {
            _devices[devIdx] = _devices[devIdx].copyWith(
              status: DeviceStatus.underMaintenance,
            );
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final int activeCount = _devices
        .where((d) => d.status == DeviceStatus.active)
        .length;
    final int maintCount = _devices
        .where((d) => d.status == DeviceStatus.underMaintenance)
        .length;
    final int faultyCount = _devices
        .where((d) => d.status == DeviceStatus.faulty)
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ref.watch(authStateProvider).value?.name ?? 'Staff Member',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: AppColors.icon,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          ref
                                  .watch(authStateProvider)
                                  .value
                                  ?.assignedZoneName ??
                              'Assigned Zone Scope',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: _isLoggingOut
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.logout_rounded, color: AppColors.icon),
                    tooltip: 'Sign Out',
                    onPressed: () async {
                      setState(() => _isLoggingOut = true);
                      try {
                        await ref.read(authStateProvider.notifier).logout();
                        AppSnackbar.info('Signed out successfully');
                      } catch (e) {
                        if (mounted) setState(() => _isLoggingOut = false);
                      }
                    },
                  ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.checklist_rounded, size: 18),
              text: 'Daily Checks',
            ),
            Tab(icon: Icon(Icons.videocam_outlined, size: 18), text: 'Devices'),
            Tab(
              icon: Icon(Icons.confirmation_number_outlined, size: 18),
              text: 'Issues',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // KPI Metric Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surface,
            child: Row(
              children: [
                _buildSummaryItem(
                  label: 'Total Devices',
                  value: '${_devices.length}',
                  color: AppColors.primary,
                  icon: Icons.devices,
                ),
                _buildDivider(),
                _buildSummaryItem(
                  label: 'Active',
                  value: '$activeCount',
                  color: AppColors.successText,
                  icon: Icons.check_circle_outline,
                ),
                _buildDivider(),
                _buildSummaryItem(
                  label: 'Maintenance',
                  value: '$maintCount',
                  color: AppColors.warningText,
                  icon: Icons.build_circle_outlined,
                ),
                _buildDivider(),
                _buildSummaryItem(
                  label: 'Faulty',
                  value: '$faultyCount',
                  color: AppColors.errorText,
                  icon: Icons.error_outline,
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Daily Checks
                _buildDailyCheckTab(),

                // TAB 2: Devices Directory
                _buildDevicesTab(),

                // TAB 3: Issues Tracker
                _buildIssuesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      color: AppColors.divider,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: DAILY CHECKS
  // -------------------------------------------------------------
  Widget _buildDailyCheckTab() {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        final noteController = _getNoteController(device.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device Header Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.videocam_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${device.hardwareTypeName} • ${device.location}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          device.zoneName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge.device(device.status),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 12),

              // Action Buttons: Working, Attention, Down / Fault
              const Text(
                'Mark Status for Today:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  // 1. Working
                  Expanded(
                    child: _buildLogActionButton(
                      label: 'Working',
                      icon: Icons.check_circle_outline,
                      bgColor: AppColors.successLight,
                      textColor: AppColors.successText,
                      borderColor: AppColors.success,
                      onTap: () => _handleDeviceStatusLog(
                        device,
                        DailyLogStatus.working,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 2. Needs Attention
                  Expanded(
                    child: _buildLogActionButton(
                      label: 'Attention',
                      icon: Icons.warning_amber_rounded,
                      bgColor: AppColors.warningLight,
                      textColor: AppColors.warningText,
                      borderColor: AppColors.warning,
                      onTap: () => _handleDeviceStatusLog(
                        device,
                        DailyLogStatus.needsAttention,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 3. Not Working
                  Expanded(
                    child: _buildLogActionButton(
                      label: 'Down / Fault',
                      icon: Icons.cancel_outlined,
                      bgColor: AppColors.errorLight,
                      textColor: AppColors.errorText,
                      borderColor: AppColors.error,
                      onTap: () => _handleDeviceStatusLog(
                        device,
                        DailyLogStatus.notWorking,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Optional Note Field
              TextField(
                controller: noteController,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Add note (e.g. lens dirty, flicker, normal)...',
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  filled: true,
                  fillColor: AppColors.cardAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogActionButton({
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: DEVICES DIRECTORY
  // -------------------------------------------------------------
  Widget _buildDevicesTab() {
    var filtered = _devices;
    if (_deviceFilterStatus != null) {
      filtered = filtered
          .where((d) => d.status == _deviceFilterStatus)
          .toList();
    }
    if (_deviceSearchQuery.trim().isNotEmpty) {
      final q = _deviceSearchQuery.toLowerCase();
      filtered = filtered.where((d) {
        return d.name.toLowerCase().contains(q) ||
            d.location.toLowerCase().contains(q) ||
            d.zoneName.toLowerCase().contains(q) ||
            d.serialNumber.toLowerCase().contains(q);
      }).toList();
    }

    return Column(
      children: [
        // Search & Status Filters
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surface,
          child: Column(
            children: [
              TextField(
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search devices or locations...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.icon),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() => _deviceSearchQuery = val),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All Status', null),
                    _buildFilterChip('Active', DeviceStatus.active),
                    _buildFilterChip(
                      'Maintenance',
                      DeviceStatus.underMaintenance,
                    ),
                    _buildFilterChip('Faulty', DeviceStatus.faulty),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: AppColors.divider),

        // Device List
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'No devices found matching filter',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: 80,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final device = filtered[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  device.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              StatusBadge.device(device.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${device.hardwareTypeName} • SN: ${device.serialNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppColors.icon,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${device.zoneName} (${device.location})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),

                          if (device.specFields.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cardAlt,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.settings_ethernet,
                                    size: 14,
                                    color: AppColors.icon,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'IP: ${device.specFields['ip'] ?? 'N/A'}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (device.specFields['model'] != null) ...[
                                    const SizedBox(width: 10),
                                    Text(
                                      'Model: ${device.specFields['model']}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _openRaiseIssueSheet(device),
                                icon: const Icon(
                                  Icons.report_problem_outlined,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Report Fault',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.errorText,
                                  side: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                  minimumSize: const Size(120, 36),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, DeviceStatus? status) {
    final isSelected = _deviceFilterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primaryBg,
        backgroundColor: AppColors.surface,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
        onSelected: (_) => setState(() => _deviceFilterStatus = status),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 3: ISSUES TRACKER
  // -------------------------------------------------------------
  Widget _buildIssuesTab() {
    if (_issues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 48,
              color: AppColors.success,
            ),
            const SizedBox(height: 12),
            const Text(
              'No Issues Reported in Zone',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'All devices in this zone are running normally',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openRaiseIssueSheet(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Raise Issue Ticket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                minimumSize: const Size(160, 44),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
      itemCount: _issues.length,
      itemBuilder: (context, index) {
        final issue = _issues[index];

        return InkWell(
          onTap: () => IssueDetailSheet.show(context, issue),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      issue.id,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    StatusBadge.priority(issue.priority),
                    const SizedBox(width: 6),
                    StatusBadge.issue(issue.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  issue.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${issue.deviceName} • ${issue.zoneName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.engineering_outlined,
                          size: 14,
                          color: AppColors.icon,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          issue.assignedTechnicianName != null
                              ? 'Tech: ${issue.assignedTechnicianName}'
                              : 'Tech: Unassigned',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.history,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${issue.history.length} updates',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
