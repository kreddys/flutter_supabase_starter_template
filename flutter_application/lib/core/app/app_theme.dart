import 'package:flutter/material.dart';
import 'package:amaravati_chamber/core/constants/font_sizes.dart';
import 'package:google_fonts/google_fonts.dart';

final theme = _getTheme(_lightColorScheme);
final darkTheme = _getTheme(_darkColorScheme);

final _lightColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF47828F),
  brightness: Brightness.light,
);

final _darkColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFFA7C8FF),
  brightness: Brightness.dark,
);

ThemeData _getTheme(ColorScheme colorScheme) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: _getTextTheme(colorScheme),
  );
}

TextTheme _getTextTheme(ColorScheme colorScheme) {
  return GoogleFonts.rubikTextTheme(
    TextTheme(
      bodyMedium: TextStyle(
        fontSize: FontSize.s16,
        fontWeight: FontWeight.w400,
        color: colorScheme.onBackground,
        decoration: TextDecoration.none, // Explicitly remove any decoration
      ),
      titleLarge: TextStyle(
        fontSize: FontSize.s20,
        fontWeight: FontWeight.w400,
        color: colorScheme.onBackground,
        decoration: TextDecoration.none,
      ),
    ),
  );
}