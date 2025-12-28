import 'dart:async';
import 'dart:math' as dart_math;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

/// Mock location service for testing intermediate stops without physically traveling
/// Enable this in debug mode to simulate GPS locations
class MockLocationService {
  static final MockLocationService _instance = MockLocationService._internal();
  factory MockLocationService() => _instance;
  MockLocationService._internal();

  bool _isMockEnabled = false;
  Position? _mockPosition;
  
  // Stream controller for mock location updates
  final _mockLocationController = StreamController<Position>.broadcast();
  Stream<Position> get mockLocationStream => _mockLocationController.stream;

  bool get isMockEnabled => _isMockEnabled;
  Position? get currentMockPosition => _mockPosition;

  /// Enable mock location mode
  void enableMockMode() {
    _isMockEnabled = true;
    debugPrint('🧪 Mock location mode ENABLED');
  }

  /// Disable mock location mode
  void disableMockMode() {
    _isMockEnabled = false;
    _mockPosition = null;
    debugPrint('🧪 Mock location mode DISABLED');
  }

  /// Set a mock location manually
  void setMockLocation({
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
    double? accuracy,
  }) {
    if (!_isMockEnabled) {
      debugPrint('⚠️ Mock mode not enabled. Call enableMockMode() first.');
      return;
    }

    _mockPosition = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: accuracy ?? 10.0,
      altitude: 0.0,
      heading: heading ?? 0.0,
      speed: speed ?? 0.0,
      speedAccuracy: 1.0,
      altitudeAccuracy: 1.0,
      headingAccuracy: 1.0,
    );

    debugPrint('📍 Mock location SET: $latitude, $longitude');
    _mockLocationController.add(_mockPosition!);
    debugPrint('📡 Mock location EMITTED to stream');
  }

  /// Quick presets for testing intermediate stops
  /// Set mock location from predefined coordinates
  void setMockLocationByName(String locationName) {
    if (!_isMockEnabled) {
      debugPrint('⚠️ Mock mode not enabled. Call enableMockMode() first.');
      return;
    }

    final coords = _predefinedLocations[locationName.toLowerCase()];
    if (coords == null) {
      debugPrint('⚠️ Location "$locationName" not found in presets');
      debugPrint('Available locations: ${_predefinedLocations.keys.join(", ")}');
      return;
    }

    setMockLocation(
      latitude: coords['lat']!,
      longitude: coords['lng']!,
      speed: coords['speed'] ?? 0.0,
      heading: coords['heading'] ?? 0.0,
    );
    debugPrint('📍 Moved to $locationName');
  }

  /// Predefined test locations (Add your actual intermediate stop coordinates here)
  final Map<String, Map<String, double>> _predefinedLocations = {
    // Your actual ride stops - Hyderabad locations
    'pickup': {
      'lat': 17.4243,  // Asian Living, Gachibowli
      'lng': 78.3463,
    },
    'stop1': {
      'lat': 17.4410,  // Wipro Circle, Gachibowli
      'lng': 78.3668,
    },
    'stop2': {
      'lat': 17.4347,  // Raidurg Metro Station
      'lng': 78.3473,
    },
    'stop3': {
      'lat': 17.4484,  // Hitec City Metro Station
      'lng': 78.3908,
    },
    'dropoff': {
      'lat': 17.4500,  // Durgam Cheruvu Metro Station
      'lng': 78.3875,
    },
    
    // Intermediate positions (between stops)
    'between-pickup-stop1': {
      'lat': 17.4327,  // Midpoint between pickup and stop1
      'lng': 78.3566,
    },
    'between-stop1-stop2': {
      'lat': 17.4379,  // Midpoint between stop1 and stop2
      'lng': 78.3571,
    },
    'between-stop2-stop3': {
      'lat': 17.4416,  // Midpoint between stop2 and stop3
      'lng': 78.3691,
    },
    'between-stop3-dropoff': {
      'lat': 17.4492,  // Midpoint between stop3 and dropoff
      'lng': 78.3892,
    },
    // Add more locations as needed
  };

  /// Get list of available predefined locations
  List<String> getAvailableLocations() {
    return _predefinedLocations.keys.toList();
  }

  /// Add a new predefined location dynamically
  void addLocation(String name, double latitude, double longitude) {
    _predefinedLocations[name.toLowerCase()] = {
      'lat': latitude,
      'lng': longitude,
    };
    debugPrint('✅ Added location: $name ($latitude, $longitude)');
  }

  /// Simulate movement along a route between two points
  Future<void> simulateMovement({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    int steps = 10,
    Duration stepDuration = const Duration(seconds: 2),
  }) async {
    if (!_isMockEnabled) {
      debugPrint('⚠️ Mock mode not enabled. Call enableMockMode() first.');
      return;
    }

    debugPrint('🚗 Simulating movement from ($fromLat, $fromLng) to ($toLat, $toLng)');

    for (int i = 0; i <= steps; i++) {
      final progress = i / steps;
      final lat = fromLat + (toLat - fromLat) * progress;
      final lng = fromLng + (toLng - fromLng) * progress;
      
      // Calculate heading (bearing)
      final heading = _calculateBearing(fromLat, fromLng, toLat, toLng);
      
      // Simulate speed (in m/s, ~30 km/h average)
      final speed = i > 0 && i < steps ? 8.33 : 0.0;

      setMockLocation(
        latitude: lat,
        longitude: lng,
        speed: speed,
        heading: heading,
      );

      if (i < steps) {
        await Future.delayed(stepDuration);
      }
    }

    debugPrint('✅ Arrived at destination');
  }

  /// Calculate bearing between two points
  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    const double toRadians = 3.14159265359 / 180.0;
    const double toDegrees = 180.0 / 3.14159265359;

    final dLon = (lon2 - lon1) * toRadians;
    final lat1Rad = lat1 * toRadians;
    final lat2Rad = lat2 * toRadians;

    final y = dart_math.sin(dLon) * dart_math.cos(lat2Rad);
    final x = dart_math.cos(lat1Rad) * dart_math.sin(lat2Rad) -
        dart_math.sin(lat1Rad) * dart_math.cos(lat2Rad) * dart_math.cos(dLon);

    final bearing = dart_math.atan2(y, x) * toDegrees;
    return (bearing + 360) % 360;
  }

  /// Clean up resources
  void dispose() {
    _mockLocationController.close();
  }
}
