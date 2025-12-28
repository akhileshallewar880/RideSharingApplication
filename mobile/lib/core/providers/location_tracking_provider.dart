import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_tracking_service.dart';
import '../services/socket_service.dart';
import '../data/local/ride_cache.dart';

/// Provider for location tracking state management
final locationTrackingProvider = StateNotifierProvider<LocationTrackingNotifier, LocationTrackingState>((ref) {
  return LocationTrackingNotifier();
});

/// Location tracking state
class LocationTrackingState {
  final Position? currentLocation;
  final Position? driverLocation;
  final double? remainingDistance;
  final int? estimatedArrival; // in minutes
  final bool isTracking;
  final bool isSocketConnected;
  final CachedRide? cachedRide;
  final List<IntermediateStopData> intermediateStops;
  final String? currentRideId;
  final String? errorMessage;

  LocationTrackingState({
    this.currentLocation,
    this.driverLocation,
    this.remainingDistance,
    this.estimatedArrival,
    this.isTracking = false,
    this.isSocketConnected = false,
    this.cachedRide,
    this.intermediateStops = const [],
    this.currentRideId,
    this.errorMessage,
  });

  LocationTrackingState copyWith({
    Position? currentLocation,
    Position? driverLocation,
    double? remainingDistance,
    int? estimatedArrival,
    bool? isTracking,
    bool? isSocketConnected,
    CachedRide? cachedRide,
    List<IntermediateStopData>? intermediateStops,
    String? currentRideId,
    String? errorMessage,
  }) {
    return LocationTrackingState(
      currentLocation: currentLocation ?? this.currentLocation,
      driverLocation: driverLocation ?? this.driverLocation,
      remainingDistance: remainingDistance ?? this.remainingDistance,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      isTracking: isTracking ?? this.isTracking,
      isSocketConnected: isSocketConnected ?? this.isSocketConnected,
      cachedRide: cachedRide ?? this.cachedRide,
      intermediateStops: intermediateStops ?? this.intermediateStops,
      currentRideId: currentRideId ?? this.currentRideId,
      errorMessage: errorMessage,
    );
  }
}

/// Location tracking notifier
class LocationTrackingNotifier extends StateNotifier<LocationTrackingState> {
  LocationTrackingNotifier() : super(LocationTrackingState()) {
    _init();
  }

  final LocationTrackingService _locationService = LocationTrackingService();
  final SocketService _socketService = SocketService();
  final RideCacheManager _cacheManager = RideCacheManager();
  
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<LocationUpdateEvent>? _socketLocationSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  Timer? _syncTimer;

  void _init() {
    // Listen to socket connection status
    _connectionSubscription = _socketService.connectionStatus.listen((isConnected) {
      state = state.copyWith(isSocketConnected: isConnected);
      
      if (isConnected) {
        _syncPendingUpdates();
      }
    });
  }

  /// Start tracking as driver
  Future<void> startTracking(String rideId) async {
    debugPrint('🚀 Provider.startTracking() CALLED for ride: $rideId');
    debugPrint('Starting location tracking for ride: $rideId');
    
    // Load cached ride data
    final cachedRide = await _cacheManager.getCachedRide(rideId);
    if (cachedRide != null) {
      state = state.copyWith(
        cachedRide: cachedRide,
        intermediateStops: _parseIntermediateStops(cachedRide),
      );
    }
    
    // Connect to socket
    final socketConnected = await _socketService.connect();
    if (socketConnected) {
      _socketService.joinRide(rideId);
    }
    
    // Start GPS tracking
    final started = await _locationService.startTracking(rideId);
    if (started) {
      state = state.copyWith(
        isTracking: true,
        currentRideId: rideId,
      );
      
      // Listen to location updates
      debugPrint('🎧 SUBSCRIBING to location stream...');
      _locationSubscription = _locationService.locationStream.listen(
        (position) {
          debugPrint('🎧 SUBSCRIPTION RECEIVED: ${position.latitude}, ${position.longitude}');
          _handleLocationUpdate(position, rideId);
        },
        onError: (error) {
          debugPrint('❌ Stream error: $error');
        },
        onDone: () {
          debugPrint('✅ Stream done');
        },
      );
      
      // Start periodic sync timer (every 3 seconds for real-time updates)
      _syncTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        // Get current position and trigger update
        final position = await _locationService.getCurrentLocation();
        if (position != null) {
          _handleLocationUpdate(position, rideId);
        }
        _syncPendingUpdates();
      });
    } else {
      state = state.copyWith(
        errorMessage: 'Failed to start location tracking',
      );
    }
  }

  /// Handle location update from GPS
  void _handleLocationUpdate(Position position, String rideId) {
    debugPrint('🔄 Provider handling location update: ${position.latitude}, ${position.longitude}');
    
    state = state.copyWith(currentLocation: position);
    debugPrint('✅ Provider state updated with new location');
    
    // Update cached ride location
    _cacheManager.updateRideLocation(rideId, position.latitude, position.longitude);
    
    // Broadcast to passengers via socket
    if (state.isSocketConnected) {
      _socketService.sendLocationUpdate(
        rideId: rideId,
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,
        heading: position.heading,
      );
      debugPrint('📡 Location broadcasted via socket');
    }
    
    // Calculate remaining distance and ETA
    _updateMetrics(position);
  }

  /// Join ride as passenger to receive updates
  Future<void> joinRideAsPassenger(String rideId) async {
    debugPrint('Joining ride as passenger: $rideId');
    
    // Connect to socket
    final connected = await _socketService.connect();
    if (connected) {
      _socketService.joinRide(rideId);
      state = state.copyWith(currentRideId: rideId);
      
      // Listen for driver location updates
      _socketLocationSubscription = _socketService.locationUpdates.listen((event) {
        if (event.rideId == rideId) {
          final driverPosition = Position(
            latitude: event.latitude,
            longitude: event.longitude,
            speed: event.speed,
            heading: event.heading,
            accuracy: 0.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0,
            speedAccuracy: 0.0,
            timestamp: DateTime.now(),
          );
          
          state = state.copyWith(
            driverLocation: driverPosition,
            remainingDistance: event.remainingDistance,
            estimatedArrival: event.estimatedArrival?.toInt(),
          );
        }
      });
    }
  }

  /// Stop tracking
  Future<void> stopTracking() async {
    debugPrint('🛑 Stopping location tracking');
    debugPrint('🛑 Canceling subscriptions...');
    
    await _locationService.stopTracking();
    _socketService.leaveRide();
    
    await _locationSubscription?.cancel();
    await _socketLocationSubscription?.cancel();
    _syncTimer?.cancel();
    
    debugPrint('🛑 Subscriptions canceled');
    _locationSubscription = null;
    _socketLocationSubscription = null;
    
    state = LocationTrackingState();
    debugPrint('🛑 Tracking stopped, state reset');
  }

  /// Mark payment as collected
  Future<void> markPaymentCollected(String rideId, String bookingId, double amount) async {
    await _cacheManager.updatePassengerStatus(
      rideId,
      bookingId,
      paymentCollected: true,
      paymentStatus: 'paid',
    );
    
    // Notify via socket
    _socketService.notifyPaymentCollected(
      rideId: rideId,
      bookingId: bookingId,
      amount: amount,
    );
    
    // Reload cached ride
    final cachedRide = await _cacheManager.getCachedRide(rideId);
    if (cachedRide != null) {
      state = state.copyWith(cachedRide: cachedRide);
    }
  }

  /// Update trip metrics (distance, ETA)
  void _updateMetrics(Position currentPosition) {
    final stops = state.intermediateStops;
    if (stops.isEmpty) return;
    
    double totalRemaining = 0.0;
    final updatedStops = <IntermediateStopData>[];
    
    for (var stop in stops) {
      final distance = _calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        stop.latitude,
        stop.longitude,
      );
      
      // Mark stop as passed if within 200 meters
      final isPassed = distance < 0.2;
      
      if (!isPassed) {
        totalRemaining += distance;
      }
      
      updatedStops.add(IntermediateStopData(
        locationName: stop.locationName,
        latitude: stop.latitude,
        longitude: stop.longitude,
        distanceFromOrigin: distance,
        pickupCount: stop.pickupCount,
        dropoffCount: stop.dropoffCount,
        pickupPassengerNames: stop.pickupPassengerNames,
        dropoffPassengerNames: stop.dropoffPassengerNames,
        isPassed: isPassed,
      ));
    }
    
    // Calculate ETA
    final speed = currentPosition.speed * 3.6; // m/s to km/h
    final avgSpeed = speed > 5 ? speed : 40.0;
    final hours = totalRemaining / avgSpeed;
    final eta = (hours * 60).round();
    
    state = state.copyWith(
      intermediateStops: updatedStops,
      remainingDistance: totalRemaining,
      estimatedArrival: eta,
    );
  }

  /// Calculate distance in kilometers
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Parse intermediate stops from cached ride
  List<IntermediateStopData> _parseIntermediateStops(CachedRide ride) {
    // TODO: Parse from ride.intermediateStops and passenger data
    // For now, return empty list
    return [];
  }

  /// Sync pending location updates to server
  Future<void> _syncPendingUpdates() async {
    if (!state.isSocketConnected) return;
    
    final pending = await _locationService.getPendingUpdates();
    for (var update in pending) {
      _socketService.sendLocationUpdate(
        rideId: update.rideId,
        latitude: update.latitude,
        longitude: update.longitude,
        speed: update.speed,
        heading: update.heading,
      );
      
      // Mark as synced
      await _locationService.clearPendingUpdate(update.id);
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _socketLocationSubscription?.cancel();
    _connectionSubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}
