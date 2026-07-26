/// Shared text styles for screen content and placeholders.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static TextStyle displayLarge(BuildContext context) {
    return Theme.of(context).textTheme.displayLarge ??
        const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.onBackground,
        );
  }

  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.onBackground,
    height: 1.2,
  );

  static const TextStyle sectionHeader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.onBackground,
    height: 1.3,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.onBackground,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.onBackground,
  );

  static const TextStyle quickActionLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.onBackground,
    height: 1.2,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle statValue = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.onBackground,
  );

  static const TextStyle bottomNavActive = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static const TextStyle bottomNavInactive = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}
