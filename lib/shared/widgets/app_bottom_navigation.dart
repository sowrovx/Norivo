/// Reusable bottom navigation bar widget for the main app views.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({super.key, this.currentIndex = 0, this.onTap});

  final int currentIndex;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final items = const [
      _BottomNavItemData(
        icon: Icons.home_rounded,
        activeIcon: Icons.home_rounded,
        label: 'Home',
      ),
      _BottomNavItemData(
        icon: Icons.explore_outlined,
        activeIcon: Icons.explore_rounded,
        label: 'Trips',
      ),
      _BottomNavItemData(
        icon: Icons.access_time_rounded,
        activeIcon: Icons.access_time_filled_rounded,
        label: 'History',
      ),
      _BottomNavItemData(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: 'Settings',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTap?.call(index),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected
                              ? AppColors.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: isSelected
                              ? AppTextStyles.bottomNavActive
                              : AppTextStyles.bottomNavInactive.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItemData {
  const _BottomNavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
