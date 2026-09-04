import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

class CustomPasswordField extends StatefulWidget {
  final TextInputType keyboardType;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const CustomPasswordField({
    super.key,
    this.keyboardType = TextInputType.visiblePassword,
    required this.labelText,
    required this.hintText,
    this.prefixIcon = Icons.lock_outline,
    this.controller,
    this.onChanged,
  });

  @override
  State<CustomPasswordField> createState() => _CustomPasswordFieldState();
}

class _CustomPasswordFieldState extends State<CustomPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: _obscureText,
      onChanged: widget.onChanged,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: Icon(widget.prefixIcon, color: AppColors.icon),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
          icon: Icon(
            _obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: AppColors.icon,
          ),
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
