import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../issues/issues.dart';

class TechnicianSearchFilterBar extends StatefulWidget {
  final String searchQuery;
  final IssuePriority? selectedPriority;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<IssuePriority?> onPriorityChanged;

  const TechnicianSearchFilterBar({
    super.key,
    required this.searchQuery,
    required this.selectedPriority,
    required this.onSearchChanged,
    required this.onPriorityChanged,
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

    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: searchHint,
              prefixIcon: const Icon(Icons.search, color: AppColors.icon),
              suffixIcon: widget.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: AppColors.icon),
                      onPressed: () {
                        _searchController.clear();
                        widget.onSearchChanged('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: widget.onSearchChanged,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPriorityFilterChip(allLabel, null),
                const SizedBox(width: 6),
                _buildPriorityFilterChip(criticalLabel, IssuePriority.critical),
                const SizedBox(width: 6),
                _buildPriorityFilterChip(highLabel, IssuePriority.high),
                const SizedBox(width: 6),
                _buildPriorityFilterChip(mediumLabel, IssuePriority.medium),
                const SizedBox(width: 6),
                _buildPriorityFilterChip(lowLabel, IssuePriority.low),
              ],
            ),
          ),
        ],
      ),
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
