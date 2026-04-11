import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = "isDarkMode";
  bool _isDarkMode = true;

  ThemeService() {
    _loadTheme();
  }

  bool get isDarkMode => _isDarkMode;

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint("ThemeService _loadTheme error: $e");
    }
  }

  Future<void> toggleDarkMode(bool isDark) async {
    try {
      _isDarkMode = isDark;
      notifyListeners(); // Notify immediately for UI responsiveness
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, isDark);
    } catch (e) {
      debugPrint("ThemeService toggleDarkMode error: $e");
    }
  }
}
