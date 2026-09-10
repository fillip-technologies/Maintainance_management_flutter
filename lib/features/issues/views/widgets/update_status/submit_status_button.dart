import 'package:flutter/material.dart';
import 'package:equipment_management_system/core/theme/colors.dart';
import 'package:equipment_management_system/features/issues/models/issue_model.dart';

class SubmitStatusButton extends StatelessWidget {
  final bool isSubmitting;
  final IssueStatus selectedStatus;
  final bool hasValidGps;
  final VoidCallback? onSubmit;

  const SubmitStatusButton({
    super.key,
    required this.isSubmitting,
    required this.selectedStatus,
    required this.hasValidGps,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isSubmitting ? null : onSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: selectedStatus == IssueStatus.resolved && !hasValidGps
            ? AppColors.error
            : AppColors.primary,
        foregroundColor: AppColors.textWhite,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: isSubmitting
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Updating status...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ],
            )
          : Text(
              selectedStatus == IssueStatus.resolved && !hasValidGps
                  ? 'Resolve Ticket (Turn On GPS)'
                  : 'Confirm & Transition to ${selectedStatus.label}',
            ),
    );
  }
}
