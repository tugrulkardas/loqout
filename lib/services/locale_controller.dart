import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-app language preference: follow system, or force English / Turkish.
enum AppLanguagePreference { system, english, turkish }

/// Persisted locale preference for TapFocus.
class LocaleController extends ChangeNotifier {
  LocaleController._();

  static final LocaleController instance = LocaleController._();

  static const _prefsKey = 'tapfocus_language_pref_v1';

  AppLanguagePreference _preference = AppLanguagePreference.system;
  bool _loaded = false;

  AppLanguagePreference get preference => _preference;
  bool get isLoaded => _loaded;

  /// `null` = follow device language (MaterialApp default resolution).
  Locale? get materialLocale => switch (_preference) {
        AppLanguagePreference.system => null,
        AppLanguagePreference.english => const Locale('en'),
        AppLanguagePreference.turkish => const Locale('tr'),
      };

  IconData get preferenceIcon => switch (_preference) {
        AppLanguagePreference.system => Icons.language,
        AppLanguagePreference.english => Icons.translate,
        AppLanguagePreference.turkish => Icons.translate,
      };

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      _preference = switch (raw) {
        'en' => AppLanguagePreference.english,
        'tr' => AppLanguagePreference.turkish,
        'system' => AppLanguagePreference.system,
        _ => AppLanguagePreference.system,
      };
    } catch (_) {
      _preference = AppLanguagePreference.system;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setPreference(AppLanguagePreference preference) async {
    if (_preference == preference) return;
    _preference = preference;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final wire = switch (preference) {
        AppLanguagePreference.system => 'system',
        AppLanguagePreference.english => 'en',
        AppLanguagePreference.turkish => 'tr',
      };
      await prefs.setString(_prefsKey, wire);
    } catch (_) {}
  }
}
