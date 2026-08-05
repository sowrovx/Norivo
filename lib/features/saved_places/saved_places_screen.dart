import 'package:flutter/material.dart';

import '../../core/models/saved_place.dart';
import '../../core/router/app_router.dart';
import '../../core/services/saved_places_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  @override
  void initState() {
    super.initState();
    SavedPlacesService.instance.getSavedPlaces();
  }

  void _onPlaceTap(SavedPlace saved) {
    Navigator.of(context).pushNamed(
      AppRouter.alarmSetup,
      arguments: saved.toDestinationPlace(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Saved Places',
          style: AppTextStyles.heading1.copyWith(fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<List<SavedPlace>>(
          valueListenable: SavedPlacesService.instance.savedPlacesNotifier,
          builder: (context, savedPlaces, child) {
            if (savedPlaces.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bookmark_outline_rounded,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Saved Places Yet',
                        style: AppTextStyles.sectionHeader,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Bookmark places during search to quickly access them here.',
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
              itemCount: savedPlaces.length,
              separatorBuilder: (_, _) =>
                  Divider(color: Theme.of(context).dividerColor, height: 1),
              itemBuilder: (context, index) {
                final saved = savedPlaces[index];

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  onTap: () => _onPlaceTap(saved),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.place_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    saved.destinationName,
                    style: AppTextStyles.cardTitle.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: saved.address != null && saved.address!.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            saved.address!,
                            style: AppTextStyles.subtitle.copyWith(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      : null,
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.bookmark_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    onPressed: () {
                      SavedPlacesService.instance.deleteSavedPlace(saved.id);
                    },
                    tooltip: 'Remove Bookmark',
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
