import 'dart:convert';

import 'destination_place.dart';

class SavedPlace {
  const SavedPlace({
    required this.id,
    required this.label,
    required this.destinationName,
    this.address,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String label;
  final String destinationName;
  final String? address;
  final double latitude;
  final double longitude;

  DestinationPlace toDestinationPlace() {
    return DestinationPlace(
      name: destinationName,
      address: address ?? '',
      latitude: latitude,
      longitude: longitude,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'destinationName': destinationName,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory SavedPlace.fromJson(Map<String, dynamic> json) {
    return SavedPlace(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? 'Custom',
      destinationName: json['destinationName'] as String? ?? 'Saved Place',
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String encode() => jsonEncode(toJson());

  factory SavedPlace.decode(String str) =>
      SavedPlace.fromJson(jsonDecode(str) as Map<String, dynamic>);
}
