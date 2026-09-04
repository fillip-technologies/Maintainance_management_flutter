import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../issues/issues.dart';
import 'technician_issue_card.dart';

class TechnicianIssueList extends StatelessWidget {
  final List<IssueModel> issues;
  final String emptyMessage;
  final bool isLoading;
  final bool hasError;
  final Future<void> Function() onRefresh;
  final void Function(IssueModel issue) onOpenDetail;
  final void Function(IssueModel issue, [IssueStatus? targetStatus]) onOpenUpdateStatus;

  const TechnicianIssueList({
    super.key,
    required this.issues,
    required this.emptyMessage,
    required this.isLoading,
    required this.hasError,
    required this.onRefresh,
    required this.onOpenDetail,
    required this.onOpenUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: (isLoading || hasError || issues.isEmpty) ? 1 : issues.length,
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
              padding: const EdgeInsets.only(top: 40),
              child: ErrorStateView(
                title: 'Failed to load technician queue',
                subtitle: 'Please check your network and try again',
                onRetry: onRefresh,
              ),
            );
          }

          if (issues.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 40),
              child: EmptyStateView(
                icon: Icons.task_alt,
                iconColor: AppColors.primary,
                iconBackgroundColor: AppColors.primaryBg,
                title: emptyMessage,
                subtitle: 'Pull down to refresh ticket feed',
              ),
            );
          }

          final issue = issues[index];
          return TechnicianIssueCard(
            key: ValueKey(issue.id),
            issue: issue,
            onTap: () => onOpenDetail(issue),
            onOpenTimeline: () => onOpenDetail(issue),
            onUpdateStatus: (newStatus) => onOpenUpdateStatus(issue, newStatus),
          );
        },
      ),
    );
  }
}
