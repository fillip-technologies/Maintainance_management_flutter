import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Standardized pill-shaped filter chip used across lists and directory tabs.
class AppFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final String? badgeText;
  final Color? badgeColor;
  final Color? activeColor;
  final Color? activeTextColor;
  final Color? inactiveColor;
  final Color? inactiveTextColor;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.badgeText,
    this.badgeColor,
    this.activeColor,
    this.activeTextColor,
    this.inactiveColor,
    this.inactiveTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveActiveColor = activeColor ?? AppColors.primary;
    final effectiveActiveTextColor = activeTextColor ?? AppColors.textWhite;
    final effectiveInactiveColor = inactiveColor ?? AppColors.cardAlt;
    final effectiveInactiveTextColor = inactiveTextColor ?? AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? effectiveActiveColor : effectiveInactiveColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? effectiveActiveColor : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? effectiveActiveTextColor : effectiveInactiveTextColor,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? effectiveActiveTextColor : effectiveInactiveTextColor,
                ),
              ),
              if (badgeText != null && badgeText!.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : (badgeColor?.withValues(alpha: 0.15) ?? AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? effectiveActiveTextColor
                          : (badgeColor ?? AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
