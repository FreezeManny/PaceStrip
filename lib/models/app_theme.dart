import 'package:flutter/material.dart';

/// The selectable app appearances. [black] is a true-black variant of [dark]
/// for OLED screens, where pure-black pixels are switched off entirely.
enum AppTheme { light, dark, black }

extension AppThemeX on AppTheme {
  String get label => switch (this) {
        AppTheme.light => 'Light',
        AppTheme.dark => 'Dark',
        AppTheme.black => 'Black',
      };

  bool get isDark => this != AppTheme.light;
}

const _seedColor = Color(0xFF4FC3F7);

ThemeData buildLightTheme() => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
      useMaterial3: true,
    );

/// Builds the dark theme. When [oled] is true the scaffold background is pure
/// black for OLED power saving; cards keep their elevated surface color so they
/// stay legible against it.
ThemeData buildDarkTheme({bool oled = false}) => ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor:
          oled ? Colors.black : const Color(0xFF0A0A0A),
      useMaterial3: true,
    );
