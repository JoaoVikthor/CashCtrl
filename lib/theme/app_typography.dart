import 'package:flutter/material.dart';

class AppTypography {
  static const double hero = 28;
  static const double title = 20;
  static const double section = 16;
  static const double body = 14;
  static const double secondary = 12;
  static const double caption = 11;

  static TextStyle _style(double size, FontWeight weight) =>
      TextStyle(fontFamily: 'Roboto', fontSize: size, fontWeight: weight);

  static TextTheme get dark => TextTheme(
    displayLarge: _style(hero, FontWeight.w700),
    headlineMedium: _style(title, FontWeight.w700),
    titleMedium: _style(section, FontWeight.w600),
    bodyLarge: _style(body, FontWeight.w500),
    bodyMedium: _style(secondary, FontWeight.w400),
    bodySmall: _style(caption, FontWeight.w500),
  );

  static TextStyle number({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) => TextStyle(
    fontFamily: 'Roboto',
    fontFeatures: const [FontFeature.tabularFigures()],
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
  );
}
