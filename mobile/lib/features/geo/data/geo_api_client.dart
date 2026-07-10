import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../shared/models/geo_point.dart';
import '../domain/geo_suggestion.dart';

class GeoApiException implements Exception {
  GeoApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// HTTP-клиент geo API (NestJS → Яндекс).
class GeoApiClient {
  GeoApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<List<GeoSuggestion>> suggest(
    String query, {
    GeoPoint? bias,
  }) async {
    final params = <String, String>{'q': query};
    if (bias != null) {
      params['ll'] = '${bias.longitude},${bias.latitude}';
    }

    final uri = Uri.parse('$_baseUrl/geo/suggest').replace(queryParameters: params);
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw GeoApiException(
        'Suggest failed (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];

    return [
      for (final item in decoded)
        if (item is Map<String, dynamic>) _parseSuggestion(item),
    ];
  }

  Future<GeoSuggestion> reverseGeocode(GeoPoint point) async {
    final uri = Uri.parse('$_baseUrl/geo/geocode');
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'latitude': point.latitude,
            'longitude': point.longitude,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw GeoApiException(
        'Reverse geocode failed (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw GeoApiException('Invalid geocode response');
    }

    return _parseSuggestion(decoded, fallbackLocation: point);
  }

  GeoSuggestion _parseSuggestion(
    Map<String, dynamic> json, {
    GeoPoint? fallbackLocation,
  }) {
    final lat = (json['latitude'] as num?)?.toDouble();
    final lng = (json['longitude'] as num?)?.toDouble();
    final location = lat != null && lng != null
        ? GeoPoint(latitude: lat, longitude: lng)
        : fallbackLocation;

    if (location == null) {
      throw GeoApiException('Suggestion missing coordinates');
    }

    return GeoSuggestion(
      title: json['title'] as String? ?? 'Точка',
      subtitle: json['subtitle'] as String? ??
          json['address'] as String? ??
          '',
      location: location,
      cityId: json['cityId'] as String?,
    );
  }
}
