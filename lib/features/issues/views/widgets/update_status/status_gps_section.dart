import 'package:flutter/material.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../location/location_helper.dart';
import '../../../models/issue_model.dart';

class StatusGpsSection extends StatelessWidget {
  final IssueStatus selectedStatus;
  final bool isFetchingLocation;
  final LocationResult? locationResult;
  final VoidCallback onRetryLocation;
  final VoidCallback onOpenLocationSettings;
  final VoidCallback onOpenAppSettings;

  const StatusGpsSection({
    super.key,
    required this.selectedStatus,
    required this.isFetchingLocation,
    required this.locationResult,
    required this.onRetryLocation,
    required this.onOpenLocationSettings,
    required this.onOpenAppSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isResolved = selectedStatus == IssueStatus.resolved;

    // State 1: Currently fetching GPS coordinates
    if (isFetchingLocation) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryBg.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isResolved
                    ? 'Acquiring GPS fix (required to resolve ticket)...'
                    : 'Acquiring GPS coordinates...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // State 2: GPS coordinates successfully acquired
    if (locationResult != null && locationResult!.isSuccess) {
      final lat = locationResult!.latitude!;
      final lng = locationResult!.longitude!;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on, size: 20, color: AppColors.success),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'GPS: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.successText,
                        ),
                      ),
                      if (isResolved) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Required ✓',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'On-site technician position recorded',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh, size: 18, color: AppColors.successText),
              tooltip: 'Re-acquire GPS',
              onPressed: onRetryLocation,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      );
    }

    // State 3: GPS missing & status is RESOLVED (MANDATORY REQUIREMENT)
    if (isResolved) {
      final errorType = locationResult?.error;
      final errorMsg = locationResult?.errorMessage;

      final (warningText, primaryBtnLabel, IconData primaryIcon, VoidCallback onPrimaryAction) =
          switch (errorType) {
        LocationErrorType.serviceDisabled => (
            'Location (GPS) is turned off on this device. You must turn on GPS to resolve this ticket.',
            'Open GPS Settings',
            Icons.location_on,
            onOpenLocationSettings,
          ),
        LocationErrorType.permissionDeniedForever => (
            'Location permission is permanently denied. Please enable location permissions in device Settings.',
            'Open App Settings',
            Icons.settings,
            onOpenAppSettings,
          ),
        LocationErrorType.permissionDenied => (
            'Location permission was denied. Location is mandatory to confirm on-site repair.',
            'Grant Permission',
            Icons.my_location,
            onRetryLocation,
          ),
        _ => (
            errorMsg ?? 'GPS coordinates are mandatory to mark an issue as Resolved.',
            'Turn On / Retry GPS',
            Icons.my_location,
            onRetryLocation,
          ),
      };

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.4), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_disabled_rounded, color: AppColors.errorText, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GPS Location Required to Resolve',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.errorText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        warningText,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: onPrimaryAction,
                  icon: Icon(primaryIcon, size: 14),
                  label: Text(
                    primaryBtnLabel,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.white,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    elevation: 0,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onRetryLocation,
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text(
                    'Retry',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorText,
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // State 4: GPS missing & status is NOT resolved (OPTIONAL)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.location_off_outlined, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'GPS location not acquired (optional for ${selectedStatus.label})',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetryLocation,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text(
              'Retry GPS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
