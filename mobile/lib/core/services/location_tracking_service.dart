import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../data/local/location_queue.dart';
import 'mock_location_service.dart';

/// Service for real-time GPS location tracking with offline support
/// Tracks location every 30 seconds for UI updates and stores every 15 minutes
/// Supports mock locations for testing intermediate stops
class LocationTrackingService {
  static final LocationTrackingService _instance = LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  final LocationQueue _locationQueue = LocationQueue();
  final MockLocationService _mockLocationService = MockLocationService();
  
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<Position>? _mockPositionSubscription;
  Position? _lastPosition;
  DateTime? _lastStoredTime;
  
  // Stream controller for location updates
  final _locationController = StreamController<Position>.broadcast();
  Stream<Position> get locationStream => _locationController.stream;
  
  Position? get lastPosition => _lastPosition;
  bool _isTracking = false;
  bool get isTracking => _isTracking;
  
  // Mock location getters
  bool get isMockEnabled => _mockLocationService.isMockEnabled;
  MockLocationService get mockService => _mockLocationService;
  
  // Tracking configuration
  static const Duration _storageInterval = Duration(minutes: 15);
  static const double _minDistanceForUpdate = 10.0; // meters
  
  /// Start tracking location for a specific ride
  Future<bool> startTracking(String rideId) async {
    if (_isTracking) {
      debugPrint('Location tracking already active');
      return true;
    }
    
    try {
      // Use mock location if enabled (for testing)
      if (_mockLocationService.isMockEnabled) {
        debugPrint('🧪 Using MOCK location tracking for ride: $rideId');
        
        // Listen to mock location stream
        _mockPositionSubscription = _mockLocationService.mockLocationStream.listen(
          (Position position) {
            debugPrint('📥 RECEIVED mock location: ${position.latitude}, ${position.longitude}');
            _handlePositionUpdate(position, rideId);
          },
        );
        
        // If there's already a mock position, use it
        if (_mockLocationService.currentMockPosition != null) {
          debugPrint('📥 Using existing mock position');
          _handlePositionUpdate(_mockLocationService.currentMockPosition!, rideId);
        }
        
        _isTracking = true;
        _lastStoredTime = DateTime.now();
        debugPrint('✅ Mock tracking started successfully');
        return true;
      }
      
      // Normal GPS tracking
      // Check and request permissions
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        debugPrint('Location permission denied');
        return false;
      }
      
      // Configure location settings
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0, // Update immediately on any location change
      );
      
      // Start listening to position stream
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _handlePositionUpdate(position, rideId);
        },
        onError: (error) {
          debugPrint('Location tracking error: $error');
        },
      );
      
      _isTracking = true;
      _lastStoredTime = DateTime.now();
      debugPrint('Location tracking started for ride: $rideId');
      return true;
      
    } catch (e) {
      debugPrint('Failed to start location tracking: $e');
      return false;
    }
  }
  
  /// Stop tracking location
  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    await _mockPositionSubscription?.cancel();
    _positionSubscription = null;
    _mockPositionSubscription = null;
    _isTracking = false;
    _lastPosition = null;
    _lastStoredTime = null;
    debugPrint('Location tracking stopped');
  }
  
  /// Handle position updates
  void _handlePositionUpdate(Position position, String rideId) {
    // For mock locations, skip distance check to allow immediate updates
    final isMockLocation = _mockLocationService.isMockEnabled;
    
    // Check if position changed significantly (skip for mock locations)
    if (!isMockLocation && _lastPosition != null) {
      final distance = _calculateDistance(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      
      if (distance < _minDistanceForUpdate) {
        return; // Skip insignificant updates
      }
    }
    
    _lastPosition = position;
    
    // Emit to stream for UI updates
    _locationController.add(position);
    debugPrint('📍 Location updated: ${position.latitude}, ${position.longitude}');
    
    // Store to queue every 15 minutes (or immediately for mock locations)
    final now = DateTime.now();
    if (isMockLocation || _lastStoredTime == null || 
        now.difference(_lastStoredTime!) >= _storageInterval) {
      _storeLocationUpdate(position, rideId);
      _lastStoredTime = now;
    }
  }
  
  /// Store location update to offline queue
  void _storeLocationUpdate(Position position, String rideId) {
    final locationData = LocationUpdateData(
      rideId: rideId,
      latitude: position.latitude,
      longitude: position.longitude,
      speed: position.speed,
      heading: position.heading,
      accuracy: position.accuracy,
      timestamp: DateTime.now(),
    );
    
    _locationQueue.addLocationUpdate(locationData);
    debugPrint('Location stored: ${position.latitude}, ${position.longitude}');
  }
  
  /// Check and request location permissions
  Future<bool> _checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;
    
    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled');
      return false;
    }
    
    // Check permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permission denied');
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission denied forever');
      return false;
    }
    
    return true;
  }
  
  /// Get current location once
  Future<Position?> getCurrentLocation() async {
    try {
      // Return mock position if mock mode is enabled
      if (_mockLocationService.isMockEnabled) {
        return _mockLocationService.currentMockPosition ?? _lastPosition;
      }
      
      final hasPermission = await _checkPermissions();
      if (!hasPermission) return null;
      
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Failed to get current location: $e');
      return null;
    }
  }
  
  /// Calculate distance between two coordinates in meters using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }
  
  /// Calculate distance to a specific location in kilometers
  double? calculateDistanceToLocation(double targetLat, double targetLon) {
    if (_lastPosition == null) return null;
    
    final distanceInMeters = _calculateDistance(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      targetLat,
      targetLon,
    );
    
    return distanceInMeters / 1000; // Convert to kilometers
  }
  
  /// Estimate time to reach location based on current speed
  Duration? estimateTimeToLocation(double targetLat, double targetLon) {
    if (_lastPosition == null) return null;
    
    final distanceKm = calculateDistanceToLocation(targetLat, targetLon);
    if (distanceKm == null) return null;
    
    // Use current speed or assume average speed of 40 km/h
    final speedKmh = _lastPosition!.speed > 0 
        ? _lastPosition!.speed * 3.6  // m/s to km/h
        : 40.0; // Default average speed
    
    final hours = distanceKm / speedKmh;
    return Duration(minutes: (hours * 60).round());
  }
  
  /// Get pending location updates from offline queue
  Future<List<LocationUpdateData>> getPendingUpdates() async {
    return await _locationQueue.getPendingUpdates();
  }
  
  /// Clear pending updates after successful sync
  Future<void> clearPendingUpdate(String id) async {
    await _locationQueue.removeUpdate(id);
  }
  
  /// Dispose resources
  void dispose() {
    _positionSubscription?.cancel();
    _locationController.close();
    _isTracking = false;
  }
}

/// Model for location update data
class LocationUpdateData {
  final String id;
  final String rideId;
  final double latitude;
  final double longitude;
  final double speed;
  final double heading;
  final double accuracy;
  final DateTime timestamp;
  final bool synced;
  
  LocationUpdateData({
    String? id,
    required this.rideId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.heading,
    required this.accuracy,
    required this.timestamp,
    this.synced = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'rideId': rideId,
    'latitude': latitude,
    'longitude': longitude,
    'speed': speed,
    'heading': heading,
    'accuracy': accuracy,
    'timestamp': timestamp.toIso8601String(),
    'synced': synced,
  };
  
  factory LocationUpdateData.fromJson(Map<String, dynamic> json) {
    return LocationUpdateData(
      id: json['id'] as String,
      rideId: json['rideId'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      speed: json['speed'] as double,
      heading: json['heading'] as double,
      accuracy: json['accuracy'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
      synced: json['synced'] as bool? ?? false,
    );
  }
  
  LocationUpdateData copyWith({bool? synced}) {
    return LocationUpdateData(
      id: id,
      rideId: rideId,
      latitude: latitude,
      longitude: longitude,
      speed: speed,
      heading: heading,
      accuracy: accuracy,
      timestamp: timestamp,
      synced: synced ?? this.synced,
    );
  }
}
