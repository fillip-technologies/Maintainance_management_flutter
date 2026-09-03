import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../data/models/user_model.dart';
import '../../../l10n/app_localizations.dart';

class ProfileHeaderCard extends StatelessWidget {
  final UserModel user;

  const ProfileHeaderCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isTech = user.role.isTechnician;

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
            child: Icon(
              isTech ? Icons.engineering_outlined : Icons.shield_outlined,
              size: 38,
              color: isTech ? AppColors.primary : AppColors.purpleText,
            ),
          ),
          const SizedBox(height: 14),

          // User Full Name
          Text(
            user.name.isNotEmpty
                ? user.name
                : (isTech ? 'Hardware Technician' : 'Zone Staff Member'),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Email Address
          Text(
            user.email,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),

          // Badges: Role + Active Status
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isTech ? AppColors.primaryBg : AppColors.purpleLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isTech ? Icons.build_circle_outlined : Icons.location_on,
                      size: 13,
                      color: isTech ? AppColors.primary : AppColors.purpleText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isTech
                          ? l10n.roleHardwareTechnician
                          : l10n.roleZoneStaff,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isTech ? AppColors.primary : AppColors.purpleText,
                      ),
                    ),
                  ],
                ),
              ),

              // Active Account Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 13,
                      color: AppColors.successText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.activeStatus,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.successText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
