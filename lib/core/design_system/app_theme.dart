import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Palette ────────────────────────────────────────────────────────────────
  static const Color background    = Color(0xFF0A0A0A);
  static const Color surfaceCard   = Color(0xFF1C1C1E);
  static const Color surfaceCard2  = Color(0xFF2C2C2E);
  static const Color primary       = Color(0xFF3478F6);
  static const Color onBackground  = Color(0xFFFFFFFF);
  static const Color onSurface     = Color(0xFFFFFFFF);
  static const Color onSurfaceSub  = Color(0xFF8E8E93);
  static const Color error         = Color(0xFFFF453A);
  static const Color success       = Color(0xFF30D158);
  static const Color primaryDark   = Color(0xFF0066CC);
  static const Color surface       = Color(0xFF1C1C1E);
  static const Color warning       = Color(0xFFFF9F0A);
  static const Color divider       = Color(0xFF38383A);
  // ── ThemeData ──────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          surface: surfaceCard,
          error: error,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: primary),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceCard,
          hintStyle: const TextStyle(color: onSurfaceSub),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: error, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}
