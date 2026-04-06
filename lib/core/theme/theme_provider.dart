import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

enum AppThemeMode { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'user_theme_preference';
  final SharedPreferences _prefs;
  AppThemeMode _appThemeMode = AppThemeMode.system;

  ThemeProvider(this._prefs) {
    _loadTheme();
  }

  AppThemeMode get appThemeMode => _appThemeMode;

  ThemeMode get themeMode {
    switch (_appThemeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  void _loadTheme() {
    final themeString = _prefs.getString(_themeKey);
    if (themeString != null) {
      try {
        _appThemeMode = AppThemeMode.values.firstWhere(
          (e) => e.toString() == themeString,
        );
      } catch (_) {
        _appThemeMode = AppThemeMode.system;
      }
    }
    notifyListeners();
  }

  bool isDarkMode(BuildContext context) {
    if (_appThemeMode == AppThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _appThemeMode == AppThemeMode.dark;
  }

  ThemeData getThemeData(BuildContext context) {
    return isDarkMode(context) ? AppTheme.darkTheme : AppTheme.lightTheme;
  }

  Future<void> setTheme(AppThemeMode mode) async {
    _appThemeMode = mode;
    await _prefs.setString(_themeKey, mode.toString());
    notifyListeners();
  }
}

