import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equipment_management_system/core/theme/colors.dart';
import 'package:equipment_management_system/features/devices/devices.dart';
import 'package:equipment_management_system/l10n/app_localizations.dart';
import 'package:equipment_management_system/features/issues/controllers/replace_device_controller.dart';
import 'package:equipment_management_system/features/issues/controllers/replace_device_state.dart';

class ReplaceDeviceActionSelector extends StatelessWidget {
  final ReplacementChoice replacementChoice;
  final DeviceModel? selectedSpareDevice;
  final AsyncValue<List<DeviceModel>> sparesAsync;
  final TextEditingController searchController;
  final ScrollController sparesScrollController;
  final String searchQuery;
  final ValueChanged<ReplacementChoice> onChoiceSelected;
  final ValueChanged<DeviceModel> onSpareSelected;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  const ReplaceDeviceActionSelector({
    super.key,
    required this.replacementChoice,
    required this.selectedSpareDevice,
    required this.sparesAsync,
    required this.searchController,
    required this.sparesScrollController,
    required this.searchQuery,
    required this.onChoiceSelected,
    required this.onSpareSelected,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Step 2: What action did you take?
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                shape: BoxShape.circle,
              ),
              child: Text('2', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.stepWhatDidYouDo,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Choice 1: Removed only (slot left empty)
        _buildActionCard(
          isSelected: replacementChoice == ReplacementChoice.none,
          onTap: () => onChoiceSelected(ReplacementChoice.none),
          icon: Icons.remove_circle_outline_rounded,
          iconColor: AppColors.error,
          title: l10n.actionRemovedOnly,
          subtitle: l10n.actionRemovedOnlySub,
        ),
        const SizedBox(height: 10),

        // Choice 2: Replaced with Spare from Inventory
        _buildActionCard(
          isSelected: replacementChoice == ReplacementChoice.inStock,
          onTap: () => onChoiceSelected(ReplacementChoice.inStock),
          icon: Icons.inventory_2_outlined,
          iconColor: AppColors.success,
          title: l10n.actionReplacedFromStock,
          subtitle: l10n.actionReplacedFromStockSub,
        ),

        // Expandable Inventory Spares List
        if (replacementChoice == ReplacementChoice.inStock) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sparesAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '$err',
                      style: TextStyle(fontSize: 12, color: AppColors.errorText),
                    ),
                  ),
                  data: (spares) {
                    if (spares.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 20, color: AppColors.icon),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.noSparesAvailable,
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final filteredSpares = ReplaceDeviceController.filterSpares(
                      spares: spares,
                      searchQuery: searchQuery,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shelves, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${l10n.availableSparesHeading} (${spares.length})',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.selectSparePrompt,
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),

                        // Search Bar if more than 3 spares
                        if (spares.length > 3) ...[
                          TextField(
                            controller: searchController,
                            onChanged: onSearchChanged,
                            style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: l10n.searchSparesHint,
                              hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                              prefixIcon: Icon(Icons.search, size: 18, color: AppColors.icon),
                              suffixIcon: searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: onClearSearch,
                                    )
                                  : null,
                              filled: true,
                              fillColor: AppColors.surface,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                          const SizedBox(height: 10),
                        ],

                        // Bounded Scrollable Spares List Box (Max Height: 220px)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: Scrollbar(
                            thumbVisibility: true,
                            controller: sparesScrollController,
                            child: ListView.separated(
                              controller: sparesScrollController,
                              shrinkWrap: true,
                              itemCount: filteredSpares.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final spare = filteredSpares[index];
                                final isSelected = selectedSpareDevice?.id == spare.id;

                                return InkWell(
                                  onTap: () => onSpareSelected(spare),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primaryBg : AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primary : AppColors.border,
                                        width: isSelected ? 2.0 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.cardAlt,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            HardwareIconHelper.getIcon(spare.categoryName.isNotEmpty ? spare.categoryName : spare.name),
                                            color: isSelected ? AppColors.primary : AppColors.icon,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                spare.name,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${l10n.hardwareCode}: ${spare.code.isNotEmpty ? spare.code : "N/A"}',
                                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              l10n.selectedSpareBadge,
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.white),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionCard({
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBg : AppColors.cardAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : iconColor, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.8) : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : AppColors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 14, color: AppColors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
