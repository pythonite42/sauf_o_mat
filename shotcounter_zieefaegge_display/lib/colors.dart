import 'package:flutter/material.dart';

Color defaultOnPrimary = Color(0xFFC7C5D0);
Color defaultOnScroll = Color(0xFF8B4513);
Color westernGold = Color(0xFFE9A94A);
Color sunsetRed = Color(0xFFB22222);
Color lightRusticBrown = Color(0xFFA86E4A);
Color cactusGreen = Color(0xFF2E8B57);
Color redAccent = Color(0xFFFF5252);
Color greenAccent = Color(0xFF2EC91C);
Color transparentWhite = Color(0xC8FFFFFF);
Color backgroundColor = Color(0xFFCA7F36);
final ThemeData appTheme = ThemeData(
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: const Color(0xFF8B4513), // Saddle brown
    onPrimary: Colors.white,
    secondary: const Color(0xFFD2691E), // Chocolate brown
    onSecondary: Colors.white,
    tertiary: const Color(0xFFF4A460), // Sandy brown
    onTertiary: Colors.black,
    error: Colors.red.shade700,
    onError: Colors.white,
    surface: const Color(0xFFFFDEAD), // Navajo white
    onSurface: Colors.brown.shade900,
  ),
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFFFFE4B5), // Desert sand
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF8B4513),
    foregroundColor: Colors.white,
    elevation: 2,
    titleTextStyle: TextStyle(
      fontFamily: 'Georgia',
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFD2691E),
      foregroundColor: Colors.white,
      textStyle: const TextStyle(
        fontFamily: 'Georgia',
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4), // More rustic look
      ),
    ),
  ),
  textTheme: TextTheme(
    headlineSmall: const TextStyle(
      color: Color(0xFF8B4513),
      fontWeight: FontWeight.bold,
      fontFamily: 'Georgia',
    ),
    titleLarge: TextStyle(
      color: Colors.brown.shade800,
      fontSize: 60,
    ),
    titleMedium: TextStyle(
      color: Colors.brown.shade800,
      fontFamily: 'Georgia',
    ),
    bodyMedium: TextStyle(
      color: Colors.brown.shade900,
      fontFamily: 'Georgia',
    ),
    bodyLarge: TextStyle(
      color: Colors.brown.shade900,
      fontFamily: 'Georgia',
    ),
  ),
);
