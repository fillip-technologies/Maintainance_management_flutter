import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/colors.dart';
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
  String _searchQuery = '';
  IssuePriority? _selectedPriorityFilter;

  // Local Static / Demo Data for Technician Flow
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
      description:
          'Heavy fogging on interior lens glass after monsoon rain. Unable to view water pool clearly.',
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
      createdByUserName: 'Sarah Connor (Staff)',
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
        IssueStatusHistoryModel(
          id: 'hist-05',
          issueId: 'ISSUE-1002',
          fromStatus: IssueStatus.open,
          toStatus: IssueStatus.assigned,
          changedByUserId: 'usr-admin-004',
          changedByUserName: 'Director Vance',
          comment: 'Assigned to Marcus Vance',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ],
    ),
    IssueModel(
      id: 'ISSUE-1003',
      title: 'PoE Switch Intermittent Dropout',
      description:
          'Camera video feed glitches every 10-15 minutes due to power fluctuation on switch port 3.',
      deviceId: 'dev-cam-08',
      deviceName: 'Tropical Dome Top Deck',
      zoneId: 'zone-aviary-06',
      zoneName: 'Bird Sanctuary (A3)',
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
          comment:
              'Tested Ethernet cabling; cable is fine, switch port is failing',
          createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        ),
        IssueStatusHistoryModel(
          id: 'hist-08',
          issueId: 'ISSUE-1003',
          fromStatus: IssueStatus.inProgress,
          toStatus: IssueStatus.onHold,
          changedByUserId: 'usr-tech-003',
          changedByUserName: 'Marcus Vance',
          comment:
              'Waiting for replacement 8-port Gigabit PoE switch from central store',
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
          fromStatus: IssueStatus.open,
          toStatus: IssueStatus.inProgress,
          changedByUserId: 'usr-tech-003',
          changedByUserName: 'Marcus Vance',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        IssueStatusHistoryModel(
          id: 'hist-11',
          issueId: 'ISSUE-1000',
          fromStatus: IssueStatus.inProgress,
          toStatus: IssueStatus.resolved,
          changedByUserId: 'usr-tech-003',
          changedByUserName: 'Marcus Vance',
          comment:
              'Replaced IR ring LED board and tested in darkness simulator',
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
    super.dispose();
  }

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

            final updatedHistory = List<IssueStatusHistoryModel>.from(
              _issues[index].history,
            )..add(historyItem);

            _issues[index] = _issues[index].copyWith(
              status: newStatus,
              updatedAt: DateTime.now(),
              imagePath: resolutionPhoto?.path ?? _issues[index].imagePath,
              history: updatedHistory,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: newStatus == IssueStatus.resolved
                ? AppColors.successText
                : newStatus == IssueStatus.onHold
                ? AppColors.purpleText
                : AppColors.primary,
            content: Text(
              'Ticket ${issue.id} moved to ${newStatus.label}',
              style: const TextStyle(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeIssues = _issues
        .where(
          (i) =>
              i.status == IssueStatus.assigned ||
              i.status == IssueStatus.inProgress,
        )
        .toList();
    final onHoldIssues = _issues
        .where((i) => i.status == IssueStatus.onHold)
        .toList();
    final resolvedIssues = _issues
        .where(
          (i) =>
              i.status == IssueStatus.resolved ||
              i.status == IssueStatus.closed,
        )
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
              child: const Icon(
                Icons.engineering_outlined,
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
                    ref.watch(authStateProvider).value?.name ?? 'Field Technician',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Row(
                    children: [
                      Icon(
                        Icons.build_circle_outlined,
                        size: 12,
                        color: AppColors.icon,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Hardware Technician • All Assigned Zones',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
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
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          tabs: [
            Tab(
              icon: const Icon(Icons.assignment_outlined, size: 18),
              text: 'Active Queue (${activeIssues.length})',
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
      body: Column(
        children: [
          // KPI Metric Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surface,
            child: Row(
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
                  value:
                      '${_issues.where((i) => i.status == IssueStatus.inProgress).length}',
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
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // Search and Priority Filter
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
                    hintText: 'Search tickets, devices, zones...',
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
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPriorityFilterChip('All Priorities', null),
                      _buildPriorityFilterChip(
                        'Critical',
                        IssuePriority.critical,
                      ),
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

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Active Queue
                _buildIssueList(
                  activeIssues,
                  emptyMessage: 'No active tickets in queue',
                ),

                // TAB 2: On Hold
                _buildIssueList(
                  onHoldIssues,
                  emptyMessage: 'No tickets currently on hold',
                ),

                // TAB 3: Resolved
                _buildIssueList(
                  resolvedIssues,
                  emptyMessage: 'No resolved tickets yet',
                ),
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

  Widget _buildIssueList(
    List<IssueModel> list, {
    required String emptyMessage,
  }) {
    var filtered = list;
    if (_selectedPriorityFilter != null) {
      filtered = filtered
          .where((i) => i.priority == _selectedPriorityFilter)
          .toList();
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
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Check other tabs or search criteria',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 24),
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
                  // Top Row: ID, Priority, Status Badge
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

                  const SizedBox(height: 8),

                  // Issue Title
                  Text(
                    issue.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Device & Location
                  Row(
                    children: [
                      const Icon(
                        Icons.videocam_outlined,
                        size: 14,
                        color: AppColors.icon,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${issue.deviceName} • ${issue.zoneName}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Description snippet
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

                  // Attached photo indicator if present
                  if (issue.imagePath != null &&
                      File(issue.imagePath!).existsSync()) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.photo_camera,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Photo Attached',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 10),

                  // Technician Action Bar
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
                              onPressed: () => _openUpdateStatusSheet(
                                issue,
                                IssueStatus.inProgress,
                              ),
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                size: 16,
                              ),
                              label: const Text(
                                'Start Work',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.textWhite,
                                minimumSize: const Size(100, 36),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                            ),
                          ] else if (issue.status ==
                              IssueStatus.inProgress) ...[
                            OutlinedButton(
                              onPressed: () => _openUpdateStatusSheet(
                                issue,
                                IssueStatus.onHold,
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.purpleText,
                                side: const BorderSide(color: AppColors.purple),
                                minimumSize: const Size(80, 36),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                              child: const Text(
                                'Hold',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _openUpdateStatusSheet(
                                issue,
                                IssueStatus.resolved,
                              ),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text(
                                'Resolve',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.successText,
                                foregroundColor: AppColors.textWhite,
                                minimumSize: const Size(95, 36),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                            ),
                          ] else if (issue.status == IssueStatus.onHold) ...[
                            ElevatedButton.icon(
                              onPressed: () => _openUpdateStatusSheet(
                                issue,
                                IssueStatus.inProgress,
                              ),
                              icon: const Icon(Icons.replay, size: 16),
                              label: const Text(
                                'Resume Work',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.textWhite,
                                minimumSize: const Size(110, 36),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                            ),
                          ] else ...[
                            OutlinedButton.icon(
                              onPressed: () =>
                                  IssueDetailSheet.show(context, issue),
                              icon: const Icon(
                                Icons.visibility_outlined,
                                size: 16,
                              ),
                              label: const Text(
                                'View History',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                side: const BorderSide(color: AppColors.border),
                                minimumSize: const Size(100, 36),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
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
