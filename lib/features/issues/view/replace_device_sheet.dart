import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/device_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/models/device_model.dart';
import '../../../data/models/issue_model.dart';
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
  String? _selectedSpareDeviceId;

  final _notesController = TextEditingController();
  final _newDeviceNameController = TextEditingController();
  final _newDeviceSerialController = TextEditingController();

  File? _proofPhoto;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _notesController.text = 'Hardware physically damaged beyond repair. Removed from site mounting.';
  }

  @override
  void dispose() {
    _notesController.dispose();
    _newDeviceNameController.dispose();
    _newDeviceSerialController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _proofPhoto = File(picked.path));
      }
    } catch (e) {
      AppSnackbar.error('Failed to capture photo: $e');
    }
  }

  Future<void> _handleSubmit() async {
    final notes = _notesController.text.trim();
    if (notes.isEmpty) {
      AppSnackbar.warning('Please provide decommission notes explaining the removal.');
      return;
    }

    if (_replacementChoice == ReplacementChoice.inStock && _selectedSpareDeviceId == null) {
      AppSnackbar.warning('Please select an in-stock spare device.');
      return;
    }

    if (_replacementChoice == ReplacementChoice.newDevice &&
        _newDeviceNameController.text.trim().isEmpty) {
      AppSnackbar.warning('Please enter the name of the new replacement hardware.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onConfirm(
        reason: _selectedReason,
        notes: notes,
        replacementChoice: _replacementChoice,
        spareDeviceId: _selectedSpareDeviceId,
        newDeviceName: _newDeviceNameController.text.trim().isNotEmpty
            ? _newDeviceNameController.text.trim()
            : null,
        newDeviceSerial: _newDeviceSerialController.text.trim().isNotEmpty
            ? _newDeviceSerialController.text.trim()
            : null,
        proofPhoto: _proofPhoto,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      AppSnackbar.error('Failed to decommission hardware: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.92;
    final staffDevices = ref.watch(staffDevicesProvider).value ?? [];
    final inStockSpares = staffDevices.where((d) => d.status == DeviceStatus.provisioned || d.zoneName.toLowerCase().contains('stock')).toList();

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Title Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: AppColors.errorText, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.decommissionHeading ?? 'Decommission & Replace Equipment',
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
          const Divider(height: 20, color: AppColors.divider),

          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Decommission Notice Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.neutralLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.archive_outlined, size: 20, color: AppColors.neutralText),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'The current unit will be marked as ${l10n?.deviceStatusRetired ?? "Removed / Retired"}. Past service history remains preserved.',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section 1: Removal Reason
                  Text(
                    l10n?.decommissionReason ?? 'Reason for Removal',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildReasonChip(
                        DecommissionReason.physicalDamage,
                        l10n?.reasonPhysicalDamage ?? 'Physical Damage / Smashed',
                        Icons.broken_image_outlined,
                      ),
                      _buildReasonChip(
                        DecommissionReason.burntWater,
                        l10n?.reasonBurntWater ?? 'Burnt / Water Damage',
                        Icons.water_damage_outlined,
                      ),
                      _buildReasonChip(
                        DecommissionReason.unrepairable,
                        l10n?.reasonUnrepairable ?? 'Unrepairable Defect',
                        Icons.cancel_outlined,
                      ),
                      _buildReasonChip(
                        DecommissionReason.obsolete,
                        l10n?.reasonObsolete ?? 'Obsolete / Scrapped',
                        Icons.delete_sweep_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Section 2: Replacement Action Choice
                  Text(
                    l10n?.replacementOptions ?? 'Replacement Action',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),

                  _buildChoiceCard(
                    choice: ReplacementChoice.none,
                    title: l10n?.replacementOptionNone ?? 'Decommission Only (No Immediate Replacement)',
                    subtitle: 'Device is uninstalled from wall; location left vacant.',
                    icon: Icons.remove_circle_outline,
                  ),
                  const SizedBox(height: 8),

                  _buildChoiceCard(
                    choice: ReplacementChoice.newDevice,
                    title: l10n?.replacementOptionNew ?? 'Register & Install New Hardware',
                    subtitle: 'New box unpacked on-site. Enter serial number and model.',
                    icon: Icons.add_circle_outline,
                  ),

                  if (_replacementChoice == ReplacementChoice.newDevice) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _newDeviceNameController,
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'New Hardware Name *',
                              hintText: 'e.g. Hikvision Bullet 4K Camera 02',
                              filled: true,
                              fillColor: AppColors.surface,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _newDeviceSerialController,
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Serial Number / QR Code',
                              hintText: 'e.g. SN-HK-994201',
                              filled: true,
                              fillColor: AppColors.surface,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),
                  _buildChoiceCard(
                    choice: ReplacementChoice.inStock,
                    title: l10n?.replacementOptionSpares ?? 'Deploy Spare Unit from Stockroom',
                    subtitle: 'Assign an existing in-stock device to this slot.',
                    icon: Icons.inventory_2_outlined,
                  ),

                  if (_replacementChoice == ReplacementChoice.inStock) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: inStockSpares.isEmpty
                          ? const Text(
                              'No provisioned spare units found in stock. Use "Register & Install New Hardware" instead.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            )
                          : DropdownButtonFormField<String>(
                              initialValue: _selectedSpareDeviceId,
                              hint: const Text('Select In-Stock Spare', style: TextStyle(fontSize: 13)),
                              items: inStockSpares.map((d) {
                                return DropdownMenuItem<String>(
                                  value: d.id,
                                  child: Text('${d.name} (${d.hardwareTypeName})', style: const TextStyle(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedSpareDeviceId = val),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.surface,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Section 3: Photo Proof
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Damage Verification Photo (Optional)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      if (_proofPhoto != null)
                        TextButton(
                          onPressed: () => setState(() => _proofPhoto = null),
                          child: const Text('Remove', style: TextStyle(fontSize: 12, color: AppColors.error)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_proofPhoto != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_proofPhoto!, height: 140, width: double.infinity, fit: BoxFit.cover),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined, size: 16),
                            label: const Text('Take Photo', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined, size: 16),
                            label: const Text('Gallery', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 18),

                  // Section 4: Decommission Notes
                  const Text(
                    'Decommission Observations & Notes *',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Enter specific details about the physical removal...',
                      filled: true,
                      fillColor: AppColors.cardAlt,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(color: AppColors.textWhite, strokeWidth: 2),
                          )
                        : const Text(
                            'Confirm Decommission & Resolve Ticket',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonChip(DecommissionReason reason, String label, IconData icon) {
    final isSelected = _selectedReason == reason;
    return ChoiceChip(
      avatar: Icon(icon, size: 15, color: isSelected ? AppColors.textWhite : AppColors.primary),
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.cardAlt,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
      ),
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
      onSelected: (_) => setState(() => _selectedReason = reason),
    );
  }

  Widget _buildChoiceCard({
    required ReplacementChoice choice,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _replacementChoice == choice;
    return InkWell(
      onTap: () => setState(() => _replacementChoice = choice),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBg : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.icon, size: 20),
            const SizedBox(width: 10),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Radio<ReplacementChoice>(
              value: choice,
              groupValue: _replacementChoice,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) setState(() => _replacementChoice = val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
