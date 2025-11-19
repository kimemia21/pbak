import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // PBAK Color Palette inspired by pbak.co.ke
  static const Color primaryBlack = Color(0xFF0A0A0A);
  static const Color secondaryBlack = Color(0xFF1A1A1A);
  static const Color silverGrey = Color(0xFFC0C0C0);
  static const Color lightSilver = Color(0xFFE8E8E8);
  static const Color deepRed = Color(0xFFD32F2F);
  static const Color brightRed = Color(0xFFE53935);
  static const Color goldAccent = Color(0xFFFFD700);
  static const Color darkGold = Color(0xFFB8860B);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkGrey = Color(0xFF424242);
  static const Color mediumGrey = Color(0xFF757575);
  
  // Additional UI colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  
  // Spacing
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  
  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryBlack,
      secondary: deepRed,
      tertiary: goldAccent,
      surface: white,
      error: brightRed,
      onPrimary: white,
      onSecondary: white,
      onSurface: primaryBlack,
    ),
    scaffoldBackgroundColor: lightSilver,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryBlack,
      foregroundColor: white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: white,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: primaryBlack,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: primaryBlack,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: primaryBlack,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primaryBlack,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primaryBlack,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primaryBlack,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primaryBlack,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: primaryBlack,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: primaryBlack,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: primaryBlack,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: mediumGrey,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: white,
      ),
    ),
    cardTheme: CardThemeData(
      color: white,
      elevation: 2,
      shadowColor: primaryBlack.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusM),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlack,
        foregroundColor: white,
        padding: const EdgeInsets.symmetric(
          horizontal: paddingL,
          vertical: paddingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        elevation: 2,
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlack,
        side: const BorderSide(color: primaryBlack, width: 2),
        padding: const EdgeInsets.symmetric(
          horizontal: paddingL,
          vertical: paddingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: paddingM,
        vertical: paddingM,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: silverGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: silverGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: primaryBlack, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: brightRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: brightRed, width: 2),
      ),
      labelStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: mediumGrey,
      ),
      hintStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: mediumGrey,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: deepRed,
      foregroundColor: white,
      elevation: 4,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: white,
      selectedItemColor: deepRed,
      unselectedItemColor: mediumGrey,
      elevation: 8,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: goldAccent,
      secondary: deepRed,
      tertiary: silverGrey,
      surface: secondaryBlack,
      error: brightRed,
      onPrimary: primaryBlack,
      onSecondary: white,
      onSurface: white,
    ),
    scaffoldBackgroundColor: primaryBlack,
    appBarTheme: AppBarTheme(
      backgroundColor: secondaryBlack,
      foregroundColor: goldAccent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: goldAccent,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: white,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: white,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: white,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: white,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: white,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: white,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: white,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: silverGrey,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: white,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: silverGrey,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: mediumGrey,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primaryBlack,
      ),
    ),
    cardTheme: CardThemeData(
      color: secondaryBlack,
      elevation: 2,
      shadowColor: primaryBlack.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusM),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: goldAccent,
        foregroundColor: primaryBlack,
        padding: const EdgeInsets.symmetric(
          horizontal: paddingL,
          vertical: paddingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        elevation: 2,
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: goldAccent,
        side: const BorderSide(color: goldAccent, width: 2),
        padding: const EdgeInsets.symmetric(
          horizontal: paddingL,
          vertical: paddingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: secondaryBlack,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: paddingM,
        vertical: paddingM,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: darkGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: darkGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: goldAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: brightRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: brightRed, width: 2),
      ),
      labelStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: silverGrey,
      ),
      hintStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: mediumGrey,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: deepRed,
      foregroundColor: white,
      elevation: 4,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: secondaryBlack,
      selectedItemColor: goldAccent,
      unselectedItemColor: mediumGrey,
      elevation: 8,
    ),
  );
}
