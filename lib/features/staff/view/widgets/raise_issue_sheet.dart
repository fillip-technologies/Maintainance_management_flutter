import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/colors.dart';
import '../../../../data/models/device_model.dart';
import '../../../../data/models/issue_model.dart';

class RaiseIssueSheet extends StatefulWidget {
  final List<DeviceModel> devices;
  final DeviceModel? initialDevice;
  final Function(IssueModel newIssue) onIssueCreated;

  const RaiseIssueSheet({
    super.key,
    required this.devices,
    this.initialDevice,
    required this.onIssueCreated,
  });

  static Future<void> show(
    BuildContext context, {
    required List<DeviceModel> devices,
    DeviceModel? initialDevice,
    required Function(IssueModel newIssue) onIssueCreated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => RaiseIssueSheet(
        devices: devices,
        initialDevice: initialDevice,
        onIssueCreated: onIssueCreated,
      ),
    );
  }

  @override
  State<RaiseIssueSheet> createState() => _RaiseIssueSheetState();
}

class _RaiseIssueSheetState extends State<RaiseIssueSheet> {
  DeviceModel? _selectedDevice;
  String? _selectedCategory;
  IssuePriority _selectedPriority = IssuePriority.medium;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _attachedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isPickingImage = false;
  String? _errorMessage;

  final List<String> _categories = [
    'Video Loss / No Signal',
    'PTZ Motor & Rotation Stuck',
    'Physical Lens Obstruction / Dirt',
    'Night Vision / IR Illuminator Failure',
    'Power Fluctuation / PoE Drop',
    'Water Ingress / Enclosure Condensation',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDevice = widget.initialDevice;
    if (widget.initialDevice != null) {
      _titleController.text = '${widget.initialDevice!.name} Fault';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // Close source selection bottom sheet
    setState(() => _isPickingImage = true);

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _attachedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorText,
            content: Text(
              'Failed to capture image: $e',
              style: const TextStyle(color: AppColors.textWhite),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  void _showImageSourceModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Attach Device Photo',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Take a picture of the faulty equipment or pick from gallery',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSourceOption(
                  icon: Icons.camera_alt_rounded,
                  iconColor: AppColors.primary,
                  iconBgColor: AppColors.primaryBg,
                  title: 'Take a Photo (Camera)',
                  subtitle: 'Open camera to capture device fault',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                const SizedBox(height: 10),
                _buildSourceOption(
                  icon: Icons.photo_library_rounded,
                  iconColor: AppColors.purple,
                  iconBgColor: AppColors.purpleLight,
                  title: 'Choose from Gallery',
                  subtitle: 'Select an existing photo from library',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.iconLight, size: 20),
          ],
        ),
      ),
    );
  }

  void _submitIssue() {
    if (_selectedDevice == null) {
      setState(() => _errorMessage = 'Please select a device');
      return;
    }
    if (_selectedCategory == null) {
      setState(() => _errorMessage = 'Please select a fault category');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a summary title');
      return;
    }

    final newIssue = IssueModel(
      id: 'ISSUE-${1000 + DateTime.now().millisecond}',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      deviceId: _selectedDevice!.id,
      deviceName: _selectedDevice!.name,
      zoneId: _selectedDevice!.zoneId,
      zoneName: _selectedDevice!.zoneName,
      categoryId: 'cat-01',
      categoryName: _selectedCategory!,
      priority: _selectedPriority,
      status: IssueStatus.open,
      createdByUserId: 'usr-staff-001',
      createdByUserName: 'Sarah Connor (Staff)',
      imagePath: _attachedImage?.path,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      history: [
        IssueStatusHistoryModel(
          id: 'hist-${DateTime.now().millisecondsSinceEpoch}',
          issueId: 'ISSUE-NEW',
          fromStatus: null,
          toStatus: IssueStatus.open,
          changedByUserId: 'usr-staff-001',
          changedByUserName: 'Sarah Connor',
          comment: _attachedImage != null
              ? 'Reported by staff with attached photo'
              : 'Reported by zone staff',
          createdAt: DateTime.now(),
        ),
      ],
    );

    widget.onIssueCreated(newIssue);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.successText,
        content: Text(
          'Maintenance issue raised successfully!',
          style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.report_problem_outlined, color: AppColors.error, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Raise Maintenance Issue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.icon),
                ),
              ],
            ),

            const Divider(color: AppColors.divider),
            const SizedBox(height: 12),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 13, color: AppColors.errorText),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 1. Device Picker
            const Text(
              'Select Device',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<DeviceModel>(
                  value: _selectedDevice != null
                      ? widget.devices.where((d) => d.id == _selectedDevice!.id).firstOrNull
                      : null,
                  hint: const Text('Choose device to report...', style: TextStyle(color: AppColors.textMuted)),
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  items: widget.devices.map((d) {
                    return DropdownMenuItem(
                      value: d,
                      child: Text(
                        '${d.name} (${d.zoneName})',
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedDevice = val;
                      if (val != null && _titleController.text.isEmpty) {
                        _titleController.text = '${val.name} Issue';
                      }
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 2. Fault Category
            const Text(
              'Fault Category',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  hint: const Text('Select fault type...', style: TextStyle(color: AppColors.textMuted)),
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  items: _categories.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text(
                        c,
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 3. Priority Selector
            const Text(
              'Priority Level',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: IssuePriority.values.map((p) {
                final isSelected = _selectedPriority == p;
                final bg = isSelected
                    ? (p == IssuePriority.critical ? AppColors.errorText : AppColors.primary)
                    : AppColors.surface;
                final textCol = isSelected ? AppColors.textWhite : AppColors.textSecondary;
                final borderCol = isSelected ? AppColors.transparent : AppColors.border;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => setState(() => _selectedPriority = p),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderCol),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          p.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textCol,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            // 4. Issue Summary
            const Text(
              'Issue Summary',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Brief summary of the issue...',
              ),
            ),

            const SizedBox(height: 14),

            // 5. Description
            const Text(
              'Detailed Description / Observations',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Describe symptoms, errors, physical damage...',
              ),
            ),

            const SizedBox(height: 14),

            // 6. Camera / Device Photo Section
            const Text(
              'Attach Device Photo (Optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),

            if (_isPickingImage)
              Container(
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.cardAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_attachedImage != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cardAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _attachedImage!,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle, color: AppColors.success, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Photo Attached',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _attachedImage!.path.split('/').last,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _showImageSourceModal,
                            child: const Text(
                              'Change Photo',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () => setState(() => _attachedImage = null),
                      tooltip: 'Remove photo',
                    ),
                  ],
                ),
              )
            else
              InkWell(
                onTap: _showImageSourceModal,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.border,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Take Photo or Upload (Camera / Gallery)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 22),

            // Submit Button
            ElevatedButton(
              onPressed: _submitIssue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
              ),
              child: const Text('Submit Maintenance Ticket'),
            ),
          ],
        ),
      ),
    );
  }
}
