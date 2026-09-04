import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../devices/views/helpers/hardware_icon_helper.dart';
import '../../technician/viewmodels/technician_action_viewmodel.dart';
import '../../technician/viewmodels/technician_queue_viewmodel.dart';
import '../models/issue_model.dart';

class BulkResolveIssuesSheet extends ConsumerStatefulWidget {
  const BulkResolveIssuesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BulkResolveIssuesSheet(),
    );
  }

  @override
  ConsumerState<BulkResolveIssuesSheet> createState() => _BulkResolveIssuesSheetState();
}

class _BulkResolveIssuesSheetState extends ConsumerState<BulkResolveIssuesSheet> {
  final Set<String> _selectedIssueIds = {};
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  IssueStatus _targetStatus = IssueStatus.resolved;
  String _selectedTypeFilter = 'all';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _toggleIssue(String issueId) {
    setState(() {
      if (_selectedIssueIds.contains(issueId)) {
        _selectedIssueIds.remove(issueId);
      } else {
        if (_selectedIssueIds.length >= 50) {
          final l10n = AppLocalizations.of(context);
          AppSnackbar.warning(l10n?.errMaxTicketsLimit ?? 'Maximum limit of 50 tickets reached');
          return;
        }
        _selectedIssueIds.add(issueId);
      }
    });
  }

  void _toggleGroup(List<IssueModel> groupIssues) {
    final groupIds = groupIssues.map((e) => e.id).toSet();
    final allSelected = groupIds.every(_selectedIssueIds.contains);

    setState(() {
      if (allSelected) {
        _selectedIssueIds.removeAll(groupIds);
      } else {
        for (final id in groupIds) {
          if (_selectedIssueIds.length >= 50) break;
          _selectedIssueIds.add(id);
        }
      }
    });
  }

  void _selectAll(List<IssueModel> issues) {
    setState(() {
      _selectedIssueIds.clear();
      for (final issue in issues) {
        if (_selectedIssueIds.length >= 50) break;
        _selectedIssueIds.add(issue.id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIssueIds.clear();
    });
  }

  Future<void> _submitBulkTransition(List<IssueModel> allIssues) async {
    final l10n = AppLocalizations.of(context);

    if (_selectedIssueIds.isEmpty) {
      AppSnackbar.warning(l10n?.errSelectAtLeastOneTicket ?? 'Please select at least 1 ticket');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final selectedList = _selectedIssueIds.toList();
      final notes = _notesController.text.trim();

      final result = await ref.read(technicianActionViewModelProvider).bulkUpdateStatus(
            issueIds: selectedList,
            toStatus: _targetStatus,
            notes: notes.isNotEmpty ? notes : null,
          );

      if (!mounted) return;

      final updatedCount = result.updated.length;
      final errorCount = result.errors.length;

      if (updatedCount > 0) {
        final statusLabel = _targetStatus.label;
        final msg = l10n?.bulkStatusSuccessMsg(updatedCount, statusLabel) ??
            '$updatedCount tickets updated to $statusLabel';
        AppSnackbar.success(msg);
      }

      if (errorCount > 0) {
        AppSnackbar.warning('$errorCount ticket(s) could not be updated (invalid transition)');
      }

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error('Failed to update tickets: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final queueState = ref.watch(technicianQueueStateProvider);

    // Tickets available for bulk resolution: active and on-hold tickets (non-resolved, non-closed)
    final candidateIssues = [
      ...queueState.activeIssues,
      ...queueState.onHoldIssues,
    ];

    // Filter by type
    var filtered = candidateIssues;
    if (_selectedTypeFilter != 'all') {
      filtered = filtered.where((i) {
        final typeName = i.categoryName.isNotEmpty ? i.categoryName : i.deviceName;
        return typeName.toLowerCase() == _selectedTypeFilter.toLowerCase();
      }).toList();
    }

    // Filter by search query
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((i) {
        return i.id.toLowerCase().contains(query) ||
            i.deviceName.toLowerCase().contains(query) ||
            i.categoryName.toLowerCase().contains(query) ||
            i.zoneName.toLowerCase().contains(query) ||
            i.displayDescription.toLowerCase().contains(query);
      }).toList();
    }

    // Available types for horizontal filter chips
    final availableTypes = <String>{};
    for (final issue in candidateIssues) {
      final name = issue.categoryName.isNotEmpty ? issue.categoryName : issue.deviceName;
      if (name.isNotEmpty) availableTypes.add(name);
    }

    // Group filtered tickets by category/device
    final grouped = <String, List<IssueModel>>{};
    for (final issue in filtered) {
      final groupKey = issue.categoryName.isNotEmpty ? issue.categoryName : issue.deviceName;
      grouped.putIfAbsent(groupKey, () => []).add(issue);
    }

    final allFilteredSelected =
        filtered.isNotEmpty && filtered.every((i) => _selectedIssueIds.contains(i.id));

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.task_alt_rounded,
                    color: AppColors.success,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.bulkResolveTitle ?? 'Bulk Resolve Issues',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n?.bulkResolveSubtitle ?? 'Batch update status for multiple tickets (1–50)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Counter Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _selectedIssueIds.isNotEmpty
                        ? AppColors.primary
                        : AppColors.cardAlt,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_selectedIssueIds.length}/50',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _selectedIssueIds.isNotEmpty
                          ? AppColors.textWhite
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.icon),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // Scrollable Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                // Target Status Choice Chips
                Text(
                  l10n?.applyToSelected ?? 'Apply to Selected',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatusChip(
                      status: IssueStatus.resolved,
                      label: l10n?.actionMarkResolved ?? 'Mark Resolved',
                      icon: Icons.check_circle_outline,
                      color: AppColors.success,
                      bgColor: AppColors.successLight,
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(
                      status: IssueStatus.inProgress,
                      label: l10n?.actionStartWork ?? 'Start Work',
                      icon: Icons.play_circle_outline,
                      color: AppColors.info,
                      bgColor: AppColors.infoLight,
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(
                      status: IssueStatus.onHold,
                      label: l10n?.actionHold ?? 'Hold',
                      icon: Icons.pause_circle_outline,
                      color: AppColors.warning,
                      bgColor: AppColors.warningLight,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Resolution Notes & Quick Fill Chips
                Text(
                  l10n?.resolutionNotesLabel ?? 'Technician Resolution / Work Notes',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: l10n?.resolutionNotesHint ??
                        'Explain steps taken, repairs made, or reason for status update...',
                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Quick-fill chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPresetChip(l10n?.presetPowerRestored ?? 'Main power supply restored'),
                      const SizedBox(width: 6),
                      _buildPresetChip(l10n?.presetBatchRepaired ?? 'Batch repair completed and verified'),
                      const SizedBox(width: 6),
                      _buildPresetChip(l10n?.presetFirmwareUpdated ?? 'Firmware updated & rebooted'),
                      const SizedBox(width: 6),
                      _buildPresetChip(l10n?.presetCablesTested ?? 'Cables re-seated & tested'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 12),

                // Search & Filter Bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: l10n?.searchTicketsHint ?? 'Search ticket by ID, device, category...',
                          hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.icon),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Type Filter Chips
                if (availableTypes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          selected: _selectedTypeFilter == 'all',
                          label: Text(l10n?.allTypes ?? 'All Types'),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _selectedTypeFilter == 'all'
                                ? AppColors.textWhite
                                : AppColors.textPrimary,
                          ),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          checkmarkColor: AppColors.textWhite,
                          onSelected: (_) => setState(() => _selectedTypeFilter = 'all'),
                        ),
                        ...availableTypes.map((type) {
                          final isSel = _selectedTypeFilter.toLowerCase() == type.toLowerCase();
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: FilterChip(
                              selected: isSel,
                              label: Text(type),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSel ? AppColors.textWhite : AppColors.textPrimary,
                              ),
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.surface,
                              checkmarkColor: AppColors.textWhite,
                              onSelected: (_) => setState(() => _selectedTypeFilter = type),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Select All / Clear Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n?.selectTickets(filtered.length) ?? 'Select Tickets (${filtered.length})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: filtered.isEmpty ? null : () => _selectAll(filtered),
                          icon: Icon(
                            allFilteredSelected
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            l10n?.selectAll ?? 'Select All',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                        ),
                        if (_selectedIssueIds.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: _clearSelection,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                            ),
                            child: Text(
                              l10n?.clearSelection ?? 'Clear',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
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
                                ? 'No pending issues to resolve'
                                : 'No matching tickets found',
                            style: const TextStyle(
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
                    final groupName = entry.key;
                    final groupIssues = entry.value;
                    final groupIds = groupIssues.map((e) => e.id).toSet();
                    final allGroupSelected = groupIds.every(_selectedIssueIds.contains);
                    final groupSelectedCount = groupIssues.where((i) => _selectedIssueIds.contains(i.id)).length;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: allGroupSelected
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : AppColors.border,
                        ),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              HardwareIconHelper.getIcon(groupName),
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  groupName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.cardAlt,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$groupSelectedCount/${groupIssues.length}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: TextButton(
                            onPressed: () => _toggleGroup(groupIssues),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: Text(
                              allGroupSelected
                                  ? (l10n?.deselectGroup ?? 'Deselect')
                                  : (l10n?.selectAllInGroup ?? 'Select Group'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: allGroupSelected ? AppColors.error : AppColors.primary,
                              ),
                            ),
                          ),
                          children: groupIssues.map((issue) {
                            final isSelected = _selectedIssueIds.contains(issue.id);
                            final units = issue.unitsAffected;

                            return InkWell(
                              onTap: () => _toggleIssue(issue.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryBg.withValues(alpha: 0.2)
                                      : Colors.transparent,
                                  border: const Border(
                                    top: BorderSide(color: AppColors.divider, width: 0.5),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: Checkbox(
                                        value: isSelected,
                                        onChanged: (_) => _toggleIssue(issue.id),
                                        activeColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                issue.id.length > 8
                                                    ? '#${issue.id.substring(0, 8)}'
                                                    : '#${issue.id}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              if (units != null && units > 1) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.purpleLight,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    '$units Units',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.purpleText,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              const Spacer(),
                                              StatusBadge.priority(issue.priority),
                                              const SizedBox(width: 4),
                                              StatusBadge.issue(issue.status),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${issue.deviceName} • ${issue.zoneName}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          if (issue.displayDescription.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              issue.displayDescription,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),

          // Sticky Footer Action CTA
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting || _selectedIssueIds.isEmpty
                      ? null
                      : () => _submitBulkTransition(candidateIssues),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _targetStatus == IssueStatus.resolved
                        ? AppColors.success
                        : (_targetStatus == IssueStatus.onHold
                            ? AppColors.warning
                            : AppColors.primary),
                    foregroundColor: AppColors.textWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _targetStatus == IssueStatus.resolved
                                  ? Icons.task_alt_rounded
                                  : (_targetStatus == IssueStatus.onHold
                                      ? Icons.pause_circle_outline
                                      : Icons.play_circle_outline),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n?.btnApplyStatusToTickets(
                                    _targetStatus.label,
                                    _selectedIssueIds.length,
                                  ) ??
                                  'Apply ${_targetStatus.label} to ${_selectedIssueIds.length} Ticket(s)',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required IssueStatus status,
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    final isSelected = _targetStatus == status;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _targetStatus = status),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? bgColor : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? color : AppColors.icon),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? color : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String text) {
    return ActionChip(
      label: Text(text),
      labelStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      onPressed: () {
        setState(() {
          _notesController.text = text;
        });
      },
    );
  }
}
