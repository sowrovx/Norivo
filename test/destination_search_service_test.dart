import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:norivo/core/models/destination_place.dart';
import 'package:norivo/core/services/destination_search_service.dart';

class _MockClient extends http.BaseClient {
  _MockClient(this.body);

  final String body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(Stream.value(utf8.encode(body)), 200);
  }
}

void main() {
  test('search returns parsed destination places', () async {
    final service = DestinationSearchService(
      client: _MockClient(
        r'''[{"display_name":"Central Station, Kuala Lumpur","lat":"3.1390","lon":"101.6869"}]''',
      ),
    );

    final results = await service.search('kuala lumpur');

    expect(results, hasLength(1));
    expect(results.first, isA<DestinationPlace>());
    expect(results.first.name, 'Central Station');
    expect(results.first.address, contains('Central Station'));
  });
}
