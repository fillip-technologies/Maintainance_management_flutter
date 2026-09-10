import 'package:flutter/material.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../l10n/app_localizations.dart';

class ReplaceDeviceSubmitFooter extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback? onSubmit;

  const ReplaceDeviceSubmitFooter({
    super.key,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            offset: const Offset(0, -3),
            blurRadius: 8,
          ),
        ],
      ),
      child: SizedBox(
        height: 54,
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: isSubmitting ? null : onSubmit,
          icon: isSubmitting
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                )
              : const Icon(Icons.check_circle_rounded, size: 22),
          label: Text(
            isSubmitting ? l10n.submittingDecommission : l10n.btnSubmitAndClose,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: AppColors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
