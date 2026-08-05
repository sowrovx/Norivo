import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/destination_place.dart';
import '../models/saved_place.dart';

class SavedPlacesService {
  SavedPlacesService({this.preferences});

  static final SavedPlacesService instance = SavedPlacesService();
  static const String keySavedPlaces = 'norivo_saved_places';

  SharedPreferences? preferences;

  final ValueNotifier<List<SavedPlace>> savedPlacesNotifier =
      ValueNotifier<List<SavedPlace>>([]);

  Future<SharedPreferences> _getPrefs() async {
    if (preferences != null) return preferences!;
    preferences = await SharedPreferences.getInstance();
    return preferences!;
  }

  Future<List<SavedPlace>> getSavedPlaces() async {
    try {
      final prefs = await _getPrefs();
      final rawList = prefs.getStringList(keySavedPlaces);
      if (rawList == null) {
        final initial = _defaultSavedPlaces();
        await saveAll(initial);
        savedPlacesNotifier.value = List.unmodifiable(initial);
        return initial;
      }
      final places = rawList
          .map((item) {
            try {
              return SavedPlace.decode(item);
            } catch (e) {
              return null;
            }
          })
          .whereType<SavedPlace>()
          .toList();

      savedPlacesNotifier.value = List.unmodifiable(places);
      return places;
    } catch (e) {
      debugPrint('Error reading saved places: $e');
      return [];
    }
  }

  Future<void> saveAll(List<SavedPlace> places) async {
    try {
      final prefs = await _getPrefs();
      final rawList = places.map((p) => p.encode()).toList();
      await prefs.setStringList(keySavedPlaces, rawList);
      savedPlacesNotifier.value = List.unmodifiable(places);
    } catch (e) {
      debugPrint('Error saving places list: $e');
    }
  }

  Future<void> addSavedPlace(SavedPlace place) async {
    try {
      final current = await getSavedPlaces();
      final updated = [...current, place];
      await saveAll(updated);
    } catch (e) {
      debugPrint('Error adding saved place: $e');
    }
  }

  Future<void> updateSavedPlace(SavedPlace place) async {
    try {
      final current = await getSavedPlaces();
      final index = current.indexWhere((p) => p.id == place.id);
      if (index != -1) {
        current[index] = place;
        await saveAll(current);
      }
    } catch (e) {
      debugPrint('Error updating saved place: $e');
    }
  }

  Future<void> deleteSavedPlace(String id) async {
    try {
      final current = await getSavedPlaces();
      final updated = current.where((p) => p.id != id).toList();
      await saveAll(updated);
    } catch (e) {
      debugPrint('Error deleting saved place: $e');
    }
  }

  Future<bool> toggleSavedPlace(DestinationPlace place) async {
    try {
      final current = await getSavedPlaces();
      final existingIndex = current.indexWhere(
        (p) =>
            p.destinationName == place.name &&
            p.latitude == place.latitude &&
            p.longitude == place.longitude,
      );

      if (existingIndex != -1) {
        final updated = List<SavedPlace>.from(current)..removeAt(existingIndex);
        await saveAll(updated);
        return false;
      } else {
        final newPlace = SavedPlace(
          id: '${DateTime.now().millisecondsSinceEpoch}',
          label: place.name,
          destinationName: place.name,
          address: place.address,
          latitude: place.latitude,
          longitude: place.longitude,
        );
        final updated = [...current, newPlace];
        await saveAll(updated);
        return true;
      }
    } catch (e) {
      debugPrint('Error toggling saved place: $e');
      return false;
    }
  }

  bool isSaved(DestinationPlace place) {
    return savedPlacesNotifier.value.any(
      (p) =>
          p.destinationName == place.name &&
          p.latitude == place.latitude &&
          p.longitude == place.longitude,
    );
  }

  List<SavedPlace> _defaultSavedPlaces() {
    return const [
      SavedPlace(
        id: 'home_default',
        label: 'Home',
        destinationName: 'Home',
        address: 'Sylhet, Bangladesh',
        latitude: 24.8949,
        longitude: 91.8687,
      ),
      SavedPlace(
        id: 'univ_default',
        label: 'University',
        destinationName: 'Universiti Albukhary',
        address: 'Alor Setar, Kedah',
        latitude: 6.1248,
        longitude: 100.3678,
      ),
      SavedPlace(
        id: 'work_default',
        label: 'Work',
        destinationName: 'KL Sentral Office',
        address: 'Kuala Lumpur, Malaysia',
        latitude: 3.1342,
        longitude: 101.6861,
      ),
    ];
  }
}
