import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../l10n/app_localizations.dart';
import '../../location/location_helper.dart';
import '../models/issue_model.dart';
import '../models/replacement_request_model.dart';
import '../viewmodels/issue_action_viewmodel.dart';
import '../viewmodels/issue_query_viewmodel.dart';
import 'replace_device_sheet.dart';

/// Approval-gated equipment replacement.
///
/// 1. Technician files a request ([startReplacementRequest]) — nothing is
///    resolved yet; the org head / super admin are notified.
/// 2. An admin approves (or rejects) it from the web dashboard.
/// 3. Once approved the technician carries it out
///    ([completeApprovedReplacement]), which resolves the ticket.

String _choiceValue(ReplacementChoice choice) => switch (choice) {
      ReplacementChoice.inStock => 'in_stock',
      ReplacementChoice.newDevice => 'new_device',
      ReplacementChoice.none => 'none',
    };

/// Opens the replace sheet and submits the result as a replacement REQUEST.
Future<void> startReplacementRequest(
  BuildContext context,
  WidgetRef ref,
  IssueModel issue,
) {
  final l10n = AppLocalizations.of(context)!;
  final actions = ref.read(issueActionControllerProvider.notifier);

  return ReplaceDeviceSheet.show(
    context,
    issue: issue,
    onConfirm: ({
      required reason,
      required notes,
      required replacementChoice,
      spareDeviceId,
      newDeviceName,
      newDeviceSerial,
      proofPhoto,
      latitude,
      longitude,
    }) async {
      await actions.requestReplacement(
        issueId: issue.id,
        reason: reason.value,
        replacementChoice: _choiceValue(replacementChoice),
        spareDeviceId: spareDeviceId,
        newDeviceName: newDeviceName,
        notes: notes,
      );
      AppSnackbar.success(l10n.replacementRequestSubmitted);
    },
  );
}

/// Executes an approved replacement (captures GPS, then resolves the ticket).
/// Returns true when the replacement was completed.
Future<bool> completeApprovedReplacement(
  BuildContext context,
  WidgetRef ref,
  IssueModel issue,
  ReplacementRequestModel request,
) async {
  final l10n = AppLocalizations.of(context)!;
  final actions = ref.read(issueActionControllerProvider.notifier);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.replacementCompleteTitle),
      content: Text(l10n.replacementCompleteBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.btnCancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.btnConfirm)),
      ],
    ),
  );
  if (confirmed != true) return false;

  final helper = LocationHelper();
  final loc = await helper.getLocation();
  if (!loc.isSuccess) {
    AppSnackbar.error(
      loc.errorMessage ??
          'GPS coordinates are required to complete a replacement. Please turn on GPS.',
    );
    if (loc.error == LocationErrorType.serviceDisabled) {
      await helper.openLocationSettings();
    } else if (loc.error == LocationErrorType.permissionDeniedForever) {
      await helper.openAppSettings();
    }
    return false;
  }

  try {
    await actions.completeReplacement(
      issueId: issue.id,
      requestId: request.id,
      latitude: loc.latitude,
      longitude: loc.longitude,
    );
    AppSnackbar.success(l10n.replacementSuccess);
    return true;
  } catch (e) {
    AppSnackbar.error('Failed to complete replacement: $e');
    return false;
  }
}

/// Single entry point for every "replace equipment" affordance: does the right
/// thing for the issue's current request state.
Future<void> handleReplacementAction(
  BuildContext context,
  WidgetRef ref,
  IssueModel issue,
) async {
  final l10n = AppLocalizations.of(context)!;
  ReplacementRequestModel? existing;
  try {
    existing = await ref.read(replacementRequestForIssueProvider(issue.id).future);
  } catch (e) {
    AppSnackbar.error('$e');
    return;
  }
  if (!context.mounted) return;

  if (existing != null && existing.isPending) {
    AppSnackbar.info(l10n.replacementAwaitingApproval);
  } else if (existing != null && existing.isApproved) {
    await completeApprovedReplacement(context, ref, issue, existing);
  } else {
    await startReplacementRequest(context, ref, issue);
  }
}
