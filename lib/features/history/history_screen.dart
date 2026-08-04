import 'package:flutter/material.dart';

import '../../core/models/journey_history_record.dart';
import '../../core/router/app_router.dart';
import '../../core/services/destination_search_service.dart';
import '../../core/services/journey_history_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_bottom_navigation.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    JourneyHistoryService.instance.getHistoryRecords();
  }

  void _onNavTap(int index) {
    if (index == 2) return;
    if (index == 0) {
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

  void _openSummary(JourneyHistoryRecord record) {
    Navigator.of(context).pushNamed(
      AppRouter.journeySummary,
      arguments: record,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Journey History',
          style: AppTextStyles.heading1,
        ),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<List<JourneyHistoryRecord>>(
          valueListenable: JourneyHistoryService.instance.historyNotifier,
          builder: (context, records, child) {
            if (records.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Journey History Yet',
                        style: AppTextStyles.sectionHeader,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Completed and cancelled journeys will automatically appear here.',
                        style: AppTextStyles.subtitle,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: records.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final record = records[index];
                return _buildHistoryCard(context, record);
              },
            );
          },
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 2,
        onTap: _onNavTap,
      ),
    );
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  Widget _buildHistoryCard(BuildContext context, JourneyHistoryRecord record) {
    final isCompleted = record.status.toLowerCase() == 'completed';
    final statusColor = isCompleted ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final dt = record.startTime;
    final formattedDate = '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
    final totalMins = (record.totalDurationSeconds / 60).round();
    final durationText = totalMins < 1 ? '< 1 min' : '$totalMins mins';
    final distanceText = record.totalDistanceMeters > 0
        ? DestinationSearchService.formatDistance(record.totalDistanceMeters)
        : '';

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _openSummary(record),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.place_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            record.destinationName,
                            style: AppTextStyles.cardTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            record.status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$formattedDate • $durationText${distanceText.isNotEmpty ? ' • $distanceText' : ''}',
                      style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
