import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../issues/issues.dart';

class StaffIssuesTrackerTab extends ConsumerStatefulWidget {
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
  ConsumerState<StaffIssuesTrackerTab> createState() => _StaffIssuesTrackerTabState();
}

class _StaffIssuesTrackerTabState extends ConsumerState<StaffIssuesTrackerTab> {
  int _filterIndex = 0; // 0: Open, 1: Closed, 2: All
  bool _isSelectionMode = false;
  final Set<String> _selectedIssueIds = {};
  IssueStatus _bulkStatus = IssueStatus.resolved;
  bool _isApplying = false;

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIssueIds.contains(id)) {
        _selectedIssueIds.remove(id);
        if (_selectedIssueIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIssueIds.add(id);
      }
    });
  }

  void _toggleSelectAll(List<IssueModel> displayedIssues) {
    setState(() {
      final allSelected = displayedIssues.isNotEmpty && displayedIssues.every((i) => _selectedIssueIds.contains(i.id));
      if (allSelected) {
        _selectedIssueIds.clear();
        _isSelectionMode = false;
      } else {
        _isSelectionMode = true;
        _selectedIssueIds.addAll(displayedIssues.map((i) => i.id));
      }
    });
  }

  Future<void> _handleBulkApply() async {
    if (_selectedIssueIds.isEmpty || _isApplying) return;
    final l10n = AppLocalizations.of(context);

    setState(() => _isApplying = true);
    try {
      final result = await ref.read(issueActionControllerProvider.notifier).bulkUpdateStatus(
            issueIds: _selectedIssueIds.toList(),
            status: _bulkStatus,
          );

      if (result != null) {
        final count = result.updated.length;
        final errorCount = result.errors.length;
        if (mounted) {
          if (errorCount == 0) {
            AppSnackbar.success(l10n?.bulkDefectSuccessMsg(count) ?? '$count issues updated successfully');
          } else {
            AppSnackbar.warning('$count updated, $errorCount skipped');
          }
          setState(() {
            _selectedIssueIds.clear();
            _isSelectionMode = false;
          });
          widget.onRefresh();
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error('Failed to update: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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

    final allSelected = displayedIssues.isNotEmpty && displayedIssues.every((i) => _selectedIssueIds.contains(i.id));

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
              const Spacer(),
              if (displayedIssues.isNotEmpty) ...[
                if (_isSelectionMode) ...[
                  InkWell(
                    onTap: () => _toggleSelectAll(displayedIssues),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(
                        allSelected ? (l10n?.clearSelection ?? 'Clear') : (l10n?.selectAll ?? 'Select All'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: () => setState(() {
                      _isSelectionMode = false;
                      _selectedIssueIds.clear();
                    }),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n?.doneSelecting ?? 'Done',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                  ),
                ] else ...[
                  InkWell(
                    onTap: () => setState(() => _isSelectionMode = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.checklist_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            l10n?.selectMode ?? 'Select',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),

        // Bulk Action Bar (matches TicketList.jsx in web frontend)
        if (_selectedIssueIds.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.primaryBg.withValues(alpha: 0.5),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '${_selectedIssueIds.length} Selected',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const Spacer(),
                DropdownButton<IssueStatus>(
                  value: _bulkStatus,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  items: const [
                    DropdownMenuItem(
                      value: IssueStatus.resolved,
                      child: Text('Resolved', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.successText)),
                    ),
                    DropdownMenuItem(
                      value: IssueStatus.inProgress,
                      child: Text('In Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warningText)),
                    ),
                    DropdownMenuItem(
                      value: IssueStatus.onHold,
                      child: Text('On Hold', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.purpleText)),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _bulkStatus = val);
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isApplying ? null : _handleBulkApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isApplying
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n?.applyToSelected ?? 'Apply', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppColors.icon),
                  onPressed: () => setState(() {
                    _selectedIssueIds.clear();
                    _isSelectionMode = false;
                  }),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
        ],

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
                final isSelected = _selectedIssueIds.contains(issue.id);

                return IssueCard(
                  issue: issue,
                  isSelectable: _isSelectionMode,
                  isSelected: isSelected,
                  onSelect: (_) => _toggleSelect(issue.id),
                  onTap: _isSelectionMode
                      ? () => _toggleSelect(issue.id)
                      : () => widget.onOpenIssueDetail(issue),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

