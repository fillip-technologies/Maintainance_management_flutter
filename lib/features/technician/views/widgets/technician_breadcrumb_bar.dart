import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../devices/models/technician_zone_node.dart';

/// Horizontal scrolling breadcrumb navigation bar with quick jump-to-level support.
class TechnicianBreadcrumbBar extends StatelessWidget {
  final List<TechnicianZoneNode> currentPath;
  final VoidCallback onNavigateUp;
  final VoidCallback onJumpToRoot;
  final ValueChanged<int> onJumpToBreadcrumb;

  const TechnicianBreadcrumbBar({
    super.key,
    required this.currentPath,
    required this.onNavigateUp,
    required this.onJumpToRoot,
    required this.onJumpToBreadcrumb,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAtRoot = currentPath.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.6), width: 1),
        ),
      ),
      child: Row(
        children: [
          if (!isAtRoot) ...[
            InkWell(
              onTap: onNavigateUp,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: false,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  // Root Chip
                  _BreadcrumbChip(
                    icon: Icons.home_rounded,
                    label: l10n.techAllZones,
                    isActive: isAtRoot,
                    onTap: onJumpToRoot,
                  ),

                  // Breadcrumb ancestor trail
                  for (int i = 0; i < currentPath.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                      ),
                    ),
                    _BreadcrumbChip(
                      icon: i == currentPath.length - 1
                          ? Icons.meeting_room_rounded
                          : Icons.location_city_rounded,
                      label: currentPath[i].name,
                      isActive: i == currentPath.length - 1,
                      onTap: () => onJumpToBreadcrumb(i),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreadcrumbChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BreadcrumbChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.12) : AppColors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary.withValues(alpha: 0.3) : AppColors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
