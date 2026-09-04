import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// =========================================================================
// CAMERA PROOF CAPTURE (COMMENTED OUT FOR NOW - WILL BE ENABLED IN FUTURE)
// import 'package:image_picker/image_picker.dart';
// =========================================================================
import '../../devices/devices.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../models/issue_model.dart';
import '../../../l10n/app_localizations.dart';

enum DecommissionReason {
  physicalDamage('physical_damage'),
  burntWater('burnt_water'),
  unrepairable('unrepairable'),
  obsolete('obsolete');

  final String value;
  const DecommissionReason(this.value);
}

enum ReplacementChoice {
  inStock,
  newDevice,
  none,
}

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
    }) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
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
  DecommissionReason _selectedReason = DecommissionReason.physicalDamage;
  ReplacementChoice _replacementChoice = ReplacementChoice.none;
  DeviceModel? _selectedSpareDevice;

  final _optionalNotesController = TextEditingController();
  final _searchController = TextEditingController();
  final _sparesScrollController = ScrollController();
  String _searchQuery = '';
  bool _isSubmitting = false;

  // =========================================================================
  // CAMERA PROOF CAPTURE (COMMENTED OUT FOR NOW - WILL BE ENABLED IN FUTURE)
  // =========================================================================
  // File? _proofPhoto;
  // final ImagePicker _picker = ImagePicker();
  // Future<void> _pickImage(ImageSource source) async {
  //   try {
  //     final XFile? picked = await _picker.pickImage(
  //       source: source,
  //       maxWidth: 1800,
  //       maxHeight: 1800,
  //       imageQuality: 85,
  //     );
  //     if (picked != null) {
  //       setState(() => _proofPhoto = File(picked.path));
  //     }
  //   } catch (e) {
  //     AppSnackbar.error('Failed to capture photo: $e');
  //   }
  // }
  // =========================================================================

  @override
  void dispose() {
    _optionalNotesController.dispose();
    _searchController.dispose();
    _sparesScrollController.dispose();
    super.dispose();
  }

  String _getReasonLabel(DecommissionReason reason, AppLocalizations l10n) {
    return switch (reason) {
      DecommissionReason.physicalDamage => l10n.reasonPhysicalDamage,
      DecommissionReason.burntWater => l10n.reasonBurntWater,
      DecommissionReason.unrepairable => l10n.reasonUnrepairable,
      DecommissionReason.obsolete => l10n.reasonObsolete,
    };
  }

  Future<void> _handleSubmit(AppLocalizations l10n) async {
    if (_replacementChoice == ReplacementChoice.inStock && _selectedSpareDevice == null) {
      AppSnackbar.warning(l10n.selectSpareToProceed);
      return;
    }

    setState(() => _isSubmitting = true);

    final reasonText = _getReasonLabel(_selectedReason, l10n);
    final userNotes = _optionalNotesController.text.trim();
    final baseNote = userNotes.isNotEmpty ? '$reasonText. $userNotes' : reasonText;

    final replacementText = switch (_replacementChoice) {
      ReplacementChoice.inStock => 'Installed in-stock spare unit: ${_selectedSpareDevice?.name} (${_selectedSpareDevice?.code.isNotEmpty == true ? _selectedSpareDevice?.code : _selectedSpareDevice?.id}).',
      ReplacementChoice.newDevice => 'Installed new hardware unit.',
      ReplacementChoice.none => 'No replacement installed; slot left vacant.',
    };

    final fullComment = '[HARDWARE DECOMMISSIONED - ${_selectedReason.name.toUpperCase()}] $baseNote. $replacementText';

    try {
      await widget.onConfirm(
        reason: _selectedReason,
        notes: fullComment,
        replacementChoice: _replacementChoice,
        spareDeviceId: _selectedSpareDevice?.id,
        newDeviceName: _selectedSpareDevice?.name,
        newDeviceSerial: _selectedSpareDevice?.code,
        proofPhoto: null, // Camera proof disabled for now
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      AppSnackbar.error('Failed to decommission: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sparesAsync = ref.watch(availableSparesProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.broken_image_rounded, color: AppColors.errorText, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.decommissionHeading,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          '${widget.issue.deviceName} • ${widget.issue.zoneName}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.icon),
                  ),
                ],
              ),
            ),
            const Divider(height: 18, color: AppColors.divider),

            // Scrollable Content Area
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Step 1: Reason / What happened?
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Text('1', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.stepWhatHappened,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 2x2 Pictorial Tiles
                    Row(
                      children: [
                        Expanded(
                          child: _buildPictorialTile(
                            reason: DecommissionReason.physicalDamage,
                            icon: Icons.hardware_rounded,
                            iconColor: Colors.deepOrange,
                            iconBgColor: Colors.deepOrange.withValues(alpha: 0.12),
                            label: l10n.reasonPhysicalDamage,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPictorialTile(
                            reason: DecommissionReason.burntWater,
                            icon: Icons.water_drop_rounded,
                            iconColor: Colors.blueAccent,
                            iconBgColor: Colors.blueAccent.withValues(alpha: 0.12),
                            label: l10n.reasonBurntWater,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPictorialTile(
                            reason: DecommissionReason.unrepairable,
                            icon: Icons.cancel_rounded,
                            iconColor: AppColors.error,
                            iconBgColor: AppColors.errorLight,
                            label: l10n.reasonUnrepairable,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPictorialTile(
                            reason: DecommissionReason.obsolete,
                            icon: Icons.delete_sweep_rounded,
                            iconColor: Colors.brown,
                            iconBgColor: Colors.brown.withValues(alpha: 0.12),
                            label: l10n.reasonObsolete,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Step 2: What action did you take?
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Text('2', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.stepWhatDidYouDo,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Choice 1: Removed only (slot left empty)
                    _buildActionCard(
                      isSelected: _replacementChoice == ReplacementChoice.none,
                      onTap: () => setState(() {
                        _replacementChoice = ReplacementChoice.none;
                        _selectedSpareDevice = null;
                      }),
                      icon: Icons.remove_circle_outline_rounded,
                      iconColor: AppColors.error,
                      title: l10n.actionRemovedOnly,
                      subtitle: l10n.actionRemovedOnlySub,
                    ),
                    const SizedBox(height: 10),

                    // Choice 2: Replaced with Spare from Inventory
                    _buildActionCard(
                      isSelected: _replacementChoice == ReplacementChoice.inStock,
                      onTap: () => setState(() {
                        _replacementChoice = ReplacementChoice.inStock;
                      }),
                      icon: Icons.inventory_2_outlined,
                      iconColor: AppColors.success,
                      title: l10n.actionReplacedFromStock,
                      subtitle: l10n.actionReplacedFromStockSub,
                    ),

                    // Expandable Inventory Spares List
                    if (_replacementChoice == ReplacementChoice.inStock) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.cardAlt,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            sparesAsync.when(
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              error: (err, _) => Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  '$err',
                                  style: const TextStyle(fontSize: 12, color: AppColors.errorText),
                                ),
                              ),
                              data: (spares) {
                                if (spares.isEmpty) {
                                  return Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.info_outline, size: 20, color: AppColors.icon),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            l10n.noSparesAvailable,
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                final filteredSpares = _searchQuery.isEmpty
                                    ? spares
                                    : spares.where((s) {
                                        final q = _searchQuery.toLowerCase();
                                        return s.name.toLowerCase().contains(q) ||
                                            s.code.toLowerCase().contains(q) ||
                                            s.hardwareTypeName.toLowerCase().contains(q);
                                      }).toList();

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.shelves, size: 18, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${l10n.availableSparesHeading} (${spares.length})',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      l10n.selectSparePrompt,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 10),

                                    // Search Bar if more than 3 spares
                                    if (spares.length > 3) ...[
                                      TextField(
                                        controller: _searchController,
                                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                        decoration: InputDecoration(
                                          hintText: l10n.searchSparesHint,
                                          hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.icon),
                                          suffixIcon: _searchQuery.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.clear, size: 16),
                                                  onPressed: () {
                                                    _searchController.clear();
                                                    setState(() => _searchQuery = '');
                                                  },
                                                )
                                              : null,
                                          filled: true,
                                          fillColor: AppColors.surface,
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: AppColors.border),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: AppColors.border),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],

                                    // Bounded Scrollable Spares List Box (Max Height: 220px)
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxHeight: 220),
                                      child: Scrollbar(
                                        thumbVisibility: true,
                                        controller: _sparesScrollController,
                                        child: ListView.separated(
                                          controller: _sparesScrollController,
                                          shrinkWrap: true,
                                          itemCount: filteredSpares.length,
                                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                                          itemBuilder: (context, index) {
                                            final spare = filteredSpares[index];
                                            final isSelected = _selectedSpareDevice?.id == spare.id;

                                            return InkWell(
                                              onTap: () => setState(() => _selectedSpareDevice = spare),
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: isSelected ? AppColors.primaryBg : AppColors.surface,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: isSelected ? AppColors.primary : AppColors.border,
                                                    width: isSelected ? 2.0 : 1.0,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: BoxDecoration(
                                                        color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.cardAlt,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Icon(
                                                        HardwareIconHelper.getIcon(spare.categoryName.isNotEmpty ? spare.categoryName : spare.name),
                                                        color: isSelected ? AppColors.primary : AppColors.icon,
                                                        size: 22,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            spare.name,
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.bold,
                                                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            '${l10n.hardwareCode}: ${spare.code.isNotEmpty ? spare.code : "N/A"}',
                                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    if (isSelected)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.primary,
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          l10n.selectedSpareBadge,
                                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Optional technician notes field
                    TextField(
                      controller: _optionalNotesController,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: l10n.optionalNoteHint,
                        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.edit_note_rounded, size: 20, color: AppColors.icon),
                        filled: true,
                        fillColor: AppColors.cardAlt,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // PINNED BOTTOM SUBMIT BAR (ALWAYS VISIBLE)
            Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(top: BorderSide(color: AppColors.divider)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : () => _handleSubmit(l10n),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 22),
                  label: Text(
                    _isSubmitting ? l10n.submittingDecommission : l10n.btnSubmitAndClose,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPictorialTile({
    required DecommissionReason reason,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
  }) {
    final isSelected = _selectedReason == reason;

    return InkWell(
      onTap: () => setState(() => _selectedReason = reason),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBg : AppColors.cardAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2.2 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBg : AppColors.cardAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : iconColor, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.8) : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
