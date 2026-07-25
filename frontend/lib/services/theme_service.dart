import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
class ThemeService extends ChangeNotifier {

  static final ThemeService instance =
  ThemeService._();

  ThemeService._();

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  Future<void> _saveTheme(String theme) async {

    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setString(
      'app_theme',
      theme,
    );

  }
  Future<void> loadTheme() async {

    final prefs =
    await SharedPreferences.getInstance();

    final savedTheme =
        prefs.getString('app_theme') ?? 'System';


    switch (savedTheme) {
      case 'Light':
        _themeMode = ThemeMode.light;
        break;

      case 'Dark':
        _themeMode = ThemeMode.dark;
        break;

      default:
        _themeMode = ThemeMode.system;
    }

    notifyListeners();
  }

  Future<void> setTheme(String theme) async {
    switch (theme) {

      case 'Light':
        _themeMode = ThemeMode.light;
        break;

      case 'Dark':
        _themeMode = ThemeMode.dark;
        break;

      default:
        _themeMode = ThemeMode.system;
    }

    await _saveTheme(theme);
    final prefs = await SharedPreferences.getInstance();
    print("Immediately after save: ${prefs.getString('app_theme')}");

    notifyListeners();
  }

}