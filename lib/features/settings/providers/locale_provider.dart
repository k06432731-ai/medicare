import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_provider.dart';

const _kLocale = 'app_locale';

class LocaleNotifier extends StateNotifier<Locale> {
  final SharedPreferences _prefs;

  LocaleNotifier(SharedPreferences prefs)
      : _prefs = prefs,
        super(Locale(prefs.getString(_kLocale) ?? 'fr'));

  Future<void> setLocale(Locale locale) async {
    await _prefs.setString(_kLocale, locale.languageCode);
    state = locale;
  }

  /// Available app locales
  static const supported = [
    Locale('fr'), // Français (default)
    Locale('ar'), // العربية
  ];

  static String labelOf(Locale locale) => switch (locale.languageCode) {
        'ar' => 'العربية',
        _ => 'Français',
      };
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});
