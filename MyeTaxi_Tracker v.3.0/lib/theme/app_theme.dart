import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Core Colors
  static const Color bg = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF111827);
  static const Color card = Color(0xFF1A2235);
  static const Color border = Color(0xFF1E2D45);
  static const Color accent = Color(0xFF00D4FF);
  static const Color accentGlow = Color(0x2600D4FF);
  static const Color green = Color(0xFF00E676);
  static const Color orange = Color(0xFFFF9100);
  static const Color red = Color(0xFFFF3D71);
  static const Color yellow = Color(0xFFFFD600);
  static const Color textPrimary = Color(0xFFE8EFF8);
  static const Color textMuted = Color(0xFF5A7A9A);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: green,
        error: red,
        surface: surface,
        background: bg,
      ),
      textTheme: GoogleFonts.rajdhaniTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textMuted),
          labelLarge: TextStyle(color: accent, fontWeight: FontWeight.w700),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0D1520),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: const TextStyle(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class AppTextStyles {
  static TextStyle get monoLarge => const TextStyle(
    fontFamily: 'monospace',
    color: AppTheme.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get monoMedium => const TextStyle(
    fontFamily: 'monospace',
    color: AppTheme.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get label => const TextStyle(
    color: AppTheme.textMuted,
    fontSize: 11,
    letterSpacing: 1.2,
    fontWeight: FontWeight.w500,
  );
}
