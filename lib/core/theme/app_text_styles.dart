/// Shared text styles for screen content and placeholders.
library;

import 'package:flutter/material.dart';

class AppTextStyles {
  const AppTextStyles._();

  static TextStyle displayLarge(BuildContext context) {
    return Theme.of(context).textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ) ??
        const TextStyle(fontSize: 32, fontWeight: FontWeight.w600);
  }

  static TextStyle headlineMedium(BuildContext context) {
    return Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ) ??
        const TextStyle(fontSize: 24, fontWeight: FontWeight.w600);
  }

  static TextStyle bodyLarge(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.secondary,
        ) ??
        const TextStyle(fontSize: 16);
  }
}
