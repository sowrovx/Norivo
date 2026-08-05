/// Destination Search Screen matching the Figma design reference.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/models/destination_place.dart';
import '../../core/models/saved_place.dart';
import '../../core/router/app_router.dart';
import '../../core/services/destination_search_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/saved_places_service.dart';
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
  final DestinationSearchService _searchService = DestinationSearchService();
  final List<_RecentSearchItem> _recentSearches = const [
    _RecentSearchItem(title: 'Butterworth Railway Station', subtitle: 'Penang'),
    _RecentSearchItem(title: 'KL Sentral', subtitle: 'Kuala Lumpur'),
    _RecentSearchItem(title: 'Universiti Albukhary', subtitle: 'Alor Setar'),
    _RecentSearchItem(title: 'Home', subtitle: 'Sylhet'),
  ];

  Timer? _debounceTimer;
  StreamSubscription<Position>? _positionSubscription;
  DestinationPlace? _selectedPlace;
  List<DestinationPlace> _searchResults = const [];
  bool _isLoading = false;
  String? _errorMessage;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _refreshCurrentLocation();
    _initPositionSubscription();
    SavedPlacesService.instance.getSavedPlaces();
  }

  Future<void> _initPositionSubscription() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      final permission = await LocationService.checkAndRequestPermission();
      if (permission != LocationPermissionState.granted) return;

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).listen(
        (position) {
          if (!mounted) return;
          setState(() {
            _currentPosition = position;
          });
        },
        onError: (error) {
          debugPrint('Location stream error: $error');
        },
      );
    } catch (error) {
      debugPrint('Error initializing position stream: $error');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _positionSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentPosition();
      if (!mounted) {
        return;
      }
      setState(() {
        _currentPosition = position;
      });
    } catch (error) {
      debugPrint('Current location unavailable: $error');
    }
  }

  void _selectDestination(DestinationPlace place) {
    setState(() {
      _selectedPlace = place;
      _searchController.text = place.name;
      _errorMessage = null;
    });
  }

  void _onContinuePressed() {
    FocusScope.of(context).unfocus();
    if (_selectedPlace == null) {
      return;
    }

    Navigator.of(
      context,
    ).pushNamed(AppRouter.alarmSetup, arguments: _selectedPlace);
  }

  void _searchDestinations(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 450), () async {
      if (!mounted) {
        return;
      }

      if (query.trim().isEmpty) {
        setState(() {
          _searchResults = const [];
          _isLoading = false;
          _errorMessage = null;
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final results = await _searchService.search(query);
        if (!mounted) {
          return;
        }
        setState(() {
          _searchResults = results;
          _isLoading = false;
          _errorMessage = results.isEmpty ? 'No matching places found.' : null;
        });
      } on DestinationSearchException catch (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _searchResults = const [];
          _isLoading = false;
          _errorMessage = error.message;
        });
      } catch (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _searchResults = const [];
          _isLoading = false;
          _errorMessage = 'Unable to search destinations right now.';
        });
      }
    });
  }

  IconData _iconForLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('home')) return Icons.home_rounded;
    if (lower.contains('school') || lower.contains('univ')) return Icons.school_rounded;
    if (lower.contains('work') || lower.contains('office')) return Icons.work_rounded;
    return Icons.star_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedPlace != null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Theme.of(context).colorScheme.onSurface,
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
                    child: Text(
                      'Choose Destination',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
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
                      isFocused: false,
                      controller: _searchController,
                      onChanged: (val) {
                        if (_selectedPlace != null &&
                            _searchController.text != _selectedPlace!.name) {
                          setState(() {
                            _selectedPlace = null;
                          });
                        }
                        _searchDestinations(val);
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
                            onTap: () {
                              final saved = SavedPlacesService.instance.savedPlacesNotifier.value
                                  .firstWhere(
                                    (p) => p.label.toLowerCase() == 'home',
                                    orElse: () => const SavedPlace(
                                      id: '',
                                      label: 'Home',
                                      destinationName: 'Home',
                                      latitude: 24.8949,
                                      longitude: 91.8687,
                                    ),
                                  );
                              _selectDestination(saved.toDestinationPlace());
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            icon: Icons.school_outlined,
                            label: 'University',
                            onTap: () {
                              final saved = SavedPlacesService.instance.savedPlacesNotifier.value
                                  .firstWhere(
                                    (p) =>
                                        p.label.toLowerCase().contains('univ') ||
                                        p.label.toLowerCase().contains('school'),
                                    orElse: () => const SavedPlace(
                                      id: '',
                                      label: 'University',
                                      destinationName: 'Universiti Albukhary',
                                      latitude: 6.1248,
                                      longitude: 100.3678,
                                    ),
                                  );
                              _selectDestination(saved.toDestinationPlace());
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            icon: Icons.work_outline_rounded,
                            label: 'Work',
                            onTap: () {
                              final saved = SavedPlacesService.instance.savedPlacesNotifier.value
                                  .firstWhere(
                                    (p) => p.label.toLowerCase() == 'work',
                                    orElse: () => const SavedPlace(
                                      id: '',
                                      label: 'Work',
                                      destinationName: 'KL Sentral Office',
                                      latitude: 3.1342,
                                      longitude: 101.6861,
                                    ),
                                  );
                              _selectDestination(saved.toDestinationPlace());
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            icon: Icons.my_location_rounded,
                            label: 'Current Location',
                            onTap: () {
                              _searchController.text = 'Current Location';
                              _searchDestinations('Current Location');
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Saved Places Section
                    const Text(
                      'Saved Places',
                      style: AppTextStyles.sectionHeader,
                    ),
                    const SizedBox(height: 8),

                    ValueListenableBuilder<List<SavedPlace>>(
                      valueListenable: SavedPlacesService.instance.savedPlacesNotifier,
                      builder: (context, savedPlaces, child) {
                        if (savedPlaces.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No saved places yet. Tap the bookmark icon on any search result to save it.',
                              style: AppTextStyles.bodyMuted,
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: savedPlaces.length,
                          separatorBuilder: (_, _) =>
                              Divider(color: Theme.of(context).dividerColor, height: 1),
                          itemBuilder: (context, index) {
                            final saved = savedPlaces[index];
                            final place = saved.toDestinationPlace();
                            final isSelected = _selectedPlace?.name == place.name &&
                                _selectedPlace?.latitude == place.latitude &&
                                _selectedPlace?.longitude == place.longitude;

                            final distanceText = _currentPosition == null
                                ? null
                                : DestinationSearchService.formatDistance(
                                    Geolocator.distanceBetween(
                                      _currentPosition!.latitude,
                                      _currentPosition!.longitude,
                                      place.latitude,
                                      place.longitude,
                                    ),
                                  );

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              onTap: () => _selectDestination(place),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _iconForLabel(saved.label),
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      saved.label,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      saved.destinationName,
                                      style: AppTextStyles.cardTitle.copyWith(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Theme.of(context).colorScheme.onSurface,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      saved.address ?? '',
                                      style: AppTextStyles.subtitle.copyWith(fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (distanceText != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      distanceText,
                                      style: AppTextStyles.subtitle.copyWith(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
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

                    const SizedBox(height: 24),

                    if (_isLoading ||
                        _errorMessage != null ||
                        _searchResults.isNotEmpty) ...[
                      const Text(
                        'Search Results',
                        style: AppTextStyles.sectionHeader,
                      ),
                      const SizedBox(height: 12),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            _errorMessage!,
                            style: AppTextStyles.bodyMuted,
                          ),
                        )
                      else
                        ValueListenableBuilder<List<SavedPlace>>(
                          valueListenable: SavedPlacesService.instance.savedPlacesNotifier,
                          builder: (context, savedPlaces, child) {
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _searchResults.length,
                              separatorBuilder: (_, _) =>
                                  Divider(color: Theme.of(context).dividerColor, height: 1),
                              itemBuilder: (context, index) {
                                final place = _searchResults[index];
                                final isSelected =
                                    _selectedPlace?.name == place.name &&
                                    _selectedPlace?.latitude == place.latitude &&
                                    _selectedPlace?.longitude == place.longitude;

                                final isSaved = savedPlaces.any(
                                  (p) =>
                                      p.destinationName == place.name &&
                                      p.latitude == place.latitude &&
                                      p.longitude == place.longitude,
                                );

                                final distanceText = _currentPosition == null
                                    ? null
                                    : DestinationSearchService.formatDistance(
                                        Geolocator.distanceBetween(
                                          _currentPosition!.latitude,
                                          _currentPosition!.longitude,
                                          place.latitude,
                                          place.longitude,
                                        ),
                                      );

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  onTap: () => _selectDestination(place),
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.place_outlined,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    place.name,
                                    style: AppTextStyles.cardTitle.copyWith(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Theme.of(context).colorScheme.onSurface,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: distanceText == null
                                      ? Text(
                                          place.address,
                                          style: AppTextStyles.subtitle.copyWith(
                                            fontSize: 13,
                                          ),
                                        )
                                      : Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                place.address,
                                                style: AppTextStyles.subtitle
                                                    .copyWith(fontSize: 13),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              distanceText,
                                              style: AppTextStyles.subtitle
                                                  .copyWith(
                                                    fontSize: 12,
                                                    color: AppColors.primary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      isSaved
                                          ? Icons.bookmark_rounded
                                          : Icons.bookmark_border_rounded,
                                      color: isSaved
                                          ? AppColors.primary
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      SavedPlacesService.instance.toggleSavedPlace(place);
                                    },
                                    tooltip: isSaved ? 'Remove Bookmark' : 'Save Place',
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                    ],

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
                      separatorBuilder: (_, _) =>
                          Divider(color: Theme.of(context).dividerColor, height: 1),
                      itemBuilder: (context, index) {
                        final item = _recentSearches[index];
                        final isSelected = _selectedPlace?.name == item.title;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          onTap: () {
                            _searchController.text = item.title;
                            _searchDestinations(item.title);
                          },
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                                  : Theme.of(context).colorScheme.onSurface,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            item.subtitle,
                            style: AppTextStyles.subtitle.copyWith(
                              fontSize: 13,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                              onTap: () {
                                _searchController.text = 'Airport';
                                _searchDestinations('Airport');
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 88,
                            child: QuickActionCard(
                              icon: Icons.train_rounded,
                              label: 'Train\nStation',
                              onTap: () {
                                _searchController.text = 'Train Station';
                                _searchDestinations('Train Station');
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 88,
                            child: QuickActionCard(
                              icon: Icons.directions_bus_rounded,
                              label: 'Bus\nTerminal',
                              onTap: () {
                                _searchController.text = 'Bus Terminal';
                                _searchDestinations('Bus Terminal');
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 88,
                            child: QuickActionCard(
                              icon: Icons.school_rounded,
                              label: 'University',
                              onTap: () {
                                _searchController.text = 'University';
                                _searchDestinations('University');
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 88,
                            child: QuickActionCard(
                              icon: Icons.shopping_bag_outlined,
                              label: 'Shopping\nMall',
                              onTap: () {
                                _searchController.text = 'Shopping Mall';
                                _searchDestinations('Shopping Mall');
                              },
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
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                ),
              ),
              child: PrimaryButton(
                label: 'Continue',
                onPressed: hasSelection ? _onContinuePressed : null,
                backgroundColor: hasSelection
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                textColor: hasSelection
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
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
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primary, size: 16),
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
  const _RecentSearchItem({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}
