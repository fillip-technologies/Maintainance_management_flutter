import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/daily_log_provider.dart';
import '../../../core/providers/device_provider.dart';
import '../../../core/providers/issue_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/hardware_icon_helper.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/daily_log_model.dart';
import '../../../data/models/device_model.dart';
import '../../../data/models/issue_model.dart';
import '../../issues/issues.dart';

class StaffHomePage extends ConsumerStatefulWidget {
  const StaffHomePage({super.key});

  @override
  ConsumerState<StaffHomePage> createState() => _StaffHomePageState();
}

class _StaffHomePageState extends ConsumerState<StaffHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Search & Filter state
  String _deviceSearchQuery = '';
  DeviceStatus? _deviceFilterStatus;
  int _dailyCheckFilterIndex = 0; // 0: All, 1: Pending, 2: Checked Today
  int _staffIssueFilterIndex = 0; // 0: Open, 1: Closed, 2: All

  final Set<String> _submittingDeviceLogIds = {};
  final Set<String> _editingDeviceLogIds = {};
  final Map<String, TextEditingController> _logNoteControllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentTabIndex && mounted) {
        setState(() => _currentTabIndex = _tabController.index);
      }
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
    var controller = _logNoteControllers[deviceId];
    if (controller == null) {
      controller = TextEditingController();
      _logNoteControllers[deviceId] = controller;
    }
    return controller;
  }

  Future<void> _handleDeviceStatusLog(DeviceModel device, DailyLogStatus status) async {
    final note = _getNoteController(device.id).text.trim();

    setState(() => _submittingDeviceLogIds.add(device.id));

    try {
      final dailyLogRepo = ref.read(dailyLogRepositoryProvider);
      await dailyLogRepo.createOrUpdateLog(
        deviceId: device.id,
        status: status,
        notes: note.isNotEmpty ? note : null,
      );

      final msg = 'Marked ${device.name} as ${status.label}';
      if (status == DailyLogStatus.working) {
        AppSnackbar.success(msg);
      } else if (status == DailyLogStatus.needsAttention) {
        AppSnackbar.warning(msg);
      } else {
        AppSnackbar.error(msg);
      }

      // Refresh live devices, today's logs, and KPIs
      ref.invalidate(todayLogsProvider);
      ref.invalidate(staffDevicesProvider);
      ref.invalidate(staffDashboardSummaryProvider);

      if (status == DailyLogStatus.notWorking) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _promptRaiseIssue(device);
        });
      }
    } catch (e) {
      AppSnackbar.error('Failed to record status: $e');
    } finally {
      if (mounted) {
        setState(() {
          _submittingDeviceLogIds.remove(device.id);
          _editingDeviceLogIds.remove(device.id);
        });
      }
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
              'Hardware Fault Reported',
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
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Raise Ticket'),
          ),
        ],
      ),
    );
  }

  void _openRaiseIssueSheet([DeviceModel? initialDevice]) {
    final liveDevices = ref.read(staffDevicesProvider).value ?? [];

    RaiseIssueSheet.show(
      context,
      devices: liveDevices,
      initialDevice: initialDevice,
      onIssueCreated: (newIssue) {
        ref.invalidate(staffIssuesProvider);
        ref.invalidate(staffDevicesProvider);
        ref.invalidate(staffDashboardSummaryProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffDevicesAsync = ref.watch(staffDevicesProvider);
    final staffSummaryAsync = ref.watch(staffDashboardSummaryProvider);
    final staffIssuesAsync = ref.watch(staffIssuesProvider);
    final todayLogsAsync = ref.watch(todayLogsProvider);

    return Column(
      children: [
        // Tab Bar Navigation Header
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            onTap: (index) => setState(() => _currentTabIndex = index),
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
              Tab(
                icon: Icon(Icons.devices_other_rounded, size: 18),
                text: 'Hardware',
              ),
              Tab(
                icon: Icon(Icons.confirmation_number_outlined, size: 18),
                text: 'Issues',
              ),
            ],
          ),
        ),

        // Live KPI Metric Header Bar
        _buildStaffKpiBar(staffSummaryAsync),

        const Divider(height: 1, color: AppColors.divider),

        // Active Tab View Content (Direct render without sliver conflicts)
        Expanded(
          child: _buildCurrentTab(staffDevicesAsync, todayLogsAsync, staffIssuesAsync),
        ),
      ],
    );
  }

  Widget _buildCurrentTab(
    AsyncValue<List<DeviceModel>> staffDevicesAsync,
    AsyncValue<Map<String, DailyStatusLogModel>> todayLogsAsync,
    AsyncValue<List<IssueModel>> staffIssuesAsync,
  ) {
    switch (_currentTabIndex) {
      case 0:
        return _buildStaffDailyChecklistTab(staffDevicesAsync, todayLogsAsync);
      case 1:
        return _buildStaffDevicesDirectoryTab(staffDevicesAsync);
      case 2:
        return _buildStaffIssuesTrackerTab(staffIssuesAsync);
      default:
        return _buildStaffDailyChecklistTab(staffDevicesAsync, todayLogsAsync);
    }
  }

  // ==========================================
  // STAFF KPI HEADER BAR
  // ==========================================

  Widget _buildStaffKpiBar(AsyncValue<dynamic> summaryAsync) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: summaryAsync.when(
        loading: () => Row(
          children: [
            _buildSummaryItem(label: 'Total Hardware', value: '...', color: AppColors.primary, icon: Icons.devices),
            _buildDivider(),
            _buildSummaryItem(label: 'Active', value: '...', color: AppColors.successText, icon: Icons.check_circle_outline),
            _buildDivider(),
            _buildSummaryItem(label: 'Open Issues', value: '...', color: AppColors.warningText, icon: Icons.build_circle_outlined),
            _buildDivider(),
            _buildSummaryItem(label: 'Faulty', value: '...', color: AppColors.errorText, icon: Icons.error_outline),
          ],
        ),
        error: (_, _) => Row(
          children: [
            _buildSummaryItem(label: 'Total Hardware', value: '-', color: AppColors.primary, icon: Icons.devices),
            _buildDivider(),
            _buildSummaryItem(label: 'Active', value: '-', color: AppColors.successText, icon: Icons.check_circle_outline),
            _buildDivider(),
            _buildSummaryItem(label: 'Open Issues', value: '-', color: AppColors.warningText, icon: Icons.build_circle_outlined),
            _buildDivider(),
            _buildSummaryItem(label: 'Faulty', value: '-', color: AppColors.errorText, icon: Icons.error_outline),
          ],
        ),
        data: (summary) => Row(
          children: [
            _buildSummaryItem(
              label: 'Total Hardware',
              value: '${summary.totalDevices}',
              color: AppColors.primary,
              icon: Icons.devices,
            ),
            _buildDivider(),
            _buildSummaryItem(
              label: 'Active',
              value: '${summary.activeDevices}',
              color: AppColors.successText,
              icon: Icons.check_circle_outline,
            ),
            _buildDivider(),
            _buildSummaryItem(
              label: 'Open Issues',
              value: '${summary.openIssues}',
              color: AppColors.warningText,
              icon: Icons.build_circle_outlined,
            ),
            _buildDivider(),
            _buildSummaryItem(
              label: 'Faulty',
              value: '${summary.faultyDevices}',
              color: AppColors.errorText,
              icon: Icons.error_outline,
            ),
          ],
        ),
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

  // ==========================================
  // TAB 1: DAILY CHECKS
  // ==========================================

  Widget _buildStaffDailyChecklistTab(
    AsyncValue<List<DeviceModel>> devicesAsync,
    AsyncValue<Map<String, DailyStatusLogModel>> todayLogsAsync,
  ) {
    final allDevices = devicesAsync.value ?? [];
    final todayLogsMap = todayLogsAsync.value ?? {};
    final isLoading = devicesAsync.isLoading;
    final hasError = devicesAsync.hasError;

    final completedCount = allDevices.where((d) => todayLogsMap.containsKey(d.id)).length;
    final pendingCount = allDevices.length - completedCount;

    var displayedDevices = allDevices;
    if (_dailyCheckFilterIndex == 1) {
      displayedDevices = allDevices.where((d) => !todayLogsMap.containsKey(d.id)).toList();
    } else if (_dailyCheckFilterIndex == 2) {
      displayedDevices = allDevices.where((d) => todayLogsMap.containsKey(d.id)).toList();
    }

    return Column(
      children: [
        // Segmented Status Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surface,
          child: Row(
            children: [
              _buildDailyCheckFilterChip(
                label: 'All (${allDevices.length})',
                index: 0,
              ),
              const SizedBox(width: 8),
              _buildDailyCheckFilterChip(
                label: 'Pending ($pendingCount)',
                index: 1,
                badgeColor: pendingCount > 0 ? AppColors.warningText : null,
              ),
              const SizedBox(width: 8),
              _buildDailyCheckFilterChip(
                label: 'Checked Today ($completedCount)',
                index: 2,
                badgeColor: completedCount > 0 ? AppColors.successText : null,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),

        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(staffDevicesProvider);
              ref.invalidate(todayLogsProvider);
              ref.invalidate(staffDashboardSummaryProvider);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: (isLoading || hasError || displayedDevices.isEmpty) ? 1 : displayedDevices.length,
              itemBuilder: (context, index) {
                if (isLoading) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }

                if (hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.icon),
                          const SizedBox(height: 12),
                          const Text(
                            'Failed to load hardware devices',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              ref.invalidate(staffDevicesProvider);
                              ref.invalidate(todayLogsProvider);
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (displayedDevices.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _dailyCheckFilterIndex == 1
                                ? Icons.task_alt_rounded
                                : Icons.checklist_rounded,
                            size: 48,
                            color: AppColors.iconLight,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _dailyCheckFilterIndex == 1
                                ? 'All hardware checked for today!'
                                : (_dailyCheckFilterIndex == 2
                                    ? 'No hardware checked today yet'
                                    : 'No hardware devices found'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final device = displayedDevices[index];
                final noteController = _getNoteController(device.id);
                final isSubmitting = _submittingDeviceLogIds.contains(device.id);
                final todayLog = todayLogsMap[device.id];
                final isEditing = _editingDeviceLogIds.contains(device.id);

                return Container(
                  key: ValueKey(device.id),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: todayLog != null
                          ? AppColors.success.withValues(alpha: 0.4)
                          : AppColors.border,
                      width: todayLog != null ? 1.4 : 1,
                    ),
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
                              child: Icon(
                                HardwareIconHelper.getIcon(device.hardwareTypeName),
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

                        // Checked Today Confirmation Banner
                        if (todayLog != null && !isEditing) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: (todayLog.status == DailyLogStatus.working
                                      ? AppColors.success
                                      : (todayLog.status == DailyLogStatus.needsAttention
                                          ? AppColors.warning
                                          : AppColors.error))
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: (todayLog.status == DailyLogStatus.working
                                        ? AppColors.success
                                        : (todayLog.status == DailyLogStatus.needsAttention
                                            ? AppColors.warning
                                            : AppColors.error))
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  todayLog.status == DailyLogStatus.working
                                      ? Icons.check_circle_rounded
                                      : (todayLog.status == DailyLogStatus.needsAttention
                                          ? Icons.warning_amber_rounded
                                          : Icons.cancel_outlined),
                                  size: 18,
                                  color: todayLog.status == DailyLogStatus.working
                                      ? AppColors.success
                                      : (todayLog.status == DailyLogStatus.needsAttention
                                          ? AppColors.warning
                                          : AppColors.error),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Checked Today: ${todayLog.status.label}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: todayLog.status == DailyLogStatus.working
                                              ? AppColors.successText
                                              : (todayLog.status == DailyLogStatus.needsAttention
                                                  ? AppColors.warningText
                                                  : AppColors.error),
                                        ),
                                      ),
                                      if (todayLog.notes != null && todayLog.notes!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Note: "${todayLog.notes}"',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _editingDeviceLogIds.add(device.id);
                                      if (todayLog.notes != null) {
                                        noteController.text = todayLog.notes!;
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit_outlined, size: 13, color: AppColors.primary),
                                        SizedBox(width: 4),
                                        Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Pending Check or Actively Editing
                          if (isEditing) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text(
                                  'Updating today\'s check:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () => setState(() => _editingDeviceLogIds.remove(device.id)),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                  ),
                                  child: const Text('Cancel', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 12),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: _buildChecklistButton(
                                  label: 'Working',
                                  icon: Icons.check_circle_outline,
                                  color: AppColors.success,
                                  isSelected: todayLog?.status == DailyLogStatus.working,
                                  isLoading: isSubmitting,
                                  onTap: () => _handleDeviceStatusLog(device, DailyLogStatus.working),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildChecklistButton(
                                  label: 'Attention',
                                  icon: Icons.warning_amber_outlined,
                                  color: AppColors.warning,
                                  isSelected: todayLog?.status == DailyLogStatus.needsAttention,
                                  isLoading: isSubmitting,
                                  onTap: () => _handleDeviceStatusLog(device, DailyLogStatus.needsAttention),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildChecklistButton(
                                  label: 'Down / Fault',
                                  icon: Icons.cancel_outlined,
                                  color: AppColors.error,
                                  isSelected: todayLog?.status == DailyLogStatus.notWorking,
                                  isLoading: isSubmitting,
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
                              hintText: 'Add note (e.g. wire loose, lens dirty)...',
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
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyCheckFilterChip({
    required String label,
    required int index,
    Color? badgeColor,
  }) {
    final isSelected = _dailyCheckFilterIndex == index;
    return InkWell(
      onTap: () => setState(() => _dailyCheckFilterIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.textWhite : (badgeColor ?? AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistButton({
    required String label,
    required IconData icon,
    required Color color,
    bool isSelected = false,
    bool isLoading = false,
    required VoidCallback onTap,
  }) {
    final bg = isSelected ? color : color.withValues(alpha: 0.1);
    final fg = isSelected ? AppColors.textWhite : color;
    final border = isSelected ? Colors.transparent : color.withValues(alpha: 0.3);

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: fg),
              ),
              const SizedBox(width: 4),
            ] else ...[
              Icon(isSelected ? Icons.check_circle_rounded : icon, size: 14, color: fg),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: HARDWARE DIRECTORY
  // ==========================================

  Widget _buildStaffDevicesDirectoryTab(AsyncValue<List<DeviceModel>> devicesAsync) {
    final devices = devicesAsync.value ?? [];
    final isLoading = devicesAsync.isLoading;
    final hasError = devicesAsync.hasError;

    var list = devices;
    if (_deviceFilterStatus != null) {
      list = list.where((d) => d.status == _deviceFilterStatus).toList();
    }

    if (_deviceSearchQuery.trim().isNotEmpty) {
      final q = _deviceSearchQuery.toLowerCase();
      list = list.where((d) {
        return d.name.toLowerCase().contains(q) ||
            d.hardwareTypeName.toLowerCase().contains(q) ||
            d.zoneName.toLowerCase().contains(q) ||
            d.location.toLowerCase().contains(q);
      }).toList();
    }

    return Column(
      children: [
        // Search & Filter Box
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surface,
          child: Column(
            children: [
              TextField(
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search hardware by name, type, or zone...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.icon),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    _buildFilterChip('All Hardware', null),
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
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(staffDevicesProvider);
              ref.invalidate(staffDashboardSummaryProvider);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: (isLoading || hasError || list.isEmpty) ? 1 : list.length,
              itemBuilder: (context, index) {
                if (isLoading) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }
                if (hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.icon),
                          const SizedBox(height: 12),
                          const Text(
                            'Failed to load hardware directory',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => ref.invalidate(staffDevicesProvider),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: Text(
                        'No matching hardware found',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }
                final device = list[index];
                return Container(
                  key: ValueKey(device.id),
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
                      child: Icon(
                        HardwareIconHelper.getIcon(device.hardwareTypeName),
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      device.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      '${device.hardwareTypeName} • ${device.zoneName} • ${device.location.isNotEmpty ? device.location : "Active"}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    trailing: StatusBadge.device(device.status),
                    onTap: () => _openRaiseIssueSheet(device),
                  ),
                );
              },
            ),
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

  // ==========================================
  // TAB 3: ISSUES TRACKER
  // ==========================================

  Widget _buildStaffIssuesTrackerTab(AsyncValue<List<IssueModel>> issuesAsync) {
    final allIssues = issuesAsync.value ?? [];
    final isLoading = issuesAsync.isLoading;
    final hasError = issuesAsync.hasError;

    final openIssues = allIssues
        .where((i) => i.status != IssueStatus.closed && i.status != IssueStatus.resolved)
        .toList();
    final closedIssues = allIssues
        .where((i) => i.status == IssueStatus.closed || i.status == IssueStatus.resolved)
        .toList();

    final displayedIssues = _staffIssueFilterIndex == 0
        ? openIssues
        : (_staffIssueFilterIndex == 1 ? closedIssues : allIssues);

    return Column(
      children: [
        // Segmented Issue Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surface,
          child: Row(
            children: [
              _buildStaffIssueFilterChip(
                label: 'Open (${openIssues.length})',
                index: 0,
                badgeColor: openIssues.isNotEmpty ? AppColors.warningText : null,
              ),
              const SizedBox(width: 8),
              _buildStaffIssueFilterChip(
                label: 'Closed (${closedIssues.length})',
                index: 1,
                badgeColor: closedIssues.isNotEmpty ? AppColors.successText : null,
              ),
              const SizedBox(width: 8),
              _buildStaffIssueFilterChip(
                label: 'All (${allIssues.length})',
                index: 2,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),

        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(staffIssuesProvider);
              ref.invalidate(staffDashboardSummaryProvider);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: (isLoading || hasError || displayedIssues.isEmpty) ? 1 : displayedIssues.length,
              itemBuilder: (context, index) {
                if (isLoading) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }
                if (hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.icon),
                          const SizedBox(height: 12),
                          const Text(
                            'Failed to load maintenance tickets',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => ref.invalidate(staffIssuesProvider),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (displayedIssues.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _staffIssueFilterIndex == 0
                                ? Icons.task_alt_rounded
                                : (_staffIssueFilterIndex == 1
                                    ? Icons.history_toggle_off_rounded
                                    : Icons.confirmation_number_outlined),
                            size: 48,
                            color: AppColors.iconLight,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _staffIssueFilterIndex == 0
                                ? 'No open maintenance tickets in your zone'
                                : (_staffIssueFilterIndex == 1
                                    ? 'No closed maintenance tickets yet'
                                    : 'No maintenance issues recorded in your zone'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _staffIssueFilterIndex == 0
                                ? 'All reported equipment issues have been resolved'
                                : 'Pull down to refresh tickets',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final issue = displayedIssues[index];
                return Container(
                  key: ValueKey(issue.id),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: issue.priority == IssuePriority.critical
                          ? AppColors.error.withValues(alpha: 0.5)
                          : AppColors.border,
                    ),
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
                                issue.id.length > 8 ? '#${issue.id.substring(0, 8)}' : issue.id,
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
                            issue.title.isNotEmpty ? issue.title : (issue.description.isNotEmpty ? issue.description : 'Maintenance Issue'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                HardwareIconHelper.getIcon(issue.categoryName),
                                size: 13,
                                color: AppColors.icon,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${issue.deviceName} • ${issue.zoneName} ${issue.categoryName.isNotEmpty ? "• ${issue.categoryName}" : ""}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffIssueFilterChip({
    required String label,
    required int index,
    Color? badgeColor,
  }) {
    final isSelected = _staffIssueFilterIndex == index;
    return InkWell(
      onTap: () => setState(() => _staffIssueFilterIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.textWhite : (badgeColor ?? AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
