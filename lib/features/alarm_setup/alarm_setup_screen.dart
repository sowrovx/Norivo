import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/models/destination_place.dart';
import '../../core/models/route_result.dart';
import '../../core/router/app_router.dart';
import '../../core/services/destination_search_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/route_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/primary_button.dart';

class AlarmSetupScreen extends StatefulWidget {
  const AlarmSetupScreen({
    super.key,
    this.destinationName,
    this.destinationPlace,
    this.routeService,
  });

  final String? destinationName;
  final DestinationPlace? destinationPlace;
  final RouteService? routeService;

  @override
  State<AlarmSetupScreen> createState() => _AlarmSetupScreenState();
}

class _AlarmSetupScreenState extends State<AlarmSetupScreen> {
  int _selectedDistanceIndex = 2; // Default to '1 km'
  String _selectedSound = 'Default';
  bool _isVibrationOn = true;
  bool _isVoiceOn = true;
  bool _isRepeatOn = true;
  Position? _currentPosition;
  RouteResult? _routeResult;
  late final RouteService _routeService;

  final List<String> _distances = const [
    '250 m',
    '500 m',
    '1 km',
    '2 km',
    '5 km',
  ];

  @override
  void initState() {
    super.initState();
    _routeService = widget.routeService ?? RouteService();
    _loadLocationAndRoute();
  }

  Future<void> _loadLocationAndRoute() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
      });

      if (pos != null && widget.destinationPlace != null) {
        final route = await _routeService.calculateRoute(
          startLatitude: pos.latitude,
          startLongitude: pos.longitude,
          destinationLatitude: widget.destinationPlace!.latitude,
          destinationLongitude: widget.destinationPlace!.longitude,
        );
        if (!mounted) return;
        setState(() {
          _routeResult = route;
        });
      }
    } catch (e) {
      debugPrint('Location load error in AlarmSetupScreen: $e');
    }
  }

  String get _effectiveDestination =>
      widget.destinationPlace?.name ?? widget.destinationName ?? '';

  String get _effectiveAddress => widget.destinationPlace?.address ?? '';

  String get _distanceText {
    if (_routeResult != null) {
      return _routeResult!.formattedDistance;
    }
    if (_currentPosition == null || widget.destinationPlace == null) {
      return '--';
    }
    final meters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      widget.destinationPlace!.latitude,
      widget.destinationPlace!.longitude,
    );
    return DestinationSearchService.formatDistance(meters);
  }

  String get _estimatedDurationText {
    if (_routeResult != null) {
      return _routeResult!.formattedDuration;
    }
    if (_currentPosition == null || widget.destinationPlace == null) {
      return '--';
    }
    final meters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      widget.destinationPlace!.latitude,
      widget.destinationPlace!.longitude,
    );
    final totalMins = (meters / 833).round();
    if (totalMins < 1) {
      return '< 1 min';
    }
    if (totalMins < 60) {
      return '$totalMins min';
    }
    final hrs = totalMins ~/ 60;
    final mins = totalMins % 60;
    return '$hrs hr $mins min';
  }

  void _onStartJourney() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pushNamed(
      AppRouter.activeJourney,
      arguments: widget.destinationPlace,
    );
  }

  void _onPreviewAlarm() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pushNamed(AppRouter.alarmRinging);
  }

  void _showSoundPicker() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final sounds = [
          'Default',
          'Gentle Chime',
          'Radar Alert',
          'Subtle Bell',
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Alarm Sound',
                  style: AppTextStyles.sectionHeader,
                ),
                const SizedBox(height: 12),
                ...sounds.map(
                  (sound) => ListTile(
                    title: Text(sound, style: AppTextStyles.body),
                    trailing: _selectedSound == sound
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedSound = sound;
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.destinationPlace == null && widget.destinationName == null) {
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
                    'Please choose a destination first before setting up an alarm.',
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.onBackground,
                      size: 20,
                    ),
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      Navigator.of(context).pop();
                    },
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Set Alarm',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBackground,
                          ),
                        ),
                        Text(
                          _effectiveDestination,
                          style: AppTextStyles.subtitle.copyWith(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Destination Card Summary
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
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.subway_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Destination',
                                      style: AppTextStyles.bodyMuted,
                                    ),
                                    Text(
                                      _effectiveDestination,
                                      style: AppTextStyles.cardTitle.copyWith(
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _effectiveAddress,
                                      style: AppTextStyles.subtitle,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: AppColors.border, height: 1),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Estimated Arrival',
                                      style: AppTextStyles.bodyMuted,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _estimatedDurationText,
                                      style: AppTextStyles.statValue,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Distance Remaining',
                                      style: AppTextStyles.bodyMuted,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _distanceText,
                                      style: AppTextStyles.statValue,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Wake-up Distance Section
                    const Text(
                      'Wake-up Distance',
                      style: AppTextStyles.sectionHeader,
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: List.generate(_distances.length, (index) {
                          final isSelected = index == _selectedDistanceIndex;
                          return Expanded(
                            child: Material(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedDistanceIndex = index;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _distances[index],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTextStyles.subtitle.color,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Alarm Settings Section
                    const Text(
                      'Alarm Settings',
                      style: AppTextStyles.sectionHeader,
                    ),
                    const SizedBox(height: 12),

                    Container(
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
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 2,
                              ),
                              onTap: _showSoundPicker,
                              title: const Text(
                                'Alarm Sound',
                                style: AppTextStyles.body,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedSound,
                                    style: AppTextStyles.subtitle,
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textMuted,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                            const Divider(color: AppColors.border, height: 1),
                            SwitchListTile.adaptive(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 2,
                              ),
                              value: _isVibrationOn,
                              activeTrackColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() {
                                  _isVibrationOn = val;
                                });
                              },
                              title: const Text(
                                'Vibration',
                                style: AppTextStyles.body,
                              ),
                            ),
                            const Divider(color: AppColors.border, height: 1),
                            SwitchListTile.adaptive(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 2,
                              ),
                              value: _isVoiceOn,
                              activeTrackColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() {
                                  _isVoiceOn = val;
                                });
                              },
                              title: const Text(
                                'Voice Announcement',
                                style: AppTextStyles.body,
                              ),
                            ),
                            const Divider(color: AppColors.border, height: 1),
                            SwitchListTile.adaptive(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 2,
                              ),
                              value: _isRepeatOn,
                              activeTrackColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() {
                                  _isRepeatOn = val;
                                });
                              },
                              title: const Text(
                                'Repeat Alarm',
                                style: AppTextStyles.body,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Battery & Reliability Info Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Norivo will continue monitoring your journey even while your phone is locked. Battery optimized. Safe. Reliable.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: Color(0xFF1E293B),
                                fontWeight: FontWeight.w400,
                              ),
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

            // Bottom Sticky Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    label: 'Start Journey',
                    onPressed: _onStartJourney,
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: _onPreviewAlarm,
                    child: const Text(
                      'Preview Alarm',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
