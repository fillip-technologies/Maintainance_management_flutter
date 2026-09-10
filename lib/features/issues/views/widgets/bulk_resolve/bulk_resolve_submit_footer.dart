import 'package:flutter/material.dart';
import 'package:equipment_management_system/core/theme/colors.dart';
import 'package:equipment_management_system/features/issues/models/issue_model.dart';
import 'package:equipment_management_system/l10n/app_localizations.dart';

class BulkResolveSubmitFooter extends StatelessWidget {
  final IssueStatus targetStatus;
  final int selectedCount;
  final bool isSubmitting;
  final VoidCallback? onSubmit;

  const BulkResolveSubmitFooter({
    super.key,
    required this.targetStatus,
    required this.selectedCount,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (targetStatus == IssueStatus.resolved) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, size: 13, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'GPS coordinates required on device to resolve',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.successText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isSubmitting || selectedCount == 0 ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: targetStatus == IssueStatus.resolved
                      ? AppColors.success
                      : (targetStatus == IssueStatus.onHold
                          ? AppColors.warning
                          : AppColors.primary),
                  foregroundColor: AppColors.textWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            targetStatus == IssueStatus.resolved
                                ? Icons.task_alt_rounded
                                : (targetStatus == IssueStatus.onHold
                                    ? Icons.pause_circle_outline
                                    : Icons.play_circle_outline),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n?.btnApplyStatusToTickets(
                                  targetStatus.label,
                                  selectedCount,
                                ) ??
                                'Apply ${targetStatus.label} to $selectedCount Ticket(s)',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
