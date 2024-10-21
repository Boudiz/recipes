import 'package:flutter/material.dart';
import 'colors.dart';

TextTheme _textTheme = TextTheme(
  headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  bodyMedium: TextStyle(fontSize: 16),
);

ThemeData lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.light,
    surface: backgroundColor,
    onPrimaryContainer: cardColor,
    onErrorContainer: deletedCardColor,
  ),
  textTheme: _textTheme,
);

ThemeData darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: darkPrimaryColor,
    brightness: Brightness.dark,
    surface: darkBackgroundColor,
    onPrimaryContainer: darkCardColor,
    onErrorContainer: darkDeletedCardColor,
  ),
  textTheme: _textTheme,
);
