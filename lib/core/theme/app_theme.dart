/// Central theme configuration for the app using Material 3.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: const Color(0xFFFFFFFF),
        onSurface: const Color(0xFF0F172A),
        onSurfaceVariant: const Color(0xFF64748B),
        surfaceContainerHighest: const Color(0xFFEFF6FF),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      dividerColor: const Color(0xFFF1F5F9),
      iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      cardTheme: const CardThemeData(
        color: Color(0xFFFFFFFF),
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8FAFC),
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: const Color(0xFF1E293B),
        onSurface: const Color(0xFFF8FAFC),
        onSurfaceVariant: const Color(0xFF94A3B8),
        surfaceContainerHighest: const Color(0xFF334155),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      dividerColor: const Color(0xFF334155),
      iconTheme: const IconThemeData(color: Color(0xFFF8FAFC)),
      cardTheme: const CardThemeData(
        color: Color(0xFF1E293B),
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F172A),
        foregroundColor: Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
