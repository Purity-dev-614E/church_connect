import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primaryColor,
      hintColor: AppColors.accentColor,
      scaffoldBackgroundColor: AppColors.backgroundColor,
      fontFamily: GoogleFonts.notoSans().fontFamily,

      //appBar Theme
      appBarTheme: AppBarTheme(
        color: AppColors.primaryColor,
        elevation: 4.0,
        titleTextStyle: TextStyles.heading2.copyWith(color: Colors.white),
      ),

      //button theme
      buttonTheme: ButtonThemeData(
        buttonColor: AppColors.buttonColor,
        textTheme: ButtonTextTheme.primary,
      ),

      //floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.primaryColor
      ),

      textTheme: TextTheme(
        displayLarge: TextStyles.heading1,
        displayMedium: TextStyles.heading2,
        bodyLarge: TextStyles.bodyText,
        bodyMedium: TextStyles.bodyText,
        labelLarge: TextStyles.buttonText,
      ),

    //input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primaryColor)
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primaryColor)
      ),
      labelStyle: TextStyles.bodyText.copyWith(color: AppColors.textColor)
    ),

    //card theme
    cardTheme: CardTheme(
     color:Colors.white,
      elevation: 4.0,
      shadowColor: AppColors.primaryColor.withOpacity(0.2),
    ),

  );
  //dark theme
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: Colors.black,
    fontFamily: GoogleFonts.notoSans().fontFamily,
    appBarTheme: AppBarTheme(
      color: AppColors.primaryColor,
      elevation: 4.0,
      titleTextStyle: TextStyles.heading2.copyWith(color: Colors.white),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyles.heading1.copyWith(color: Colors.white),
      displayMedium: TextStyles.heading2.copyWith(color: Colors.white),
      bodyLarge: TextStyles.bodyText.copyWith(color: Colors.white),
      bodyMedium: TextStyles.bodyText.copyWith(color: Colors.white),
      labelLarge: TextStyles.buttonText.copyWith(color: Colors.white),
    ),
  );
}
