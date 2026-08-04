/// Home screen of the Norivo app built directly from Figma designs.
library;

import 'package:flutter/material.dart';

import '../../core/router/app_router.dart';
import '../../core/services/journey_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_bottom_navigation.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/quick_action_card.dart';
import '../../shared/widgets/search_field.dart';
import 'widgets/home_location_section.dart';
import 'widgets/route_illustration.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  void _onSearchTap() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pushNamed(AppRouter.destinationSearch);
  }

  void _onQuickActionTap(String actionName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$actionName clicked (Placeholder)'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Greeting & User Avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Good Morning 👋', style: AppTextStyles.heading1),
                      SizedBox(height: 4),
                      Text(
                        'Ready for your next journey?',
                        style: AppTextStyles.subtitle,
                      ),
                    ],
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'A',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Search Field
              SearchField(
                onTap: _onSearchTap,
                onMicPressed: () => _onQuickActionTap('Voice Search'),
              ),

              const SizedBox(height: 24),

              // Quick Action Cards
              Row(
                children: [
                  Expanded(
                    child: QuickActionCard(
                      icon: Icons.bookmark_outline_rounded,
                      label: 'Saved\nPlaces',
                      onTap: () => _onQuickActionTap('Saved Places'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionCard(
                      icon: Icons.access_time_rounded,
                      label: 'Recent\nTrips',
                      onTap: () => _onQuickActionTap('Recent Trips'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionCard(
                      icon: Icons.alarm_rounded,
                      label: 'Active\nAlarm',
                      onTap: () => _onQuickActionTap('Active Alarm'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionCard(
                      icon: Icons.favorite_outline_rounded,
                      label: 'Favorites',
                      onTap: () => _onQuickActionTap('Favorites'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Today's Journey Section
              const Text("Today's Journey", style: AppTextStyles.sectionHeader),
              const SizedBox(height: 12),

              ValueListenableBuilder<ActiveJourneyState?>(
                valueListenable: JourneyService.instance.activeJourneyNotifier,
                builder: (context, activeJourney, _) {
                  final hasActive = activeJourney != null;
                  final title = hasActive ? activeJourney.destinationPlace.name : 'No active journey';
                  final subtitle = hasActive
                      ? (activeJourney.destinationPlace.address.isNotEmpty
                          ? activeJourney.destinationPlace.address
                          : 'Journey in progress')
                      : 'Search a destination to begin';
                  final buttonLabel = hasActive ? 'View Active Journey' : 'Start Journey';

                  return GestureDetector(
                    onTap: () {
                      if (hasActive) {
                        Navigator.of(context).pushNamed(
                          AppRouter.activeJourney,
                          arguments: activeJourney.destinationPlace,
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                        children: [
                          const RouteIllustration(),
                          const SizedBox(height: 16),
                          Text(
                            title,
                            style: AppTextStyles.cardTitle.copyWith(
                              color: const Color(0xFF0F172A),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: AppTextStyles.subtitle.copyWith(
                              color: const Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 20),
                          PrimaryButton(
                            label: buttonLabel,
                            onPressed: () {
                              if (hasActive) {
                                Navigator.of(context).pushNamed(
                                  AppRouter.activeJourney,
                                  arguments: activeJourney.destinationPlace,
                                );
                              } else {
                                _onSearchTap();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              const HomeLocationSection(),

              const SizedBox(height: 28),

              // Travel Insights Section
              const Text('Travel Insights', style: AppTextStyles.sectionHeader),
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                child: Row(
                  children: [
                    // Left Column: Total Completed Journeys
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "You've safely completed",
                            style: AppTextStyles.bodyMuted.copyWith(
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '14 journeys',
                            style: AppTextStyles.statValue.copyWith(
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Vertical Divider
                    Container(
                      width: 1,
                      height: 44,
                      color: AppColors.border,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),

                    // Right Column: Circular Progress & Accuracy Rate
                    Expanded(
                      flex: 6,
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 44,
                            height: 44,
                            child: CircularProgressIndicator(
                              value: 0.99,
                              strokeWidth: 4.5,
                              color: AppColors.primary,
                              backgroundColor: AppColors.primaryLight,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '99%',
                                  style: AppTextStyles.statValue.copyWith(
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'Wake-up accuracy',
                                  style: AppTextStyles.bodyMuted.copyWith(
                                    color: const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          if (index == 3) {
            Navigator.of(context).pushNamed(AppRouter.settings);
          } else if (index == 2) {
            Navigator.of(context).pushNamed(AppRouter.history);
          } else {
            setState(() {
              _currentNavIndex = index;
            });
          }
        },
      ),
    );
  }
}
