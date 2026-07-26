/// Shared color palette used across the app.
library;

import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  /// Primary brand color (vibrant royal blue)
  static const Color primary = Color(0xFF2563EB);

  /// Light tint for icon background containers and chips
  static const Color primaryLight = Color(0xFFEFF6FF);

  /// Darker shade for active pressed states
  static const Color primaryDark = Color(0xFF1D4ED8);

  /// Scaffold background color
  static const Color background = Color(0xFFF8FAFC);

  /// Card and container surface background
  static const Color surface = Color(0xFFFFFFFF);

  /// Primary text color (slate 900)
  static const Color onBackground = Color(0xFF0F172A);

  /// Secondary text color (slate 700)
  static const Color onSurface = Color(0xFF1E293B);

  /// Muted subtitle text color (slate 500)
  static const Color textSecondary = Color(0xFF64748B);

  /// Light caption / placeholder text color (slate 400)
  static const Color textMuted = Color(0xFF94A3B8);

  /// Light container border color
  static const Color border = Color(0xFFF1F5F9);

  /// Secondary accent
  static const Color secondary = Color(0xFF625B71);

  /// Soft card shadow color
  static const Color cardShadow = Color(0x0F0F172A);
}
