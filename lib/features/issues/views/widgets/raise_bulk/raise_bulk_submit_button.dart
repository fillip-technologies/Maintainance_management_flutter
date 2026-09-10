import 'package:flutter/material.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../l10n/app_localizations.dart';

class RaiseBulkSubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final int selectedCount;
  final VoidCallback? onSubmit;

  const RaiseBulkSubmitButton({
    super.key,
    required this.isSubmitting,
    required this.selectedCount,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: (isSubmitting || selectedCount == 0) ? null : onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.textWhite,
          elevation: 1,
          disabledBackgroundColor: AppColors.error.withValues(alpha: 0.4),
          disabledForegroundColor: AppColors.textWhite.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textWhite),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n?.submittingBulkDefect ?? 'Raising Defects...',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            : Text(
                selectedCount == 0
                    ? (l10n?.btnSelectUnitsFirst ?? 'Select Units Above to Report Defect')
                    : (l10n?.btnRaiseBulkDefect(selectedCount) ??
                        'Raise Defect Ticket on $selectedCount Unit(s)'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
