import 'package:flutter/material.dart';

import '../../core/models/journey_history_record.dart';
import '../../core/router/app_router.dart';
import '../../core/services/destination_search_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_bottom_navigation.dart';

class JourneySummaryScreen extends StatelessWidget {
  const JourneySummaryScreen({
    super.key,
    required this.record,
  });

  final JourneyHistoryRecord record;

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  bool get _isCompleted => record.status.toLowerCase() == 'completed';

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String get _formattedDate {
    final dt = record.startTime;
    return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String get _formattedTimeRange {
    return '${_formatTime(record.startTime)} - ${_formatTime(record.endTime)}';
  }

  String get _formattedDuration {
    final totalMins = (record.totalDurationSeconds / 60).round();
    if (totalMins < 1) return '< 1 min';
    if (totalMins < 60) return '$totalMins mins';
    final hrs = totalMins ~/ 60;
    final mins = totalMins % 60;
    return mins == 0 ? '$hrs hr' : '${hrs}h ${mins}m';
  }

  String get _formattedDistance {
    if (record.totalDistanceMeters <= 0) return 'N/A';
    return DestinationSearchService.formatDistance(record.totalDistanceMeters);
  }

  String get _formattedThreshold {
    final meters = record.alarmThresholdMeters;
    if (meters >= 1000) {
      final km = (meters / 1000).toStringAsFixed(meters % 1000 == 0 ? 0 : 1);
      return '$km km';
    }
    return '${meters.toInt()} m';
  }

  void _onNavTap(BuildContext context, int index) {
    if (index == 2) {
      Navigator.of(context).pop();
    } else if (index == 0) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.home,
        (route) => false,
      );
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

  @override
  Widget build(BuildContext context) {
    final statusColor = _isCompleted ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Journey Summary',
          style: AppTextStyles.sectionHeader,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.destinationName,
                                style: AppTextStyles.heading1.copyWith(fontSize: 22),
                              ),
                              if (record.destinationAddress != null &&
                                  record.destinationAddress!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  record.destinationAddress!,
                                  style: AppTextStyles.bodyMuted,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isCompleted
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                size: 14,
                                color: statusColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                record.status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_formattedDate • $_formattedTimeRange',
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Metrics Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      context,
                      icon: Icons.timer_outlined,
                      label: 'Duration',
                      value: _formattedDuration,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      context,
                      icon: Icons.straighten_rounded,
                      label: 'Distance',
                      value: _formattedDistance,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      context,
                      icon: Icons.notifications_active_outlined,
                      label: 'Alarm Radius',
                      value: _formattedThreshold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      context,
                      icon: Icons.directions_car_outlined,
                      label: 'Travel Mode',
                      value: record.travelMode,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Coordinates Details Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Destination Coordinates',
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${record.destinationLatitude.toStringAsFixed(4)}° N, ${record.destinationLongitude.toStringAsFixed(4)}° E',
                      style: AppTextStyles.bodyMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 2,
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
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
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 10),
          Text(label, style: AppTextStyles.bodyMuted.copyWith(fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.cardTitle.copyWith(fontSize: 16)),
        ],
      ),
    );
  }
}
