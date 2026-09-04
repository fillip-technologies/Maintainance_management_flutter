import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
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
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (issues.isEmpty) {
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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pull down to refresh ticket feed',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
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
