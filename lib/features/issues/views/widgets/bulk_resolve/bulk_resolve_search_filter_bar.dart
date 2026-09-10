import 'package:flutter/material.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../l10n/app_localizations.dart';

class BulkResolveSearchFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedTypeFilter;
  final Set<String> availableTypes;
  final ValueChanged<String> onTypeFilterChanged;
  final int filteredCount;
  final bool allFilteredSelected;
  final int selectedCount;
  final VoidCallback? onSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback onSearchChanged;

  const BulkResolveSearchFilterBar({
    super.key,
    required this.searchController,
    required this.selectedTypeFilter,
    required this.availableTypes,
    required this.onTypeFilterChanged,
    required this.filteredCount,
    required this.allFilteredSelected,
    required this.selectedCount,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search TextField
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: (_) => onSearchChanged(),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: l10n?.searchTicketsHint ?? 'Search ticket by ID, device, category...',
                  hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  prefixIcon: Icon(Icons.search, size: 18, color: AppColors.icon),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            searchController.clear();
                            onSearchChanged();
                          },
                        )
                      : null,
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
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
                  selected: selectedTypeFilter == 'all',
                  label: Text(l10n?.allTypes ?? 'All Types'),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selectedTypeFilter == 'all'
                        ? AppColors.textWhite
                        : AppColors.textPrimary,
                  ),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  checkmarkColor: AppColors.textWhite,
                  onSelected: (_) => onTypeFilterChanged('all'),
                ),
                ...availableTypes.map((type) {
                  final isSel = selectedTypeFilter.toLowerCase() == type.toLowerCase();
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
                      onSelected: (_) => onTypeFilterChanged(type),
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
              l10n?.selectTickets(filteredCount) ?? 'Select Tickets ($filteredCount)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onSelectAll,
                  icon: Icon(
                    allFilteredSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    l10n?.selectAll ?? 'Select All',
                    style: TextStyle(
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
                if (selectedCount > 0) ...[
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: onClearSelection,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    child: Text(
                      l10n?.clearSelection ?? 'Clear',
                      style: TextStyle(
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
      ],
    );
  }
}
