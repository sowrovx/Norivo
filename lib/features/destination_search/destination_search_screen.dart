/// Destination Search Screen matching the Figma design reference.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/models/destination_place.dart';
import '../../core/router/app_router.dart';
import '../../core/services/destination_search_service.dart';
import '../../core/services/location_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedPlace != null;

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
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      Navigator.of(context).pop();
                    },
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
                              _searchController.text = 'Home';
                              _searchDestinations('Home');
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            icon: Icons.school_outlined,
                            label: 'University',
                            onTap: () {
                              _searchController.text = 'University';
                              _searchDestinations('University');
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            icon: Icons.access_time_rounded,
                            label: 'Recent',
                            onTap: () {
                              _searchController.text =
                                  'Butterworth Railway Station';
                              _searchDestinations(
                                'Butterworth Railway Station',
                              );
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
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, _) =>
                              const Divider(color: AppColors.border, height: 1),
                          itemBuilder: (context, index) {
                            final place = _searchResults[index];
                            final isSelected =
                                _selectedPlace?.name == place.name &&
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
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryLight,
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
                                      : AppColors.onBackground,
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
                          const Divider(color: AppColors.border, height: 1),
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
                            style: AppTextStyles.subtitle.copyWith(
                              fontSize: 13,
                            ),
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
