import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

/// Shown on an issue whose replacement request is awaiting admin approval —
/// the ticket can't be resolved or closed until the request is reviewed.
class AwaitingReplacementBanner extends StatelessWidget {
  final String message;
  final bool compact;

  const AwaitingReplacementBanner({super.key, required this.message, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 8 : 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_top_rounded, size: compact ? 16 : 18, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
