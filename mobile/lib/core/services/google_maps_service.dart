import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for interacting with Google Maps APIs
/// Provides directions, distance/ETA calculations, and geocoding
class GoogleMapsService {
  final String _apiKey;
  final http.Client _client;

  GoogleMapsService(this._apiKey, {http.Client? client})
      : _client = client ?? http.Client();

  /// Get route directions between two points with optional waypoints
  /// Returns polyline points and turn-by-turn steps
  Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
    String mode = 'driving',
  }) async {
    try {
      var url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=$mode'
          '&key=$_apiKey';

      if (waypoints != null && waypoints.isNotEmpty) {
        final waypointsStr =
            waypoints.map((w) => '${w.latitude},${w.longitude}').join('|');
        url += '&waypoints=$waypointsStr';
      }

      final response = await _client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          final steps = <DirectionStep>[];
          if (leg['steps'] != null) {
            for (var step in leg['steps']) {
              steps.add(DirectionStep(
                instructions: step['html_instructions'] ?? '',
                distanceMeters: step['distance']['value'] ?? 0,
                durationSeconds: step['duration']['value'] ?? 0,
                startLat: step['start_location']['lat']?.toDouble() ?? 0.0,
                startLng: step['start_location']['lng']?.toDouble() ?? 0.0,
                endLat: step['end_location']['lat']?.toDouble() ?? 0.0,
                endLng: step['end_location']['lng']?.toDouble() ?? 0.0,
              ));
            }
          }

          return DirectionsResult(
            polylinePoints: route['overview_polyline']['points'] ?? '',
            distanceMeters: leg['distance']['value'] ?? 0,
            durationSeconds: leg['duration']['value'] ?? 0,
            distanceText: leg['distance']['text'] ?? '',
            durationText: leg['duration']['text'] ?? '',
            steps: steps,
          );
        }

        debugPrint('Google Maps Directions API error: ${data['status']}');
        return null;
      }

      debugPrint('HTTP error: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error getting directions: $e');
      return null;
    }
  }

  /// Get distance and ETA between two points
  Future<DistanceResult?> getDistanceAndDuration({
    required LatLng origin,
    required LatLng destination,
    String mode = 'driving',
  }) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/distancematrix/json?'
          'origins=${origin.latitude},${origin.longitude}'
          '&destinations=${destination.latitude},${destination.longitude}'
          '&mode=$mode'
          '&key=$_apiKey';

      final response = await _client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' &&
            data['rows'] != null &&
            data['rows'].isNotEmpty) {
          final element = data['rows'][0]['elements'][0];

          if (element['status'] == 'OK') {
            return DistanceResult(
              distanceMeters: element['distance']['value'] ?? 0,
              distanceKm: (element['distance']['value'] ?? 0) / 1000.0,
              durationSeconds: element['duration']['value'] ?? 0,
              durationMinutes: ((element['duration']['value'] ?? 0) / 60.0).ceil(),
              distanceText: element['distance']['text'] ?? '',
              durationText: element['duration']['text'] ?? '',
            );
          }
        }

        debugPrint('Google Maps Distance Matrix API error: ${data['status']}');
        return null;
      }

      debugPrint('HTTP error: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error getting distance: $e');
      return null;
    }
  }

  /// Convert address to coordinates (geocoding)
  Future<LatLng?> geocodeAddress(String address) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?'
          'address=${Uri.encodeComponent(address)}'
          '&key=$_apiKey';

      final response = await _client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' &&
            data['results'] != null &&
            data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return LatLng(
            location['lat']?.toDouble() ?? 0.0,
            location['lng']?.toDouble() ?? 0.0,
          );
        }

        debugPrint('Geocoding API error: ${data['status']}');
        return null;
      }

      debugPrint('HTTP error: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error geocoding address: $e');
      return null;
    }
  }

  /// Convert coordinates to address (reverse geocoding)
  Future<String?> reverseGeocode(LatLng location) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?'
          'latlng=${location.latitude},${location.longitude}'
          '&key=$_apiKey';

      final response = await _client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' &&
            data['results'] != null &&
            data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }

        debugPrint('Reverse geocoding API error: ${data['status']}');
        return null;
      }

      debugPrint('HTTP error: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Result from directions API
class DirectionsResult {
  final String polylinePoints;
  final int distanceMeters;
  final int durationSeconds;
  final String distanceText;
  final String durationText;
  final List<DirectionStep> steps;

  DirectionsResult({
    required this.polylinePoints,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.distanceText,
    required this.durationText,
    required this.steps,
  });

  double get distanceKm => distanceMeters / 1000.0;
  int get durationMinutes => (durationSeconds / 60.0).ceil();
}

/// Individual step in directions
class DirectionStep {
  final String instructions;
  final int distanceMeters;
  final int durationSeconds;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;

  DirectionStep({
    required this.instructions,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
  });
}

/// Result from distance matrix API
class DistanceResult {
  final int distanceMeters;
  final double distanceKm;
  final int durationSeconds;
  final int durationMinutes;
  final String distanceText;
  final String durationText;

  DistanceResult({
    required this.distanceMeters,
    required this.distanceKm,
    required this.durationSeconds,
    required this.durationMinutes,
    required this.distanceText,
    required this.durationText,
  });
}
