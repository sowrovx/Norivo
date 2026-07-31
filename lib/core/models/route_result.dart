import 'package:latlong2/latlong.dart';

/// Data class representing a calculated road route result between two locations.
class RouteResult {
  const RouteResult({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.polyline,
    this.isRoadRoute = true,
  });

  final double distanceMeters;
  final double durationSeconds;
  final List<LatLng> polyline;
  final bool isRoadRoute;

  /// Returns formatted road distance string (e.g. "1.5 km" or "500 m")
  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  /// Returns formatted road duration string (e.g. "18 min" or "1 hr 15 min")
  String get formattedDuration {
    final totalMins = (durationSeconds / 60).round();
    if (totalMins < 1) {
      return '< 1 min';
    }
    if (totalMins < 60) {
      return '$totalMins min';
    }
    final hrs = totalMins ~/ 60;
    final mins = totalMins % 60;
    if (mins == 0) {
      return '$hrs hr';
    }
    return '$hrs hr $mins min';
  }

  /// Returns formatted ETA time string (e.g. "08:30 PM")
  String get formattedEtaTime {
    final arrivalTime = DateTime.now().add(Duration(seconds: durationSeconds.round()));
    final hour = arrivalTime.hour % 12 == 0 ? 12 : arrivalTime.hour % 12;
    final minute = arrivalTime.minute.toString().padLeft(2, '0');
    final period = arrivalTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }
}
