import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../issues/issues.dart';

class TechnicianSearchFilterBar extends StatelessWidget {
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
        children: [
          TextField(
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: searchHint,
              prefixIcon: const Icon(Icons.search, color: AppColors.icon),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPriorityFilterChip(allLabel, null),
                _buildPriorityFilterChip(criticalLabel, IssuePriority.critical),
                _buildPriorityFilterChip(highLabel, IssuePriority.high),
                _buildPriorityFilterChip(mediumLabel, IssuePriority.medium),
                _buildPriorityFilterChip(lowLabel, IssuePriority.low),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityFilterChip(String label, IssuePriority? priority) {
    final isSelected = selectedPriority == priority;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.textWhite : AppColors.textSecondary,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => onPriorityChanged(priority),
        backgroundColor: AppColors.background,
        selectedColor: _getChipColor(priority),
        checkmarkColor: AppColors.textWhite,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.transparent : AppColors.border,
          ),
        ),
      ),
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
