import 'package:flutter/material.dart';
import 'package:primo_secreto_app/preferences/preferences_service.dart';

class ThemeProvider extends ChangeNotifier {
  final PreferencesService _preferencesService = PreferencesService();

  bool isDarkMode = false;

  ThemeProvider() {
    _load();
  }

  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> _load() async {
    isDarkMode = await _preferencesService.getIsDarkMode();
    notifyListeners();
  }

  Future<void> toggle() async {
    isDarkMode = !isDarkMode;
    notifyListeners();
    await _preferencesService.setIsDarkMode(isDarkMode);
  }
}
