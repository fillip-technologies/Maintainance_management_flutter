import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/language_switcher_button.dart';
import '../../../data/models/user_model.dart';
import '../../profile/profile.dart';
import '../../staff/view/staff_home_page.dart';
import '../../technician/view/technician_home_page.dart';

/// Global application container shell that provides a consistent top AppBar,
/// user identity display (tapping opens ProfilePage), language switcher,
/// while delegating the body layout to role-specific views (`StaffHomePage` and `TechnicianHomePage`).
class GlobalHomePage extends ConsumerWidget {
  const GlobalHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final isTechnician = user?.role == UserRole.technician;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleSpacing: 16,
        title: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isTechnician
                        ? Icons.engineering_outlined
                        : Icons.shield_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              user?.name ??
                                  (isTechnician
                                      ? 'Field Technician'
                                      : 'Staff Member'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: AppColors.iconLight,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            isTechnician
                                ? Icons.build_circle_outlined
                                : Icons.location_on,
                            size: 12,
                            color: AppColors.icon,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              isTechnician
                                  ? 'Hardware Technician • Assigned Queue'
                                  : (user?.assignedZoneName ??
                                      'Assigned Zone Scope'),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: const [
          Center(
            child: LanguageSwitcherButton(isCompact: true),
          ),
          SizedBox(width: 14),
        ],
      ),
      body: isTechnician ? const TechnicianHomePage() : const StaffHomePage(),
    );
  }
}
