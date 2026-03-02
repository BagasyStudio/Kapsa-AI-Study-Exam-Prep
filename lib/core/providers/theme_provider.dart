import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'kapsa_theme_mode';

/// Provides the current [ThemeMode] for the app.
///
/// Persists the user's choice in SharedPreferences.
/// Defaults to [ThemeMode.system] on first launch.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system);

  /// Call once at startup with the saved preference value.
  void initialize(String? saved) {
    state = _fromString(saved);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, _toString(mode));
  }

  /// Read the saved preference value (call before ProviderScope).
  static Future<String?> readSavedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kThemeModeKey);
  }

  static ThemeMode _fromString(String? value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _toString(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}

/// Convenience extension for checking dark mode in widgets.
extension BrightnessContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
