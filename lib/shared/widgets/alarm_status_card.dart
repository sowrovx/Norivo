/// Alarm status card widget for the active journey screen.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AlarmStatusCard extends StatelessWidget {
  const AlarmStatusCard({
    super.key,
    required this.status,
    required this.detail,
    this.icon,
    this.color,
  });

  final String status;
  final String detail;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon ?? Icons.alarm_rounded,
              color: color ?? AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status, style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                Text(detail, style: AppTextStyles.subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
