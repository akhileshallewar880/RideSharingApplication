import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment_config.dart';
import 'admin_auth_service.dart';
import '../models/location_suggestion.dart';

/// Service for route calculation using Google Maps API via backend
class GoogleMapsService {
  final _authService = AdminAuthService();

  /// Get distance and duration between multiple locations using Google Maps API
  /// Returns a map with 'distanceKm', 'durationMinutes', 'distanceText' and 'durationText'
  Future<Map<String, dynamic>?> getDistanceAndDuration({
    required LocationSuggestion pickupLocation,
    required LocationSuggestion dropoffLocation,
    List<LocationSuggestion>? intermediateStops,
  }) async {
    try {
      // Build the route with all locations including coordinates
      final List<Map<String, dynamic>> locations = [
        {
          'name': pickupLocation.name,
          'latitude': pickupLocation.latitude,
          'longitude': pickupLocation.longitude,
        }
      ];
      
      if (intermediateStops != null && intermediateStops.isNotEmpty) {
        for (var stop in intermediateStops) {
          locations.add({
            'name': stop.name,
            'latitude': stop.latitude,
            'longitude': stop.longitude,
          });
        }
      }
      
      locations.add({
        'name': dropoffLocation.name,
        'latitude': dropoffLocation.latitude,
        'longitude': dropoffLocation.longitude,
      });

      final uri = Uri.parse('${AdminEnvironmentConfig.apiBaseUrl}/admin/rides/calculate-route');
      
      final token = await _authService.getToken();
      if (token == null) {
        print('No auth token available');
        return null;
      }

      final requestBody = {
        'locations': locations,
      };

      print('🗺️ Calculating route with ${locations.length} locations');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          print('✅ Route calculated: ${data['distanceText']} in ${data['durationText']}');
          return {
            'distanceKm': data['distanceKm'],
            'durationMinutes': data['durationMinutes'],
            'distanceText': data['distanceText'],
            'durationText': data['durationText'],
          };
        }
      }
      
      print('❌ Error response: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('❌ Error getting distance and duration: $e');
      return null;
    }
  }
}
