import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/language_switcher_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth.dart';
import '../../devices/devices.dart';
import '../../issues/issues.dart';
import '../../profile/profile.dart';
import '../../realtime/realtime.dart';
import '../../staff/staff.dart';
import '../../technician/technician.dart';

/// Global application container shell that provides a consistent top AppBar,
/// user identity display (tapping opens ProfilePage), language switcher,
/// while delegating the body layout to role-specific views (`StaffHomePage` and `TechnicianHomePage`).
class GlobalHomePage extends ConsumerWidget {
  const GlobalHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authStateProvider).value;
    final isTechnician = user?.role == UserRole.technician;

    // Resolve zone logo: from user profile, or fallback to live loaded devices in zone
    final staffDevices = !isTechnician ? ref.watch(staffDevicesProvider).value : null;
    final fallbackZoneLogo = staffDevices
            ?.where((d) =>
                (user?.assignedZoneId == null || d.zoneId == user?.assignedZoneId) &&
                d.zoneLogoUrl != null &&
                d.zoneLogoUrl!.isNotEmpty)
            .firstOrNull
            ?.zoneLogoUrl ??
        staffDevices
            ?.where((d) => d.zoneLogoUrl != null && d.zoneLogoUrl!.isNotEmpty)
            .firstOrNull
            ?.zoneLogoUrl;

    final effectiveZoneLogoUrl =
        (user?.zoneLogoUrl != null && user!.zoneLogoUrl!.isNotEmpty)
            ? user.zoneLogoUrl
            : fallbackZoneLogo;

    final effectiveZoneName =
        (user?.assignedZoneName != null && user!.assignedZoneName!.isNotEmpty)
            ? user.assignedZoneName!
            : (staffDevices?.firstOrNull?.zoneName ?? 'Assigned Zone Scope');

    // Auto-heal local user session if zoneLogoUrl was missing at login time
    if (!isTechnician) {
      ref.listen<AsyncValue<List<DeviceModel>>>(staffDevicesProvider, (prev, next) {
        final devs = next.value;
        if (devs != null && user != null && (user.zoneLogoUrl == null || user.zoneLogoUrl!.isEmpty)) {
          final foundLogo = devs
                  .where((d) =>
                      (user.assignedZoneId == null || d.zoneId == user.assignedZoneId) &&
                      d.zoneLogoUrl != null &&
                      d.zoneLogoUrl!.isNotEmpty)
                  .firstOrNull
                  ?.zoneLogoUrl ??
              devs.where((d) => d.zoneLogoUrl != null && d.zoneLogoUrl!.isNotEmpty).firstOrNull?.zoneLogoUrl;
          if (foundLogo != null) {
            final updatedUser = user.copyWith(
              zoneLogoUrl: foundLogo,
              assignedZoneName: user.assignedZoneName ?? devs.firstOrNull?.zoneName,
            );
            ref.read(authStateProvider.notifier).setUser(updatedUser);
            ref.read(storageServiceProvider).saveUser(updatedUser);
          }
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0.0,
        titleSpacing: 16,
        title: InkWell(
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (effectiveZoneLogoUrl != null && effectiveZoneLogoUrl.isNotEmpty)
                      ? Image.network(
                          effectiveZoneLogoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Center(
                            child: Icon(
                              isTechnician
                                  ? Icons.engineering_outlined
                                  : Icons.shield_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            isTechnician
                                ? Icons.engineering_outlined
                                : Icons.shield_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
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
                                  : effectiveZoneName,
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
          Center(child: ConnectionStatusPill()),
          SizedBox(width: 8),
          Center(child: LanguageSwitcherButton(isCompact: true)),
          SizedBox(width: 14),
        ],
      ),
      body: isTechnician ? const TechnicianHomePage() : const StaffHomePage(),
      floatingActionButton: isTechnician
          ? FloatingActionButton.extended(
              onPressed: () => BulkResolveIssuesSheet.show(context),
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.textWhite,
              elevation: 4,
              icon: const Icon(Icons.task_alt_rounded),
              label: Text(
                l10n?.btnBulkResolve ?? 'Bulk Resolve',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            )
          : FloatingActionButton.extended(
              onPressed: () => RaiseBulkIssueSheet.show(context),
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textWhite,
              elevation: 4,
              icon: const Icon(Icons.playlist_add_rounded),
              label: Text(
                l10n?.btnBulkDefect ?? 'Bulk Defect',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
    );
  }
}
