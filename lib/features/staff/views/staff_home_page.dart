import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:equipment_management_system/features/daily_logs/daily_logs.dart';
import 'package:equipment_management_system/features/devices/devices.dart';
import 'package:equipment_management_system/features/issues/issues.dart';
import 'package:equipment_management_system/features/realtime/realtime.dart';
import '../viewmodels/staff_checklist_viewmodel.dart';
import '../viewmodels/staff_dashboard_viewmodel.dart';
import 'widgets/widgets.dart';

class StaffHomePage extends ConsumerStatefulWidget {
  const StaffHomePage({super.key});

  @override
  ConsumerState<StaffHomePage> createState() => _StaffHomePageState();
}

class _StaffHomePageState extends ConsumerState<StaffHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

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
    super.dispose();
  }

  Future<void> _handleDeviceStatusLog(
    DeviceModel device,
    DailyLogStatus status,
  ) async {
    try {
      await ref.read(staffChecklistViewModelProvider.notifier).submitStatus(
            device: device,
            status: status,
          );

      final msg = 'Marked ${device.name} as ${status.label}';
      if (status == DailyLogStatus.working) {
        AppSnackbar.success(msg);
      } else if (status == DailyLogStatus.needsAttention) {
        AppSnackbar.warning(msg);
      } else {
        AppSnackbar.error(msg);
      }

      if (status == DailyLogStatus.notWorking) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _promptRaiseIssue(device);
        });
      }
    } catch (e) {
      AppSnackbar.error('Failed to record status: $e');
    }
  }

  void _promptRaiseIssue(DeviceModel device) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 24,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hardware Down!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          'You marked "${device.name}" as Down / Faulty.\n\nWould you like to raise a maintenance defect ticket now so the technician team can dispatch immediately?',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Later',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _openRaiseIssueSheet(device);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Raise Ticket Now'),
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
        final dashboardVm = ref.read(staffDashboardViewModelProvider);
        dashboardVm.refreshIssues();
        dashboardVm.refreshDevices();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dashboardVm = ref.read(staffDashboardViewModelProvider);

    // Realtime: Sync daily logs submitted by any staff member in this zone
    ref.listen<AsyncValue<DailyStatusLogModel>>(
      socketLogSubmittedStreamProvider,
      (previous, next) {
        if (next.value == null) return;
        dashboardVm.refreshTodayLogs();
        dashboardVm.refreshDevices();
      },
    );

    // Realtime: Sync issue defect creation
    ref.listen<AsyncValue<IssueModel>>(
      socketIssueCreatedStreamProvider,
      (previous, next) {
        if (next.value == null) return;
        dashboardVm.refreshIssues();
        dashboardVm.refreshDevices();
      },
    );

    // Realtime: Sync issue updates (technician started work, resolved, or closed)
    ref.listen<AsyncValue<IssueModel>>(
      socketIssueUpdatedStreamProvider,
      (previous, next) {
        final issue = next.value;
        if (issue == null) return;

        dashboardVm.refreshIssues();
        dashboardVm.refreshDevices();
        ref.invalidate(issueDetailProvider(issue.id));

        // If issue was marked resolved by tech, notify staff to verify
        if (issue.status == IssueStatus.resolved) {
          RealtimeToastHelper.showSimpleToast(
            context,
            title: l10n?.issueResolvedAlert ?? 'Defect Resolved',
            message: '${issue.deviceName} has been resolved by technician. Tap to verify & close.',
            icon: Icons.check_circle_outline,
            iconColor: AppColors.success,
            onTap: () => IssueDetailSheet.show(context, issue),
          );
        }
      },
    );

    final staffDevicesAsync = ref.watch(staffDevicesProvider);
    final staffSummaryAsync = ref.watch(staffDashboardSummaryProvider);
    final staffIssuesAsync = ref.watch(staffIssuesProvider);
    final todayLogsAsync = ref.watch(todayLogsProvider);
    final checklistState = ref.watch(staffChecklistViewModelProvider);
    final checklistNotifier = ref.read(staffChecklistViewModelProvider.notifier);

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
            tabs: [
              Tab(
                icon: const Icon(Icons.devices_other_rounded, size: 18),
                text: l10n?.tabCatalogue ?? 'Hardware',
              ),
              Tab(
                icon: const Icon(Icons.checklist_rounded, size: 18),
                text: l10n?.tabDailyChecklist ?? 'Daily Checks',
              ),
              Tab(
                icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                text: l10n?.tabIssues ?? 'Issues',
              ),
            ],
          ),
        ),

        // Live KPI Metric Header Bar
        StaffKpiBar(summaryAsync: staffSummaryAsync),

        const Divider(height: 1, color: AppColors.divider),

        // Active Tab View Content
        Expanded(
          child: switch (_currentTabIndex) {
            0 => StaffDevicesDirectoryTab(
                devices: staffDevicesAsync.value ?? [],
                isLoading: staffDevicesAsync.isLoading,
                hasError: staffDevicesAsync.hasError,
                onRefresh: () async => dashboardVm.refreshDevices(),
                onOpenRaiseIssue: _openRaiseIssueSheet,
              ),
            1 => StaffDailyChecklistTab(
                allDevices: staffDevicesAsync.value ?? [],
                todayLogsMap: todayLogsAsync.value ?? {},
                isLoading: staffDevicesAsync.isLoading,
                hasError: staffDevicesAsync.hasError,
                checklistState: checklistState,
                onFilterChanged: checklistNotifier.setFilterIndex,
                onNoteChanged: checklistNotifier.setDraftNote,
                onLogStatus: _handleDeviceStatusLog,
                onToggleEdit: checklistNotifier.startEditing,
                onCancelEdit: checklistNotifier.cancelEditing,
                onRefresh: () async => dashboardVm.refreshAll(),
              ),
            2 => StaffIssuesTrackerTab(
                issues: staffIssuesAsync.value ?? [],
                isLoading: staffIssuesAsync.isLoading,
                hasError: staffIssuesAsync.hasError,
                onRefresh: () async => dashboardVm.refreshIssues(),
                onOpenIssueDetail: (issue) => IssueDetailSheet.show(context, issue),
              ),
            _ => const SizedBox.shrink(),
          },
        ),
      ],
    );
  }
}
