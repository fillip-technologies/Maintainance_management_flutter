import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/issue_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/hardware_icon_helper.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/issue_model.dart';
import '../../staff/view/widgets/issue_detail_sheet.dart';
import 'widgets/update_status_sheet.dart';

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
    final issuesAsync = ref.watch(technicianIssuesProvider);
    final issues = issuesAsync.value ?? [];
    final isLoading = issuesAsync.isLoading;
    final hasError = issuesAsync.hasError;

    final activeIssues = issues
        .where((i) => i.status == IssueStatus.assigned || i.status == IssueStatus.inProgress)
        .toList();
    final onHoldIssues = issues.where((i) => i.status == IssueStatus.onHold).toList();
    final resolvedIssues = issues
        .where((i) => i.status == IssueStatus.resolved || i.status == IssueStatus.closed)
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
            ],
          ),
        ),

        // Live KPI Metric Header Bar
        _buildTechnicianKpiBar(
          assigned: issues.length,
          inProgress: issues.where((i) => i.status == IssueStatus.inProgress).length,
          onHold: onHoldIssues.length,
          resolved: resolvedIssues.length,
        ),

        const Divider(height: 1, color: AppColors.divider),

        // Search & Priority Filter Box
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surface,
          child: Column(
            children: [
              TextField(
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search tickets, devices, zones...',
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
                    _buildPriorityFilterChip('All Priorities', null),
                    _buildPriorityFilterChip('Critical', IssuePriority.critical),
                    _buildPriorityFilterChip('High', IssuePriority.high),
                    _buildPriorityFilterChip('Medium', IssuePriority.medium),
                    _buildPriorityFilterChip('Low', IssuePriority.low),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: AppColors.divider),

        // Active Tab View Content (Direct render without sliver conflicts)
        Expanded(
          child: _buildCurrentTab(activeIssues, onHoldIssues, resolvedIssues, isLoading, hasError),
        ),
      ],
    );
  }

  Widget _buildCurrentTab(
    List<IssueModel> activeIssues,
    List<IssueModel> onHoldIssues,
    List<IssueModel> resolvedIssues,
    bool isLoading,
    bool hasError,
  ) {
    switch (_currentTabIndex) {
      case 0:
        return _buildTechnicianIssueList(
          activeIssues,
          emptyMessage: 'No active tickets in queue',
          isLoading: isLoading,
          hasError: hasError,
        );
      case 1:
        return _buildTechnicianIssueList(
          onHoldIssues,
          emptyMessage: 'No tickets currently on hold',
          isLoading: isLoading,
          hasError: hasError,
        );
      case 2:
        return _buildTechnicianIssueList(
          resolvedIssues,
          emptyMessage: 'No resolved tickets yet',
          isLoading: isLoading,
          hasError: hasError,
        );
      default:
        return _buildTechnicianIssueList(
          activeIssues,
          emptyMessage: 'No active tickets in queue',
          isLoading: isLoading,
          hasError: hasError,
        );
    }
  }

  // ==========================================
  // TECHNICIAN KPI HEADER BAR
  // ==========================================

  Widget _buildTechnicianKpiBar({
    required int assigned,
    required int inProgress,
    required int onHold,
    required int resolved,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: Row(
        children: [
          _buildSummaryItem(
            label: 'Assigned',
            value: '$assigned',
            color: AppColors.primary,
            icon: Icons.assignment_outlined,
          ),
          _buildDivider(),
          _buildSummaryItem(
            label: 'In Progress',
            value: '$inProgress',
            color: AppColors.warningText,
            icon: Icons.sync,
          ),
          _buildDivider(),
          _buildSummaryItem(
            label: 'On Hold',
            value: '$onHold',
            color: AppColors.purpleText,
            icon: Icons.pause_circle_outline,
          ),
          _buildDivider(),
          _buildSummaryItem(
            label: 'Resolved',
            value: '$resolved',
            color: AppColors.successText,
            icon: Icons.check_circle_outline,
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

  Widget _buildPriorityFilterChip(String label, IssuePriority? priority) {
    final isSelected = _selectedPriorityFilter == priority;
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
        onSelected: (_) => setState(() => _selectedPriorityFilter = priority),
      ),
    );
  }

  // ==========================================
  // TECHNICIAN ISSUE LIST TAB
  // ==========================================

  Widget _buildTechnicianIssueList(
    List<IssueModel> list, {
    required String emptyMessage,
    required bool isLoading,
    required bool hasError,
  }) {
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

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(technicianIssuesProvider);
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: (isLoading || hasError || filtered.isEmpty) ? 1 : filtered.length,
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
                      'Failed to load technician queue',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(technicianIssuesProvider),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (filtered.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Center(
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
              ),
            );
          }

          final issue = filtered[index];

          return Container(
            key: ValueKey(issue.id),
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
                    // Header Row: Ticket ID, Priority, Status
                    Row(
                      children: [
                        Text(
                          issue.id.length > 8 ? '#${issue.id.substring(0, 8)}' : issue.id,
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
                    const SizedBox(height: 8),

                    // Issue Title
                    Text(
                      issue.title.isNotEmpty ? issue.title : (issue.description.isNotEmpty ? issue.description : 'Maintenance Issue'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Equipment Info & Zone
                    Row(
                      children: [
                        Icon(
                          HardwareIconHelper.getIcon(issue.categoryName),
                          size: 14,
                          color: AppColors.icon,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${issue.deviceName} • ${issue.zoneName} ${issue.categoryName.isNotEmpty ? "• ${issue.categoryName}" : ""}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (issue.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        issue.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 10),

                    // Technician Workflow Quick Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${issue.history.length} timeline events',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Row(
                          children: [
                            if (issue.status == IssueStatus.assigned) ...[
                              ElevatedButton.icon(
                                onPressed: () => _openUpdateStatusSheet(issue, IssueStatus.inProgress),
                                icon: const Icon(Icons.play_arrow_rounded, size: 15),
                                label: const Text('Start Work', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.warning,
                                  foregroundColor: AppColors.textWhite,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ] else if (issue.status == IssueStatus.inProgress) ...[
                              OutlinedButton(
                                onPressed: () => _openUpdateStatusSheet(issue, IssueStatus.onHold),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: AppColors.purpleText,
                                  side: const BorderSide(color: AppColors.border),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Hold', style: TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => _openUpdateStatusSheet(issue, IssueStatus.resolved),
                                icon: const Icon(Icons.check, size: 15),
                                label: const Text('Resolve', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: AppColors.textWhite,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ] else if (issue.status == IssueStatus.onHold) ...[
                              ElevatedButton.icon(
                                onPressed: () => _openUpdateStatusSheet(issue, IssueStatus.inProgress),
                                icon: const Icon(Icons.play_arrow_rounded, size: 15),
                                label: const Text('Resume', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.textWhite,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ] else ...[
                              OutlinedButton.icon(
                                onPressed: () => _openUpdateStatusSheet(issue),
                                icon: const Icon(Icons.history, size: 14),
                                label: const Text('Timeline', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: AppColors.textSecondary,
                                  side: const BorderSide(color: AppColors.border),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      ),
    );
  }
}
