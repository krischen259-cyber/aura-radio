import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Stitch 「Night FM」浅色渐变与 Material 调色盘映射。
abstract final class NightFmColors {
  static const primary = Color(0xFF4B626C);
  static const onSurface = Color(0xFF191C1A);
  static const onSurfaceVariant = Color(0xFF42474B);
  static const outlineVariant = Color(0xFFC2C7CB);
  static const surface = Color(0xFFF8FAF6);
  static const surfaceBright = Color(0xFFF8FAF6);
  static const primaryFixed = Color(0xFFCEE6F3);
  static const secondaryFixed = Color(0xFFD6E7DA);
  static const tertiary = Color(0xFF5F5F59);
  static const onPrimaryContainer = Color(0xFF536974);
  static const error = Color(0xFFBA1A1A);
}

ThemeData nightFmTheme() {
  const baseScheme = ColorScheme.light(
    primary: NightFmColors.primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFD1E9F6),
    onPrimaryContainer: NightFmColors.onPrimaryContainer,
    secondary: Color(0xFF536258),
    onSecondary: Colors.white,
    surface: NightFmColors.surface,
    onSurface: NightFmColors.onSurface,
    error: NightFmColors.error,
    onError: Colors.white,
    outline: Color(0xFF73787B),
    outlineVariant: NightFmColors.outlineVariant,
  );

  final textTheme = GoogleFonts.manropeTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: baseScheme,
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.white.withValues(alpha: 0.55),
      foregroundColor: NightFmColors.primary,
      titleTextStyle: GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
        color: NightFmColors.onSurface,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.35),
      selectedColor: Colors.white.withValues(alpha: 0.65),
      labelStyle: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.6,
        color: NightFmColors.onSurfaceVariant.withValues(alpha: 0.75),
      ),
      secondaryLabelStyle: GoogleFonts.manrope(fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: NightFmColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle:
            GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.55),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
            color: NightFmColors.outlineVariant.withValues(alpha: 0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: NightFmColors.primary, width: 1.4),
      ),
      hintStyle: GoogleFonts.manrope(
        color: NightFmColors.onSurfaceVariant.withValues(alpha: 0.55),
        fontSize: 14,
      ),
    ),
  );
}
