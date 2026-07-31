import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/route_result.dart';

class RouteException implements Exception {
  const RouteException(this.message);
  final String message;

  @override
  String toString() => 'RouteException: $message';
}

/// Reusable service for calculating road routes, distance, ETA, and polyline coordinates.
class RouteService {
  RouteService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _osrmBaseUrl =
      'https://router.project-osrm.org/route/v1/driving';

  /// Calculates road route between start and destination coordinates.
  /// Uses Open Source Routing Machine (OSRM) driving profile with 5 second timeout.
  /// Catches SocketException, TimeoutException, and ClientException to prevent UI freeze.
  Future<RouteResult> calculateRoute({
    required double startLatitude,
    required double startLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    bool allowFallback = true,
  }) async {
    final startLatLng = LatLng(startLatitude, startLongitude);
    final destLatLng = LatLng(destinationLatitude, destinationLongitude);

    final directMeters = Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      destinationLatitude,
      destinationLongitude,
    );

    if (directMeters < 1) {
      return RouteResult(
        distanceMeters: 0,
        durationSeconds: 0,
        polyline: [startLatLng, destLatLng],
        isRoadRoute: false,
      );
    }

    final urlString =
        '$_osrmBaseUrl/${startLongitude.toStringAsFixed(6)},${startLatitude.toStringAsFixed(6)};${destinationLongitude.toStringAsFixed(6)},${destinationLatitude.toStringAsFixed(6)}?overview=full&geometries=geojson';

    final uri = Uri.parse(urlString);

    try {
      final response = await _client.get(uri).timeout(
            const Duration(seconds: 5),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['code'] == 'Ok' &&
            data['routes'] is List &&
            (data['routes'] as List).isNotEmpty) {
          final routeData =
              (data['routes'] as List).first as Map<String, dynamic>;
          final double distance = (routeData['distance'] as num).toDouble();
          final double duration = (routeData['duration'] as num).toDouble();

          final geometry = routeData['geometry'] as Map<String, dynamic>?;
          final coordinates = geometry?['coordinates'] as List<dynamic>?;

          final List<LatLng> polyline = [];
          if (coordinates != null) {
            for (final point in coordinates) {
              if (point is List && point.length >= 2) {
                final double lon = (point[0] as num).toDouble();
                final double lat = (point[1] as num).toDouble();
                polyline.add(LatLng(lat, lon));
              }
            }
          }

          if (polyline.isEmpty) {
            polyline.addAll([startLatLng, destLatLng]);
          }

          return RouteResult(
            distanceMeters: distance,
            durationSeconds: duration,
            polyline: polyline,
            isRoadRoute: true,
          );
        }
      }
    } on SocketException catch (e) {
      debugPrint('Route calculation SocketException: $e');
      if (!allowFallback) {
        throw const RouteException(
          'No internet connection. Please check your connection and try again.',
        );
      }
    } on TimeoutException catch (e) {
      debugPrint('Route calculation TimeoutException: $e');
      if (!allowFallback) {
        throw const RouteException(
          'The route request timed out. Please check your connection.',
        );
      }
    } on http.ClientException catch (e) {
      debugPrint('Route calculation ClientException: $e');
      if (!allowFallback) {
        throw const RouteException(
          'No internet connection. Please check your connection and try again.',
        );
      }
    } on FormatException catch (e) {
      debugPrint('Route calculation FormatException: $e');
      if (!allowFallback) {
        throw const RouteException(
          'Unexpected route response format.',
        );
      }
    } catch (e) {
      debugPrint('Route calculation error: $e');
      if (!allowFallback) {
        throw const RouteException(
          'Unable to calculate road route right now.',
        );
      }
    }

    if (!allowFallback) {
      throw const RouteException(
        'Unable to calculate road route right now.',
      );
    }

    // Fallback to straight-line geodesic distance with average urban driving speed (~50 km/h = 13.89 m/s)
    final fallbackDurationSeconds = directMeters / 13.89;

    return RouteResult(
      distanceMeters: directMeters,
      durationSeconds: fallbackDurationSeconds,
      polyline: [startLatLng, destLatLng],
      isRoadRoute: false,
    );
  }
}
