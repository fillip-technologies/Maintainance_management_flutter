import 'package:flutter/material.dart';
import 'colors.dart';
import 'dark_colors.dart';

class AppTheme {
  AppTheme._();

  /// Light theme definition (default).
  static ThemeData get light => AppColors.theme;

  /// Dark theme definition based on AppDarkColors.
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppDarkColors.primary,
        brightness: Brightness.dark,
        primary: AppDarkColors.primary,
        surface: AppDarkColors.surface,
        error: AppDarkColors.error,
      ),

      scaffoldBackgroundColor: AppDarkColors.background,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppDarkColors.surface,
        foregroundColor: AppDarkColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),

      // Text
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppDarkColors.textPrimary),
        displayMedium: TextStyle(color: AppDarkColors.textPrimary),
        displaySmall: TextStyle(color: AppDarkColors.textPrimary),
        headlineLarge: TextStyle(color: AppDarkColors.textPrimary),
        headlineMedium: TextStyle(color: AppDarkColors.textPrimary),
        headlineSmall: TextStyle(color: AppDarkColors.textPrimary),
        titleLarge: TextStyle(color: AppDarkColors.textPrimary),
        titleMedium: TextStyle(color: AppDarkColors.textPrimary),
        titleSmall: TextStyle(color: AppDarkColors.textSecondary),
        bodyLarge: TextStyle(color: AppDarkColors.textPrimary),
        bodyMedium: TextStyle(color: AppDarkColors.textSecondary),
        bodySmall: TextStyle(color: AppDarkColors.textSecondary),
      ),

      // TextFields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppDarkColors.surface,

        labelStyle: const TextStyle(color: AppDarkColors.textSecondary),
        hintStyle: const TextStyle(color: AppDarkColors.textMuted),

        prefixIconColor: AppDarkColors.icon,
        suffixIconColor: AppDarkColors.icon,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppDarkColors.border),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppDarkColors.primary, width: 1.5),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppDarkColors.error),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppDarkColors.error, width: 1.5),
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppDarkColors.primary,
          foregroundColor: AppDarkColors.textWhite,
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
          backgroundColor: AppDarkColors.surface,
          foregroundColor: AppDarkColors.textPrimary,
          side: const BorderSide(color: AppDarkColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppDarkColors.primary),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppDarkColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppDarkColors.border),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(color: AppDarkColors.divider, thickness: 1),

      // Icons
      iconTheme: const IconThemeData(color: AppDarkColors.icon),
    );
  }
}
