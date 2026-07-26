/// Reusable pill-shaped primary button component matching the Norivo design system.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.height = 52,
    this.backgroundColor,
    this.textColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final double height;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppColors.primary;
    final effectiveTextColor = textColor ?? Colors.white;

    final buttonChild = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: effectiveTextColor, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: AppTextStyles.buttonText.copyWith(color: effectiveTextColor),
        ),
      ],
    );

    return SizedBox(
      height: height,
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBg,
          foregroundColor: effectiveTextColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(height / 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: buttonChild,
      ),
    );
  }
}
