import 'package:flutter_test/flutter_test.dart';
import 'package:norivo/core/models/destination_place.dart';
import 'package:norivo/core/models/saved_place.dart';
import 'package:norivo/core/services/saved_places_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SavedPlacesService tests', () {
    test('getSavedPlaces returns default initial places on first load', () async {
      final service = SavedPlacesService();
      final places = await service.getSavedPlaces();
      expect(places.isNotEmpty, true);
      expect(places.any((p) => p.label == 'Home'), true);
    });

    test('addSavedPlace, updateSavedPlace, and deleteSavedPlace work correctly', () async {
      final service = SavedPlacesService();
      await service.getSavedPlaces();

      const newPlace = SavedPlace(
        id: 'gym_123',
        label: 'Gym',
        destinationName: 'Fitness First',
        address: 'KLCC',
        latitude: 3.1579,
        longitude: 101.7116,
      );

      await service.addSavedPlace(newPlace);
      var places = await service.getSavedPlaces();
      expect(places.any((p) => p.id == 'gym_123'), true);

      const updatedPlace = SavedPlace(
        id: 'gym_123',
        label: 'Gym HQ',
        destinationName: 'Fitness First Platinum',
        address: 'KLCC Tower',
        latitude: 3.1579,
        longitude: 101.7116,
      );

      await service.updateSavedPlace(updatedPlace);
      places = await service.getSavedPlaces();
      final target = places.firstWhere((p) => p.id == 'gym_123');
      expect(target.label, 'Gym HQ');
      expect(target.destinationName, 'Fitness First Platinum');

      await service.deleteSavedPlace('gym_123');
      places = await service.getSavedPlaces();
      expect(places.any((p) => p.id == 'gym_123'), false);
    });

    test('toggleSavedPlace bookmarks and un-bookmarks a place with 1-tap', () async {
      final service = SavedPlacesService();
      await service.getSavedPlaces();

      const place = DestinationPlace(
        name: 'Penang Hill Station',
        address: 'Penang',
        latitude: 5.4084,
        longitude: 100.2772,
      );

      expect(service.isSaved(place), false);

      final isSavedNow = await service.toggleSavedPlace(place);
      expect(isSavedNow, true);
      expect(service.isSaved(place), true);

      final isSavedAfterToggle = await service.toggleSavedPlace(place);
      expect(isSavedAfterToggle, false);
      expect(service.isSaved(place), false);
    });
  });
}
