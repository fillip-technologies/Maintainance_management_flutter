import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/storage_service.dart';

class LocaleNotifier extends Notifier<Locale> {
  static const _prefKey = 'selected_language_code';

  @override
  Locale build() {
    _loadSavedLocale();
    return const Locale('en');
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null && (savedCode == 'en' || savedCode == 'hi')) {
        state = Locale(savedCode);
      }
    } catch (_) {
      // Default to English on error
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (state.languageCode == newLocale.languageCode) return;
    state = newLocale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, newLocale.languageCode);
    } catch (_) {}
  }

  void toggleLanguage() {
    if (state.languageCode == 'en') {
      setLocale(const Locale('hi'));
    } else {
      setLocale(const Locale('en'));
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
