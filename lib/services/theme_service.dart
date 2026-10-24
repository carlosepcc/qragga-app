import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _keySeedColor = 'qragga_theme_seed';
  static const String _keyThemeMode = 'qragga_theme_mode';

  Color _seedColor = const Color(0xFF6750A4);
  ThemeMode _themeMode = ThemeMode.system;

  Color get seedColor => _seedColor;
  ThemeMode get themeMode => _themeMode;

  static final List<Color> presetColors = [
    const Color(0xFF6750A4), // Material Deep Purple (Default)
    const Color(0xFF006A6A), // Teal
    const Color(0xFF0061A4), // Blue
    const Color(0xFF386A20), // Forest Green
    const Color(0xFF984061), // Berry
    const Color(0xFF904A1D), // Terracotta
    const Color(0xFF5A5F41), // Olive
    const Color(0xFF1E293B), // Slate / Midnight
  ];

  ThemeService() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedColor = prefs.getInt(_keySeedColor);
    if (savedColor != null) {
      _seedColor = Color(savedColor);
    }
    final savedMode = prefs.getString(_keyThemeMode);
    if (savedMode == 'light') {
      _themeMode = ThemeMode.light;
    } else if (savedMode == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setSeedColor(Color color) async {
    _seedColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySeedColor, color.value);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    await prefs.setString(_keyThemeMode, modeStr);
  }
}
