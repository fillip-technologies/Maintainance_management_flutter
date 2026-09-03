import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/hardware_icon_helper.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../data/models/issue_model.dart';

class StaffIssuesTrackerTab extends StatefulWidget {
  final List<IssueModel> issues;
  final bool isLoading;
  final bool hasError;
  final Future<void> Function() onRefresh;
  final void Function(IssueModel issue) onOpenIssueDetail;

  const StaffIssuesTrackerTab({
    super.key,
    required this.issues,
    required this.isLoading,
    required this.hasError,
    required this.onRefresh,
    required this.onOpenIssueDetail,
  });

  @override
  State<StaffIssuesTrackerTab> createState() => _StaffIssuesTrackerTabState();
}

class _StaffIssuesTrackerTabState extends State<StaffIssuesTrackerTab> {
  int _filterIndex = 0; // 0: Open, 1: Closed, 2: All

  @override
  Widget build(BuildContext context) {
    final allIssues = widget.issues;
    final openIssues = allIssues
        .where((i) => i.status != IssueStatus.closed && i.status != IssueStatus.resolved)
        .toList();
    final closedIssues = allIssues
        .where((i) => i.status == IssueStatus.closed || i.status == IssueStatus.resolved)
        .toList();

    final displayedIssues = _filterIndex == 0
        ? openIssues
        : (_filterIndex == 1 ? closedIssues : allIssues);

    return Column(
      children: [
        // Segmented Issue Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surface,
          child: Row(
            children: [
              _buildFilterChip(
                label: 'Open (${openIssues.length})',
                index: 0,
                badgeColor: openIssues.isNotEmpty ? AppColors.warningText : null,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Closed (${closedIssues.length})',
                index: 1,
                badgeColor: closedIssues.isNotEmpty ? AppColors.successText : null,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
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
            onRefresh: widget.onRefresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: (widget.isLoading || widget.hasError || displayedIssues.isEmpty)
                  ? 1
                  : displayedIssues.length,
              itemBuilder: (context, index) {
                if (widget.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }
                if (widget.hasError) {
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
                            onPressed: widget.onRefresh,
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
                            _filterIndex == 0
                                ? Icons.task_alt_rounded
                                : (_filterIndex == 1
                                    ? Icons.history_toggle_off_rounded
                                    : Icons.confirmation_number_outlined),
                            size: 48,
                            color: AppColors.iconLight,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _filterIndex == 0
                                ? 'No open maintenance tickets in your zone'
                                : (_filterIndex == 1
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
                            _filterIndex == 0
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
                    onTap: () => widget.onOpenIssueDetail(issue),
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

  Widget _buildFilterChip({
    required String label,
    required int index,
    Color? badgeColor,
  }) {
    final isSelected = _filterIndex == index;
    return InkWell(
      onTap: () => setState(() => _filterIndex = index),
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
