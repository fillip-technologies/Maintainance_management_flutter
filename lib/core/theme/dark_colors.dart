import 'package:flutter/material.dart';

/// Dark mode color palette.
/// Easily customize shades and colors for dark theme in this file.
class AppDarkColors {
  AppDarkColors._();

  // Primary
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryBg = Color(0xFF1E293B);

  // Background & Surfaces
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B); // Slate 800
  static const Color card = Color(0xFF1E293B); // Slate 800
  static const Color cardAlt = Color(0xFF334155); // Slate 700
  static const Color cardShadow = Color(0x33000000);

  // Text
  static const Color textPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color textWhite = Color(0xFFFFFFFF);

  // Border
  static const Color border = Color(0xFF334155); // Slate 700
  static const Color borderLight = Color(0xFF1E293B);

  // Icons
  static const Color icon = Color(0xFF94A3B8);
  static const Color iconLight = Color(0xFF64748B);

  // Status Colors (Normal, Dark Backgrounds, Light Text)
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFF064E3B);
  static const Color successText = Color(0xFF4ADE80);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFF7F1D1D);
  static const Color errorText = Color(0xFFF87171);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFF78350F);
  static const Color warningText = Color(0xFFFBBF24);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF1E3A8A);
  static const Color infoText = Color(0xFF60A5FA);

  static const Color purple = Color(0xFFA855F7);
  static const Color purpleLight = Color(0xFF581C87);
  static const Color purpleText = Color(0xFFC084FC);

  static const Color orange = Color(0xFFF97316);
  static const Color orangeLight = Color(0xFF7C2D12);
  static const Color orangeText = Color(0xFFFB923C);

  static const Color neutral = Color(0xFF94A3B8);
  static const Color neutralLight = Color(0xFF334155);
  static const Color neutralText = Color(0xFFCBD5E1);

  // Social & Brand
  static const Color google = Color(0xFFEA4335);

  // Divider
  static const Color divider = Color(0xFF334155);

  // Transparent / Shading
  static const Color transparent = Colors.transparent;

  // Pure Neutrals & Common
  static const Color white = Color(0xFFFFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color black87 = Color(0xDD000000);
  static const Color black54 = Color(0x8A000000);
  static const Color grey = Color(0xFF64748B);

  // Status Card Backgrounds (Soft dark tints)
  static const Color statusSuccessBg = Color(0xFF064E3B);
  static const Color statusErrorBg = Color(0xFF450A0A);
  static const Color statusWarningBg = Color(0xFF451A03);
  static const Color statusPurpleBg = Color(0xFF3B0764);

  // Status Tag Backgrounds
  static const Color statusSuccessTagBg = Color(0xFF065F46);
  static const Color statusErrorTagBg = Color(0xFF7F1D1D);

  // Specific Status Variants
  static const Color statusWarningTextDark = Color(0xFFFBBF24);
  static const Color statusErrorTextDark = Color(0xFFFCA5A5);
  static const Color statusErrorBorder = Color(0xFFEF4444);

  // Additional Brand / Category Accents
  static const Color deepOrange = Color(0xFFFF7043);
  static const Color blueAccent = Color(0xFF60A5FA);
  static const Color brown = Color(0xFF8D6E63);

  // Component Specific
  static const Color trackBackground = Color(0xFF334155);
  static const Color snackbarBg = Color(0xF00F172A);
  static const Color sunAccent = Color(0xFFFACC15);
  static const Color overlayScrim = Color(0xF0000000);
  static const Color overlayScrimLight = Color(0xAA000000);

  // Gradients
  static const List<List<Color>> subzoneGradients = [
    [Color(0xFF3730A3), Color(0xFF0284C7)],
    [Color(0xFF5B21B6), Color(0xFF7C3AED)],
    [Color(0xFF065F46), Color(0xFF0D9488)],
    [Color(0xFF9F1239), Color(0xFFBE123C)],
    [Color(0xFF92400E), Color(0xFFB45309)],
    [Color(0xFF0369A1), Color(0xFF0284C7)],
  ];

  static const List<Color> gradientError = [
    Color(0xFFDC2626),
    Color(0xFF991B1B),
  ];

  static const List<Color> gradientWarning = [
    Color(0xFFD97706),
    Color(0xFFB45309),
  ];
}
