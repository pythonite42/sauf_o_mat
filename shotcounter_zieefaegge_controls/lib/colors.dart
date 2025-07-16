import 'package:flutter/material.dart';

final defaultOnPrimary = Color(0xFFC7C5D0);
final cyanAccent = Color(0xFF18d9ff);
final redAccent = Color(0xFFFF5252);
final greenAccent = Color(0xFF2EC91C);
final transparentWhite = Color(0xC8FFFFFF);
final darkAccent = Color(0xFF07168A);

final ThemeData appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF0F22AF),
    primary: const Color(0xFF0F22AF),
    secondary: const Color(0xFFDE28d8),
    tertiary: const Color(0xFFF5BF17),
    brightness: Brightness.dark,
  ),
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFF0F22AF),
  appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0F22AF), foregroundColor: Colors.white, elevation: 0),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFF5BF17),
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  canvasColor: darkAccent,
  textTheme: const TextTheme(
    headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    titleMedium: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
    bodyLarge: TextStyle(color: Colors.white),
  ),
);
