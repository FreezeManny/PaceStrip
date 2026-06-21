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
/// black for OLED power saving; cards turn pure black too and gain an outline
/// (see [cardStyle]) so they stay legible without a grey surface.
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

/// Surface color and shape for cards in the current theme. In the true-black
/// (OLED) theme cards are pure black with an outline, so they read as cards
/// without lifting to a grey surface; otherwise they use the elevated surface.
({Color color, ShapeBorder shape}) cardStyle(BuildContext context) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final isBlack = theme.scaffoldBackgroundColor == Colors.black;
  return (
    color: isBlack ? Colors.black : scheme.surfaceContainerHigh,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: isBlack ? BorderSide(color: scheme.outlineVariant) : BorderSide.none,
    ),
  );
}
