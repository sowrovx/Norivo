/// Active journey screen showing route status, progress, and travel details.
library;

import 'package:flutter/material.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/alarm_status_card.dart';
import '../../shared/widgets/app_bottom_navigation.dart';
import '../../shared/widgets/journey_info_card.dart';
import '../../shared/widgets/journey_status_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/progress_section.dart';

class ActiveJourneyScreen extends StatelessWidget {
  const ActiveJourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      Navigator.of(context).pushNamed(AppRouter.alarmSetup);
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Active Journey',
                          style: AppTextStyles.heading1,
                        ),
                        Text(
                          'Butterworth Railway Station',
                          style: AppTextStyles.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.directions_car_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Selected destination',
                                      style: AppTextStyles.bodyMuted,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Butterworth Railway Station',
                                      style: AppTextStyles.cardTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const JourneyStatusCard(
                            title: 'Journey status',
                            value: 'Approaching destination',
                            icon: Icons.route_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 12),
                          const ProgressSection(
                            progressValue: 0.72,
                            progressLabel: '72% of the trip is complete',
                            eta: '08:12 AM',
                            remainingDistance: '1.4 km',
                            remainingTime: '12 mins',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const AlarmStatusCard(
                      status: 'Alarm status',
                      detail: 'Enabled • 1 km before arrival',
                      icon: Icons.alarm_on_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Current travel mode',
                        style: AppTextStyles.sectionHeader,
                      ),
                    ),
                    const JourneyInfoCard(
                      label: 'Travel mode',
                      value: 'Drive',
                      caption: 'Fastest route selected',
                      icon: Icons.directions_car_rounded,
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                      children: const [
                        JourneyInfoCard(
                          label: 'Estimated arrival',
                          value: '08:12 AM',
                          caption: 'Traffic normal',
                          icon: Icons.access_time_rounded,
                        ),
                        JourneyInfoCard(
                          label: 'Remaining distance',
                          value: '1.4 km',
                          caption: '3 mins away',
                          icon: Icons.straighten_rounded,
                        ),
                        JourneyInfoCard(
                          label: 'Travel time',
                          value: '12 mins',
                          caption: 'Door-to-door',
                          icon: Icons.timer_rounded,
                        ),
                        JourneyInfoCard(
                          label: 'Service status',
                          value: 'On track',
                          caption: 'No issues',
                          icon: Icons.check_circle_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'End Journey',
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        Navigator.of(context).pushNamed(AppRouter.alarmRinging);
                      },
                      icon: Icons.stop_circle_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 2),
    );
  }
}
