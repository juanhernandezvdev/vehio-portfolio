import 'package:flutter/material.dart';

class AppTheme {
  // Tema Claro adaptado con los colores de Vehio
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFFE50914),
    scaffoldBackgroundColor: const Color(0xFFF4F5F7),
    cardColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFE50914),
      secondary: Color(0xFF1E232B),
      surface: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  // Tema Oscuro adaptado con los colores de Vehio
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFE50914),
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E232B),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFE50914),
      secondary: Color(0xFFF4F5F7),
      surface: const Color(0xFF1E232B),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}