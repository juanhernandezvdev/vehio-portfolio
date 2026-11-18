import 'package:flutter/material.dart';
import 'dart:ui';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}