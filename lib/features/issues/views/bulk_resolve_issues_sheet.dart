import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equipment_management_system/core/theme/colors.dart';
import 'package:equipment_management_system/core/utils/app_snackbar.dart';
import 'package:equipment_management_system/features/location/location_helper.dart';
import 'package:equipment_management_system/features/technician/viewmodels/technician_action_viewmodel.dart';
import 'package:equipment_management_system/features/technician/viewmodels/technician_queue_viewmodel.dart';
import 'package:equipment_management_system/l10n/app_localizations.dart';
import '../controllers/bulk_resolve_controller.dart';
import '../controllers/bulk_resolve_state.dart';
import '../models/issue_model.dart';
import 'widgets/bulk_resolve/bulk_resolve_group_accordion.dart';
import 'widgets/bulk_resolve/bulk_resolve_header.dart';
import 'widgets/bulk_resolve/bulk_resolve_notes_input.dart';
import 'widgets/bulk_resolve/bulk_resolve_search_filter_bar.dart';
import 'widgets/bulk_resolve/bulk_resolve_submit_footer.dart';
import 'widgets/bulk_resolve/bulk_resolve_target_status_chips.dart';

class BulkResolveIssuesSheet extends ConsumerStatefulWidget {
  const BulkResolveIssuesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => const BulkResolveIssuesSheet(),
    );
  }

  @override
  ConsumerState<BulkResolveIssuesSheet> createState() => _BulkResolveIssuesSheetState();
}

class _BulkResolveIssuesSheetState extends ConsumerState<BulkResolveIssuesSheet> {
  late final BulkResolveController _controller;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = BulkResolveController(
      onStateChanged: _onStateChanged,
    );
    _notesController.addListener(() {
      _controller.setNotes(_notesController.text);
    });
  }

  void _onStateChanged(BulkResolveState state) {
    if (!mounted) return;
    if (_notesController.text != state.notes) {
      _notesController.text = state.notes;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleToggleIssue(String issueId) {
    final success = _controller.toggleIssue(issueId);
    if (!success) {
      final l10n = AppLocalizations.of(context);
      AppSnackbar.warning(l10n?.errMaxTicketsLimit ?? 'Maximum limit of 50 tickets reached');
    }
  }

  Future<void> _submitBulkTransition(List<IssueModel> allIssues) async {
    final l10n = AppLocalizations.of(context);
    final state = _controller.state;

    if (state.selectedIssueIds.isEmpty) {
      AppSnackbar.warning(l10n?.errSelectAtLeastOneTicket ?? 'Please select at least 1 ticket');
      return;
    }

    _controller.setSubmitting(true);

    try {
      double? lat;
      double? lng;
      if (state.targetStatus == IssueStatus.resolved) {
        final locRes = await _controller.locationHelper.getLocation();
        if (!locRes.isSuccess) {
          if (mounted) {
            AppSnackbar.error(
              locRes.errorMessage ??
                  'GPS coordinates are required to resolve tickets. Please turn on GPS.',
            );
            if (locRes.error == LocationErrorType.serviceDisabled) {
              await _controller.locationHelper.openLocationSettings();
            } else if (locRes.error == LocationErrorType.permissionDeniedForever) {
              await _controller.locationHelper.openAppSettings();
            }
          }
          return;
        }
        lat = locRes.latitude;
        lng = locRes.longitude;
      }

      final selectedList = state.selectedIssueIds.toList();
      final notes = _notesController.text.trim();

      final result = await ref.read(technicianActionViewModelProvider).bulkUpdateStatus(
            issueIds: selectedList,
            toStatus: state.targetStatus,
            notes: notes.isNotEmpty ? notes : null,
            latitude: lat,
            longitude: lng,
          );

      if (!mounted) return;

      final updatedCount = result.updated.length;
      final errorCount = result.errors.length;
      final statusLabel = state.targetStatus.label;

      if (updatedCount > 0) {
        final msg = l10n?.bulkStatusSuccessMsg(updatedCount, statusLabel) ??
            '$updatedCount tickets updated to $statusLabel';
        AppSnackbar.success(msg);
      }

      if (errorCount > 0) {
        final alreadyCount = result.errors
            .where((e) => (e['message'] as String? ?? '').contains('already'))
            .length;
        if (alreadyCount == errorCount) {
          AppSnackbar.info(
            l10n?.bulkAlreadyInStatus(errorCount, statusLabel) ??
                '$errorCount already $statusLabel',
          );
        } else {
          AppSnackbar.warning(
            l10n?.bulkCouldNotUpdate(errorCount) ??
                "$errorCount couldn't change from their current state",
          );
        }
      }

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(
        l10n?.bulkFailedToUpdate('$e') ?? 'Failed to update tickets: $e',
      );
    } finally {
      if (mounted) _controller.setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final queueState = ref.watch(technicianQueueStateProvider);
    final state = _controller.state;

    // Tickets available for bulk resolution: active and on-hold tickets (non-resolved, non-closed)
    final candidateIssues = [
      ...queueState.activeIssues,
      ...queueState.onHoldIssues,
    ];

    final filtered = BulkResolveController.filterIssues(
      candidateIssues: candidateIssues,
      selectedTypeFilter: state.selectedTypeFilter,
      searchQuery: _searchController.text,
    );

    final availableTypes = BulkResolveController.extractAvailableTypes(candidateIssues);
    final grouped = BulkResolveController.groupIssues(filtered);

    final allFilteredSelected =
        filtered.isNotEmpty && filtered.every((i) => state.selectedIssueIds.contains(i.id));

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          BulkResolveHeader(
            selectedCount: state.selectedCount,
            onClose: () => Navigator.pop(context),
          ),

          Divider(height: 1, color: AppColors.divider),

          // Scrollable Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                BulkResolveTargetStatusChips(
                  targetStatus: state.targetStatus,
                  onTargetStatusChanged: _controller.setTargetStatus,
                ),

                const SizedBox(height: 14),

                BulkResolveNotesInput(
                  controller: _notesController,
                  onPresetSelected: (preset) {
                    _notesController.text = preset;
                    _controller.setNotes(preset);
                  },
                ),

                const SizedBox(height: 16),
                Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 12),

                BulkResolveSearchFilterBar(
                  searchController: _searchController,
                  selectedTypeFilter: state.selectedTypeFilter,
                  availableTypes: availableTypes,
                  onTypeFilterChanged: _controller.setSelectedTypeFilter,
                  filteredCount: filtered.length,
                  allFilteredSelected: allFilteredSelected,
                  selectedCount: state.selectedCount,
                  onSelectAll: filtered.isEmpty ? null : () => _controller.selectAll(filtered),
                  onClearSelection: _controller.clearSelection,
                  onSearchChanged: () {
                    _controller.setSearchQuery(_searchController.text);
                    setState(() {});
                  },
                ),

                const SizedBox(height: 8),

                // Ticket Items / Grouped Accordions
                if (filtered.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: AppColors.iconLight),
                          const SizedBox(height: 8),
                          Text(
                            candidateIssues.isEmpty
                                ? (l10n?.bulkNoPendingIssues ?? 'No pending issues to resolve')
                                : (l10n?.bulkNoMatchingTickets ?? 'No matching tickets found'),
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  ...grouped.entries.map((entry) {
                    return BulkResolveGroupAccordion(
                      groupName: entry.key,
                      groupIssues: entry.value,
                      selectedIssueIds: state.selectedIssueIds,
                      onToggleIssue: _handleToggleIssue,
                      onToggleGroup: () => _controller.toggleGroup(entry.value),
                    );
                  }),
                ],
              ],
            ),
          ),

          // Sticky Footer Action CTA
          BulkResolveSubmitFooter(
            targetStatus: state.targetStatus,
            selectedCount: state.selectedCount,
            isSubmitting: state.isSubmitting,
            onSubmit: () => _submitBulkTransition(candidateIssues),
          ),
        ],
      ),
    );
  }
}
