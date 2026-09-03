import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/issue_model.dart';
import '../controller/issue_providers.dart';

/// A sleek chronological vertical node-stepper that displays the full audit history
/// of an issue from creation through work progress to resolution.
class IssueTimelineView extends ConsumerWidget {
  final String issueId;
  final List<IssueStatusHistoryModel>? initialHistory;

  const IssueTimelineView({
    super.key,
    required this.issueId,
    this.initialHistory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(issueHistoryProvider(issueId));

    return historyAsync.when(
      data: (historyList) {
        final items = historyList.isNotEmpty ? historyList : (initialHistory ?? []);

        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.cardAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: AppColors.iconLight),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No transitions logged yet. Issue is in initial state.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final isLast = index == items.length - 1;
            final item = entry.value;

            return _buildTimelineNode(
              item: item,
              isLast: isLast,
              index: index,
            );
          }).toList(),
        );
      },
      loading: () => Column(
        children: [
          _buildShimmerItem(),
          const SizedBox(height: 8),
          _buildShimmerItem(),
        ],
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Failed to load timeline: $e',
                style: const TextStyle(fontSize: 12, color: AppColors.errorText),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 16, color: AppColors.error),
              onPressed: () => ref.invalidate(issueHistoryProvider(issueId)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineNode({
    required IssueStatusHistoryModel item,
    required bool isLast,
    required int index,
  }) {
    final (nodeColor, nodeIcon) = switch (item.toStatus) {
      IssueStatus.open => (AppColors.info, Icons.radio_button_checked),
      IssueStatus.assigned => (AppColors.primary, Icons.assignment_ind_outlined),
      IssueStatus.inProgress => (AppColors.warning, Icons.play_arrow_rounded),
      IssueStatus.onHold => (AppColors.purple, Icons.pause_circle_outline),
      IssueStatus.resolved => (AppColors.success, Icons.check_circle_outline),
      IssueStatus.closed => (AppColors.textSecondary, Icons.lock_outline),
      IssueStatus.reopened => (AppColors.error, Icons.replay_rounded),
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Node & Connecting Line
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: nodeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: nodeColor, width: 2),
                ),
                child: Icon(nodeIcon, size: 12, color: nodeColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Right Content Box
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 4 : 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Status Badge & Timestamp
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusBadge.issue(item.toStatus),
                        Text(
                          _formatTimestamp(item.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Author line
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          item.changedByUserName.isNotEmpty
                              ? item.changedByUserName
                              : 'System Event',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (item.fromStatus != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '(${item.fromStatus!.label} → ${item.toStatus.label})',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Work Notes / Transition Comment
                    if (item.comment != null && item.comment!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.cardAlt,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '"${item.comment!.trim()}"',
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerItem() {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day}/${dt.month} at $hour:$min';
    }
  }
}
