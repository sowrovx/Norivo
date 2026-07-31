import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/destination_place.dart';

class DestinationSearchException implements Exception {
  const DestinationSearchException(this.message);

  final String message;
}

class DestinationSearchService {
  DestinationSearchService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';
  static const String _userAgent = 'Norivo/1.0 (Flutter destination alarm app)';

  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  Future<List<DestinationPlace>> search(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return const [];
    }

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'q': trimmedQuery,
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': '5',
      },
    );

    debugPrint('Destination search request URL: $uri');

    try {
      final response = await _client
          .get(
            uri,
            headers: {'User-Agent': _userAgent, 'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('Destination search status code: ${response.statusCode}');
      debugPrint('Destination search response body: ${response.body}');

      if (response.statusCode != 200) {
        if (response.statusCode == 429) {
          throw const DestinationSearchException(
            'The search service is busy right now. Please try again in a moment.',
          );
        }
        if (response.statusCode >= 500) {
          throw const DestinationSearchException(
            'The destination search service is temporarily unavailable. Please try again.',
          );
        }
        throw const DestinationSearchException(
          'The destination search service could not complete that request.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List<dynamic>) {
        throw const FormatException(
          'Unexpected destination search response format.',
        );
      }

      return decoded.map((item) {
        final map = item as Map<String, dynamic>;
        final displayName = (map['display_name'] as String?) ?? 'Unknown place';
        final latitude = double.tryParse(map['lat']?.toString() ?? '');
        final longitude = double.tryParse(map['lon']?.toString() ?? '');

        if (latitude == null || longitude == null) {
          throw const FormatException('Invalid place coordinates.');
        }

        debugPrint('Destination location: lat=$latitude, lon=$longitude');

        return DestinationPlace(
          name: displayName.split(',').first.trim(),
          address: displayName,
          latitude: latitude,
          longitude: longitude,
        );
      }).toList();
    } on SocketException catch (error) {
      debugPrint('Destination search SocketException: $error');
      throw const DestinationSearchException(
        'No internet connection detected. Please check your connection and try again.',
      );
    } on TimeoutException catch (error) {
      debugPrint('Destination search TimeoutException: $error');
      throw const DestinationSearchException(
        'The destination search timed out. Please try again.',
      );
    } on FormatException catch (error) {
      debugPrint('Destination search FormatException: $error');
      throw const DestinationSearchException(
        'The destination search returned an unexpected response. Please try another place.',
      );
    } on DestinationSearchException {
      rethrow;
    } catch (error) {
      debugPrint('Destination search unexpected error: $error');
      throw const DestinationSearchException(
        'Unable to search destinations right now.',
      );
    }
  }
}
