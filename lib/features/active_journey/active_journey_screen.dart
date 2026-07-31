/// Active journey screen showing route status, progress, and travel details.
library;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/models/destination_place.dart';
import '../../core/router/app_router.dart';
import '../../core/services/destination_search_service.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/alarm_status_card.dart';
import '../../shared/widgets/app_bottom_navigation.dart';
import '../../shared/widgets/journey_info_card.dart';
import '../../shared/widgets/journey_status_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/progress_section.dart';

class ActiveJourneyScreen extends StatefulWidget {
  const ActiveJourneyScreen({
    super.key,
    this.destinationPlace,
  });

  final DestinationPlace? destinationPlace;

  @override
  State<ActiveJourneyScreen> createState() => _ActiveJourneyScreenState();
}

class _ActiveJourneyScreenState extends State<ActiveJourneyScreen> {
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
      });
    } catch (e) {
      debugPrint('Location load error in ActiveJourneyScreen: $e');
    }
  }

  double? get _distanceMeters {
    if (_currentPosition == null || widget.destinationPlace == null) {
      return null;
    }
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      widget.destinationPlace!.latitude,
      widget.destinationPlace!.longitude,
    );
  }

  String get _remainingDistanceText {
    if (_distanceMeters == null) return '--';
    return DestinationSearchService.formatDistance(_distanceMeters!);
  }

  String get _remainingTimeText {
    if (_distanceMeters == null) return '--';
    final totalMins = (_distanceMeters! / 833).round();
    if (totalMins < 1) return '< 1 min';
    if (totalMins < 60) return '$totalMins mins';
    final hrs = totalMins ~/ 60;
    final mins = totalMins % 60;
    return '${hrs}h ${mins}m';
  }

  String get _etaText {
    if (_distanceMeters == null) return '--';
    final totalMins = (_distanceMeters! / 833).round();
    final arrivalTime = DateTime.now().add(Duration(minutes: totalMins));
    final hour = arrivalTime.hour % 12 == 0 ? 12 : arrivalTime.hour % 12;
    final minute = arrivalTime.minute.toString().padLeft(2, '0');
    final period = arrivalTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.destinationPlace == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No destination selected',
                    style: AppTextStyles.sectionHeader,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please choose a destination first to start a journey.',
                    style: AppTextStyles.subtitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Choose Destination',
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed(
                        AppRouter.destinationSearch,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final destinationName = widget.destinationPlace!.name;

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
                      Navigator.of(context).pushNamed(
                        AppRouter.alarmSetup,
                        arguments: widget.destinationPlace,
                      );
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
                          destinationName,
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
                                      destinationName,
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
                          ProgressSection(
                            progressValue: 0.72,
                            progressLabel: 'Journey in progress',
                            eta: _etaText,
                            remainingDistance: _remainingDistanceText,
                            remainingTime: _remainingTimeText,
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
                      children: [
                        JourneyInfoCard(
                          label: 'Estimated arrival',
                          value: _etaText,
                          caption: 'Traffic normal',
                          icon: Icons.access_time_rounded,
                        ),
                        JourneyInfoCard(
                          label: 'Remaining distance',
                          value: _remainingDistanceText,
                          caption: 'On route',
                          icon: Icons.straighten_rounded,
                        ),
                        JourneyInfoCard(
                          label: 'Travel time',
                          value: _remainingTimeText,
                          caption: 'Door-to-door',
                          icon: Icons.timer_rounded,
                        ),
                        const JourneyInfoCard(
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
