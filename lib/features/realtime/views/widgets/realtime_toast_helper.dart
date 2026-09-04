import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../issues/issues.dart';

class RealtimeToastHelper {
  static void showNewIssueToast(
    BuildContext context, {
    required IssueModel issue,
    required VoidCallback onTap,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 10, left: 16, right: 16, bottom: 20),
        backgroundColor: AppColors.surface,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.errorText, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'New Defect Ticket',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      StatusBadge.priority(issue.priority),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${issue.deviceName} • ${issue.zoneName}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                messenger.hideCurrentSnackBar();
                onTap();
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primaryBg,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  static void showSimpleToast(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.info_outline,
    Color iconColor = AppColors.primary,
    VoidCallback? onTap,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 10, left: 16, right: 16, bottom: 20),
        backgroundColor: AppColors.surface,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  onTap();
                },
                child: const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
