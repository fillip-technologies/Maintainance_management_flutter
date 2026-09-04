import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../issues/issues.dart';

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
              AppFilterChip(
                label: 'Open (${openIssues.length})',
                isSelected: _filterIndex == 0,
                badgeColor: openIssues.isNotEmpty ? AppColors.warningText : null,
                onTap: () => setState(() => _filterIndex = 0),
              ),
              const SizedBox(width: 8),
              AppFilterChip(
                label: 'Closed (${closedIssues.length})',
                isSelected: _filterIndex == 1,
                badgeColor: closedIssues.isNotEmpty ? AppColors.successText : null,
                onTap: () => setState(() => _filterIndex = 1),
              ),
              const SizedBox(width: 8),
              AppFilterChip(
                label: 'All (${allIssues.length})',
                isSelected: _filterIndex == 2,
                onTap: () => setState(() => _filterIndex = 2),
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
                    padding: const EdgeInsets.only(top: 40),
                    child: ErrorStateView(
                      title: 'Failed to load maintenance tickets',
                      subtitle: 'Please check your connection and try again',
                      onRetry: widget.onRefresh,
                    ),
                  );
                }
                if (displayedIssues.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: EmptyStateView(
                      icon: _filterIndex == 0
                          ? Icons.task_alt_rounded
                          : (_filterIndex == 1
                              ? Icons.history_toggle_off_rounded
                              : Icons.confirmation_number_outlined),
                      iconColor: _filterIndex == 0 ? AppColors.successText : AppColors.icon,
                      iconBackgroundColor: _filterIndex == 0 ? AppColors.successLight : AppColors.cardAlt,
                      title: _filterIndex == 0
                          ? 'No open maintenance tickets in your zone'
                          : (_filterIndex == 1
                              ? 'No closed maintenance tickets yet'
                              : 'No maintenance issues recorded in your zone'),
                      subtitle: _filterIndex == 0
                          ? 'All reported equipment issues have been resolved'
                          : 'Pull down to refresh tickets',
                    ),
                  );
                }

                final issue = displayedIssues[index];
                return IssueCard(
                  issue: issue,
                  onTap: () => widget.onOpenIssueDetail(issue),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
