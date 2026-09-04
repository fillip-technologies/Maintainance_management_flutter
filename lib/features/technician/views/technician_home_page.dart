import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../issues/issues.dart';
import '../../realtime/realtime.dart';
import '../models/technician_queue_state.dart';
import '../viewmodels/technician_action_viewmodel.dart';
import '../viewmodels/technician_queue_viewmodel.dart';
import 'widgets/widgets.dart';

class TechnicianHomePage extends ConsumerStatefulWidget {
  const TechnicianHomePage({super.key});

  @override
  ConsumerState<TechnicianHomePage> createState() => _TechnicianHomePageState();
}

class _TechnicianHomePageState extends ConsumerState<TechnicianHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (!mounted) return;
      ref.read(technicianQueueFilterProvider.notifier).setTabIndex(_tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openUpdateStatusSheet(IssueModel issue, [IssueStatus? targetStatus]) {
    UpdateStatusSheet.show(
      context,
      issue: issue,
      initialTargetStatus: targetStatus,
      onStatusUpdated: (newStatus, comment, resolutionPhoto) async {
        try {
          await ref.read(technicianActionViewModelProvider).updateStatus(
            issueId: issue.id,
            toStatus: newStatus,
            notes: comment,
          );

          final ticketIdStr = issue.id.length > 8 ? '#${issue.id.substring(0, 8)}' : issue.id;
          final msg = 'Ticket $ticketIdStr moved to ${newStatus.label}';
          if (newStatus == IssueStatus.resolved) {
            AppSnackbar.success(msg);
          } else if (newStatus == IssueStatus.onHold) {
            AppSnackbar.warning(msg);
          } else {
            AppSnackbar.info(msg);
          }
        } catch (e) {
          AppSnackbar.error('Failed to update status: $e');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Realtime: Listen for incoming new tickets and show toast + refresh
    ref.listen<AsyncValue<IssueModel>>(
      socketIssueCreatedStreamProvider,
      (previous, next) {
        final issue = next.value;
        if (issue == null) return;

        ref.read(technicianActionViewModelProvider).refreshQueue();
        RealtimeToastHelper.showNewIssueToast(
          context,
          issue: issue,
          onTap: () => IssueDetailSheet.show(context, issue),
        );
      },
    );

    // Realtime: Listen for ticket status updates (e.g. claimed or resolved)
    ref.listen<AsyncValue<IssueModel>>(
      socketIssueUpdatedStreamProvider,
      (previous, next) {
        final issue = next.value;
        if (issue == null) return;

        ref.read(technicianActionViewModelProvider).refreshQueue();
        ref.invalidate(issueDetailProvider(issue.id));
        ref.invalidate(issueHistoryProvider(issue.id));
      },
    );

    final l10n = AppLocalizations.of(context)!;
    final queueState = ref.watch(technicianQueueStateProvider);
    final filterNotifier = ref.read(technicianQueueFilterProvider.notifier);

    return Column(
      children: [
        // Tab Bar Navigation Header
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            onTap: (index) => filterNotifier.setTabIndex(index),
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
                icon: const Icon(Icons.assignment_outlined, size: 18),
                text: '${l10n.tabActiveQueue} (${queueState.activeIssues.length})',
              ),
              Tab(
                icon: const Icon(Icons.pause_circle_outline, size: 18),
                text: '${l10n.tabOnHold} (${queueState.onHoldIssues.length})',
              ),
              Tab(
                icon: const Icon(Icons.task_alt, size: 18),
                text: '${l10n.tabResolvedHistory} (${queueState.resolvedIssues.length})',
              ),
            ],
          ),
        ),

        // Live KPI Metric Header Bar
        TechnicianKpiBar(stats: queueState.kpiStats),

        const Divider(height: 1, color: AppColors.divider),

        // Search & Priority Filter Box
        TechnicianSearchFilterBar(
          searchQuery: queueState.filter.searchQuery,
          selectedPriority: queueState.filter.priority,
          onSearchChanged: filterNotifier.setSearchQuery,
          onPriorityChanged: filterNotifier.setPriority,
        ),

        const Divider(height: 1, color: AppColors.divider),

        // Active Tab View Content
        Expanded(
          child: _buildCurrentTab(
            queueState: queueState,
            tabIndex: queueState.filter.tabIndex,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentTab({
    required TechnicianQueueState queueState,
    required int tabIndex,
  }) {
    final (list, emptyMessage) = switch (tabIndex) {
      0 => (queueState.activeIssues, 'No active tickets in queue'),
      1 => (queueState.onHoldIssues, 'No tickets currently on hold'),
      2 => (queueState.resolvedIssues, 'No resolved tickets yet'),
      _ => (queueState.activeIssues, 'No active tickets in queue'),
    };

    return TechnicianIssueList(
      issues: list,
      emptyMessage: emptyMessage,
      isLoading: queueState.isLoading,
      hasError: queueState.errorMessage != null,
      onRefresh: () async {
        ref.read(technicianActionViewModelProvider).refreshQueue();
      },
      onOpenDetail: (issue) => IssueDetailSheet.show(context, issue),
      onOpenUpdateStatus: _openUpdateStatusSheet,
    );
  }
}
