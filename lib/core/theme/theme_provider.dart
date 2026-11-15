import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistence key for the stored theme mode.
const String _kThemeModeKey = 'forma_theme_mode';

/// Riverpod provider for the [ThemeModeNotifier].
///
/// Usage:
/// ```dart
/// final mode = ref.watch(themeModeProvider);
/// ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
/// ```
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Manages app-wide [ThemeMode] and persists the user's choice via
/// [SharedPreferences].
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadSavedTheme();
  }

  /// Loads the previously saved theme preference from disk.
  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kThemeModeKey);
    if (stored != null) {
      state = _parseThemeMode(stored);
    }
  }

  /// Sets the theme mode and persists it.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, mode.name);
  }

  /// Cycles through system → light → dark → system.
  Future<void> toggleTheme() async {
    final next = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    await setThemeMode(next);
  }

  /// Whether the theme is currently in dark mode (accounting for system
  /// brightness when the mode is [ThemeMode.system]).
  bool isDark(BuildContext context) {
    if (state == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return state == ThemeMode.dark;
  }

  static ThemeMode _parseThemeMode(String value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}
