import 'package:flutter/material.dart';

/// Deep midnight blue + soft amber — tuned for a bedtime radio app.
class AppTheme {
  AppTheme._();

  static const Color _midnight = Color(0xFF0A1628);
  static const Color _surface = Color(0xFF0D2137);
  static const Color _amber = Color(0xFFE8B86D);
  static const Color _amberMuted = Color(0xFFC9A26A);

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _amber,
      onPrimary: _midnight,
      secondary: _amberMuted,
      onSecondary: _midnight,
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      surface: _surface,
      onSurface: Color(0xFFE7ECF2),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: _midnight,
      appBarTheme: const AppBarTheme(
        backgroundColor: _midnight,
        foregroundColor: Color(0xFFE7ECF2),
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface.withValues(alpha: 0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A3F5A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _amber, width: 1.2),
        ),
        labelStyle: const TextStyle(color: Color(0xFFB0BEC5)),
        hintStyle: const TextStyle(color: Color(0xFF7A8A99)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _surface,
        labelStyle: const TextStyle(color: Color(0xFFE7ECF2)),
        side: const BorderSide(color: Color(0xFF2A3F5A)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        selectedColor: _amber.withValues(alpha: 0.2),
        checkmarkColor: _amber,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _amber,
          foregroundColor: _midnight,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
