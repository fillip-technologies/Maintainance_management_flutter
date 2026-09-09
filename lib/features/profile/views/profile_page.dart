import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/language_switcher_button.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../auth/auth.dart';
import '../../devices/devices.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'widgets/widgets.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
            const SizedBox(width: 8),
            Text(
              l10n.signOut,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          l10n.confirmSignOut,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    if (context.mounted) {
      Navigator.of(context).pop(); // Exit profile page
    }
    await ref.read(profileViewModelProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authStateProvider).value;
    final profileState = ref.watch(profileViewModelProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.profile)),
        body: const ProfileSkeleton(),
      );
    }

    final isTech = user.role.isTechnician;

    final staffDevices = !isTech ? ref.watch(staffDevicesProvider).value : null;
    final fallbackZoneLogo = staffDevices
        ?.where((d) => d.zoneLogoUrl != null && d.zoneLogoUrl!.isNotEmpty)
        .firstOrNull
        ?.zoneLogoUrl;

    final effectiveZoneLogoUrl =
        (user.zoneLogoUrl != null && user.zoneLogoUrl!.isNotEmpty)
            ? user.zoneLogoUrl
            : fallbackZoneLogo;

    // Auto-heal local user session if zoneLogoUrl was missing at login time
    if (!isTech) {
      ref.listen<AsyncValue<List<DeviceModel>>>(staffDevicesProvider, (prev, next) {
        final devs = next.value;
        if (devs != null && (user.zoneLogoUrl == null || user.zoneLogoUrl!.isEmpty)) {
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.profile,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Profile Card
            ProfileHeaderCard(
              user: user,
              zoneLogoUrl: effectiveZoneLogoUrl,
            ),

            const SizedBox(height: 24),

            // Section 1: Work & Assignment Scope
            _buildSectionHeader(l10n.workScope),
            const SizedBox(height: 8),
            _buildCardContainer([
              ProfileInfoTile(
                icon: Icons.badge_outlined,
                label: l10n.role,
                value: isTech
                    ? l10n.roleHardwareTechnician
                    : l10n.roleZoneStaff,
              ),
              Divider(color: AppColors.divider, height: 1),
              ProfileInfoTile(
                icon: isTech ? Icons.assignment_outlined : Icons.place_outlined,
                label: l10n.assignedLocation,
                value: isTech
                    ? l10n.orgWideQueue
                    : (user.assignedZoneName != null &&
                              user.assignedZoneName!.isNotEmpty
                          ? user.assignedZoneName!
                          : l10n.unassignedScope),
                imageUrl: !isTech ? effectiveZoneLogoUrl : null,
              ),
              if (user.clientId != null && user.clientId!.isNotEmpty) ...[
                Divider(color: AppColors.divider, height: 1),
                ProfileInfoTile(
                  icon: Icons.business_outlined,
                  label: l10n.organizationId,
                  value: user.clientId!,
                  copyableValue: user.clientId,
                ),
              ],
              Divider(color: AppColors.divider, height: 1),
              ProfileInfoTile(
                icon: Icons.fingerprint,
                label: l10n.userId,
                value: user.id.length > 18
                    ? '${user.id.substring(0, 18)}...'
                    : user.id,
                copyableValue: user.id,
              ),
            ]),

            const SizedBox(height: 24),

            // Section 2: Preferences & System
            _buildSectionHeader(l10n.preferencesSystem),
            const SizedBox(height: 8),
            _buildCardContainer([
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        Icons.translate_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Language / भाषा',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'English • हिन्दी',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const LanguageSwitcherButton(isCompact: false),
                  ],
                ),
              ),
              Divider(color: AppColors.divider, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        size: 18,
                        color: isDark ? AppColors.sunAccent : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l10n.themeTitle} / थीम',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isDark ? l10n.themeDark : l10n.themeLight,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      key: const ValueKey('theme_mode_switch'),
                      value: isDark,
                      activeTrackColor: AppColors.primary,
                      onChanged: (_) {
                        ref.read(themeModeProvider.notifier).toggleTheme();
                      },
                    ),
                  ],
                ),
              ),
              Divider(color: AppColors.divider, height: 1),
              ProfileInfoTile(
                icon: Icons.verified_outlined,
                label: l10n.appVersion,
                value: '${AppConfig.appName} v${AppConfig.appVersion}',
              ),
            ]),

            const SizedBox(height: 24),

            // Section 3: Security & Session
            _buildSectionHeader(l10n.securitySession),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: InkWell(
                onTap: profileState.isLoggingOut
                    ? null
                    : () => _handleSignOut(context, ref),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.signOut,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.confirmSignOut,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (profileState.isLoggingOut)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.error,
                          ),
                        )
                      else
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.error,
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}
