import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'colors.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _prefKey = 'selected_theme_mode';

  @override
  ThemeMode build() {
    AppColors.isDark = false;
    _loadSavedThemeMode();
    return ThemeMode.light;
  }

  Future<void> _loadSavedThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_prefKey);
      if (savedMode == 'dark') {
        AppColors.isDark = true;
        state = ThemeMode.dark;
      } else if (savedMode == 'light') {
        AppColors.isDark = false;
        state = ThemeMode.light;
      }
    } catch (_) {
      // Default to Light on error
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    AppColors.isDark = (mode == ThemeMode.dark);
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = mode == ThemeMode.dark ? 'dark' : 'light';
      await prefs.setString(_prefKey, modeStr);
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    if (state == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
