import 'package:dio/dio.dart';

import 'api_client.dart';
import '../models/place.dart';

class GeocodingService {
  static const _base = 'https://geocoding-api.open-meteo.com/v1/search';

  Future<List<Place>> searchPlaces(String query, {String language = 'vi'}) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final Response res = await ApiClient.dio.get(
      _base,
      queryParameters: {
        'name': q,
        'count': 10,
        'language': language,
        'format': 'json',
      },
    );

    final data = res.data;
    final List results = (data is Map && data['results'] is List) ? data['results'] as List : const [];
    return results.map((e) => Place.fromGeocodingJson(e as Map<String, dynamic>)).toList();
  }
}
