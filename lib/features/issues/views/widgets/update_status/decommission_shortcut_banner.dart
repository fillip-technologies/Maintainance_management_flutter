import 'package:flutter/material.dart';
import '../../../../../core/theme/colors.dart';

class DecommissionShortcutBanner extends StatelessWidget {
  final VoidCallback onTap;

  const DecommissionShortcutBanner({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.broken_image_outlined, color: AppColors.errorText, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Equipment Destroyed / Smashed?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.errorText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap here to decommission & replace hardware',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.errorText, size: 18),
          ],
        ),
      ),
    );
  }
}
