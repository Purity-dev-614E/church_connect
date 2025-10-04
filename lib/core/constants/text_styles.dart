import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import 'colors.dart';

class TextStyles {
  static TextStyle heading1 = GoogleFonts.notoSans(
    fontSize: DeviceConfig.font(22),
    fontWeight: FontWeight.bold,
  );

  static TextStyle heading2 = GoogleFonts.notoSans(
    fontSize: DeviceConfig.font(14),
    fontWeight: FontWeight.w600,
  );

  static TextStyle bodyText = GoogleFonts.notoSans(
    fontSize:DeviceConfig.font(12)

  );

  static TextStyle buttonText = GoogleFonts.notoSans(
    fontSize: DeviceConfig.font(12),
    fontWeight: FontWeight.bold,
  );
}

