import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../viewmodels/technician_org_filter_provider.dart';

/// Small "building + organization name" tag. Only appears for technicians who
/// cover two or more organizations, so single-org technicians see no clutter.
class TechnicianOrgBadge extends ConsumerWidget {
  final String? name;

  const TechnicianOrgBadge({super.key, required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = name?.trim() ?? '';
    if (label.isEmpty || ref.watch(technicianOrgsProvider).length < 2) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.apartment_rounded, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
