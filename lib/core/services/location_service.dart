import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

enum LocationPermissionState { unknown, granted, denied, permanentlyDenied }

class LocationService {
  const LocationService._();

  static Future<LocationPermissionState> checkAndRequestPermission() async {
    final status = await Permission.location.status;
    if (status.isGranted) {
      return LocationPermissionState.granted;
    }

    if (status.isPermanentlyDenied) {
      return LocationPermissionState.permanentlyDenied;
    }

    final requested = await Permission.location.request();
    if (requested.isGranted) {
      return LocationPermissionState.granted;
    }

    if (requested.isPermanentlyDenied) {
      return LocationPermissionState.permanentlyDenied;
    }

    return LocationPermissionState.denied;
  }

  static Future<Position?> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    final permissionState = await checkAndRequestPermission();
    if (permissionState != LocationPermissionState.granted) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  static LocationPermissionState mapPermissionStatus(PermissionStatus status) {
    if (status.isGranted) {
      return LocationPermissionState.granted;
    }
    if (status.isPermanentlyDenied) {
      return LocationPermissionState.permanentlyDenied;
    }
    return LocationPermissionState.denied;
  }
}
