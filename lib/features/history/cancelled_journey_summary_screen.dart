import 'package:flutter/material.dart';

import '../../core/models/journey_history_record.dart';
import '../../core/router/app_router.dart';
import '../../core/services/destination_search_service.dart';
import '../../core/services/journey_history_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_bottom_navigation.dart';
import '../../shared/widgets/primary_button.dart';

/// Cancelled Journey Summary Screen matching the Norivo design system.
class CancelledJourneySummaryScreen extends StatefulWidget {
  const CancelledJourneySummaryScreen({
    super.key,
    this.record,
  });

  final JourneyHistoryRecord? record;

  @override
  State<CancelledJourneySummaryScreen> createState() =>
      _CancelledJourneySummaryScreenState();
}

class _CancelledJourneySummaryScreenState
    extends State<CancelledJourneySummaryScreen> {
  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.record == null) {
      JourneyHistoryService.instance.getHistoryRecords();
    }
  }

  JourneyHistoryRecord _getEffectiveRecord(List<JourneyHistoryRecord> records) {
    if (widget.record != null) return widget.record!;

    if (records.isNotEmpty) {
      return records.firstWhere(
        (r) => r.status.toLowerCase() == 'cancelled',
        orElse: () => records.first,
      );
    }

    return JourneyHistoryRecord(
      id: 'none',
      destinationName: 'Not available',
      destinationAddress: 'Not available',
      destinationLatitude: 0.0,
      destinationLongitude: 0.0,
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      totalDurationSeconds: 0,
      totalDistanceMeters: 0.0,
      alarmThresholdMeters: 0.0,
      travelMode: 'Not available',
      status: 'Cancelled',
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'Not available';
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Not available';
    return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return 'Not available';
    final totalMins = (seconds / 60).round();
    if (totalMins < 1) return '< 1 min';
    if (totalMins < 60) return '$totalMins mins';
    final hrs = totalMins ~/ 60;
    final mins = totalMins % 60;
    return mins == 0 ? '$hrs hr' : '${hrs}h ${mins}m';
  }

  String _formatDistance(double meters) {
    if (meters <= 0) return 'Not available';
    return DestinationSearchService.formatDistance(meters);
  }

  String _formatThreshold(double meters) {
    if (meters <= 0) return 'Not available';
    if (meters >= 1000) {
      final km = (meters / 1000).toStringAsFixed(meters % 1000 == 0 ? 0 : 1);
      return '$km km';
    }
    return '${meters.toInt()} m';
  }

  String _calculateAverageSpeed(double distanceMeters, int durationSeconds) {
    if (distanceMeters <= 0 || durationSeconds <= 0) return 'Not available';
    final speedKmh = (distanceMeters / 1000.0) / (durationSeconds / 3600.0);
    return '${speedKmh.toStringAsFixed(1)} km/h';
  }

  void _onNavTap(BuildContext context, int index) {
    if (index == 0) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.home,
        (route) => false,
      );
    } else if (index == 2) {
      Navigator.of(context).pushNamed(AppRouter.history);
    } else if (index == 3) {
      Navigator.of(context).pushNamed(AppRouter.settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<JourneyHistoryRecord>>(
      valueListenable: JourneyHistoryService.instance.historyNotifier,
      builder: (context, records, _) {
        final rec = _getEffectiveRecord(records);
        const cancelledColor = Color(0xFFF59E0B);

        final destName = rec.destinationName.trim().isNotEmpty
            ? rec.destinationName
            : 'Not available';
        final destAddress = rec.destinationAddress != null &&
                rec.destinationAddress!.trim().isNotEmpty
            ? rec.destinationAddress!
            : 'Not available';
        final travelModeStr =
            rec.travelMode.trim().isNotEmpty ? rec.travelMode : 'Not available';

        final formattedDateStr =
            '${_formatDate(rec.startTime)} • ${_formatTime(rec.startTime)} - ${_formatTime(rec.endTime)}';
        final durationStr = _formatDuration(rec.totalDurationSeconds);
        final distanceStr = _formatDistance(rec.totalDistanceMeters);
        final thresholdStr = _formatThreshold(rec.alarmThresholdMeters);
        final speedStr = _calculateAverageSpeed(
          rec.totalDistanceMeters,
          rec.totalDurationSeconds,
        );

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // Top App Bar Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Back',
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Journey Summary',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              destName,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Graphic Card for Cancelled Journey
                        _buildHeroIllustrationCard(context),

                        const SizedBox(height: 14),

                        // Destination Header & Status Badge Container
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.cardShadow,
                                blurRadius: 12,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.place_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      destName,
                                      style: AppTextStyles.cardTitle.copyWith(
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      destAddress,
                                      style: AppTextStyles.subtitle.copyWith(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Cancelled Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: cancelledColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.cancel_rounded,
                                      size: 13,
                                      color: cancelledColor,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Cancelled',
                                      style: TextStyle(
                                        color: cancelledColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Detailed Journey Information Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.cardShadow,
                                blurRadius: 12,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Journey Information',
                                style: AppTextStyles.sectionHeader,
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                context,
                                icon: Icons.calendar_today_rounded,
                                label: 'Date & Time',
                                value: formattedDateStr,
                              ),
                              Divider(
                                color: Theme.of(context).dividerColor,
                                height: 16,
                              ),
                              _buildInfoRow(
                                context,
                                icon: Icons.timer_outlined,
                                label: 'Total Travel Time',
                                value: durationStr,
                              ),
                              Divider(
                                color: Theme.of(context).dividerColor,
                                height: 16,
                              ),
                              _buildInfoRow(
                                context,
                                icon: Icons.straighten_rounded,
                                label: 'Total Distance',
                                value: distanceStr,
                              ),
                              Divider(
                                color: Theme.of(context).dividerColor,
                                height: 16,
                              ),
                              _buildInfoRow(
                                context,
                                icon: Icons.alarm_on_rounded,
                                label: 'Alarm Threshold',
                                value: thresholdStr,
                              ),
                              Divider(
                                color: Theme.of(context).dividerColor,
                                height: 16,
                              ),
                              _buildInfoRow(
                                context,
                                icon: Icons.directions_subway_rounded,
                                label: 'Travel Mode',
                                value: travelModeStr,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Journey Insights Section
                        const Text(
                          'Journey Insights',
                          style: AppTextStyles.sectionHeader,
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: _buildInsightCard(
                                context,
                                icon: Icons.straighten_rounded,
                                title: distanceStr,
                                subtitle: 'Travel Distance',
                                caption: 'Distance before cancel',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildInsightCard(
                                context,
                                icon: Icons.timer_rounded,
                                title: durationStr,
                                subtitle: 'Travel Duration',
                                caption: 'Time before cancel',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildInsightCard(
                          context,
                          icon: Icons.speed_rounded,
                          title: speedStr,
                          subtitle: 'Average Speed',
                          caption: 'Trip average',
                          isWide: true,
                        ),

                        const SizedBox(height: 20),

                        // Action Buttons
                        PrimaryButton(
                          label: 'Return Home',
                          onPressed: () {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRouter.home,
                              (route) => false,
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed(AppRouter.history);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            child: const Text(
                              'View Journey History',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: AppBottomNavigation(
            currentIndex: 2,
            onTap: (index) => _onNavTap(context, index),
          ),
        );
      },
    );
  }

  Widget _buildHeroIllustrationCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 128,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD97706),
            Color(0xFFB45309),
            Color(0xFF78350F),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33D97706),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.cancel_rounded,
                    color: Color(0xFFD97706),
                    size: 38,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Journey Cancelled',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tracking stopped before arrival',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 17,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMuted.copyWith(fontSize: 11),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: AppTextStyles.cardTitle.copyWith(fontSize: 13.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String caption,
    bool isWide = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: isWide
          ? Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.cardTitle.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: AppTextStyles.subtitle.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  caption,
                  style: AppTextStyles.bodyMuted.copyWith(fontSize: 11),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: AppTextStyles.statValue.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  style: AppTextStyles.bodyMuted.copyWith(fontSize: 11),
                ),
              ],
            ),
    );
  }
}
