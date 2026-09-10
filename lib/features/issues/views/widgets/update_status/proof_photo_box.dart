import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../core/theme/colors.dart';

class ProofPhotoBox extends StatelessWidget {
  final File? resolutionImage;
  final bool isPickingImage;
  final VoidCallback onAddPhoto;
  final VoidCallback onRemovePhoto;

  const ProofPhotoBox({
    super.key,
    required this.resolutionImage,
    required this.isPickingImage,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Work Proof / Verification Photo (Optional)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        if (resolutionImage != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  resolutionImage!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: onRemovePhoto,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: AppColors.white, size: 18),
                  ),
                ),
              ),
            ],
          )
        else
          InkWell(
            onTap: isPickingImage ? null : onAddPhoto,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isPickingImage)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  else ...[
                    Icon(Icons.add_a_photo_outlined, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Add Proof Photo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
