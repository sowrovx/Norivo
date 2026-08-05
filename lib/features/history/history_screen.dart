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

  Future<bool?> _confirmDeleteSingle(JourneyHistoryRecord record) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Delete Journey Record',
            style: AppTextStyles.sectionHeader,
          ),
          content: Text(
            'Are you sure you want to delete the journey history record for "${record.destinationName}"?',
            style: AppTextStyles.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onClearAllPressed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Clear Journey History',
            style: AppTextStyles.sectionHeader,
          ),
          content: const Text(
            'Are you sure you want to clear all journey history records? This action cannot be undone.',
            style: AppTextStyles.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await JourneyHistoryService.instance.clearHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<JourneyHistoryRecord>>(
      valueListenable: JourneyHistoryService.instance.historyNotifier,
      builder: (context, records, child) {
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
            actions: [
              if (records.isNotEmpty)
                TextButton.icon(
                  onPressed: _onClearAllPressed,
                  icon: const Icon(
                    Icons.delete_sweep_rounded,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                  label: const Text(
                    'Clear All',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: records.isEmpty
                ? Center(
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
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: records.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return Dismissible(
                        key: Key(record.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _confirmDeleteSingle(record),
                        onDismissed: (_) {
                          JourneyHistoryService.instance.deleteRecord(record.id);
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        child: _buildHistoryCard(context, record),
                      );
                    },
                  ),
          ),
          bottomNavigationBar: AppBottomNavigation(
            currentIndex: 2,
            onTap: _onNavTap,
          ),
        );
      },
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
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: () async {
                  final confirmed = await _confirmDeleteSingle(record);
                  if (confirmed == true) {
                    await JourneyHistoryService.instance.deleteRecord(record.id);
                  }
                },
                tooltip: 'Delete',
              ),
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
