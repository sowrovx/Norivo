/// Settings screen for configuring alarm, location, and application preferences.
library;

import 'package:flutter/material.dart';

import '../../core/router/app_router.dart';
import '../../core/services/settings_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_bottom_navigation.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Temporary local state for interactive controls
  double _alarmVolume = 0.8;
  String _selectedSound = 'Alarm Clock (Default)';
  bool _isVibrationEnabled = true;
  bool _isVoiceEnabled = true;

  String _selectedDefaultRadius = '1 km';
  bool _isHighAccuracyGps = true;
  bool _isBackgroundTracking = true;

  String _selectedTravelMode = 'Drive';
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final radius = await SettingsService.instance.getDefaultRadius();
    final volume = await SettingsService.instance.getAlarmVolume();
    final isDark = await SettingsService.instance.isDarkMode();
    if (!mounted) return;
    setState(() {
      _selectedDefaultRadius = radius;
      _alarmVolume = volume;
      _isDarkMode = isDark;
    });
  }

  final List<String> _radiusOptions = const [
    '250 m',
    '500 m',
    '1 km',
    '2 km',
    '5 km',
  ];

  final List<String> _soundOptions = const [
    'Alarm Clock (Default)',
    'Chime Echo',
    'Gentle Breeze',
    'Morning Bell',
    'Digital Pulse',
  ];

  final List<String> _travelModes = const ['Drive', 'Transit', 'Walk'];

  void _onNavTap(int index) {
    if (index == 3) return; // Already on Settings
    if (index == 0) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRouter.home, (route) => false);
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

  void _showSoundPicker() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Alarm Sound',
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 16),
                ..._soundOptions.map((sound) {
                  final isSelected = sound == _selectedSound;
                  return ListTile(
                    title: Text(
                      sound,
                      style: AppTextStyles.body.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedSound = sound;
                      });
                      Navigator.of(context).pop();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTravelModePicker() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Default Travel Mode',
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 16),
                ..._travelModes.map((mode) {
                  final isSelected = mode == _selectedTravelMode;
                  return ListTile(
                    leading: Icon(
                      mode == 'Drive'
                          ? Icons.directions_car_rounded
                          : mode == 'Transit'
                              ? Icons.directions_bus_rounded
                              : Icons.directions_walk_rounded,
                      color: isSelected
                          ? AppColors.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      mode,
                      style: AppTextStyles.body.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedTravelMode = mode;
                      });
                      Navigator.of(context).pop();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInfoSnackBar(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title details'),
        duration: const Duration(seconds: 2),
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
              // Header
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
                      Icons.settings_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Settings', style: AppTextStyles.heading1),
                        SizedBox(height: 2),
                        Text(
                          'Preferences & alarm configuration',
                          style: AppTextStyles.bodyMuted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section 1: Alarm & Sound Settings
              const Text('Alarm & Sound', style: AppTextStyles.sectionHeader),
              const SizedBox(height: 12),
              _buildCardContainer(
                children: [
                  // Volume Slider
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.volume_up_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Alarm Volume',
                                style: AppTextStyles.cardTitle,
                              ),
                            ),
                            Text(
                              '${(_alarmVolume * 100).toInt()}%',
                              style: AppTextStyles.bodyMuted.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: Theme.of(context).dividerColor,
                            thumbColor: AppColors.primary,
                            overlayColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                          child: Slider.adaptive(
                            value: _alarmVolume,
                            onChanged: (val) {
                              setState(() {
                                _alarmVolume = val;
                              });
                              SettingsService.instance.setAlarmVolume(val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Theme.of(context).dividerColor, height: 1),

                  // Wake-up Sound Selector
                  ListTile(
                    leading: const Icon(
                      Icons.music_note_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Wake-up Sound',
                      style: AppTextStyles.cardTitle,
                    ),
                    subtitle: Text(
                      _selectedSound,
                      style: AppTextStyles.bodyMuted,
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onTap: _showSoundPicker,
                  ),
                  Divider(color: Theme.of(context).dividerColor, height: 1),

                  // Vibration Toggle
                  SwitchListTile.adaptive(
                    secondary: const Icon(
                      Icons.vibration_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Vibration',
                      style: AppTextStyles.cardTitle,
                    ),
                    subtitle: const Text(
                      'Vibrate during alarm trigger',
                      style: AppTextStyles.bodyMuted,
                    ),
                    value: _isVibrationEnabled,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _isVibrationEnabled = val;
                      });
                    },
                  ),
                  Divider(color: Theme.of(context).dividerColor, height: 1),

                  // Voice Alerts Toggle
                  SwitchListTile.adaptive(
                    secondary: const Icon(
                      Icons.record_voice_over_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Voice Announcements',
                      style: AppTextStyles.cardTitle,
                    ),
                    subtitle: const Text(
                      'Spoken arrival alerts',
                      style: AppTextStyles.bodyMuted,
                    ),
                    value: _isVoiceEnabled,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _isVoiceEnabled = val;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section 2: Location & Tracking
              const Text(
                'Location & Tracking',
                style: AppTextStyles.sectionHeader,
              ),
              const SizedBox(height: 12),
              _buildCardContainer(
                children: [
                  // Default Radius Selection
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.radar_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Default Wake-up Distance',
                                style: AppTextStyles.cardTitle,
                              ),
                            ),
                            Text(
                              _selectedDefaultRadius,
                              style: AppTextStyles.bodyMuted.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _radiusOptions.map((option) {
                            final isSelected = option == _selectedDefaultRadius;
                            return ChoiceChip(
                              label: Text(option),
                              selected: isSelected,
                              selectedColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Theme.of(context).dividerColor,
                                ),
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _selectedDefaultRadius = option;
                                });
                                SettingsService.instance.setDefaultRadius(option);
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Theme.of(context).dividerColor, height: 1),

                  // High Accuracy GPS Toggle
                  SwitchListTile.adaptive(
                    secondary: const Icon(
                      Icons.gps_fixed_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'High Accuracy GPS',
                      style: AppTextStyles.cardTitle,
                    ),
                    subtitle: const Text(
                      'Precise tracking for arrival detection',
                      style: AppTextStyles.bodyMuted,
                    ),
                    value: _isHighAccuracyGps,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _isHighAccuracyGps = val;
                      });
                    },
                  ),
                  Divider(color: Theme.of(context).dividerColor, height: 1),

                  // Background Tracking Toggle
                  SwitchListTile.adaptive(
                    secondary: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Background Location',
                      style: AppTextStyles.cardTitle,
                    ),
                    subtitle: const Text(
                      'Monitor location when screen is locked',
                      style: AppTextStyles.bodyMuted,
                    ),
                    value: _isBackgroundTracking,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _isBackgroundTracking = val;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section 3: App Preferences & Information
              const Text(
                'App Preferences',
                style: AppTextStyles.sectionHeader,
              ),
              const SizedBox(height: 12),
              _buildCardContainer(
                children: [
                  // Default Travel Mode
                  ListTile(
                    leading: const Icon(
                      Icons.directions_car_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Default Travel Mode',
                      style: AppTextStyles.cardTitle,
                    ),
                    subtitle: Text(
                      _selectedTravelMode,
                      style: AppTextStyles.bodyMuted,
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onTap: _showTravelModePicker,
                  ),
                  Divider(color: Theme.of(context).dividerColor, height: 1),

                  // Dark Mode Toggle
                  SwitchListTile.adaptive(
                    secondary: const Icon(
                      Icons.dark_mode_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Dark Mode',
                      style: AppTextStyles.cardTitle,
                    ),
                    subtitle: const Text(
                      'Enable dark theme',
                      style: AppTextStyles.bodyMuted,
                    ),
                    value: _isDarkMode,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _isDarkMode = val;
                      });
                      SettingsService.instance.setDarkMode(val);
                    },
                  ),
                  Divider(color: Theme.of(context).dividerColor, height: 1),

                  // App Version
                  const ListTile(
                    leading: Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      'Version',
                      style: AppTextStyles.cardTitle,
                    ),
                    subtitle: Text(
                      'Norivo v1.0.0 (Build 100)',
                      style: AppTextStyles.bodyMuted,
                    ),
                  ),
                  Divider(color: Theme.of(context).dividerColor, height: 1),

                  // Privacy Policy
                  ListTile(
                    leading: const Icon(
                      Icons.privacy_tip_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Privacy Policy',
                      style: AppTextStyles.cardTitle,
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onTap: () => _showInfoSnackBar('Privacy Policy'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 3,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildCardContainer({required List<Widget> children}) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}
