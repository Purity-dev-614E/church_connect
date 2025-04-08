import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class TextStyles {
  static TextStyle heading1 = GoogleFonts.notoSans(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textColor,
  );

  static TextStyle heading2 = GoogleFonts.notoSans(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textColor,
  );

  static TextStyle bodyText = GoogleFonts.notoSans(
    fontSize: 16.0,
    color: AppColors.textColor,
  );

  static TextStyle buttonText = GoogleFonts.notoSans(
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
    color: AppColors.buttonColor,
  );
}

