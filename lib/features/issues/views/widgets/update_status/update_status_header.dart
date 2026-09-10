import 'package:flutter/material.dart';
import '../../../../../core/theme/colors.dart';

class UpdateStatusHeader extends StatelessWidget {
  final String issueId;
  final VoidCallback onClose;

  const UpdateStatusHeader({
    super.key,
    required this.issueId,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              issueId.length > 8 ? '#${issueId.substring(0, 8)}' : '#$issueId',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Update Work Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: onClose,
          icon: Icon(Icons.close, color: AppColors.icon),
        ),
      ],
    );
  }
}
