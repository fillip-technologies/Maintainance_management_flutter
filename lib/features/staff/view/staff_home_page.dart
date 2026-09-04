import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/daily_log_provider.dart';
import '../../../core/providers/device_provider.dart';
import '../../../core/providers/socket_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/realtime_toast_helper.dart';
import '../../../data/models/daily_log_model.dart';
import '../../../data/models/device_model.dart';
import '../../../data/models/issue_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../issues/issues.dart';
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

  Future<void> _handleDeviceStatusLog(
    DeviceModel device,
    DailyLogStatus status,
  ) async {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Expanded(
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
        ref.invalidate(staffIssuesProvider);
        ref.invalidate(staffDevicesProvider);
        ref.invalidate(staffDashboardSummaryProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Realtime: Sync daily logs submitted by any staff member in this zone
    ref.listen<AsyncValue<DailyStatusLogModel>>(
      socketLogSubmittedStreamProvider,
      (previous, next) {
        final log = next.value;
        if (log != null) {
          ref.invalidate(todayLogsProvider);
          ref.invalidate(staffDashboardSummaryProvider);
          ref.invalidate(staffDevicesProvider);
        }
      },
    );

    // Realtime: Sync issue defect creation
    ref.listen<AsyncValue<IssueModel>>(
      socketIssueCreatedStreamProvider,
      (previous, next) {
        final issue = next.value;
        if (issue != null) {
          ref.invalidate(staffIssuesProvider);
          ref.invalidate(staffDevicesProvider);
          ref.invalidate(staffDashboardSummaryProvider);
        }
      },
    );

    // Realtime: Sync issue updates (technician started work, resolved, or closed)
    ref.listen<AsyncValue<IssueModel>>(
      socketIssueUpdatedStreamProvider,
      (previous, next) {
        final issue = next.value;
        if (issue != null) {
          ref.invalidate(staffIssuesProvider);
          ref.invalidate(staffDevicesProvider);
          ref.invalidate(staffDashboardSummaryProvider);
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
        }
      },
    );

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
            tabs: [
              Tab(
                icon: const Icon(Icons.checklist_rounded, size: 18),
                text: l10n?.tabDailyChecklist ?? 'Daily Checks',
              ),
              Tab(
                icon: const Icon(Icons.devices_other_rounded, size: 18),
                text: l10n?.tabCatalogue ?? 'Hardware',
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
          child: _buildCurrentTab(
            staffDevicesAsync,
            todayLogsAsync,
            staffIssuesAsync,
          ),
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
        return StaffDailyChecklistTab(
          allDevices: staffDevicesAsync.value ?? [],
          todayLogsMap: todayLogsAsync.value ?? {},
          isLoading: staffDevicesAsync.isLoading,
          hasError: staffDevicesAsync.hasError,
          submittingDeviceLogIds: _submittingDeviceLogIds,
          editingDeviceLogIds: _editingDeviceLogIds,
          getNoteController: _getNoteController,
          onLogStatus: _handleDeviceStatusLog,
          onToggleEdit: (deviceId) {
            setState(() {
              _editingDeviceLogIds.add(deviceId);
              final existingLog = todayLogsAsync.value?[deviceId];
              if (existingLog?.notes != null) {
                _getNoteController(deviceId).text = existingLog!.notes!;
              }
            });
          },
          onCancelEdit: (deviceId) {
            setState(() => _editingDeviceLogIds.remove(deviceId));
          },
          onRefresh: () async {
            ref.invalidate(staffDevicesProvider);
            ref.invalidate(todayLogsProvider);
            ref.invalidate(staffDashboardSummaryProvider);
          },
        );

      case 1:
        return StaffDevicesDirectoryTab(
          devices: staffDevicesAsync.value ?? [],
          isLoading: staffDevicesAsync.isLoading,
          hasError: staffDevicesAsync.hasError,
          onRefresh: () async {
            ref.invalidate(staffDevicesProvider);
            ref.invalidate(staffDashboardSummaryProvider);
          },
          onOpenRaiseIssue: _openRaiseIssueSheet,
        );

      case 2:
        return StaffIssuesTrackerTab(
          issues: staffIssuesAsync.value ?? [],
          isLoading: staffIssuesAsync.isLoading,
          hasError: staffIssuesAsync.hasError,
          onRefresh: () async {
            ref.invalidate(staffIssuesProvider);
            ref.invalidate(staffDashboardSummaryProvider);
          },
          onOpenIssueDetail: (issue) => IssueDetailSheet.show(context, issue),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
