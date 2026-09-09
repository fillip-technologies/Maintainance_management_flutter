import 'package:flutter/material.dart';
import 'dark_colors.dart';

/// Light mode color palette values.
class AppLightColors {
  AppLightColors._();

  // Primary
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryBg = Color(0xFFEFF6FF);

  // Background & Surfaces
  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardAlt = Color(0xFFF8FAFC);
  static const Color cardShadow = Color(0x0A000000);
  static const Color sidebar = Color(0xFFF8FAFC);
  static const Color header = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1A1D29);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Border
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color borderHover = Color(0xFFCBD5E1);

  // Icons
  static const Color icon = Color(0xFF6B7280);
  static const Color iconLight = Color(0xFF9CA3AF);

  // Status Colors (Normal, Light Backgrounds, Dark Text)
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color successText = Color(0xFF15803D);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorText = Color(0xFFB91C1C);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningText = Color(0xFFB45309);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoText = Color(0xFF1D4ED8);

  static const Color purple = Color(0xFF9333EA);
  static const Color purpleLight = Color(0xFFF3E8FF);
  static const Color purpleText = Color(0xFF6B21A8);

  static const Color orange = Color(0xFFEA580C);
  static const Color orangeLight = Color(0xFFFFEDD5);
  static const Color orangeText = Color(0xFFC2410C);

  static const Color neutral = Color(0xFF6B7280);
  static const Color neutralLight = Color(0xFFF3F4F6);
  static const Color neutralText = Color(0xFF374151);

  // Social & Brand
  static const Color google = Color(0xFFDB4437);

  // Divider
  static const Color divider = Color(0xFFE5E7EB);

  // Transparent / Shading
  static const Color transparent = Colors.transparent;

  // Pure Neutrals & Common
  static const Color white = Color(0xFFFFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color black87 = Color(0xDD000000);
  static const Color black54 = Color(0x8A000000);
  static const Color grey = Color(0xFF9E9E9E);

  // Status Card Backgrounds (Soft tints)
  static const Color statusSuccessBg = Color(0xFFF0FDF4);
  static const Color statusErrorBg = Color(0xFFFEF2F2);
  static const Color statusWarningBg = Color(0xFFFFFBEB);
  static const Color statusPurpleBg = Color(0xFFFAF5FF);

  // Status Tag Backgrounds
  static const Color statusSuccessTagBg = Color(0xFFDCFCE7);
  static const Color statusErrorTagBg = Color(0xFFFEE2E2);

  // Specific Status Variants
  static const Color statusWarningTextDark = Color(0xFFD97706);
  static const Color statusErrorTextDark = Color(0xFF991B1B);
  static const Color statusErrorBorder = Color(0xFFF87171);

  // Additional Brand / Category Accents
  static const Color deepOrange = Color(0xFFFF5722);
  static const Color blueAccent = Color(0xFF448AFF);
  static const Color brown = Color(0xFF795548);

  // Component Specific
  static const Color trackBackground = Color(0xFFF1F5F9);
  static const Color snackbarBg = Color(0xE61E293B);
  static const Color sunAccent = Color(0xFFFACC15);
  static const Color overlayScrim = Color(0xDD000000);
  static const Color overlayScrimLight = Color(0x8A000000);

  // Gradients
  static const List<List<Color>> subzoneGradients = [
    [Color(0xFF4F46E5), Color(0xFF0EA5E9)],
    [Color(0xFF7C3AED), Color(0xFFA855F7)],
    [Color(0xFF059669), Color(0xFF14B8A6)],
    [Color(0xFFE11D48), Color(0xFFF43F5E)],
    [Color(0xFFD97706), Color(0xFFF59E0B)],
    [Color(0xFF0284C7), Color(0xFF38BDF8)],
  ];

  static const List<Color> gradientError = [
    Color(0xFFEF4444),
    Color(0xFFDC2626),
  ];

  static const List<Color> gradientWarning = [
    Color(0xFFF59E0B),
    Color(0xFFD97706),
  ];
}

/// Dynamic AppColors that automatically routes to either AppLightColors
/// or AppDarkColors depending on the currently active ThemeMode.
class AppColors {
  AppColors._();

  static bool isDark = false;

  // Primary
  static Color get primary => isDark ? AppDarkColors.primary : AppLightColors.primary;
  static Color get primaryDark => isDark ? AppDarkColors.primaryDark : AppLightColors.primaryDark;
  static Color get primaryLight => isDark ? AppDarkColors.primaryLight : AppLightColors.primaryLight;
  static Color get primaryBg => isDark ? AppDarkColors.primaryBg : AppLightColors.primaryBg;

  // Background & Surfaces
  static Color get background => isDark ? AppDarkColors.background : AppLightColors.background;
  static Color get surface => isDark ? AppDarkColors.surface : AppLightColors.surface;
  static Color get card => isDark ? AppDarkColors.card : AppLightColors.card;
  static Color get cardAlt => isDark ? AppDarkColors.cardAlt : AppLightColors.cardAlt;
  static Color get cardShadow => isDark ? AppDarkColors.cardShadow : AppLightColors.cardShadow;
  static Color get sidebar => isDark ? AppDarkColors.sidebar : AppLightColors.sidebar;
  static Color get header => isDark ? AppDarkColors.header : AppLightColors.header;

  // Text
  static Color get textPrimary => isDark ? AppDarkColors.textPrimary : AppLightColors.textPrimary;
  static Color get textSecondary => isDark ? AppDarkColors.textSecondary : AppLightColors.textSecondary;
  static Color get textMuted => isDark ? AppDarkColors.textMuted : AppLightColors.textMuted;
  static Color get textWhite => isDark ? AppDarkColors.textWhite : AppLightColors.textWhite;

  // Border
  static Color get border => isDark ? AppDarkColors.border : AppLightColors.border;
  static Color get borderLight => isDark ? AppDarkColors.borderLight : AppLightColors.borderLight;
  static Color get borderHover => isDark ? AppDarkColors.borderHover : AppLightColors.borderHover;

  // Icons
  static Color get icon => isDark ? AppDarkColors.icon : AppLightColors.icon;
  static Color get iconLight => isDark ? AppDarkColors.iconLight : AppLightColors.iconLight;

  // Status Colors (Normal, Light Backgrounds, Dark Text)
  static Color get success => isDark ? AppDarkColors.success : AppLightColors.success;
  static Color get successLight => isDark ? AppDarkColors.successLight : AppLightColors.successLight;
  static Color get successText => isDark ? AppDarkColors.successText : AppLightColors.successText;

  static Color get error => isDark ? AppDarkColors.error : AppLightColors.error;
  static Color get errorLight => isDark ? AppDarkColors.errorLight : AppLightColors.errorLight;
  static Color get errorText => isDark ? AppDarkColors.errorText : AppLightColors.errorText;

  static Color get warning => isDark ? AppDarkColors.warning : AppLightColors.warning;
  static Color get warningLight => isDark ? AppDarkColors.warningLight : AppLightColors.warningLight;
  static Color get warningText => isDark ? AppDarkColors.warningText : AppLightColors.warningText;

  static Color get info => isDark ? AppDarkColors.info : AppLightColors.info;
  static Color get infoLight => isDark ? AppDarkColors.infoLight : AppLightColors.infoLight;
  static Color get infoText => isDark ? AppDarkColors.infoText : AppLightColors.infoText;

  static Color get purple => isDark ? AppDarkColors.purple : AppLightColors.purple;
  static Color get purpleLight => isDark ? AppDarkColors.purpleLight : AppLightColors.purpleLight;
  static Color get purpleText => isDark ? AppDarkColors.purpleText : AppLightColors.purpleText;

  static Color get orange => isDark ? AppDarkColors.orange : AppLightColors.orange;
  static Color get orangeLight => isDark ? AppDarkColors.orangeLight : AppLightColors.orangeLight;
  static Color get orangeText => isDark ? AppDarkColors.orangeText : AppLightColors.orangeText;

  static Color get neutral => isDark ? AppDarkColors.neutral : AppLightColors.neutral;
  static Color get neutralLight => isDark ? AppDarkColors.neutralLight : AppLightColors.neutralLight;
  static Color get neutralText => isDark ? AppDarkColors.neutralText : AppLightColors.neutralText;

  // Social & Brand
  static Color get google => AppLightColors.google;

  // Divider
  static Color get divider => isDark ? AppDarkColors.divider : AppLightColors.divider;

  // Transparent / Shading
  static const Color transparent = Colors.transparent;

  // Pure Neutrals & Common
  static Color get white => isDark ? AppDarkColors.white : AppLightColors.white;
  static Color get white70 => isDark ? AppDarkColors.white70 : AppLightColors.white70;
  static Color get black => isDark ? AppDarkColors.black : AppLightColors.black;
  static Color get black87 => isDark ? AppDarkColors.black87 : AppLightColors.black87;
  static Color get black54 => isDark ? AppDarkColors.black54 : AppLightColors.black54;
  static Color get grey => isDark ? AppDarkColors.grey : AppLightColors.grey;

  // Status Card Backgrounds
  static Color get statusSuccessBg => isDark ? AppDarkColors.statusSuccessBg : AppLightColors.statusSuccessBg;
  static Color get statusErrorBg => isDark ? AppDarkColors.statusErrorBg : AppLightColors.statusErrorBg;
  static Color get statusWarningBg => isDark ? AppDarkColors.statusWarningBg : AppLightColors.statusWarningBg;
  static Color get statusPurpleBg => isDark ? AppDarkColors.statusPurpleBg : AppLightColors.statusPurpleBg;

  // Status Tag Backgrounds
  static Color get statusSuccessTagBg => isDark ? AppDarkColors.statusSuccessTagBg : AppLightColors.statusSuccessTagBg;
  static Color get statusErrorTagBg => isDark ? AppDarkColors.statusErrorTagBg : AppLightColors.statusErrorTagBg;

  // Specific Status Variants
  static Color get statusWarningTextDark => isDark ? AppDarkColors.statusWarningTextDark : AppLightColors.statusWarningTextDark;
  static Color get statusErrorTextDark => isDark ? AppDarkColors.statusErrorTextDark : AppLightColors.statusErrorTextDark;
  static Color get statusErrorBorder => isDark ? AppDarkColors.statusErrorBorder : AppLightColors.statusErrorBorder;

  // Additional Brand / Category Accents
  static Color get deepOrange => isDark ? AppDarkColors.deepOrange : AppLightColors.deepOrange;
  static Color get blueAccent => isDark ? AppDarkColors.blueAccent : AppLightColors.blueAccent;
  static Color get brown => isDark ? AppDarkColors.brown : AppLightColors.brown;

  // Component Specific
  static Color get trackBackground => isDark ? AppDarkColors.trackBackground : AppLightColors.trackBackground;
  static Color get snackbarBg => isDark ? AppDarkColors.snackbarBg : AppLightColors.snackbarBg;
  static Color get sunAccent => isDark ? AppDarkColors.sunAccent : AppLightColors.sunAccent;
  static Color get overlayScrim => isDark ? AppDarkColors.overlayScrim : AppLightColors.overlayScrim;
  static Color get overlayScrimLight => isDark ? AppDarkColors.overlayScrimLight : AppLightColors.overlayScrimLight;

  // Gradients
  static List<List<Color>> get subzoneGradients => isDark ? AppDarkColors.subzoneGradients : AppLightColors.subzoneGradients;
  static List<Color> get gradientError => isDark ? AppDarkColors.gradientError : AppLightColors.gradientError;
  static List<Color> get gradientWarning => isDark ? AppDarkColors.gradientWarning : AppLightColors.gradientWarning;

  // --------------------------------------------------
  // THEME
  // --------------------------------------------------

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppLightColors.primary,
        brightness: Brightness.light,
        primary: AppLightColors.primary,
        surface: AppLightColors.surface,
        error: AppLightColors.error,
      ),

      scaffoldBackgroundColor: AppLightColors.background,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppLightColors.surface,
        foregroundColor: AppLightColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),

      // Text
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppLightColors.textPrimary),
        displayMedium: TextStyle(color: AppLightColors.textPrimary),
        displaySmall: TextStyle(color: AppLightColors.textPrimary),
        headlineLarge: TextStyle(color: AppLightColors.textPrimary),
        headlineMedium: TextStyle(color: AppLightColors.textPrimary),
        headlineSmall: TextStyle(color: AppLightColors.textPrimary),
        titleLarge: TextStyle(color: AppLightColors.textPrimary),
        titleMedium: TextStyle(color: AppLightColors.textPrimary),
        titleSmall: TextStyle(color: AppLightColors.textSecondary),
        bodyLarge: TextStyle(color: AppLightColors.textPrimary),
        bodyMedium: TextStyle(color: AppLightColors.textSecondary),
        bodySmall: TextStyle(color: AppLightColors.textSecondary),
      ),

      // TextFields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppLightColors.surface,

        labelStyle: const TextStyle(color: AppLightColors.textSecondary),
        hintStyle: const TextStyle(color: AppLightColors.textMuted),

        prefixIconColor: AppLightColors.icon,
        suffixIconColor: AppLightColors.icon,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppLightColors.border),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppLightColors.primary, width: 1.5),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppLightColors.error),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppLightColors.error, width: 1.5),
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppLightColors.primary,
          foregroundColor: AppLightColors.textWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppLightColors.surface,
          foregroundColor: AppLightColors.textPrimary,
          side: const BorderSide(color: AppLightColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppLightColors.primary),
      ),

      // Divider
      dividerTheme: const DividerThemeData(color: AppLightColors.divider, thickness: 1),

      // Icons
      iconTheme: const IconThemeData(color: AppLightColors.icon),
    );
  }
}
