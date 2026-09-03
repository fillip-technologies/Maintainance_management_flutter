import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/models/issue_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../issues/issues.dart';
import 'widgets/widgets.dart';

class TechnicianHomePage extends ConsumerStatefulWidget {
  const TechnicianHomePage({super.key});

  @override
  ConsumerState<TechnicianHomePage> createState() => _TechnicianHomePageState();
}

class _TechnicianHomePageState extends ConsumerState<TechnicianHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;
  String _searchQuery = '';
  IssuePriority? _selectedPriorityFilter;

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

  void _openUpdateStatusSheet(IssueModel issue, [IssueStatus? targetStatus]) {
    UpdateStatusSheet.show(
      context,
      issue: issue,
      initialTargetStatus: targetStatus,
      onStatusUpdated: (newStatus, comment, resolutionPhoto) async {
        try {
          final issueRepo = ref.read(issueRepositoryProvider);
          await issueRepo.updateIssueStatus(
            issueId: issue.id,
            toStatus: newStatus,
            notes: comment,
          );

          ref.invalidate(technicianIssuesProvider);

          final msg = 'Ticket ${issue.id.length > 8 ? "#${issue.id.substring(0, 8)}" : issue.id} moved to ${newStatus.label}';
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
    final l10n = AppLocalizations.of(context)!;
    final issuesAsync = ref.watch(technicianIssuesProvider);
    final issues = issuesAsync.value ?? [];
    final isLoading = issuesAsync.isLoading;
    final hasError = issuesAsync.hasError;

    final activeIssues = issues
        .where((i) =>
            i.status == IssueStatus.open ||
            i.status == IssueStatus.assigned ||
            i.status == IssueStatus.inProgress ||
            i.status == IssueStatus.reopened)
        .toList();
    final onHoldIssues =
        issues.where((i) => i.status == IssueStatus.onHold).toList();
    final resolvedIssues = issues
        .where(
            (i) => i.status == IssueStatus.resolved || i.status == IssueStatus.closed)
        .toList();

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
                icon: const Icon(Icons.assignment_outlined, size: 18),
                text: '${l10n.tabActiveQueue} (${activeIssues.length})',
              ),
              Tab(
                icon: const Icon(Icons.pause_circle_outline, size: 18),
                text: '${l10n.tabOnHold} (${onHoldIssues.length})',
              ),
              Tab(
                icon: const Icon(Icons.task_alt, size: 18),
                text: '${l10n.tabResolvedHistory} (${resolvedIssues.length})',
              ),
            ],
          ),
        ),

        // Live KPI Metric Header Bar
        TechnicianKpiBar(
          total: issues.length,
          open: issues.where((i) =>
              i.status == IssueStatus.open ||
              i.status == IssueStatus.assigned ||
              i.status == IssueStatus.inProgress ||
              i.status == IssueStatus.reopened).length,
          onHold: onHoldIssues.length,
          resolved: resolvedIssues.length,
        ),

        const Divider(height: 1, color: AppColors.divider),

        // Search & Priority Filter Box
        TechnicianSearchFilterBar(
          searchQuery: _searchQuery,
          selectedPriority: _selectedPriorityFilter,
          onSearchChanged: (val) => setState(() => _searchQuery = val),
          onPriorityChanged: (p) => setState(() => _selectedPriorityFilter = p),
        ),

        const Divider(height: 1, color: AppColors.divider),

        // Active Tab View Content
        Expanded(
          child: _buildCurrentTab(
            activeIssues: activeIssues,
            onHoldIssues: onHoldIssues,
            resolvedIssues: resolvedIssues,
            isLoading: isLoading,
            hasError: hasError,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentTab({
    required List<IssueModel> activeIssues,
    required List<IssueModel> onHoldIssues,
    required List<IssueModel> resolvedIssues,
    required bool isLoading,
    required bool hasError,
  }) {
    final (list, emptyMessage) = switch (_currentTabIndex) {
      0 => (activeIssues, 'No active tickets in queue'),
      1 => (onHoldIssues, 'No tickets currently on hold'),
      2 => (resolvedIssues, 'No resolved tickets yet'),
      _ => (activeIssues, 'No active tickets in queue'),
    };

    return TechnicianIssueList(
      issues: list,
      emptyMessage: emptyMessage,
      isLoading: isLoading,
      hasError: hasError,
      searchQuery: _searchQuery,
      selectedPriority: _selectedPriorityFilter,
      onRefresh: () async {
        ref.invalidate(technicianIssuesProvider);
      },
      onOpenDetail: (issue) => IssueDetailSheet.show(context, issue),
      onOpenUpdateStatus: _openUpdateStatusSheet,
    );
  }
}
