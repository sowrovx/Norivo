import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/services/location_service.dart';
import '../../core/services/map_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class CurrentLocationMapCard extends StatefulWidget {
  const CurrentLocationMapCard({super.key});

  @override
  State<CurrentLocationMapCard> createState() => _CurrentLocationMapCardState();
}

class _CurrentLocationMapCardState extends State<CurrentLocationMapCard> {
  final MapController _mapController = MapController();

  LatLng? _center;
  bool _isLoading = true;
  String? _errorMessage;
  LocationPermissionState _permissionState = LocationPermissionState.unknown;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    debugPrint('Location service enabled: $serviceEnabled');

    final permissionState = await LocationService.checkAndRequestPermission();
    if (!mounted) {
      return;
    }

    setState(() {
      _permissionState = permissionState;
    });
    debugPrint('Location permission status: $permissionState');

    if (!serviceEnabled) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Location services are disabled. Please enable GPS to see your current location.';
      });
      return;
    }

    if (permissionState != LocationPermissionState.granted) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            permissionState == LocationPermissionState.permanentlyDenied
            ? 'Location access is disabled in settings. Please enable it to see your position on the map.'
            : 'Location permission is required to show your current location.';
      });
      return;
    }

    await _moveToCurrentLocation();
  }

  Future<void> _moveToCurrentLocation() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    debugPrint('Location service enabled: $serviceEnabled');

    final permissionState = await LocationService.checkAndRequestPermission();
    if (!mounted) {
      return;
    }

    setState(() {
      _permissionState = permissionState;
    });
    debugPrint('Location permission status: $permissionState');

    if (!serviceEnabled) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Location services are disabled. Please enable GPS to see your current location.';
      });
      return;
    }

    if (permissionState != LocationPermissionState.granted) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            permissionState == LocationPermissionState.permanentlyDenied
            ? 'Location access is disabled in settings. Please enable it to see your position on the map.'
            : 'Location permission is required to show your current location.';
      });
      return;
    }

    final position = await LocationService.getCurrentPosition();
    if (!mounted) {
      return;
    }

    if (position == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to determine your location right now.';
      });
      return;
    }

    final latLng = LatLng(position.latitude, position.longitude);
    debugPrint(
      'Current location: lat=${position.latitude}, lng=${position.longitude}',
    );

    setState(() {
      _center = latLng;
      _isLoading = false;
      _errorMessage = null;
    });

    _mapController.move(latLng, 15);
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1),
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
            children: [
              const Icon(
                Icons.my_location_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Live location',
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
                ),
              ),
              if (_permissionState == LocationPermissionState.granted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Live',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _center != null ? _moveToCurrentLocation : null,
                icon: const Icon(Icons.my_location_rounded),
                color: AppColors.primary,
                tooltip: 'Center on current location',
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _buildMapBody(),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
            ),
          ],
          if (_permissionState ==
              LocationPermissionState.permanentlyDenied) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: openAppSettings,
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Open settings'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapBody() {
    if (_isLoading) {
      return Container(
        color: const Color(0xFFF2F6FB),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Preparing your map view...'),
            ],
          ),
        ),
      );
    }

    if (_center == null) {
      return Container(
        color: const Color(0xFFF2F6FB),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.map_outlined,
              size: 40,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Location view is currently unavailable.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center!,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.norivo.norivo',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _center!,
                  width: 40,
                  height: 40,
                  child: MapService.buildUserMarkerAvatar(),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'zoom-in',
                onPressed: _zoomIn,
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primary,
                child: const Icon(Icons.add_rounded),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'zoom-out',
                onPressed: _zoomOut,
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primary,
                child: const Icon(Icons.remove_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
