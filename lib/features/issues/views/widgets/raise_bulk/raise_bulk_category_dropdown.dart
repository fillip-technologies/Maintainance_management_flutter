import 'package:flutter/material.dart';
import 'package:equipment_management_system/core/theme/colors.dart';
import 'package:equipment_management_system/features/issues/models/issue_model.dart';
import 'package:equipment_management_system/l10n/app_localizations.dart';

class RaiseBulkCategoryDropdown extends StatelessWidget {
  final bool isLoading;
  final List<IssueCategoryModel> categories;
  final IssueCategoryModel? selectedCategory;
  final ValueChanged<IssueCategoryModel?> onCategoryChanged;

  const RaiseBulkCategoryDropdown({
    super.key,
    required this.isLoading,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n?.defectCategory ?? 'Defect Category',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        if (isLoading)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n?.loadingCategories ?? 'Loading defect categories...',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else if (categories.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              l10n?.noCategoriesFound ?? 'No defect categories found. Please contact an administrator.',
              style: TextStyle(fontSize: 12, color: AppColors.warningText),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<IssueCategoryModel>(
                value: selectedCategory,
                isExpanded: true,
                hint: Text(l10n?.selectCategoryHint ?? 'Select Defect Category'),
                items: categories.map((cat) {
                  return DropdownMenuItem<IssueCategoryModel>(
                    value: cat,
                    child: Text(
                      cat.name,
                      style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    ),
                  );
                }).toList(),
                onChanged: onCategoryChanged,
              ),
            ),
          ),
      ],
    );
  }
}
