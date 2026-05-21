import 'package:flutter/material.dart';

class AppTheme {
  static const Color background  = Color(0xFF1A1A1A);
  static const Color surface     = Color(0xFF252525);
  static const Color surfaceHigh = Color(0xFF2E2E2E);
  static const Color accent      = Color(0xFFFF6B35);
  static const Color accentDark  = Color(0xFFE55525);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFCCCCCC);
  static const Color textMuted   = Color(0xFF888888);
  static const Color success     = Color(0xFF22C55E);
  static const Color danger      = Color(0xFFEF4444);
  static const Color border      = Color(0xFF333333);
  static const Color badgeYellow = Color(0xFFFFB800);

  static ThemeData build() {
    return ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        surface: surface,
        error: danger,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHigh,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHigh,
        hintStyle: const TextStyle(color: textMuted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: accent, width: 1.5)),
      ),
    );
  }
}
