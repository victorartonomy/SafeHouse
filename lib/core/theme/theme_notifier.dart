import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeNotifier extends ValueNotifier<ThemeData> {
  final SharedPreferences _prefs;
  AppThemeMode _currentMode = AppThemeMode.dark;
  Color _currentAccentColor = AppColors.green;

  static const String _themeModeKey = 'theme_mode';
  static const String _accentColorKey = 'accent_color';

  ThemeNotifier({required SharedPreferences prefs})
    : _prefs = prefs,
      super(
        AppTheme.getTheme(
          mode: AppThemeMode.dark,
          accentColor: AppColors.green,
        ),
      ) {
    _loadTheme();
  }

  AppThemeMode get currentMode => _currentMode;
  Color get currentAccentColor => _currentAccentColor;

  void _loadTheme() {
    final modeString = _prefs.getString(_themeModeKey);
    if (modeString != null) {
      _currentMode = AppThemeMode.values.firstWhere(
        (e) => e.toString() == modeString,
        orElse: () => AppThemeMode.dark,
      );
    }

    final colorValue = _prefs.getInt(_accentColorKey);
    if (colorValue != null) {
      _currentAccentColor = Color(colorValue);
    }

    _updateTheme();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _currentMode = mode;
    await _prefs.setString(_themeModeKey, mode.toString());
    _updateTheme();
  }

  Future<void> setAccentColor(Color color) async {
    _currentAccentColor = color;
    await _prefs.setInt(_accentColorKey, color.toARGB32());
    _updateTheme();
  }

  void _updateTheme() {
    value = AppTheme.getTheme(
      mode: _currentMode,
      accentColor: _currentAccentColor,
    );
  }
}
