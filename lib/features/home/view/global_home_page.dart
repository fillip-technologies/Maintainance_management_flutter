import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/daily_log_model.dart';
import '../../../data/models/device_model.dart';
import '../../../data/models/issue_model.dart';
import '../../../data/models/user_model.dart';
import '../../staff/view/widgets/issue_detail_sheet.dart';
import '../../staff/view/widgets/raise_issue_sheet.dart';
import '../../technician/view/widgets/update_status_sheet.dart';

class GlobalHomePage extends ConsumerStatefulWidget {
  const GlobalHomePage({super.key});

  @override
  ConsumerState<GlobalHomePage> createState() => _GlobalHomePageState();
}

class _GlobalHomePageState extends ConsumerState<GlobalHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Search & Filter state
  String _searchQuery = '';
  DeviceStatus? _deviceFilterStatus;
  IssuePriority? _selectedPriorityFilter;

  final Map<String, TextEditingController> _logNoteControllers = {};

  // In-Memory Data Store (shared & role-reactive)
  final List<DeviceModel> _devices = [
    DeviceModel(
      id: 'dev-cam-01',
      zoneId: 'zone-lion-03',
      zoneName: 'Lion Enclosure (A1.1)',
      name: 'Lion Feed Area Cam #1',
      serialNumber: 'SN-LION-001',
      location: 'South Perimeter Pole #4, 4m height',
      status: DeviceStatus.underMaintenance,
      hardwareTypeId: 'hw-type-ptz',
      hardwareTypeName: 'PTZ Dome 4K',
      lastCheckedAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    DeviceModel(
      id: 'dev-cam-02',
      zoneId: 'zone-lion-03',
      zoneName: 'Lion Enclosure (A1.1)',
      name: 'Lion Den Night-Vision Cam #2',
      serialNumber: 'SN-LION-002',
      location: 'Cave Entrance High Angle',
      status: DeviceStatus.active,
      hardwareTypeId: 'hw-type-ir',
      hardwareTypeName: 'IR Fixed Bullet 1080p',
      lastCheckedAt: DateTime.now().subtract(const Duration(minutes: 50)),
    ),
    DeviceModel(
      id: 'dev-cam-03',
      zoneId: 'zone-tiger-04',
      zoneName: 'Tiger Den (A1.2)',
      name: 'Tiger Gate Entry Cam #1',
      serialNumber: 'SN-TIGER-001',
      location: 'Security Gate East, 3.5m',
      status: DeviceStatus.active,
      hardwareTypeId: 'hw-type-ptz',
      hardwareTypeName: 'PTZ Dome 4K',
      lastCheckedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 10)),
    ),
    DeviceModel(
      id: 'dev-cam-04',
      zoneId: 'zone-tiger-04',
      zoneName: 'Tiger Den (A1.2)',
      name: 'Tiger Water Pool Cam #1',
      serialNumber: 'SN-TIGER-002',
      location: 'North Pond Overlook',
      status: DeviceStatus.faulty,
      hardwareTypeId: 'hw-type-bullet',
      hardwareTypeName: 'Fixed Bullet 4K',
      lastCheckedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    DeviceModel(
      id: 'dev-cam-05',
      zoneId: 'zone-safari-01',
      zoneName: 'Open Safari Trail (A2)',
      name: 'Main Jeep Track Cam #1',
      serialNumber: 'SN-SAFARI-001',
      location: 'Tower Post Alpha, 6m height',
      status: DeviceStatus.active,
      hardwareTypeId: 'hw-type-solar',
      hardwareTypeName: 'Solar Cellular PTZ',
      lastCheckedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    DeviceModel(
      id: 'dev-cam-06',
      zoneId: 'zone-safari-01',
      zoneName: 'Open Safari Trail (A2)',
      name: 'Safari Waterhole Cam #2',
      serialNumber: 'SN-SAFARI-002',
      location: 'Waterhole Tree Hide, 4m',
      status: DeviceStatus.active,
      hardwareTypeId: 'hw-type-solar',
      hardwareTypeName: 'Solar Cellular PTZ',
      lastCheckedAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
  ];

  final List<IssueModel> _issues = [
    IssueModel(
      id: 'ISSUE-1001',
      title: 'PTZ Vertical Motor Jammed',
      description: 'Camera will not tilt vertically beyond 45 degrees. Squeaking noise heard from gear mechanism.',
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
      createdByUserId: 'usr-head-001',
      createdByUserName: 'Alex Mercer (Head)',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      history: [
        IssueStatusHistoryModel(
          id: 'hist-01',
          issueId: 'ISSUE-1001',
          fromStatus: null,
          toStatus: IssueStatus.open,
          changedByUserId: 'usr-head-001',
          changedByUserName: 'Alex Mercer',
          comment: 'Reported during morning status round',
          createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
        ),
        IssueStatusHistoryModel(
          id: 'hist-02',
          issueId: 'ISSUE-1001',
          fromStatus: IssueStatus.open,
          toStatus: IssueStatus.assigned,
          changedByUserId: 'usr-admin-004',
          changedByUserName: 'Director Vance',
          comment: 'Assigned to Senior Hardware Tech Marcus Vance',
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
      description: 'Heavy fogging on interior lens glass after monsoon rain. Unable to view water pool clearly.',
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
    IssueModel(
      id: 'ISSUE-1003',
      title: 'PoE Switch Intermittent Dropout',
      description: 'Camera video feed glitches every 10-15 minutes due to power fluctuation on switch port 3.',
      deviceId: 'dev-cam-01',
      deviceName: 'Main Jeep Track Cam #1',
      zoneId: 'zone-safari-01',
      zoneName: 'Open Safari Trail (A2)',
      categoryId: 'cat-05',
      categoryName: 'Power Fluctuation / PoE Drop',
      priority: IssuePriority.medium,
      status: IssueStatus.onHold,
      assignedTechnicianId: 'usr-tech-003',
      assignedTechnicianName: 'Marcus Vance',
      createdByUserId: 'usr-head-001',
      createdByUserName: 'Alex Mercer',
      createdAt: DateTime.now().subtract(const Duration(hours: 14)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
      history: [
        IssueStatusHistoryModel(
          id: 'hist-06',
          issueId: 'ISSUE-1003',
          fromStatus: null,
          toStatus: IssueStatus.open,
          changedByUserId: 'usr-head-001',
          changedByUserName: 'Alex Mercer',
          createdAt: DateTime.now().subtract(const Duration(hours: 14)),
        ),
        IssueStatusHistoryModel(
          id: 'hist-07',
          issueId: 'ISSUE-1003',
          fromStatus: IssueStatus.open,
          toStatus: IssueStatus.inProgress,
          changedByUserId: 'usr-tech-003',
          changedByUserName: 'Marcus Vance',
          comment: 'Tested Ethernet cabling; cable is fine, switch port is failing',
          createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        ),
        IssueStatusHistoryModel(
          id: 'hist-08',
          issueId: 'ISSUE-1003',
          fromStatus: IssueStatus.inProgress,
          toStatus: IssueStatus.onHold,
          changedByUserId: 'usr-tech-003',
          changedByUserName: 'Marcus Vance',
          comment: 'Waiting for replacement 8-port Gigabit PoE switch from central store',
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        ),
      ],
    ),
    IssueModel(
      id: 'ISSUE-1000',
      title: 'Night Vision IR Lamp Replacement',
      description: 'IR LED board failed; nocturnal tracking lost.',
      deviceId: 'dev-cam-02',
      deviceName: 'Lion Den Night-Vision Cam #2',
      zoneId: 'zone-lion-03',
      zoneName: 'Lion Enclosure (A1.1)',
      categoryId: 'cat-04',
      categoryName: 'Night Vision / IR Illuminator Failure',
      priority: IssuePriority.medium,
      status: IssueStatus.resolved,
      assignedTechnicianId: 'usr-tech-003',
      assignedTechnicianName: 'Marcus Vance',
      createdByUserId: 'usr-head-001',
      createdByUserName: 'Alex Mercer',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      history: [
        IssueStatusHistoryModel(
          id: 'hist-09',
          issueId: 'ISSUE-1000',
          fromStatus: null,
          toStatus: IssueStatus.open,
          changedByUserId: 'usr-head-001',
          changedByUserName: 'Alex Mercer',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        IssueStatusHistoryModel(
          id: 'hist-10',
          issueId: 'ISSUE-1000',
          fromStatus: IssueStatus.inProgress,
          toStatus: IssueStatus.resolved,
          changedByUserId: 'usr-tech-003',
          changedByUserName: 'Marcus Vance',
          comment: 'Replaced IR ring LED board and tested in darkness simulator',
          createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

  // --- Staff Actions ---

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
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Text(
              'Device Fault Reported',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          '${device.name} has been marked as Not Working.\nWould you like to raise a maintenance ticket now?',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openRaiseIssueSheet(device);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorText,
              foregroundColor: AppColors.textWhite,
            ),
            child: const Text('Raise Ticket'),
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

  // --- Technician Actions ---

  void _openUpdateStatusSheet(IssueModel issue, [IssueStatus? targetStatus]) {
    UpdateStatusSheet.show(
      context,
      issue: issue,
      initialTargetStatus: targetStatus,
      onStatusUpdated: (newStatus, comment, resolutionPhoto) {
        setState(() {
          final index = _issues.indexWhere((i) => i.id == issue.id);
          if (index != -1) {
            final historyItem = IssueStatusHistoryModel(
              id: 'hist-${DateTime.now().millisecondsSinceEpoch}',
              issueId: issue.id,
              fromStatus: issue.status,
              toStatus: newStatus,
              changedByUserId: 'usr-tech-003',
              changedByUserName: 'Marcus Vance (Tech)',
              comment: comment,
              createdAt: DateTime.now(),
            );

            final updatedHistory = List<IssueStatusHistoryModel>.from(_issues[index].history)
              ..add(historyItem);

            _issues[index] = _issues[index].copyWith(
              status: newStatus,
              updatedAt: DateTime.now(),
              imagePath: resolutionPhoto?.path ?? _issues[index].imagePath,
              history: updatedHistory,
            );
          }
        });

        final msg = 'Ticket ${issue.id} moved to ${newStatus.label}';
        if (newStatus == IssueStatus.resolved) {
          AppSnackbar.success(msg);
        } else if (newStatus == IssueStatus.onHold) {
          AppSnackbar.warning(msg);
        } else {
          AppSnackbar.info(msg);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final isTechnician = user?.role == UserRole.technician;

    // Staff KPI calculations
    final int activeCount = _devices.where((d) => d.status == DeviceStatus.active).length;
    final int maintCount = _devices.where((d) => d.status == DeviceStatus.underMaintenance).length;
    final int faultyCount = _devices.where((d) => d.status == DeviceStatus.faulty).length;

    // Technician KPI calculations
    final activeIssues = _issues
        .where((i) => i.status == IssueStatus.assigned || i.status == IssueStatus.inProgress)
        .toList();
    final onHoldIssues = _issues.where((i) => i.status == IssueStatus.onHold).toList();
    final resolvedIssues = _issues
        .where((i) => i.status == IssueStatus.resolved || i.status == IssueStatus.closed)
        .toList();

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
              child: Icon(
                isTechnician ? Icons.engineering_outlined : Icons.shield_outlined,
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
                    user?.name ?? (isTechnician ? 'Field Technician' : 'Staff Member'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        isTechnician ? Icons.build_circle_outlined : Icons.location_on,
                        size: 12,
                        color: AppColors.icon,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          isTechnician
                              ? 'Hardware Technician • All Assigned Zones'
                              : user?.assignedZoneName ?? 'North Wing (Cascading Tree)',
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
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.icon),
              tooltip: 'Sign Out',
              onPressed: () {
                ref.read(authStateProvider.notifier).logout();
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
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          tabs: isTechnician
              ? [
                  Tab(
                    icon: const Icon(Icons.assignment_outlined, size: 18),
                    text: 'Active (${activeIssues.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.pause_circle_outline, size: 18),
                    text: 'On Hold (${onHoldIssues.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.task_alt, size: 18),
                    text: 'Resolved (${resolvedIssues.length})',
                  ),
                ]
              : const [
                  Tab(
                    icon: Icon(Icons.checklist_rounded, size: 18),
                    text: 'Daily Checks',
                  ),
                  Tab(
                    icon: Icon(Icons.videocam_outlined, size: 18),
                    text: 'Devices',
                  ),
                  Tab(
                    icon: Icon(Icons.confirmation_number_outlined, size: 18),
                    text: 'Issues',
                  ),
                ],
        ),
      ),
      body: Column(
        children: [
          // KPI Metric Header Bar (Dynamic by role)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surface,
            child: isTechnician
                ? Row(
                    children: [
                      _buildSummaryItem(
                        label: 'Assigned',
                        value: '${_issues.length}',
                        color: AppColors.primary,
                        icon: Icons.assignment_outlined,
                      ),
                      _buildDivider(),
                      _buildSummaryItem(
                        label: 'In Progress',
                        value: '${_issues.where((i) => i.status == IssueStatus.inProgress).length}',
                        color: AppColors.warningText,
                        icon: Icons.sync,
                      ),
                      _buildDivider(),
                      _buildSummaryItem(
                        label: 'On Hold',
                        value: '${onHoldIssues.length}',
                        color: AppColors.purpleText,
                        icon: Icons.pause_circle_outline,
                      ),
                      _buildDivider(),
                      _buildSummaryItem(
                        label: 'Resolved',
                        value: '${resolvedIssues.length}',
                        color: AppColors.successText,
                        icon: Icons.check_circle_outline,
                      ),
                    ],
                  )
                : Row(
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
                        icon: Icons.build_outlined,
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

          // Main Tab View
          Expanded(
            child: isTechnician
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTechnicianIssueList(activeIssues, emptyMessage: 'No active tickets in queue'),
                      _buildTechnicianIssueList(onHoldIssues, emptyMessage: 'No tickets currently on hold'),
                      _buildTechnicianIssueList(resolvedIssues, emptyMessage: 'No resolved tickets yet'),
                    ],
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStaffDailyChecklistTab(),
                      _buildStaffDevicesDirectoryTab(),
                      _buildStaffIssuesTrackerTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SHARED KPI WIDGETS
  // ==========================================

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

  // ==========================================
  // STAFF VIEW TABS
  // ==========================================

  Widget _buildStaffDailyChecklistTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        final noteController = _getNoteController(device.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.videocam_outlined,
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
                            device.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${device.hardwareTypeName} • ${device.zoneName}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge.device(device.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildChecklistButton(
                        label: 'Working',
                        icon: Icons.check_circle_outline,
                        color: AppColors.success,
                        onTap: () => _handleDeviceStatusLog(device, DailyLogStatus.working),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildChecklistButton(
                        label: 'Attention',
                        icon: Icons.warning_amber_outlined,
                        color: AppColors.warning,
                        onTap: () => _handleDeviceStatusLog(device, DailyLogStatus.needsAttention),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildChecklistButton(
                        label: 'Down / Fault',
                        icon: Icons.cancel_outlined,
                        color: AppColors.error,
                        onTap: () => _handleDeviceStatusLog(device, DailyLogStatus.notWorking),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Add note (e.g. lens dirty, PTZ lag)...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: AppColors.cardAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChecklistButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffDevicesDirectoryTab() {
    var list = _devices;
    if (_deviceFilterStatus != null) {
      list = list.where((d) => d.status == _deviceFilterStatus).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((d) => d.name.toLowerCase().contains(q) || d.zoneName.toLowerCase().contains(q)).toList();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surface,
          child: Column(
            children: [
              TextField(
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search devices by name or zone...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.icon),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All Devices', null),
                    _buildFilterChip('Active', DeviceStatus.active),
                    _buildFilterChip('Maintenance', DeviceStatus.underMaintenance),
                    _buildFilterChip('Faulty', DeviceStatus.faulty),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final device = list[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.videocam, color: AppColors.primary, size: 20),
                  ),
                  title: Text(
                    device.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    '${device.zoneName} • ${device.location}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  trailing: StatusBadge.device(device.status),
                  onTap: () => _openRaiseIssueSheet(device),
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

  Widget _buildStaffIssuesTrackerTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _issues.length,
      itemBuilder: (context, index) {
        final issue = _issues[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: InkWell(
            onTap: () => IssueDetailSheet.show(context, issue),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        issue.id,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${issue.deviceName} • ${issue.zoneName}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TECHNICIAN VIEW TABS
  // ==========================================

  Widget _buildTechnicianIssueList(List<IssueModel> list, {required String emptyMessage}) {
    var filtered = list;
    if (_selectedPriorityFilter != null) {
      filtered = filtered.where((i) => i.priority == _selectedPriorityFilter).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((i) {
        return i.title.toLowerCase().contains(q) ||
            i.deviceName.toLowerCase().contains(q) ||
            i.zoneName.toLowerCase().contains(q) ||
            i.id.toLowerCase().contains(q);
      }).toList();
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.task_alt, size: 48, color: AppColors.iconLight),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final issue = filtered[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: issue.priority == IssuePriority.critical
                  ? AppColors.error.withValues(alpha: 0.5)
                  : AppColors.border,
              width: issue.priority == IssuePriority.critical ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: () => IssueDetailSheet.show(context, issue),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        issue.id,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      const Spacer(),
                      StatusBadge.priority(issue.priority),
                      const SizedBox(width: 6),
                      StatusBadge.issue(issue.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    issue.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.videocam_outlined, size: 14, color: AppColors.icon),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${issue.deviceName} • ${issue.zoneName}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    issue.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
                  ),
                  if (issue.imagePath != null && File(issue.imagePath!).existsSync()) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.cardAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_camera, size: 13, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'Photo Attached',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${issue.history.length} timeline events',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      Row(
                        children: [
                          if (issue.status == IssueStatus.assigned) ...[
                            ElevatedButton.icon(
                              onPressed: () => _openUpdateStatusSheet(issue, IssueStatus.inProgress),
                              icon: const Icon(Icons.play_arrow_rounded, size: 16),
                              label: const Text('Start Work', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.textWhite,
                                minimumSize: const Size(100, 36),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                            ),
                          ] else if (issue.status == IssueStatus.inProgress) ...[
                            OutlinedButton(
                              onPressed: () => _openUpdateStatusSheet(issue, IssueStatus.onHold),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.purpleText,
                                side: const BorderSide(color: AppColors.purple),
                                minimumSize: const Size(80, 36),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                              child: const Text('Hold', style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _openUpdateStatusSheet(issue, IssueStatus.resolved),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Resolve', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.successText,
                                foregroundColor: AppColors.textWhite,
                                minimumSize: const Size(95, 36),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                            ),
                          ] else if (issue.status == IssueStatus.onHold) ...[
                            ElevatedButton.icon(
                              onPressed: () => _openUpdateStatusSheet(issue, IssueStatus.inProgress),
                              icon: const Icon(Icons.replay, size: 16),
                              label: const Text('Resume Work', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.textWhite,
                                minimumSize: const Size(110, 36),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                            ),
                          ] else ...[
                            OutlinedButton.icon(
                              onPressed: () => IssueDetailSheet.show(context, issue),
                              icon: const Icon(Icons.visibility_outlined, size: 16),
                              label: const Text('View History', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                side: const BorderSide(color: AppColors.border),
                                minimumSize: const Size(100, 36),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
