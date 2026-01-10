import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:allapalli_ride/features/passenger/domain/models/location_suggestion.dart';
import 'dart:math' as math;

/// Service for location search and autocomplete
class LocationService {
  // ignore: unused_field
  final Dio _dio;
  
  LocationService(this._dio);
  
  /// Get user's current location
  /// Returns null if permission denied or location unavailable
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permission permanently denied');
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      return position;
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }
  
  /// Get address from coordinates using reverse geocoding
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.locality}, ${place.administrativeArea}';
      }
      return null;
    } catch (e) {
      print('Error reverse geocoding: $e');
      return null;
    }
  }
  
  /// Check if a location is within service area (Legacy sync method)
  /// Deprecated: Use isLocationInServiceAreaAsync instead
  /// Always returns true for backward compatibility
  bool isLocationInServiceArea(double latitude, double longitude) {
    // This method is deprecated - use async version instead
    return true;
  }
  
  /// Calculate distance between two coordinates in kilometers
  /// Uses Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
        math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) *
        math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadiusKm * c;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }
  
  /// Find nearest predefined location to given coordinates
  /// Deprecated: Use API-based location search instead
  LocationSuggestion? findNearestLocation(double latitude, double longitude) {
    // This method is deprecated - locations are now fetched from API
    return null;
  }
  
  /// Get popular cities for displaying in placeholders
  /// Returns top cities from Cities API
  Future<List<String>> getPopularCitiesAsync({int limit = 10}) async {
    try {
      final locations = await getPopularLocations(limit: limit);
      return locations.map((loc) => loc.name).toList();
    } catch (e) {
      print('Error fetching popular cities: $e');
      return [];
    }
  }
  
  /// Get popular locations from API
  /// Returns popular cities and locations from the backend
  Future<List<LocationSuggestion>> getPopularLocations({int limit = 20}) async {
    try {
      final response = await _dio.get('/locations/popular', 
        queryParameters: {'limit': limit}
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => LocationSuggestion.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching popular locations: $e');
      return [];
    }
  }
  
  /// Search locations using API
  /// Returns a list of location suggestions matching the query
  Future<List<LocationSuggestion>> searchLocations(String query) async {
    if (query.trim().isEmpty || query.length < 2) {
      return [];
    }

    try {
      final response = await _dio.get('/locations/search', 
        queryParameters: {'query': query, 'limit': 10}
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => LocationSuggestion.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error searching locations via API: $e');
      return [];
    }
  }
  
  /// Check if a location is within service area by querying Cities API
  /// Returns true if the location exists in our database
  Future<bool> isLocationInServiceAreaAsync(double latitude, double longitude) async {
    try {
      final response = await _dio.get('/locations/check-service-area',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
        }
      );
      
      if (response.statusCode == 200 && response.data != null) {
        return response.data['inServiceArea'] as bool? ?? false;
      }
      
      return false;
    } catch (e) {
      print('Error checking service area: $e');
      return false;
    }
  }
}
