import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/auth.dart';

class ProfileHeaderCard extends StatelessWidget {
  final UserModel user;
  final String? zoneLogoUrl;

  const ProfileHeaderCard({
    super.key,
    required this.user,
    this.zoneLogoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isTech = user.role.isTechnician;
    final effectiveLogo = (zoneLogoUrl != null && zoneLogoUrl!.isNotEmpty)
        ? zoneLogoUrl
        : user.zoneLogoUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Large Avatar Icon
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: isTech
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.purpleLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: isTech ? AppColors.primary : AppColors.purple,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: (!isTech && effectiveLogo != null && effectiveLogo.isNotEmpty)
                  ? Image.network(
                      effectiveLogo,
                      fit: BoxFit.cover,
                      width: 76,
                      height: 76,
                      errorBuilder: (_, _, _) => Center(
                        child: Icon(
                          Icons.shield_outlined,
                          size: 38,
                          color: AppColors.purpleText,
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        isTech
                            ? Icons.engineering_outlined
                            : Icons.shield_outlined,
                        size: 38,
                        color: isTech
                            ? AppColors.primary
                            : AppColors.purpleText,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),

          // User Full Name
          Text(
            user.name.isNotEmpty
                ? user.name
                : (isTech ? 'Hardware Technician' : 'Zone Staff Member'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            user.email,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Role Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isTech ? AppColors.primaryBg : AppColors.purpleLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isTech ? AppColors.primary : AppColors.purple)
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isTech ? AppColors.primary : AppColors.purpleText,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isTech
                      ? l10n.roleHardwareTechnician
                      : l10n.roleZoneStaff,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isTech ? AppColors.primary : AppColors.purpleText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
