import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SuperAdminTheme {
  // Theme: Amber Vorcas Tech Lab (Deep Black #000000 & Vibrant Orange #f48c25)
  static const Color primaryOrange = Color(0xFFF48C25);
  static const Color backgroundBlack = Color(0xFF000000);
  static const Color surfaceCard = Color(0xFF161618); // Slightly lighter than black for cards
  static const Color surfaceLighter = Color(0xFF222225);
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0A5);

  static const Color statusPositive = Color(0xFF4CAF50);
  static const Color statusNegative = Color(0xFFF44336);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryOrange,
      scaffoldBackgroundColor: backgroundBlack,
      cardColor: surfaceCard,
      colorScheme: const ColorScheme.dark(
        primary: primaryOrange,
        secondary: primaryOrange,
        surface: surfaceCard,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
        titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: textPrimary),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textSecondary),
        labelSmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary, letterSpacing: 0.5),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundBlack,
        selectedItemColor: primaryOrange,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundBlack,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
