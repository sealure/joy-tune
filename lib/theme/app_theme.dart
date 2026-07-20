import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── 配色 ──
  static const _accent = Color(0xFF6366F1); // Indigo 为主色调
  static const _accentDark = Color(0xFF818CF8);

  static const _bg = Color(0xFFFAFAFA);
  static const _bgDark = Color(0xFF121212);

  static const _surface = Colors.white;
  static const _surfaceDark = Color(0xFF1E1E1E);

  static const _text = Color(0xFF1A1A1A);
  static const _textDark = Color(0xFFE0E0E0);
  static const _textSecondary = Color(0xFF888888);

  // ── 明亮主题 ──
  static final light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: _bg,
    colorScheme: const ColorScheme.light(
      primary: _accent,
      surface: _surface,
      onSurface: _text,
      secondary: _textSecondary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: _text,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _text),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text),
      bodyMedium: TextStyle(fontSize: 14, color: _text),
      bodySmall: TextStyle(fontSize: 12, color: _textSecondary),
    ),
    cardTheme: CardThemeData(
      color: _surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surface,
      hintStyle: const TextStyle(color: _textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
    iconTheme: const IconThemeData(color: _textSecondary, size: 22),
  );

  // ── 暗色主题 ──
  static final dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _bgDark,
    colorScheme: const ColorScheme.dark(
      primary: _accentDark,
      surface: _surfaceDark,
      onSurface: _textDark,
      secondary: _textSecondary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: _textDark,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _textDark),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textDark),
      bodyMedium: TextStyle(fontSize: 14, color: _textDark),
      bodySmall: TextStyle(fontSize: 12, color: _textSecondary),
    ),
    cardTheme: CardThemeData(
      color: _surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF2A2A2A),
      hintStyle: TextStyle(color: _textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        borderSide: BorderSide.none,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
    iconTheme: const IconThemeData(color: _textSecondary, size: 22),
  );
}
