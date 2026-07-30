import 'package:flutter_test/flutter_test.dart';
import 'package:norivo/core/services/location_service.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  group('LocationService permission mapping', () {
    test('maps granted status correctly', () {
      expect(
        LocationService.mapPermissionStatus(PermissionStatus.granted),
        LocationPermissionState.granted,
      );
    });

    test('maps denied status correctly', () {
      expect(
        LocationService.mapPermissionStatus(PermissionStatus.denied),
        LocationPermissionState.denied,
      );
    });

    test('maps permanently denied status correctly', () {
      expect(
        LocationService.mapPermissionStatus(PermissionStatus.permanentlyDenied),
        LocationPermissionState.permanentlyDenied,
      );
    });
  });
}
