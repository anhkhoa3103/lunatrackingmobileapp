import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _pink = Color(0xFFE05D6F);

  // ── Text styles using Nunito ─────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.nunito(
    fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5);

  static TextStyle get displayMedium => GoogleFonts.nunito(
    fontSize: 24, fontWeight: FontWeight.w700);

  static TextStyle get headlineLarge => GoogleFonts.nunito(
    fontSize: 20, fontWeight: FontWeight.w600);

  static TextStyle get headlineMedium => GoogleFonts.nunito(
    fontSize: 18, fontWeight: FontWeight.w600);

  static TextStyle get headlineSmall => GoogleFonts.nunito(
    fontSize: 16, fontWeight: FontWeight.w600);

  static TextStyle get titleLarge => GoogleFonts.nunito(
    fontSize: 15, fontWeight: FontWeight.w500);

  static TextStyle get titleMedium => GoogleFonts.nunito(
    fontSize: 14, fontWeight: FontWeight.w500);

  static TextStyle get bodyLarge => GoogleFonts.nunito(
    fontSize: 14, fontWeight: FontWeight.w400);

  static TextStyle get bodyMedium => GoogleFonts.nunito(
    fontSize: 13, fontWeight: FontWeight.w400);

  static TextStyle get bodySmall => GoogleFonts.nunito(
    fontSize: 12, fontWeight: FontWeight.w400);

  static TextStyle get labelLarge => GoogleFonts.nunito(
    fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5);

  static TextStyle get labelSmall => GoogleFonts.nunito(
    fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.4);

  // ── Light Theme ──────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _pink,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    useMaterial3: true,

    // Apply Nunito to all text
    textTheme: GoogleFonts.nunitoTextTheme(
      ThemeData.light().textTheme,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey[800],
      elevation: 0,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.grey[800],
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _pink,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.nunito(
          fontSize: 15, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      hintStyle: GoogleFonts.nunito(
          fontSize: 14, color: Colors.grey[400]),
      labelStyle: GoogleFonts.nunito(fontSize: 14),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedLabelStyle: GoogleFonts.nunito(
          fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.nunito(fontSize: 10),
    ),

    chipTheme: ChipThemeData(
      labelStyle: GoogleFonts.nunito(fontSize: 13),
    ),
  );

  // ── Dark Theme ───────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _pink,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    useMaterial3: true,

    textTheme: GoogleFonts.nunitoTextTheme(
      ThemeData.dark().textTheme,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1A1A1A),
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),

    cardColor: const Color(0xFF2A2A2A),
    dividerColor: const Color(0xFF3A3A3A),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _pink,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.nunito(
            fontSize: 15, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );
}
