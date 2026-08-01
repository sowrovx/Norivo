/// Progress section widget showing completion and ETA details.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ProgressSection extends StatelessWidget {
  const ProgressSection({
    super.key,
    required this.progressValue,
    required this.progressLabel,
    required this.eta,
    required this.remainingDistance,
    required this.remainingTime,
  });

  final double progressValue;
  final String progressLabel;
  final String eta;
  final String remainingDistance;
  final String remainingTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Current progress', style: AppTextStyles.sectionHeader),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 10,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(progressLabel, style: AppTextStyles.body),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ETA', style: AppTextStyles.bodyMuted),
                    const SizedBox(height: 4),
                    Text(eta, style: AppTextStyles.statValue),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Remaining', style: AppTextStyles.bodyMuted),
                    const SizedBox(height: 4),
                    Text(remainingDistance, style: AppTextStyles.statValue),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Travel time left: $remainingTime',
            style: AppTextStyles.subtitle,
          ),
        ],
      ),
    );
  }
}
