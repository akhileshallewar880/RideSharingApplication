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
  
  /// Check if a location is within service area
  /// Returns true if the location is within 50km of any predefined location
  bool isLocationInServiceArea(double latitude, double longitude) {
    final predefinedLocations = _getPredefinedLocations();
    const maxDistanceKm = 50.0; // Service radius of 50km
    
    for (final location in predefinedLocations) {
      if (location.latitude == null || location.longitude == null) continue;
      
      final distance = _calculateDistance(
        latitude,
        longitude,
        location.latitude!,
        location.longitude!,
      );
      
      if (distance <= maxDistanceKm) {
        return true;
      }
    }
    
    return false;
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
  LocationSuggestion? findNearestLocation(double latitude, double longitude) {
    final predefinedLocations = _getPredefinedLocations();
    
    LocationSuggestion? nearest;
    double minDistance = double.infinity;
    
    for (final location in predefinedLocations) {
      if (location.latitude == null || location.longitude == null) continue;
      
      final distance = _calculateDistance(
        latitude,
        longitude,
        location.latitude!,
        location.longitude!,
      );
      
      if (distance < minDistance) {
        minDistance = distance;
        nearest = location;
      }
    }
    
    return nearest;
  }
  
  /// Search for locations by query string
  /// Returns a list of location suggestions
  Future<List<LocationSuggestion>> searchLocations(String query) async {
    try {
      // Use local predefined locations only
      // API disabled to ensure only curated Maharashtra locations are shown
      return _searchLocalLocations(query);
      
      /* API call disabled - uncomment to enable server-side location search
      // If backend has location search API, use it
      // Try API first (if available)
      try {
        final response = await _dio.get(
          '${AppConstants.apiBaseUrl}/locations/search',
          queryParameters: {'query': query, 'limit': 10},
        );
        
        if (response.statusCode == 200 && response.data['success'] == true) {
          final List<dynamic> locations = response.data['data']['locations'] ?? [];
          return locations
              .map((json) => LocationSuggestion.fromJson(json))
              .toList();
        }
      } catch (e) {
        // API not available, use fallback
        print('Location API not available, using fallback: $e');
      }
      
      // Fallback to predefined local locations
      return _searchLocalLocations(query);
      */
    } catch (e) {
      print('Error searching locations: $e');
      return _searchLocalLocations(query);
    }
  }
  
  /// Search predefined local locations
  /// This is a fallback when API is not available
  List<LocationSuggestion> _searchLocalLocations(String query) {
    final lowerQuery = query.toLowerCase().trim();
    
    if (lowerQuery.isEmpty) {
      return [];
    }
    
    // Predefined locations in and around Allapalli region
    final locations = _getPredefinedLocations();
    
    // Filter locations based on query
    final filtered = locations.where((location) {
      return location.name.toLowerCase().contains(lowerQuery) ||
          location.fullAddress.toLowerCase().contains(lowerQuery) ||
          (location.district?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
    
    // Sort by relevance (exact match first, then starts with, then contains)
    filtered.sort((a, b) {
      final aName = a.name.toLowerCase();
      final bName = b.name.toLowerCase();
      
      if (aName == lowerQuery) return -1;
      if (bName == lowerQuery) return 1;
      
      if (aName.startsWith(lowerQuery) && !bName.startsWith(lowerQuery)) return -1;
      if (bName.startsWith(lowerQuery) && !aName.startsWith(lowerQuery)) return 1;
      
      return aName.compareTo(bName);
    });
    
    // Return top 10 results
    return filtered.take(10).toList();
  }
  
  /// Get predefined locations in Maharashtra
  /// Focus on Gadchiroli, Chandrapur, and nearby districts
  List<LocationSuggestion> _getPredefinedLocations() {
    return [
      // Gadchiroli District
      LocationSuggestion(
        id: '1',
        name: 'Allapalli',
        state: 'Maharashtra',
        district: 'Gadchiroli',
        latitude: 19.4333,
        longitude: 79.9167,
        fullAddress: 'Allapalli, Maharashtra',
      ),
      LocationSuggestion(
        id: '2',
        name: 'Gadchiroli',
        state: 'Maharashtra',
        district: 'Gadchiroli',
        latitude: 19.7667,
        longitude: 80.0167,
        fullAddress: 'Gadchiroli, Maharashtra',
      ),
      LocationSuggestion(
        id: '3',
        name: 'Aheri',
        state: 'Maharashtra',
        district: 'Gadchiroli',
        latitude: 19.2667,
        longitude: 79.7333,
        fullAddress: 'Aheri, Maharashtra',
      ),
      LocationSuggestion(
        id: '4',
        name: 'Etapalli',
        state: 'Maharashtra',
        district: 'Gadchiroli',
        latitude: 19.1167,
        longitude: 80.0500,
        fullAddress: 'Etapalli, Maharashtra',
      ),
      LocationSuggestion(
        id: '5',
        name: 'Bhamragad',
        state: 'Maharashtra',
        district: 'Gadchiroli',
        latitude: 19.0833,
        longitude: 80.0667,
        fullAddress: 'Bhamragad, Maharashtra',
      ),
      LocationSuggestion(
        id: '6',
        name: 'Dhanora',
        state: 'Maharashtra',
        district: 'Gadchiroli',
        latitude: 19.8667,
        longitude: 79.7833,
        fullAddress: 'Dhanora, Maharashtra',
      ),
      LocationSuggestion(
        id: '7',
        name: 'Desaiganj (Wadsa)',
        state: 'Maharashtra',
        district: 'Gadchiroli',
        latitude: 20.0833,
        longitude: 79.9833,
        fullAddress: 'Desaiganj (Wadsa), Maharashtra',
      ),
      LocationSuggestion(
        id: '8',
        name: 'Armori',
        state: 'Maharashtra',
        district: 'Gadchiroli',
        latitude: 20.1500,
        longitude: 80.0333,
        fullAddress: 'Armori, Maharashtra',
      ),
      LocationSuggestion(
        id: '9',
        name: 'Kurkheda',
        state: 'Maharashtra',
        district: 'Gadchiroli',
        latitude: 19.9333,
        longitude: 80.2000,
        fullAddress: 'Kurkheda, Maharashtra',
      ),
      LocationSuggestion(
        id: '10',
        name: 'Korchi',
        state: 'Maharashtra',
        district: 'Gadchiroli',
        latitude: 19.6167,
        longitude: 79.8667,
        fullAddress: 'Korchi, Maharashtra',
      ),
      LocationSuggestion(
        id: '11',
        name: 'Chamorshi',
        state: 'Maharashtra',
        district: 'Gadchiroli',
        latitude: 19.6500,
        longitude: 79.5833,
        fullAddress: 'Chamorshi, Maharashtra',
      ),
      LocationSuggestion(
        id: '12',
        name: 'Mulchera',
        state: 'Maharashtra',
        district: 'Gadchiroli',
        latitude: 19.5833,
        longitude: 79.7167,
        fullAddress: 'Mulchera, Maharashtra',
      ),
      LocationSuggestion(
        id: '13',
        name: 'Sironcha',
        state: 'Maharashtra',
        district: 'Gadchiroli',
        latitude: 18.8333,
        longitude: 79.6667,
        fullAddress: 'Sironcha, Maharashtra',
      ),
      
      // Chandrapur District
      LocationSuggestion(
        id: '14',
        name: 'Chandrapur',
        state: 'Maharashtra',
        district: 'Chandrapur',
        latitude: 19.9500,
        longitude: 79.3000,
        fullAddress: 'Chandrapur, Maharashtra',
      ),
      LocationSuggestion(
        id: '15',
        name: 'Ballarpur',
        state: 'Maharashtra',
        district: 'Chandrapur',
        latitude: 19.8500,
        longitude: 79.3500,
        fullAddress: 'Ballarpur, Maharashtra',
      ),
      LocationSuggestion(
        id: '16',
        name: 'Bramhapuri',
        state: 'Maharashtra',
        district: 'Chandrapur',
        latitude: 20.6000,
        longitude: 79.8667,
        fullAddress: 'Bramhapuri, Maharashtra',
      ),
      LocationSuggestion(
        id: '17',
        name: 'Mul',
        state: 'Maharashtra',
        district: 'Chandrapur',
        latitude: 20.0833,
        longitude: 79.6833,
        fullAddress: 'Mul, Maharashtra',
      ),
      LocationSuggestion(
        id: '18',
        name: 'Warora',
        state: 'Maharashtra',
        district: 'Chandrapur',
        latitude: 20.2333,
        longitude: 79.0000,
        fullAddress: 'Warora, Maharashtra',
      ),
      LocationSuggestion(
        id: '19',
        name: 'Rajura',
        state: 'Maharashtra',
        district: 'Chandrapur',
        latitude: 19.7667,
        longitude: 79.3667,
        fullAddress: 'Rajura, Maharashtra',
      ),
      LocationSuggestion(
        id: '20',
        name: 'Gondpipri',
        state: 'Maharashtra',
        district: 'Chandrapur',
        latitude: 20.1833,
        longitude: 79.3000,
        fullAddress: 'Gondpipri, Maharashtra',
      ),
      LocationSuggestion(
        id: '21',
        name: 'Bhadravati',
        state: 'Maharashtra',
        district: 'Chandrapur',
        latitude: 20.1167,
        longitude: 79.6000,
        fullAddress: 'Bhadravati, Maharashtra',
      ),
      LocationSuggestion(
        id: '22',
        name: 'Sindewahi',
        state: 'Maharashtra',
        district: 'Chandrapur',
        latitude: 20.3333,
        longitude: 79.6667,
        fullAddress: 'Sindewahi, Maharashtra',
      ),
      LocationSuggestion(
        id: '23',
        name: 'Chimur',
        state: 'Maharashtra',
        district: 'Chandrapur',
        latitude: 19.6000,
        longitude: 79.3833,
        fullAddress: 'Chimur, Maharashtra',
      ),
      LocationSuggestion(
        id: '24',
        name: 'Pombhurna',
        state: 'Maharashtra',
        district: 'Chandrapur',
        latitude: 20.2500,
        longitude: 79.4833,
        fullAddress: 'Pombhurna, Maharashtra',
      ),
      LocationSuggestion(
        id: '25',
        name: 'Sawli',
        state: 'Maharashtra',
        district: 'Chandrapur',
        latitude: 19.7833,
        longitude: 79.3333,
        fullAddress: 'Sawli, Maharashtra',
      ),
      LocationSuggestion(
        id: '26',
        name: 'Korpana',
        state: 'Maharashtra',
        district: 'Chandrapur',
        latitude: 19.9000,
        longitude: 79.4000,
        fullAddress: 'Korpana, Maharashtra',
      ),
      LocationSuggestion(
        id: '27',
        name: 'Jivati',
        state: 'Maharashtra',
        district: 'Chandrapur',
        latitude: 19.4500,
        longitude: 79.5500,
        fullAddress: 'Jivati, Maharashtra',
      ),
      LocationSuggestion(
        id: '28',
        name: 'Nagbhir',
        state: 'Maharashtra',
        district: 'Chandrapur',
        latitude: 20.1333,
        longitude: 79.3833,
        fullAddress: 'Nagbhir, Maharashtra',
      ),
      
      // Nagpur District (Major City Nearby)
      LocationSuggestion(
        id: '29',
        name: 'Nagpur',
        state: 'Maharashtra',
        district: 'Nagpur',
        latitude: 21.1458,
        longitude: 79.0882,
        fullAddress: 'Nagpur, Maharashtra',
      ),
      LocationSuggestion(
        id: '30',
        name: 'Kamptee',
        state: 'Maharashtra',
        district: 'Nagpur',
        latitude: 21.2167,
        longitude: 79.2000,
        fullAddress: 'Kamptee, Maharashtra',
      ),
      LocationSuggestion(
        id: '31',
        name: 'Umred',
        state: 'Maharashtra',
        district: 'Nagpur',
        latitude: 20.8500,
        longitude: 79.3333,
        fullAddress: 'Umred, Maharashtra',
      ),
      LocationSuggestion(
        id: '32',
        name: 'Ramtek',
        state: 'Maharashtra',
        district: 'Nagpur',
        latitude: 21.3833,
        longitude: 79.3167,
        fullAddress: 'Ramtek, Maharashtra',
      ),
      LocationSuggestion(
        id: '33',
        name: 'Katol',
        state: 'Maharashtra',
        district: 'Nagpur',
        latitude: 21.2833,
        longitude: 78.5833,
        fullAddress: 'Katol, Maharashtra',
      ),
      LocationSuggestion(
        id: '34',
        name: 'Parseoni',
        state: 'Maharashtra',
        district: 'Nagpur',
        latitude: 20.8833,
        longitude: 78.9833,
        fullAddress: 'Parseoni, Maharashtra',
      ),
      LocationSuggestion(
        id: '35',
        name: 'Saoner',
        state: 'Maharashtra',
        district: 'Nagpur',
        latitude: 21.3833,
        longitude: 78.9167,
        fullAddress: 'Saoner, Maharashtra',
      ),
      
      // Gondia District
      LocationSuggestion(
        id: '36',
        name: 'Gondia',
        state: 'Maharashtra',
        district: 'Gondia',
        latitude: 21.4500,
        longitude: 80.2000,
        fullAddress: 'Gondia, Maharashtra',
      ),
      LocationSuggestion(
        id: '37',
        name: 'Tirora',
        state: 'Maharashtra',
        district: 'Gondia',
        latitude: 21.6833,
        longitude: 79.7167,
        fullAddress: 'Tirora, Maharashtra',
      ),
      LocationSuggestion(
        id: '38',
        name: 'Sadak Arjuni',
        state: 'Maharashtra',
        district: 'Gondia',
        latitude: 21.1667,
        longitude: 80.0333,
        fullAddress: 'Sadak Arjuni, Maharashtra',
      ),
      LocationSuggestion(
        id: '39',
        name: 'Goregaon',
        state: 'Maharashtra',
        district: 'Gondia',
        latitude: 21.6500,
        longitude: 80.0500,
        fullAddress: 'Goregaon, Maharashtra',
      ),
      LocationSuggestion(
        id: '40',
        name: 'Salekasa',
        state: 'Maharashtra',
        district: 'Gondia',
        latitude: 21.0333,
        longitude: 79.9833,
        fullAddress: 'Salekasa, Maharashtra',
      ),
      
      // Additional towns
      LocationSuggestion(
        id: '41',
        name: 'Palasgad',
        state: 'Maharashtra',
        district: 'Gadchiroli',
        latitude: 19.3000,
        longitude: 80.0000,
        fullAddress: 'Palasgad, Maharashtra',
      ),
      LocationSuggestion(
        id: '42',
        name: 'Jimalgatta',
        state: 'Maharashtra',
        district: 'Gadchiroli',
        latitude: 19.2000,
        longitude: 79.8000,
        fullAddress: 'Jimalgatta, Maharashtra',
      ),
      LocationSuggestion(
        id: '43',
        name: 'Kelapur',
        state: 'Maharashtra',
        district: 'Chandrapur',
        latitude: 19.5000,
        longitude: 79.7500,
        fullAddress: 'Kelapur, Maharashtra',
      ),
      LocationSuggestion(
        id: '44',
        name: 'Asian Living PG',
        state: 'Telangana',
        district: 'Hyderabad',
        latitude: 17.4243,
        longitude: 78.3463,
        fullAddress: 'Asian Living PG, Gachibowli, Hyderabad',
      ),
    ];
  }
}
