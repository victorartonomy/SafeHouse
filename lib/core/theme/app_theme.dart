import 'package:flutter/material.dart';

enum AppThemeMode { light, dark }

class AppColors {
  static const Color green = Color(0xFF00FF85);
  static const Color red = Color(0xFFFF4D4D);
  static const Color blue = Color(0xFF4FC3F7);
  static const Color purple = Color(0xFFB39DDB);
  static const Color orange = Color(0xFFFFB74D);
  static const Color pink = Color(0xFFF06292);
  static const Color yellow = Color(0xFFFFD54F);
  static const Color cyan = Color(0xFF4DD0E1);

  static const List<Color> allAccents = [
    green,
    red,
    blue,
    purple,
    orange,
    pink,
    yellow,
    cyan,
  ];
}

class AppTheme {
  static ThemeData getTheme({
    required AppThemeMode mode,
    required Color accentColor,
  }) {
    final isDark = mode == AppThemeMode.dark;

    final Color background = isDark
        ? const Color(0xFF0D0D0D)
        : const Color(0xFFF5F5F5);
    final Color surface = isDark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFFFFFFF);
    final Color onSurface = isDark
        ? const Color(0xFFE0E0E0)
        : const Color(0xFF1A1A1A);
    final Color subtle = isDark
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFE0E0E0);

    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: accentColor,
        onPrimary: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFFFFFF),
        secondary: accentColor,
        onSecondary: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFFFFFF),
        error: AppColors.red,
        onError: Colors.white,
        surface: surface,
        onSurface: onSurface,
        outline: subtle,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: subtle),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: subtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: subtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.red),
        ),
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFF888888) : const Color(0xFF666666),
        ),
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF555555) : const Color(0xFF999999),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: isDark
              ? const Color(0xFF0D0D0D)
              : const Color(0xFFFFFFFF),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: subtle),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: onSurface,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: onSurface,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: onSurface, fontSize: 15),
        bodyMedium: TextStyle(
          color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
          fontSize: 13,
        ),
        labelSmall: const TextStyle(
          color: Color(0xFF666666),
          fontSize: 11,
          letterSpacing: 0.8,
        ),
      ),
      dividerTheme: DividerThemeData(color: subtle, thickness: 1, space: 1),
      iconTheme: IconThemeData(
        color: isDark ? const Color(0xFF888888) : const Color(0xFF666666),
        size: 22,
      ),
    );
  }
}
