import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/widgets/language_switcher_button.dart';
import '../../../data/models/user_model.dart';
import '../../staff/view/staff_home_page.dart';
import '../../technician/view/technician_home_page.dart';

/// Global application container shell that provides a consistent top AppBar,
/// user identity display, server settings, and sign-out controls, while delegating
/// the body layout to role-specific views (`StaffHomePage` and `TechnicianHomePage`).
class GlobalHomePage extends ConsumerStatefulWidget {
  const GlobalHomePage({super.key});

  @override
  ConsumerState<GlobalHomePage> createState() => _GlobalHomePageState();
}

class _GlobalHomePageState extends ConsumerState<GlobalHomePage> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final isTechnician = user?.role == UserRole.technician;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
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
                  Text(
                    user?.name ??
                        (isTechnician ? 'Field Technician' : 'Staff Member'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
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
        actions: [
          const Center(
            child: LanguageSwitcherButton(isCompact: true),
          ),
          const SizedBox(width: 4),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: _isLoggingOut
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.icon,
                    ),
                    tooltip: 'Sign Out',
                    onPressed: () async {
                      setState(() => _isLoggingOut = true);
                      try {
                        await ref.read(authStateProvider.notifier).logout();
                        AppSnackbar.info('Signed out successfully');
                      } catch (e) {
                        if (mounted) setState(() => _isLoggingOut = false);
                      }
                    },
                  ),
          ),
        ],
      ),
      body: isTechnician ? const TechnicianHomePage() : const StaffHomePage(),
    );
  }
}
