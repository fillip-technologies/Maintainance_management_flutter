import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../issues/issues.dart';
import '../../realtime/realtime.dart';
import '../models/technician_queue_state.dart';
import '../models/technician_zone_tree_state.dart';
import '../viewmodels/technician_action_viewmodel.dart';
import '../viewmodels/technician_queue_viewmodel.dart';
import '../viewmodels/technician_view_mode_provider.dart';
import 'widgets/widgets.dart';

class TechnicianHomePage extends ConsumerStatefulWidget {
  const TechnicianHomePage({super.key});

  @override
  ConsumerState<TechnicianHomePage> createState() => _TechnicianHomePageState();
}

class _TechnicianHomePageState extends ConsumerState<TechnicianHomePage> {
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
      final allSelected = displayedIssues.isNotEmpty &&
          displayedIssues.every((i) => _selectedIssueIds.contains(i.id));
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
      final result = await ref.read(technicianActionViewModelProvider).bulkUpdateStatus(
            issueIds: _selectedIssueIds.toList(),
            toStatus: _bulkStatus,
          );

      final count = result.updated.length;
      final errorCount = result.errors.length;
      if (mounted) {
        if (errorCount == 0) {
          final msg = l10n?.bulkStatusSuccessMsg(count, _bulkStatus.label) ??
              '$count tickets updated to ${_bulkStatus.label}';
          AppSnackbar.success(msg);
        } else {
          AppSnackbar.warning('$count updated, $errorCount skipped');
        }
        setState(() {
          _selectedIssueIds.clear();
          _isSelectionMode = false;
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error('Failed to update tickets: $e');
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  void _openUpdateStatusSheet(IssueModel issue, [IssueStatus? targetStatus]) {
    final actionNotifier = ref.read(technicianActionViewModelProvider);
    final issueId = issue.id;

    UpdateStatusSheet.show(
      context,
      issue: issue,
      initialTargetStatus: targetStatus,
      onStatusUpdated: (newStatus, comment, resolutionPhoto) async {
        try {
          await actionNotifier.updateStatus(
            issueId: issueId,
            toStatus: newStatus,
            notes: comment,
            attachments: resolutionPhoto != null ? [resolutionPhoto] : null,
          );

          final ticketIdStr = issueId.length > 8
              ? '#${issueId.substring(0, 8)}'
              : issueId;
          final msg = 'Ticket $ticketIdStr moved to ${newStatus.label}';
          if (newStatus == IssueStatus.resolved) {
            AppSnackbar.success(msg);
          } else if (newStatus == IssueStatus.onHold) {
            AppSnackbar.warning(msg);
          } else {
            AppSnackbar.info(msg);
          }
        } catch (e) {
          AppSnackbar.error('Failed to update status: $e');
          rethrow;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Realtime: Listen for incoming new tickets and show toast + refresh
    ref.listen<AsyncValue<IssueModel>>(socketIssueCreatedStreamProvider, (
      previous,
      next,
    ) {
      final issue = next.value;
      if (issue == null) return;

      ref.read(technicianActionViewModelProvider).refreshQueue();
      RealtimeToastHelper.showNewIssueToast(
        context,
        issue: issue,
        onTap: () => IssueDetailSheet.show(context, issue),
      );
    });

    // Realtime: Listen for ticket status updates (e.g. claimed or resolved)
    ref.listen<AsyncValue<IssueModel>>(socketIssueUpdatedStreamProvider, (
      previous,
      next,
    ) {
      final issue = next.value;
      if (issue == null) return;

      ref.read(technicianActionViewModelProvider).refreshQueue();
      ref.invalidate(issueDetailProvider(issue.id));
      ref.invalidate(issueHistoryProvider(issue.id));
    });

    // Switching tabs abandons any in-progress selection so the bulk bar can
    // never act on tickets that are no longer visible.
    ref.listen(technicianQueueFilterProvider.select((f) => f.tabIndex), (_, _) {
      if (_selectedIssueIds.isEmpty) return;
      setState(() {
        _selectedIssueIds.clear();
        _isSelectionMode = false;
      });
    });

    // Drop selected ids whose tickets disappeared (e.g. resolved via realtime).
    ref.listen(technicianQueueStateProvider, (_, next) {
      if (_selectedIssueIds.isEmpty) return;
      final liveIds = {
        for (final i in [
          ...next.activeIssues,
          ...next.onHoldIssues,
          ...next.resolvedIssues,
        ])
          i.id,
      };
      if (_selectedIssueIds.every(liveIds.contains)) return;
      setState(() {
        _selectedIssueIds.retainWhere(liveIds.contains);
        if (_selectedIssueIds.isEmpty) _isSelectionMode = false;
      });
    });

    final l10n = AppLocalizations.of(context)!;
    final queueState = ref.watch(technicianQueueStateProvider);
    final filterNotifier = ref.read(technicianQueueFilterProvider.notifier);
    final activeMode = ref.watch(technicianViewModeProvider);
    final viewModeNotifier = ref.read(technicianViewModeProvider.notifier);

    final currentList = switch (queueState.filter.tabIndex) {
      0 => queueState.activeIssues,
      1 => queueState.onHoldIssues,
      2 => queueState.resolvedIssues,
      _ => queueState.activeIssues,
    };

    return Column(
      children: [
        // 3-Mode View Switcher (Zone Map vs Zone Status vs My Tickets)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.cardAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ModeSwitchButton(
                  icon: Icons.account_tree_rounded,
                  label: l10n.techViewSpatial,
                  isActive: activeMode == TechnicianViewMode.spatialExplorer,
                  onTap: () => viewModeNotifier.setMode(TechnicianViewMode.spatialExplorer),
                ),
              ),
              Expanded(
                child: _ModeSwitchButton(
                  icon: Icons.grid_view_rounded,
                  label: l10n.techViewStatus,
                  isActive: activeMode == TechnicianViewMode.zoneStatusTable,
                  onTap: () => viewModeNotifier.setMode(TechnicianViewMode.zoneStatusTable),
                ),
              ),
              Expanded(
                child: _ModeSwitchButton(
                  icon: Icons.list_alt_rounded,
                  label: l10n.techViewQueue,
                  isActive: activeMode == TechnicianViewMode.workQueue,
                  onTap: () => viewModeNotifier.setMode(TechnicianViewMode.workQueue),
                ),
              ),
            ],
          ),
        ),

        if (activeMode == TechnicianViewMode.spatialExplorer)
          const Expanded(child: ZoneTreeExplorerView())
        else if (activeMode == TechnicianViewMode.zoneStatusTable)
          const Expanded(child: TechnicianZoneStatusView())
        else
          Expanded(
            child: Column(
              children: [
                // Merged Mobile-Friendly Search & Status/Priority Filter Bar
                TechnicianSearchFilterBar(
                  selectedTabIndex: queueState.filter.tabIndex,
                  stats: queueState.kpiStats,
                  onTabSelected: filterNotifier.setTabIndex,
                  searchQuery: queueState.filter.searchQuery,
                  selectedPriority: queueState.filter.priority,
                  onSearchChanged: filterNotifier.setSearchQuery,
                  onPriorityChanged: filterNotifier.setPriority,
                ),

                Divider(height: 1, color: AppColors.divider),

        // Selection mode toggle & select-all row
        if (currentList.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: AppColors.cardAlt,
            child: Row(
              children: [
                if (_isSelectionMode) ...[
                  InkWell(
                    onTap: () => _toggleSelectAll(currentList),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(
                            currentList.isNotEmpty &&
                                    currentList.every((i) => _selectedIssueIds.contains(i.id))
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            currentList.isNotEmpty &&
                                    currentList.every((i) => _selectedIssueIds.contains(i.id))
                                ? l10n.clearSelection
                                : l10n.selectAll,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = !_isSelectionMode;
                      if (!_isSelectionMode) _selectedIssueIds.clear();
                    });
                  },
                  icon: Icon(
                    _isSelectionMode ? Icons.close : Icons.checklist_rtl_rounded,
                    size: 16,
                  ),
                  label: Text(
                    _isSelectionMode ? l10n.doneSelecting : l10n.selectMode,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: _isSelectionMode ? AppColors.error : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.divider),
        ],

        // Bulk Action Bar (matches TicketList.jsx in web frontend)
        if (_selectedIssueIds.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.primaryBg.withValues(alpha: 0.5),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '${_selectedIssueIds.length} Selected',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                DropdownButton<IssueStatus>(
                  value: _bulkStatus,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  items: [
                    DropdownMenuItem(
                      value: IssueStatus.resolved,
                      child: Text(
                        'Resolved',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.successText,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: IssueStatus.inProgress,
                      child: Text(
                        'In Progress',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warningText,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: IssueStatus.onHold,
                      child: Text(
                        'On Hold',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.purpleText,
                        ),
                      ),
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
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          l10n.applyToSelected,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: AppColors.icon),
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
          Divider(height: 1, color: AppColors.divider),
        ],

        // Active Tab View Content
        Expanded(
          child: _buildCurrentTab(
            queueState: queueState,
            tabIndex: queueState.filter.tabIndex,
          ),
        ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentTab({
    required TechnicianQueueState queueState,
    required int tabIndex,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final (list, emptyMessage) = switch (tabIndex) {
      0 => (queueState.activeIssues, l10n.techNoActiveTickets),
      1 => (queueState.onHoldIssues, l10n.techNoOnHoldTickets),
      2 => (queueState.resolvedIssues, l10n.techNoResolvedTickets),
      _ => (queueState.activeIssues, l10n.techNoActiveTickets),
    };

    return TechnicianIssueList(
      issues: list,
      emptyMessage: emptyMessage,
      isLoading: queueState.isLoading,
      hasError: queueState.errorMessage != null,
      isSelectionMode: _isSelectionMode,
      selectedIssueIds: _selectedIssueIds,
      onToggleSelect: _toggleSelect,
      onRefresh: () async {
        ref.read(technicianActionViewModelProvider).refreshQueue();
      },
      onOpenDetail: (issue) => IssueDetailSheet.show(context, issue),
      onOpenUpdateStatus: _openUpdateStatusSheet,
    );
  }
}

class _ModeSwitchButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeSwitchButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surface : AppColors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

