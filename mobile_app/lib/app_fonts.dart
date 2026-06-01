import 'package:flutter/material.dart';

/// Provides consistent typography across the app without needing
/// the google_fonts package (which pulls in native build hooks).
class AppFonts {
  static TextStyle nunito({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = Colors.black87,
    List<Shadow>? shadows,
    Paint? foreground,
  }) {
    return TextStyle(
      fontFamily: 'Nunito',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: foreground != null ? null : color,
      shadows: shadows,
      foreground: foreground,
    );
  }
}
