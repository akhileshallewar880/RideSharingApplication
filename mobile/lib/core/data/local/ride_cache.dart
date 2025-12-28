import 'package:hive/hive.dart';

part 'ride_cache.g.dart';

/// Cached ride data for offline access
@HiveType(typeId: 0)
class CachedRide {
  @HiveField(0)
  final String rideId;
  
  @HiveField(1)
  final String rideNumber;
  
  @HiveField(2)
  final String pickupLocation;
  
  @HiveField(3)
  final String dropoffLocation;
  
  @HiveField(4)
  final List<String> intermediateStops;
  
  @HiveField(5)
  final String departureTime;
  
  @HiveField(6)
  final String status;
  
  @HiveField(7)
  final List<CachedPassenger> passengers;
  
  @HiveField(8)
  final double totalDistance;
  
  @HiveField(9)
  final int estimatedDuration;
  
  @HiveField(10)
  final String? routePolyline;
  
  @HiveField(11)
  final DateTime cachedAt;
  
  @HiveField(12)
  final double? currentLatitude;
  
  @HiveField(13)
  final double? currentLongitude;
  
  CachedRide({
    required this.rideId,
    required this.rideNumber,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.intermediateStops,
    required this.departureTime,
    required this.status,
    required this.passengers,
    required this.totalDistance,
    required this.estimatedDuration,
    this.routePolyline,
    required this.cachedAt,
    this.currentLatitude,
    this.currentLongitude,
  });
  
  CachedRide copyWith({
    String? status,
    List<CachedPassenger>? passengers,
    double? currentLatitude,
    double? currentLongitude,
  }) {
    return CachedRide(
      rideId: rideId,
      rideNumber: rideNumber,
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      intermediateStops: intermediateStops,
      departureTime: departureTime,
      status: status ?? this.status,
      passengers: passengers ?? this.passengers,
      totalDistance: totalDistance,
      estimatedDuration: estimatedDuration,
      routePolyline: routePolyline,
      cachedAt: DateTime.now(),
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
    );
  }
}

/// Cached passenger information
@HiveType(typeId: 1)
class CachedPassenger {
  @HiveField(0)
  final String bookingId;
  
  @HiveField(1)
  final String passengerName;
  
  @HiveField(2)
  final String phoneNumber;
  
  @HiveField(3)
  final int passengerCount;
  
  @HiveField(4)
  final String pickupLocation;
  
  @HiveField(5)
  final String dropoffLocation;
  
  @HiveField(6)
  final String boardingStatus;
  
  @HiveField(7)
  final String paymentStatus;
  
  @HiveField(8)
  final double totalFare;
  
  @HiveField(9)
  final bool paymentCollected;
  
  CachedPassenger({
    required this.bookingId,
    required this.passengerName,
    required this.phoneNumber,
    required this.passengerCount,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.boardingStatus,
    required this.paymentStatus,
    required this.totalFare,
    this.paymentCollected = false,
  });
  
  CachedPassenger copyWith({
    String? boardingStatus,
    String? paymentStatus,
    bool? paymentCollected,
  }) {
    return CachedPassenger(
      bookingId: bookingId,
      passengerName: passengerName,
      phoneNumber: phoneNumber,
      passengerCount: passengerCount,
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      boardingStatus: boardingStatus ?? this.boardingStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      totalFare: totalFare,
      paymentCollected: paymentCollected ?? this.paymentCollected,
    );
  }
}

/// Intermediate stop with passenger counts
@HiveType(typeId: 2)
class IntermediateStopData {
  @HiveField(0)
  final String locationName;
  
  @HiveField(1)
  final double latitude;
  
  @HiveField(2)
  final double longitude;
  
  @HiveField(3)
  final double distanceFromOrigin;
  
  @HiveField(4)
  final int pickupCount;
  
  @HiveField(5)
  final int dropoffCount;
  
  @HiveField(6)
  final List<String> pickupPassengerNames;
  
  @HiveField(7)
  final List<String> dropoffPassengerNames;
  
  @HiveField(8)
  final bool isPassed;
  
  IntermediateStopData({
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.distanceFromOrigin,
    required this.pickupCount,
    required this.dropoffCount,
    required this.pickupPassengerNames,
    required this.dropoffPassengerNames,
    this.isPassed = false,
  });
}

/// Ride cache manager
class RideCacheManager {
  static const String _boxName = 'ride_cache';
  Box<CachedRide>? _box;
  
  Future<void> init() async {
    if (_box?.isOpen ?? false) return;
    _box = await Hive.openBox<CachedRide>(_boxName);
  }
  
  /// Cache ride data
  Future<void> cacheRide(CachedRide ride) async {
    await init();
    await _box?.put(ride.rideId, ride);
  }
  
  /// Get cached ride
  Future<CachedRide?> getCachedRide(String rideId) async {
    await init();
    return _box?.get(rideId);
  }
  
  /// Update ride location
  Future<void> updateRideLocation(String rideId, double lat, double lon) async {
    await init();
    final ride = await getCachedRide(rideId);
    if (ride != null) {
      await cacheRide(ride.copyWith(
        currentLatitude: lat,
        currentLongitude: lon,
      ));
    }
  }
  
  /// Update passenger status
  Future<void> updatePassengerStatus(
    String rideId,
    String bookingId, {
    String? boardingStatus,
    String? paymentStatus,
    bool? paymentCollected,
  }) async {
    await init();
    final ride = await getCachedRide(rideId);
    if (ride != null) {
      final updatedPassengers = ride.passengers.map((p) {
        if (p.bookingId == bookingId) {
          return p.copyWith(
            boardingStatus: boardingStatus,
            paymentStatus: paymentStatus,
            paymentCollected: paymentCollected,
          );
        }
        return p;
      }).toList();
      
      await cacheRide(ride.copyWith(passengers: updatedPassengers));
    }
  }
  
  /// Delete cached ride
  Future<void> deleteCachedRide(String rideId) async {
    await init();
    await _box?.delete(rideId);
  }
  
  /// Clear all cached rides
  Future<void> clearAll() async {
    await init();
    await _box?.clear();
  }
  
  /// Get all cached rides
  Future<List<CachedRide>> getAllCachedRides() async {
    await init();
    return _box?.values.toList() ?? [];
  }
}
