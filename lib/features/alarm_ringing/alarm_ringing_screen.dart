import 'package:flutter/material.dart';

import '../../core/models/destination_place.dart';
import '../../core/router/app_router.dart';
import '../../core/services/alarm_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/primary_button.dart';

class AlarmRingingScreen extends StatefulWidget {
  const AlarmRingingScreen({
    super.key,
    this.destinationPlace,
  });

  final DestinationPlace? destinationPlace;

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  String get _destinationName =>
      widget.destinationPlace?.name ?? 'Selected Destination';

  String get _currentTimeText {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  @override
  void initState() {
    super.initState();
    AlarmService.instance.startAlarm();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.9,
      upperBound: 1.08,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    AlarmService.instance.stopAlarm();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _controller.value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 152,
                    height: 152,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.alarm_rounded,
                      size: 74,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'You have arrived',
                  style: AppTextStyles.heading1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  _destinationName,
                  style: AppTextStyles.sectionHeader.copyWith(
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your alarm is ringing to let you know you reached your destination.',
                  style: AppTextStyles.subtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 18,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('Current time: $_currentTimeText', style: AppTextStyles.body),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Stop Alarm',
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    AlarmService.instance.stopAlarm();
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil(AppRouter.home, (route) => false);
                  },
                  icon: Icons.stop_circle_rounded,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      AlarmService.instance.stopAlarm();
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil(AppRouter.home, (route) => false);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.border, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.snooze_rounded),
                    label: const Text('Snooze'),
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
