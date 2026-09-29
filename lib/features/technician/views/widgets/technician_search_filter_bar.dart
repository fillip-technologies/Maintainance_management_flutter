import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../issues/issues.dart';
import '../../models/technician_queue_state.dart';

class TechnicianSearchFilterBar extends StatefulWidget {
  final String searchQuery;
  final IssuePriority? selectedPriority;
  final int selectedTabIndex;
  final TechnicianKpiStats? stats;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<IssuePriority?> onPriorityChanged;
  final ValueChanged<int>? onTabSelected;

  const TechnicianSearchFilterBar({
    super.key,
    required this.searchQuery,
    required this.selectedPriority,
    this.selectedTabIndex = 0,
    this.stats,
    required this.onSearchChanged,
    required this.onPriorityChanged,
    this.onTabSelected,
  });

  @override
  State<TechnicianSearchFilterBar> createState() => _TechnicianSearchFilterBarState();
}

class _TechnicianSearchFilterBarState extends State<TechnicianSearchFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant TechnicianSearchFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery && _searchController.text != widget.searchQuery) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final searchHint = l10n?.searchTickets ?? 'Search tickets, devices, zones...';
    final allLabel = l10n?.priorityAll ?? 'All';
    final criticalLabel = l10n?.priorityCritical ?? 'Critical';
    final highLabel = l10n?.priorityHigh ?? 'High';
    final mediumLabel = l10n?.priorityMedium ?? 'Medium';
    final lowLabel = l10n?.priorityLow ?? 'Low';

    final activeCount = widget.stats?.open ?? 0;
    final onHoldCount = widget.stats?.onHold ?? 0;
    final resolvedCount = widget.stats?.resolved ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: searchHint,
              hintStyle: TextStyle(fontSize: 14, color: AppColors.textMuted),
              prefixIcon: Icon(Icons.search_rounded, size: 22, color: AppColors.icon),
              suffixIcon: widget.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded, size: 20, color: AppColors.icon),
                      onPressed: () {
                        _searchController.clear();
                        widget.onSearchChanged('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              filled: true,
              fillColor: AppColors.background,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: widget.onSearchChanged,
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (widget.onTabSelected != null) ...[
                  _buildStatusChip(
                    index: 0,
                    icon: Icons.assignment_outlined,
                    label: l10n?.tabActiveQueue ?? 'Active',
                    count: activeCount,
                    activeColor: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(
                    index: 1,
                    icon: Icons.pause_circle_outline,
                    label: l10n?.tabOnHold ?? 'On Hold',
                    count: onHoldCount,
                    activeColor: AppColors.purple,
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(
                    index: 2,
                    icon: Icons.task_alt,
                    label: l10n?.tabResolvedHistory ?? 'Resolved',
                    count: resolvedCount,
                    activeColor: AppColors.success,
                  ),
                  const SizedBox(width: 10),
                  Container(height: 24, width: 1, color: AppColors.border),
                  const SizedBox(width: 10),
                ],
                _buildPriorityFilterChip(allLabel, null),
                const SizedBox(width: 8),
                _buildPriorityFilterChip(criticalLabel, IssuePriority.critical),
                const SizedBox(width: 8),
                _buildPriorityFilterChip(highLabel, IssuePriority.high),
                const SizedBox(width: 8),
                _buildPriorityFilterChip(mediumLabel, IssuePriority.medium),
                const SizedBox(width: 8),
                _buildPriorityFilterChip(lowLabel, IssuePriority.low),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required int index,
    required IconData icon,
    required String label,
    required int count,
    required Color activeColor,
  }) {
    return AppFilterChip(
      label: label,
      icon: icon,
      badgeText: '$count',
      badgeColor: activeColor,
      isSelected: widget.selectedTabIndex == index,
      activeColor: activeColor,
      onTap: () => widget.onTabSelected?.call(index),
    );
  }

  Widget _buildPriorityFilterChip(String label, IssuePriority? priority) {
    final isSelected = widget.selectedPriority == priority;
    return AppFilterChip(
      label: label,
      isSelected: isSelected,
      activeColor: _getChipColor(priority),
      onTap: () => widget.onPriorityChanged(priority),
    );
  }

  Color _getChipColor(IssuePriority? priority) {
    return switch (priority) {
      IssuePriority.critical => AppColors.error,
      IssuePriority.high => AppColors.warning,
      IssuePriority.medium => AppColors.primary,
      IssuePriority.low => AppColors.info,
      null => AppColors.primary,
    };
  }
}
