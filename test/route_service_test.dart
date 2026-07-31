import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:norivo/core/services/route_service.dart';

void main() {
  group('RouteService tests', () {
    test('calculateRoute parses OSRM JSON response correctly', () async {
      final mockResponseJson = '''
      {
        "code": "Ok",
        "routes": [
          {
            "distance": 3200.5,
            "duration": 480.0,
            "geometry": {
              "coordinates": [
                [101.6869, 3.1390],
                [101.6880, 3.1400],
                [101.6900, 3.1420]
              ]
            }
          }
        ]
      }
      ''';

      final client = MockClient((request) async {
        return http.Response(mockResponseJson, 200);
      });

      final service = RouteService(client: client);
      final result = await service.calculateRoute(
        startLatitude: 3.1390,
        startLongitude: 101.6869,
        destinationLatitude: 3.1420,
        destinationLongitude: 101.6900,
      );

      expect(result.isRoadRoute, isTrue);
      expect(result.distanceMeters, 3200.5);
      expect(result.durationSeconds, 480.0);
      expect(result.polyline.length, 3);
      expect(result.polyline.first.latitude, 3.1390);
      expect(result.polyline.first.longitude, 101.6869);
      expect(result.formattedDistance, '3.2 km');
      expect(result.formattedDuration, '8 min');
    });

    test('calculateRoute falls back to direct distance when server responds with error', () async {
      final client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = RouteService(client: client);
      final result = await service.calculateRoute(
        startLatitude: 3.1390,
        startLongitude: 101.6869,
        destinationLatitude: 3.1490,
        destinationLongitude: 101.6969,
      );

      expect(result.isRoadRoute, isFalse);
      expect(result.distanceMeters, greaterThan(0));
      expect(result.polyline.length, 2);
    });

    test('calculateRoute handles SocketException gracefully with fallback', () async {
      final client = MockClient((request) async {
        throw const SocketException('No internet connection');
      });

      final service = RouteService(client: client);
      final result = await service.calculateRoute(
        startLatitude: 3.1390,
        startLongitude: 101.6869,
        destinationLatitude: 3.1490,
        destinationLongitude: 101.6969,
      );

      expect(result.isRoadRoute, isFalse);
      expect(result.distanceMeters, greaterThan(0));
    });

    test('calculateRoute throws RouteException when allowFallback is false and network fails', () async {
      final client = MockClient((request) async {
        throw const SocketException('No internet connection');
      });

      final service = RouteService(client: client);
      await expectLater(
        service.calculateRoute(
          startLatitude: 3.1390,
          startLongitude: 101.6869,
          destinationLatitude: 3.1490,
          destinationLongitude: 101.6969,
          allowFallback: false,
        ),
        throwsA(isA<RouteException>()),
      );
    });
  });
}
