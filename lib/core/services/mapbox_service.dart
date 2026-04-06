import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapboxService {
  final String _baseUrl = 'https://api.mapbox.com';
  final String _accessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';

  /// Fetch autocomplete suggestions for a given query.
  /// Uses the Mapbox Geocoding API.
  Future<List<dynamic>> getSuggestions(String query, {double? lat, double? lng}) async {
    if (query.isEmpty) return [];

    final String proximity = (lat != null && lng != null) ? '&proximity=$lng,$lat' : '';
    // Limit search to India (bbox) for better relevance
    const String bbox = '&bbox=68.16238,6.75351,97.39556,35.50870';
    
    final url = Uri.parse(
      '$_baseUrl/geocoding/v5/mapbox.places/$query.json?access_token=$_accessToken$proximity$bbox&autocomplete=true&types=poi,address,place',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['features'] ?? [];
      } else {
        throw Exception('Failed to load suggestions: ${response.statusCode}');
      }
    } catch (e) {
      print('MapboxService.getSuggestions error: $e');
      return [];
    }
  }

  /// Fetch a route between two points.
  /// Returns the full Directions API response.
  Future<Map<String, dynamic>?> getRoute(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/directions/v5/mapbox/driving/$startLng,$startLat;$endLng,$endLat?access_token=$_accessToken&geometries=polyline&overview=full&annotations=distance,duration',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch route: ${response.statusCode}');
      }
    } catch (e) {
      print('MapboxService.getRoute error: $e');
      return null;
    }
  }

  /// Helper to convert a Mapbox feature into a generic location map
  Map<String, dynamic> featureToLocation(dynamic feature) {
    final center = feature['center'];
    return {
      'place_name': feature['place_name'],
      'latitude': center[1],
      'longitude': center[0],
      'type': 'mapbox',
      'properties': feature['properties'] ?? {},
    };
  }
}
