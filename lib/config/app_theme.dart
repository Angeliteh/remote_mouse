import 'package:flutter/material.dart';

class AppTheme {
  // Colores principales
  static const Color primaryColor = Color(0xFF6C5CE7); // Morado claro
  static const Color secondaryColor = Color(0xFF5E72EB); // Azul medio
  static const Color tertiaryColor = Color(0xFF4834DF); // Morado oscuro
  static const Color surfaceColor = Color(0xFF262A43); // Azul oscuro
  static const Color backgroundColor = Color(0xFF191A2E); // Azul muy oscuro casi negro
  static const Color errorColor = Colors.redAccent;

  // Obtener tema de la aplicación
  static ThemeData getTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor, 
        tertiary: tertiaryColor,
        surface: surfaceColor,
        background: backgroundColor,
      ),
      useMaterial3: true,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondaryColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: secondaryColor, width: 2),
        ),
      ),
    );
  }
} 