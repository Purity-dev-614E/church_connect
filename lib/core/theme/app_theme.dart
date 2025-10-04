import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';

class AppTheme {
  // LIGHT THEME
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primaryColor, // Red
    scaffoldBackgroundColor: AppColors.backgroundColor, // White
    fontFamily: GoogleFonts.notoSans().fontFamily,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryColor,
      secondary: AppColors.secondaryColor,
      background: AppColors.backgroundColor,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: Colors.black,
      onSurface: Colors.black,
    ),

    // AppBar
    appBarTheme: AppBarTheme(
      color: AppColors.primaryColor,
      elevation: 4.0,
      titleTextStyle: TextStyles.heading2.copyWith(color: Colors.white),
      iconTheme: const IconThemeData(color: Colors.white),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        textStyle: TextStyles.buttonText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
    ),

    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.secondaryColor),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      labelStyle: TextStyles.bodyText.copyWith(color: AppColors.textColor),
    ),

    // Cards
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 4.0,
      shadowColor: AppColors.primaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // Text
    textTheme: TextTheme(
      displayLarge: TextStyles.heading1.copyWith(color: Colors.black),
      displayMedium: TextStyles.heading2.copyWith(color: Colors.black),
      bodyLarge: TextStyles.bodyText.copyWith(color: Colors.black87),
      bodyMedium: TextStyles.bodyText.copyWith(color: Colors.black87),
      labelLarge: TextStyles.buttonText.copyWith(color: Colors.white),
    ),

    tabBarTheme: const TabBarTheme(
      labelColor: Colors.white,               // active tab text
      unselectedLabelColor: Colors.white70,   // inactive tab text
      labelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 14,
      ),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: Colors.white, width: 2),
      ),
    ),
  );

  // DARK THEME
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryColor, // Red
    scaffoldBackgroundColor: Colors.black,
    fontFamily: GoogleFonts.notoSans().fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryColor,
      secondary: Colors.grey,
      background: Colors.black,
      surface: Color(0xFF1E1E1E), // Dark grey instead of pure black
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: Colors.white,
      onSurface: Colors.white70,
    ),

    // AppBar
    appBarTheme: AppBarTheme(
      color: AppColors.primaryColor,
      elevation: 4.0,
      titleTextStyle: TextStyles.heading2.copyWith(color: Colors.white),
      iconTheme: const IconThemeData(color: Colors.white),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        textStyle: TextStyles.buttonText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
    ),

    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF2C2C2C), // Dark grey background
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      labelStyle: TextStyles.bodyText.copyWith(color: Colors.white70),
    ),

    // Cards
    cardTheme: CardTheme(
      color: const Color(0xFF1E1E1E), // dark grey card
      elevation: 4.0,
      shadowColor: AppColors.primaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // Text
    textTheme: TextTheme(
      displayLarge: TextStyles.heading1.copyWith(color: Colors.white),
      displayMedium: TextStyles.heading2.copyWith(color: Colors.white),
      bodyLarge: TextStyles.bodyText.copyWith(color: Colors.white70),
      bodyMedium: TextStyles.bodyText.copyWith(color: Colors.white70),
      labelLarge: TextStyles.buttonText.copyWith(color: Colors.white),
    ),

    // inside darkTheme
    tabBarTheme: const TabBarTheme(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      labelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 14,
      ),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: Colors.white, width: 2),
      ),
    ),
  );


}
