import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../issues/issues.dart';

/// Read-only ticket tracker for staff: filter by stage and tap to open the
/// detail sheet. Staff no longer verify/close tickets — a technician's
/// `resolved` is final and the backend auto-closes it after a few days.
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
  int _filterIndex = 0; // 0: Fixed (resolved), 1: In Progress, 2: Done (closed)

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allIssues = widget.issues;

    final fixed = allIssues.where((i) => i.status == IssueStatus.resolved).toList();
    final inProgress = allIssues
        .where((i) => i.status != IssueStatus.resolved && i.status != IssueStatus.closed)
        .toList();
    final done = allIssues.where((i) => i.status == IssueStatus.closed).toList();

    final displayedIssues = switch (_filterIndex) {
      0 => fixed,
      1 => inProgress,
      _ => done,
    };

    return Column(
      children: [
        // Segmented Issue Filter Bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surface,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppFilterChip(
                  label: l10n?.staffFilterNeedsCheck(fixed.length) ?? 'Fixed (${fixed.length})',
                  isSelected: _filterIndex == 0,
                  activeColor: AppColors.success,
                  badgeColor: fixed.isNotEmpty ? AppColors.successText : null,
                  onTap: () => setState(() => _filterIndex = 0),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: l10n?.staffFilterInProgress(inProgress.length) ??
                      'In Progress (${inProgress.length})',
                  isSelected: _filterIndex == 1,
                  activeColor: AppColors.warning,
                  badgeColor: inProgress.isNotEmpty ? AppColors.warningText : null,
                  onTap: () => setState(() => _filterIndex = 1),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: l10n?.staffFilterDoneTickets(done.length) ?? 'Done (${done.length})',
                  isSelected: _filterIndex == 2,
                  onTap: () => setState(() => _filterIndex = 2),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),

        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: widget.onRefresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 84),
              itemCount: (widget.isLoading || widget.hasError || displayedIssues.isEmpty)
                  ? 1
                  : displayedIssues.length,
              itemBuilder: (context, index) {
                if (widget.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  );
                }
                if (widget.hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: ErrorStateView(
                      title: l10n?.staffTicketsLoadFailed ?? "Couldn't load tickets",
                      subtitle: l10n?.staffCheckConnectionRetry ??
                          'Check your connection and tap to retry',
                      onRetry: widget.onRefresh,
                    ),
                  );
                }
                if (displayedIssues.isEmpty) {
                  final (icon, title) = switch (_filterIndex) {
                    0 => (Icons.task_alt_rounded, l10n?.staffNoTicketsToCheck ?? 'No recently fixed tickets'),
                    1 => (Icons.engineering_outlined, l10n?.staffNoTicketsInProgress ?? 'No tickets being worked on'),
                    _ => (Icons.history_toggle_off_rounded, l10n?.staffNoDoneTickets ?? 'No finished tickets yet'),
                  };
                  return Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: EmptyStateView(
                      icon: icon,
                      iconColor: _filterIndex == 0 ? AppColors.successText : AppColors.icon,
                      iconBackgroundColor:
                          _filterIndex == 0 ? AppColors.successLight : AppColors.cardAlt,
                      title: title,
                      subtitle: l10n?.staffPullToRefresh ?? 'Pull down to refresh',
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
