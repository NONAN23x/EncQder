import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({
    ThemeMode initialMode = ThemeMode.system,
    SharedPreferencesAsync? preferences,
  }) : _themeMode = initialMode,
       _preferences = preferences ?? SharedPreferencesAsync();

  static const _preferenceKey = 'theme_mode';

  final SharedPreferencesAsync _preferences;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  static Future<ThemeController> load({
    SharedPreferencesAsync? preferences,
  }) async {
    final prefs = preferences ?? SharedPreferencesAsync();
    final stored = await prefs.getString(_preferenceKey);
    return ThemeController(
      initialMode: switch (stored) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      preferences: prefs,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _preferences.setString(_preferenceKey, mode.name);
  }
}
