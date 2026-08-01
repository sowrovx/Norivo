/// Reusable rounded search field widget with prefix search icon and suffix mic button.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.hintText = 'Where are you going?',
    this.onTap,
    this.onMicPressed,
    this.onChanged,
    this.readOnly = true,
    this.controller,
    this.isFocused = false,
    this.borderColor,
  });

  final String hintText;
  final VoidCallback? onTap;
  final VoidCallback? onMicPressed;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final TextEditingController? controller;
  final bool isFocused;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor =
        borderColor ?? (isFocused ? AppColors.primary : Theme.of(context).dividerColor);
    final borderWidth = isFocused || borderColor != null ? 1.5 : 1.0;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: effectiveBorderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: readOnly
                      ? Text(
                          hintText,
                          style: AppTextStyles.subtitle.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : TextField(
                          controller: controller,
                          onChanged: onChanged,
                          style: AppTextStyles.body.copyWith(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: hintText,
                            hintStyle: AppTextStyles.subtitle.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
