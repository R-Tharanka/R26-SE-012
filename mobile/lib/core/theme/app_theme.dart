import 'package:flutter/material.dart';

const Color kBrand = Color(0xFF1B4332);
const Color _brandLight = Color(0xFF2D6A4F);
const Color _surfaceLight = Color(0xFFF9F9F6);
const Color _surfaceDark = Color(0xFF101714);

final ValueNotifier<ThemeMode> appThemeMode =
    ValueNotifier<ThemeMode>(ThemeMode.light);

bool get isDarkMode => appThemeMode.value == ThemeMode.dark;

void toggleTheme() {
  appThemeMode.value = isDarkMode ? ThemeMode.light : ThemeMode.dark;
}

class AppTheme {
  const AppTheme._();

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kBrand,
      brightness: Brightness.light,
      primary: kBrand,
      surface: _surfaceLight,
    ),
    scaffoldBackgroundColor: _surfaceLight,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: _surfaceLight,
      foregroundColor: Color(0xFF1A1C1E),
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kBrand,
        foregroundColor: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kBrand,
        foregroundColor: Colors.white,
      ),
    ),
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _brandLight,
      brightness: Brightness.dark,
      primary: _brandLight,
      surface: _surfaceDark,
    ),
    scaffoldBackgroundColor: _surfaceDark,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: _surfaceDark,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF18231F),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _brandLight,
        foregroundColor: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _brandLight,
        foregroundColor: Colors.white,
      ),
    ),
  );
}
