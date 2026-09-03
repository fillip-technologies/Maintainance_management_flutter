import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../data/models/issue_model.dart';
import 'technician_issue_card.dart';

class TechnicianIssueList extends StatelessWidget {
  final List<IssueModel> issues;
  final String emptyMessage;
  final bool isLoading;
  final bool hasError;
  final String searchQuery;
  final IssuePriority? selectedPriority;
  final Future<void> Function() onRefresh;
  final void Function(IssueModel issue) onOpenDetail;
  final void Function(IssueModel issue, [IssueStatus? targetStatus]) onOpenUpdateStatus;

  const TechnicianIssueList({
    super.key,
    required this.issues,
    required this.emptyMessage,
    required this.isLoading,
    required this.hasError,
    required this.searchQuery,
    required this.selectedPriority,
    required this.onRefresh,
    required this.onOpenDetail,
    required this.onOpenUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    var filtered = issues;

    if (selectedPriority != null) {
      filtered = filtered.where((i) => i.priority == selectedPriority).toList();
    }

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered.where((i) {
        return i.title.toLowerCase().contains(q) ||
            i.deviceName.toLowerCase().contains(q) ||
            i.zoneName.toLowerCase().contains(q) ||
            i.id.toLowerCase().contains(q);
      }).toList();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
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
                      onPressed: onRefresh,
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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final issue = filtered[index];
          return TechnicianIssueCard(
            issue: issue,
            onTap: () => onOpenDetail(issue),
            onUpdateStatus: (newStatus) => onOpenUpdateStatus(issue, newStatus),
            onOpenTimeline: () => onOpenUpdateStatus(issue),
          );
        },
      ),
    );
  }
}
