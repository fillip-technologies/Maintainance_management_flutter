import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../issues/issues.dart';
import '../../location/location_helper.dart';
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
      final allSelected =
          displayedIssues.isNotEmpty &&
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
      double? lat;
      double? lng;
      if (_bulkStatus == IssueStatus.resolved) {
        final locRes = await LocationHelper().getLocation();
        if (!locRes.isSuccess) {
          if (mounted) {
            AppSnackbar.error(
              locRes.errorMessage ??
                  'GPS coordinates are required to resolve tickets. Please turn on GPS.',
            );
            if (locRes.error == LocationErrorType.serviceDisabled) {
              await LocationHelper().openLocationSettings();
            } else if (locRes.error == LocationErrorType.permissionDeniedForever) {
              await LocationHelper().openAppSettings();
            }
          }
          return;
        }
        lat = locRes.latitude;
        lng = locRes.longitude;
      }

      final result = await ref
          .read(technicianActionViewModelProvider)
          .bulkUpdateStatus(
            issueIds: _selectedIssueIds.toList(),
            toStatus: _bulkStatus,
            latitude: lat,
            longitude: lng,
          );

      final count = result.updated.length;
      final errorCount = result.errors.length;
      if (mounted) {
        if (errorCount == 0) {
          final msg =
              l10n?.bulkStatusSuccessMsg(count, _bulkStatus.label) ??
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
      onRequestReplacement: () => handleReplacementAction(context, ref, issue),
      onStatusUpdated: (newStatus, comment, resolutionPhoto, [latitude, longitude]) async {
        try {
          await actionNotifier.updateStatus(
            issueId: issueId,
            toStatus: newStatus,
            notes: comment,
            attachments: resolutionPhoto != null ? [resolutionPhoto] : null,
            latitude: latitude,
            longitude: longitude,
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

  bool _allSelected(List<IssueModel> list) =>
      list.isNotEmpty && list.every((i) => _selectedIssueIds.contains(i.id));

  ButtonStyle _selectRowButtonStyle(Color color) => TextButton.styleFrom(
    foregroundColor: color,
    minimumSize: const Size(0, 44),
    padding: const EdgeInsets.symmetric(horizontal: 10),
  );

  List<_BulkOption> _bulkOptions(BuildContext context) => [
    _BulkOption(
      IssueStatus.resolved,
      Icons.check_circle_rounded,
      AppColors.success,
      IssueStatus.resolved.localized(context),
    ),
    _BulkOption(
      IssueStatus.inProgress,
      Icons.build_circle_rounded,
      AppColors.warning,
      IssueStatus.inProgress.localized(context),
    ),
    _BulkOption(
      IssueStatus.onHold,
      Icons.pause_circle_rounded,
      AppColors.neutral,
      IssueStatus.onHold.localized(context),
    ),
  ];

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
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.cardAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ModeSwitchButton(
                  icon: Icons.grid_view_rounded,
                  label: l10n.techViewStatus,
                  isActive: activeMode == TechnicianViewMode.zoneStatusTable,
                  onTap: () => viewModeNotifier.setMode(
                    TechnicianViewMode.zoneStatusTable,
                  ),
                ),
              ),
              Expanded(
                child: _ModeSwitchButton(
                  icon: Icons.account_tree_rounded,
                  label: l10n.techViewSpatial,
                  isActive: activeMode == TechnicianViewMode.spatialExplorer,
                  onTap: () => viewModeNotifier.setMode(
                    TechnicianViewMode.spatialExplorer,
                  ),
                ),
              ),
              Expanded(
                child: _ModeSwitchButton(
                  icon: Icons.list_alt_rounded,
                  label: l10n.techViewQueue,
                  isActive: activeMode == TechnicianViewMode.workQueue,
                  onTap: () =>
                      viewModeNotifier.setMode(TechnicianViewMode.workQueue),
                ),
              ),
            ],
          ),
        ),

        const TechnicianOrgFilterBar(),

        if (activeMode == TechnicianViewMode.zoneStatusTable)
          const Expanded(child: TechnicianZoneStatusView())
        else if (activeMode == TechnicianViewMode.spatialExplorer)
          const Expanded(child: ZoneTreeExplorerView())
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
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    color: AppColors.cardAlt,
                    child: Row(
                      children: [
                        if (_isSelectionMode)
                          TextButton.icon(
                            onPressed: () => _toggleSelectAll(currentList),
                            icon: Icon(
                              _allSelected(currentList)
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              size: 22,
                            ),
                            label: Text(
                              _allSelected(currentList)
                                  ? l10n.clearSelection
                                  : l10n.selectAll,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: _selectRowButtonStyle(AppColors.primary),
                          ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _isSelectionMode = !_isSelectionMode;
                              if (!_isSelectionMode) _selectedIssueIds.clear();
                            });
                          },
                          icon: Icon(
                            _isSelectionMode
                                ? Icons.close_rounded
                                : Icons.checklist_rtl_rounded,
                            size: 22,
                          ),
                          label: Text(
                            _isSelectionMode
                                ? l10n.doneSelecting
                                : l10n.selectMode,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: _selectRowButtonStyle(
                            _isSelectionMode
                                ? AppColors.error
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppColors.divider),
                ],

                // Bulk Action Bar: count + close on top, status choice, then
                // one full-width apply button.
                if (_selectedIssueIds.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 4, 4, 12),
                    color: AppColors.primaryBg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 22,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.staffNSelected(_selectedIssueIds.length),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                size: 24,
                                color: AppColors.icon,
                              ),
                              onPressed: () => setState(() {
                                _selectedIssueIds.clear();
                                _isSelectionMode = false;
                              }),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Row(
                            children: [
                              for (final (i, option)
                                  in _bulkOptions(context).indexed) ...[
                                if (i > 0) const SizedBox(width: 8),
                                Expanded(
                                  child: _BulkStatusOption(
                                    icon: option.icon,
                                    label: option.label,
                                    color: option.color,
                                    isSelected: _bulkStatus == option.status,
                                    onTap: () => setState(
                                      () => _bulkStatus = option.status,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isApplying ? null : _handleBulkApply,
                              icon: _isApplying
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : const Icon(Icons.done_all_rounded, size: 22),
                              label: Text(
                                l10n.applyToSelected,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.textWhite,
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
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
    final color = isActive ? AppColors.primary : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? AppColors.surface : AppColors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          // Icon above label: the icon carries the meaning, the word confirms it.
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulkOption {
  final IssueStatus status;
  final IconData icon;
  final Color color;
  final String label;

  const _BulkOption(this.status, this.icon, this.color, this.label);
}

/// One big tappable status choice in the bulk bar: icon + one word, coloured.
class _BulkStatusOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _BulkStatusOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? color : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? AppColors.white : color,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
