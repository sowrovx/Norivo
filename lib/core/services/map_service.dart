import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class MapService {
  const MapService._();

  static LatLng buildDefaultCenter() {
    return const LatLng(3.1390, 101.6869);
  }

  static CircleAvatar buildUserMarkerAvatar() {
    return const CircleAvatar(
      radius: 14,
      backgroundColor: Color(0xFF2563EB),
      child: Icon(Icons.my_location_rounded, color: Colors.white, size: 16),
    );
  }
}
