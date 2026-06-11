import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Corporate "Happiness & Premium Wellness" Palette
  static const Color primaryBlue = Color(0xFF004A99);
  static const Color secondaryDeepNavy = Color(0xFF003366);
  static const Color lightGreyScaffold = Color(0xFFF2F7FB);
  static const Color accentGold = Color(0xFFD4AF37);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textLight = Color(0xFF757575);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: secondaryDeepNavy,
        surface: Colors.white,
        surfaceContainerLowest: lightGreyScaffold,
      ),
      scaffoldBackgroundColor: lightGreyScaffold,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          color: textDark,
          fontWeight: FontWeight.w700,
          fontSize: 32,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          color: textDark,
          fontWeight: FontWeight.w600,
          fontSize: 24,
        ),
        bodyLarge: GoogleFonts.inter(color: textDark, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: textLight, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.pressed)) {
              return secondaryDeepNavy;
            } else if (states.contains(WidgetState.disabled)) {
              return Colors.grey.shade400;
            }
            return primaryBlue; // Default state
          }),
          foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
          elevation: WidgetStateProperty.resolveWith<double>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.pressed)) {
              return 0;
            }
            return 4;
          }),
          padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
