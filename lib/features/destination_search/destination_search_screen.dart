/// Destination Search Screen matching the Figma design reference.
library;

import 'package:flutter/material.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/quick_action_card.dart';
import '../../shared/widgets/search_field.dart';

class DestinationSearchScreen extends StatefulWidget {
  const DestinationSearchScreen({super.key});

  @override
  State<DestinationSearchScreen> createState() =>
      _DestinationSearchScreenState();
}

class _DestinationSearchScreenState extends State<DestinationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedDestination;

  // Placeholder data for recent searches matching Figma
  final List<_RecentSearchItem> _recentSearches = const [
    _RecentSearchItem(
      title: 'Butterworth Railway Station',
      subtitle: 'Penang',
    ),
    _RecentSearchItem(
      title: 'KL Sentral',
      subtitle: 'Kuala Lumpur',
    ),
    _RecentSearchItem(
      title: 'Universiti Albukhary',
      subtitle: 'Alor Setar',
    ),
    _RecentSearchItem(
      title: 'Home',
      subtitle: 'Sylhet',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectDestination(String title) {
    setState(() {
      _selectedDestination = title;
      _searchController.text = title;
    });
  }

  void _onContinuePressed() {
    if (_selectedDestination == null && _searchController.text.trim().isEmpty) {
      return;
    }
    final destination =
        _selectedDestination ?? _searchController.text.trim();
    Navigator.of(context).pushNamed(
      AppRouter.alarmSetup,
      arguments: destination,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection =
        _selectedDestination != null || _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header
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
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Choose Destination',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onBackground,
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic_none_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Main Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Focused Search Field
                    SearchField(
                      hintText: 'Search station, city or place...',
                      readOnly: false,
                      isFocused: true,
                      autofocus: false,
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _selectedDestination = val.isEmpty ? null : val;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Quick Filter Chips Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _FilterChip(
                            icon: Icons.home_outlined,
                            label: 'Home',
                            onTap: () => _selectDestination('Home'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            icon: Icons.school_outlined,
                            label: 'University',
                            onTap: () => _selectDestination('Universiti Albukhary'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            icon: Icons.access_time_rounded,
                            label: 'Recent',
                            onTap: () => _selectDestination('Butterworth Railway Station'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            icon: Icons.my_location_rounded,
                            label: 'Current Location',
                            onTap: () => _selectDestination('Current Location'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Recent Searches Section
                    const Text(
                      'Recent Searches',
                      style: AppTextStyles.sectionHeader,
                    ),
                    const SizedBox(height: 12),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentSearches.length,
                      separatorBuilder: (_, _) => const Divider(
                        color: AppColors.border,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final item = _recentSearches[index];
                        final isSelected =
                            _selectedDestination == item.title;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          onTap: () => _selectDestination(item.title),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.access_time_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: AppTextStyles.cardTitle.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.onBackground,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            item.subtitle,
                            style: AppTextStyles.subtitle.copyWith(fontSize: 13),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textMuted,
                            size: 22,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Popular Destinations Section
                    const Text(
                      'Popular Destinations',
                      style: AppTextStyles.sectionHeader,
                    ),
                    const SizedBox(height: 12),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 88,
                            child: QuickActionCard(
                              icon: Icons.flight_takeoff_rounded,
                              label: 'Airport',
                              onTap: () => _selectDestination('Airport'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 88,
                            child: QuickActionCard(
                              icon: Icons.train_rounded,
                              label: 'Train\nStation',
                              onTap: () => _selectDestination('Train Station'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 88,
                            child: QuickActionCard(
                              icon: Icons.directions_bus_rounded,
                              label: 'Bus\nTerminal',
                              onTap: () => _selectDestination('Bus Terminal'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 88,
                            child: QuickActionCard(
                              icon: Icons.school_rounded,
                              label: 'University',
                              onTap: () => _selectDestination('University'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 88,
                            child: QuickActionCard(
                              icon: Icons.shopping_bag_outlined,
                              label: 'Shopping\nMall',
                              onTap: () => _selectDestination('Shopping Mall'),
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

            // Bottom Sticky Continue Bar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: PrimaryButton(
                label: 'Continue',
                onPressed: hasSelection ? _onContinuePressed : null,
                backgroundColor: hasSelection
                    ? AppColors.primary
                    : const Color(0xFFE2E8F0),
                textColor: hasSelection
                    ? Colors.white
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentSearchItem {
  const _RecentSearchItem({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}
