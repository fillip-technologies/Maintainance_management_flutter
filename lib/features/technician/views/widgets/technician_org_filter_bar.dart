import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../viewmodels/technician_org_filter_provider.dart';

/// Horizontal chip row to focus the technician's views on one organization.
/// Renders nothing unless the technician covers two or more organizations.
class TechnicianOrgFilterBar extends ConsumerWidget {
  const TechnicianOrgFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgs = ref.watch(technicianOrgsProvider);
    if (orgs.length < 2) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final active = ref.watch(technicianActiveOrgProvider);
    final notifier = ref.read(technicianOrgFilterProvider.notifier);

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Icon(Icons.apartment_rounded, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  AppFilterChip(
                    label: l10n.techOrgAll,
                    isSelected: active == null,
                    onTap: () => notifier.select(null),
                  ),
                  for (final org in orgs) ...[
                    const SizedBox(width: 8),
                    AppFilterChip(
                      label: org.name,
                      isSelected: active == org.id,
                      onTap: () => notifier.select(org.id),
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
