import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../devices/devices.dart';
import '../../location/location_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../controllers/replace_device_controller.dart';
import '../controllers/replace_device_state.dart';
import '../models/issue_model.dart';
import 'widgets/replace_device/replace_device_action_selector.dart';
import 'widgets/replace_device/replace_device_header.dart';
import 'widgets/replace_device/replace_device_reason_grid.dart';
import 'widgets/replace_device/replace_device_submit_footer.dart';

export '../controllers/replace_device_state.dart' show DecommissionReason, ReplacementChoice;

/// Simplified, visual bottom sheet for field technicians to report damaged hardware
/// and optionally select an in-stock spare device from inventory.
/// Strictly localized: 100% English in English mode, 100% Hindi in Hindi mode (no mixed strings).
/// Features a pinned bottom submit button and bounded, scrollable spares list with instant search.
class ReplaceDeviceSheet extends ConsumerStatefulWidget {
  final IssueModel issue;
  final Future<void> Function({
    required DecommissionReason reason,
    required String notes,
    required ReplacementChoice replacementChoice,
    String? spareDeviceId,
    String? newDeviceName,
    String? newDeviceSerial,
    File? proofPhoto,
    double? latitude,
    double? longitude,
  }) onConfirm;

  const ReplaceDeviceSheet({
    super.key,
    required this.issue,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required IssueModel issue,
    required Future<void> Function({
      required DecommissionReason reason,
      required String notes,
      required ReplacementChoice replacementChoice,
      String? spareDeviceId,
      String? newDeviceName,
      String? newDeviceSerial,
      File? proofPhoto,
      double? latitude,
      double? longitude,
    }) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => ReplaceDeviceSheet(
        issue: issue,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  ConsumerState<ReplaceDeviceSheet> createState() => _ReplaceDeviceSheetState();
}

class _ReplaceDeviceSheetState extends ConsumerState<ReplaceDeviceSheet> {
  late final ReplaceDeviceController _controller;
  final _optionalNotesController = TextEditingController();
  final _searchController = TextEditingController();
  final _sparesScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = ReplaceDeviceController(
      onStateChanged: _onStateChanged,
    );
    _optionalNotesController.addListener(() {
      _controller.setNotes(_optionalNotesController.text);
    });
  }

  void _onStateChanged(ReplaceDeviceState state) {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _optionalNotesController.dispose();
    _searchController.dispose();
    _sparesScrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(AppLocalizations l10n) async {
    final state = _controller.state;
    if (state.replacementChoice == ReplacementChoice.inStock && state.selectedSpareDevice == null) {
      AppSnackbar.warning(l10n.selectSpareToProceed);
      return;
    }

    _controller.setSubmitting(true);

    double? lat;
    double? lng;
    final locRes = await LocationHelper().getLocation();
    if (!locRes.isSuccess) {
      if (mounted) {
        _controller.setSubmitting(false);
        AppSnackbar.error(
          locRes.errorMessage ??
              'GPS coordinates are required to decommission and resolve tickets. Please turn on GPS.',
        );
        if (locRes.error == LocationErrorType.serviceDisabled) {
          await LocationHelper().openLocationSettings();
        } else if (locRes.error == LocationErrorType.permissionDeniedForever) {
          await LocationHelper().openAppSettings();
        }
      }
      return;
    }
    lat = locRes.latitude;
    lng = locRes.longitude;

    final fullComment = ReplaceDeviceController.buildFullComment(
      reason: state.selectedReason,
      choice: state.replacementChoice,
      userNotes: _optionalNotesController.text,
      selectedSpare: state.selectedSpareDevice,
      l10n: l10n,
    );

    try {
      await widget.onConfirm(
        reason: state.selectedReason,
        notes: fullComment,
        replacementChoice: state.replacementChoice,
        spareDeviceId: state.selectedSpareDevice?.id,
        newDeviceName: state.selectedSpareDevice?.name,
        newDeviceSerial: state.selectedSpareDevice?.code,
        proofPhoto: null, // Camera proof disabled for now
        latitude: lat,
        longitude: lng,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      AppSnackbar.error('Failed to decommission: $e');
    } finally {
      if (mounted) {
        _controller.setSubmitting(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sparesAsync = ref.watch(availableSparesProvider);
    final state = _controller.state;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Sheet Header
            ReplaceDeviceHeader(
              issue: widget.issue,
              onClose: () => Navigator.pop(context),
            ),
            Divider(height: 18, color: AppColors.divider),

            // Scrollable Content Area
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Step 1: Reason / What happened?
                    ReplaceDeviceReasonGrid(
                      selectedReason: state.selectedReason,
                      onReasonSelected: _controller.setReason,
                    ),
                    const SizedBox(height: 22),

                    // Step 2: What action did you take?
                    ReplaceDeviceActionSelector(
                      replacementChoice: state.replacementChoice,
                      selectedSpareDevice: state.selectedSpareDevice,
                      sparesAsync: sparesAsync,
                      searchController: _searchController,
                      sparesScrollController: _sparesScrollController,
                      searchQuery: state.searchQuery,
                      onChoiceSelected: _controller.setReplacementChoice,
                      onSpareSelected: _controller.setSelectedSpareDevice,
                      onSearchChanged: (val) {
                        _controller.setSearchQuery(val.trim());
                      },
                      onClearSearch: () {
                        _searchController.clear();
                        _controller.setSearchQuery('');
                      },
                    ),

                    const SizedBox(height: 16),

                    // Optional technician notes field
                    TextField(
                      controller: _optionalNotesController,
                      style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: l10n.optionalNoteHint,
                        hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        prefixIcon: Icon(Icons.edit_note_rounded, size: 20, color: AppColors.icon),
                        filled: true,
                        fillColor: AppColors.cardAlt,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // PINNED BOTTOM SUBMIT BAR (ALWAYS VISIBLE)
            ReplaceDeviceSubmitFooter(
              isSubmitting: state.isSubmitting,
              onSubmit: () => _handleSubmit(l10n),
            ),
          ],
        ),
      ),
    );
  }
}
