import 'package:flutter/material.dart';
import '../theme/colors.dart';

class AppSnackbar {
  /// Global ScaffoldMessengerKey attached to MaterialApp.
  /// Allows displaying snackbars from anywhere (notifiers, repositories, async tasks)
  /// without requiring a BuildContext.
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void show({
    required String message,
    String? title,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final state = messengerKey.currentState;
    if (state == null) return;

    state.clearSnackBars();
    state.showSnackBar(
      SnackBar(
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: backgroundColor ?? AppColors.textPrimary,
        duration: duration,
        action: action,
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor ?? AppColors.textWhite, size: 22),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textColor ?? AppColors.textWhite,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: title != null ? FontWeight.normal : FontWeight.w500,
                      color: textColor ?? AppColors.textWhite,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Success SnackBar (Green)
  static void success(String message, {String? title, Duration? duration}) {
    show(
      message: message,
      title: title,
      icon: Icons.check_circle_rounded,
      backgroundColor: AppColors.successText,
      textColor: AppColors.textWhite,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Error SnackBar (Red)
  static void error(String message, {String? title, Duration? duration}) {
    show(
      message: message,
      title: title,
      icon: Icons.error_outline_rounded,
      backgroundColor: AppColors.errorText,
      textColor: AppColors.textWhite,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  /// Warning SnackBar (Orange / Warning)
  static void warning(String message, {String? title, Duration? duration}) {
    show(
      message: message,
      title: title,
      icon: Icons.warning_amber_rounded,
      backgroundColor: AppColors.warning,
      textColor: AppColors.textWhite,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Info SnackBar (Primary Blue)
  static void info(String message, {String? title, Duration? duration}) {
    show(
      message: message,
      title: title,
      icon: Icons.info_outline_rounded,
      backgroundColor: AppColors.primary,
      textColor: AppColors.textWhite,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Hide any active SnackBar immediately
  static void hide() {
    messengerKey.currentState?.clearSnackBars();
  }
}
