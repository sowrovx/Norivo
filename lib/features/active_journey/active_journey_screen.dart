import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/models/destination_place.dart';
import '../../core/models/route_result.dart';
import '../../core/router/app_router.dart';
import '../../core/services/destination_search_service.dart';
import '../../core/services/journey_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/route_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/alarm_status_card.dart';
import '../../shared/widgets/app_bottom_navigation.dart';
import '../../shared/widgets/current_location_map_card.dart';
import '../../shared/widgets/journey_info_card.dart';
import '../../shared/widgets/journey_status_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/progress_section.dart';

class ActiveJourneyScreen extends StatefulWidget {
  const ActiveJourneyScreen({
    super.key,
    this.destinationPlace,
    this.routeService,
    this.alarmThresholdMeters = 1000.0,
    this.isVibrationEnabled,
  });

  final DestinationPlace? destinationPlace;
  final RouteService? routeService;
  final double alarmThresholdMeters;
  final bool? isVibrationEnabled;

  @override
  State<ActiveJourneyScreen> createState() => _ActiveJourneyScreenState();
}

class _ActiveJourneyScreenState extends State<ActiveJourneyScreen> {
  Position? _currentPosition;
  RouteResult? _routeResult;
  late final RouteService _routeService;

  @override
  void initState() {
    super.initState();
    _routeService = widget.routeService ?? RouteService();
    final currentJourney = JourneyService.instance.currentJourney;
    if (widget.destinationPlace != null &&
        (currentJourney == null ||
            currentJourney.destinationPlace.latitude != widget.destinationPlace!.latitude ||
            currentJourney.destinationPlace.longitude != widget.destinationPlace!.longitude ||
            currentJourney.destinationPlace.name != widget.destinationPlace!.name)) {
      JourneyService.instance.startJourney(
        destinationPlace: widget.destinationPlace!,
        alarmThresholdMeters: widget.alarmThresholdMeters,
        isVibrationEnabled: widget.isVibrationEnabled ?? true,
      );
    }

    _currentPosition = JourneyService.instance.currentPositionNotifier.value;
    _routeResult = JourneyService.instance.routeResultNotifier.value;

    JourneyService.instance.currentPositionNotifier.addListener(_onPositionChanged);
    JourneyService.instance.routeResultNotifier.addListener(_onRouteChanged);

    if (_currentPosition == null) {
      _loadLocationAndRoute();
    }
  }

  void _onPositionChanged() {
    if (!mounted) return;
    setState(() {
      _currentPosition = JourneyService.instance.currentPositionNotifier.value;
    });
  }

  void _onRouteChanged() {
    if (!mounted) return;
    setState(() {
      _routeResult = JourneyService.instance.routeResultNotifier.value;
    });
  }

  @override
  void dispose() {
    JourneyService.instance.currentPositionNotifier.removeListener(_onPositionChanged);
    JourneyService.instance.routeResultNotifier.removeListener(_onRouteChanged);
    super.dispose();
  }

  DestinationPlace? get _effectiveDestinationPlace =>
      widget.destinationPlace ?? JourneyService.instance.currentJourney?.destinationPlace;

  Future<void> _loadLocationAndRoute() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      if (!mounted) return;
      if (pos != null) {
        _currentPosition = pos;
        final target = _effectiveDestinationPlace;
        if (target != null) {
          final route = await _routeService.calculateRoute(
            startLatitude: pos.latitude,
            startLongitude: pos.longitude,
            destinationLatitude: target.latitude,
            destinationLongitude: target.longitude,
          );
          if (!mounted) return;
          setState(() {
            _routeResult = route;
          });
        }
      }
    } catch (e) {
      debugPrint('Location load error in ActiveJourneyScreen: $e');
    }
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.home,
        (route) => false,
      );
    } else if (index == 2) {
      Navigator.of(context).pushNamed(AppRouter.history);
    } else if (index == 3) {
      Navigator.of(context).pushNamed(AppRouter.settings);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tab under development'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _endJourney() async {
    FocusScope.of(context).unfocus();

    await JourneyService.instance.stopJourney();

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.home,
      (route) => false,
    );
  }

  double? get _distanceMeters {
    final target = _effectiveDestinationPlace;
    if (_currentPosition == null || target == null) {
      return null;
    }

    final pos = _currentPosition!;
    final polyline = _routeResult?.polyline;

    if (polyline != null && polyline.length >= 2) {
      int closestIndex = 0;
      double minDistance = double.infinity;

      for (int i = 0; i < polyline.length; i++) {
        final dist = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          polyline[i].latitude,
          polyline[i].longitude,
        );
        if (dist < minDistance) {
          minDistance = dist;
          closestIndex = i;
        }
      }

      double remainingMeters = minDistance;
      for (int i = closestIndex; i < polyline.length - 1; i++) {
        remainingMeters += Geolocator.distanceBetween(
          polyline[i].latitude,
          polyline[i].longitude,
          polyline[i + 1].latitude,
          polyline[i + 1].longitude,
        );
      }
      return remainingMeters;
    }

    return Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      target.latitude,
      target.longitude,
    );
  }

  String get _remainingDistanceText {
    if (_distanceMeters == null) return '--';
    return DestinationSearchService.formatDistance(_distanceMeters!);
  }

  String get _remainingTimeText {
    if (_distanceMeters == null) return '--';
    final speed = (_routeResult != null &&
            _routeResult!.distanceMeters > 0 &&
            _routeResult!.durationSeconds > 0)
        ? (_routeResult!.distanceMeters / _routeResult!.durationSeconds)
        : (50000 / 3600);
    final remainingSeconds = _distanceMeters! / speed;
    final totalMins = (remainingSeconds / 60).round();
    if (totalMins < 1) return '< 1 min';
    if (totalMins < 60) return '$totalMins mins';
    final hrs = totalMins ~/ 60;
    final mins = totalMins % 60;
    return '${hrs}h ${mins}m';
  }

  String get _etaText {
    if (_distanceMeters == null) return '--';
    final speed = (_routeResult != null &&
            _routeResult!.distanceMeters > 0 &&
            _routeResult!.durationSeconds > 0)
        ? (_routeResult!.distanceMeters / _routeResult!.durationSeconds)
        : (50000 / 3600);
    final remainingSeconds = _distanceMeters! / speed;
    final arrivalTime = DateTime.now().add(Duration(seconds: remainingSeconds.round()));
    final hour = arrivalTime.hour % 12 == 0 ? 12 : arrivalTime.hour % 12;
    final minute = arrivalTime.minute.toString().padLeft(2, '0');
    final period = arrivalTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  String get _formattedThresholdText {
    final meters = widget.alarmThresholdMeters;
    if (meters >= 1000) {
      final km = (meters / 1000).toStringAsFixed(meters % 1000 == 0 ? 0 : 1);
      return '$km km';
    }
    return '${meters.toInt()} m';
  }

  @override
  Widget build(BuildContext context) {
    final effectivePlace = _effectiveDestinationPlace;
    if (effectivePlace == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

    final destinationName = effectivePlace.name;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        arguments: effectivePlace,
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
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
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
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                    CurrentLocationMapCard(
                      destinationPlace: effectivePlace,
                      routePolyline: _routeResult?.polyline,
                      currentPosition: _currentPosition != null
                          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    AlarmStatusCard(
                      status: 'Alarm status',
                      detail: 'Enabled • $_formattedThresholdText before arrival',
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
                      onPressed: _endJourney,
                      icon: Icons.stop_circle_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 2,
        onTap: _onNavTap,
      ),
    );
  }
}
