import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/driver_models.dart';
import '../../../../core/providers/driver_ride_provider.dart';
import '../../../../core/providers/location_tracking_provider.dart';
import '../../../../core/providers/location_provider.dart';
import '../../../../app/themes/app_colors.dart';
import '../../../../app/themes/app_spacing.dart';
import '../../../../app/themes/text_styles.dart';
import '../widgets/stop_passengers_bottom_sheet.dart';
import 'location_debug_screen.dart';
import 'driver_trip_summary_screen.dart';

/// Driver tracking screen - shows live ride tracking in train-style UI
class DriverTrackingScreen extends ConsumerStatefulWidget {
  final String rideId;
  final RideDetailsWithPassengers rideDetails;

  const DriverTrackingScreen({
    super.key,
    required this.rideId,
    required this.rideDetails,
  });

  @override
  ConsumerState<DriverTrackingScreen> createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends ConsumerState<DriverTrackingScreen> {
  int _currentStopIndex = 0;
  DateTime? _tripStartTime;
  // Pre-fetched coordinates for all stops: stopName (normalized) -> {lat, lng}
  final Map<String, Map<String, double>> _stopCoordinates = {};

  // Get the latest ride details from provider, fallback to widget param
  RideDetailsWithPassengers get rideDetails {
    final providerState = ref.read(driverRideNotifierProvider);
    return providerState.currentRideDetails ?? widget.rideDetails;
  }

  @override
  void initState() {
    super.initState();
    _tripStartTime = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationTrackingProvider.notifier).startTracking(widget.rideId);
      _prefetchStopCoordinates();
    });
  }

  /// Seed coordinates for every stop in the route.
  /// Pickup/dropoff come directly from the ride entity (always set).
  /// Intermediate stops are resolved via the location search API.
  Future<void> _prefetchStopCoordinates() async {
    final rd = rideDetails;

    String normalize(String s) => s.split(',').first.trim().toLowerCase();

    // Pickup
    if (rd.pickupLatitude != 0.0 || rd.pickupLongitude != 0.0) {
      _stopCoordinates[normalize(rd.pickupLocation)] = {
        'lat': rd.pickupLatitude,
        'lng': rd.pickupLongitude,
      };
    }

    // Dropoff
    if (rd.dropoffLatitude != 0.0 || rd.dropoffLongitude != 0.0) {
      _stopCoordinates[normalize(rd.dropoffLocation)] = {
        'lat': rd.dropoffLatitude,
        'lng': rd.dropoffLongitude,
      };
    }

    // Intermediate stops — fetch via location search API
    if (rd.intermediateStops != null) {
      final locationService = ref.read(locationServiceProvider);
      for (final stopName in rd.intermediateStops!) {
        final key = normalize(stopName);
        if (_stopCoordinates.containsKey(key)) continue;
        try {
          final results = await locationService.searchLocations(key);
          if (results.isNotEmpty &&
              results.first.latitude != null &&
              results.first.longitude != null) {
            _stopCoordinates[key] = {
              'lat': results.first.latitude!,
              'lng': results.first.longitude!,
            };
            debugPrint('✅ Fetched coords for "$stopName": ${results.first.latitude}, ${results.first.longitude}');
          } else {
            debugPrint('⚠️ No coords found via API for "$stopName"');
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching coords for "$stopName": $e');
        }
      }
    }

    if (mounted) setState(() {});
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(locationTrackingProvider);
    final currentLocation = trackingState.currentLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Build list of all stops
    final allStops = _buildStopsList();
    
    // Find current stop based on location
    if (currentLocation != null) {
      _updateCurrentStop(currentLocation, allStops);
    }
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ride ${widget.rideId.substring(0, 8)}',
              style: TextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
            Text(
              '${rideDetails.pickupLocation} → ${rideDetails.dropoffLocation}',
              style: TextStyles.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          // Debug button (only in debug mode)
          if (const bool.fromEnvironment('dart.vm.product') == false)
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LocationDebugScreen()),
                );
              },
              icon: const Icon(Icons.bug_report),
              tooltip: 'Location Debug',
            ),
          // Passengers button
          IconButton(
            onPressed: () => _showPassengersBottomSheet(context, isDark),
            icon: Icon(Icons.people),
            tooltip: 'View Passengers',
          ),
          Container(
            margin: EdgeInsets.only(right: AppSpacing.md),
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: trackingState.isSocketConnected 
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: trackingState.isSocketConnected 
                        ? AppColors.success 
                        : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  trackingState.isSocketConnected ? 'Live' : 'Offline',
                  style: TextStyles.bodySmall.copyWith(
                    color: trackingState.isSocketConnected 
                        ? AppColors.success 
                        : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Stats header
              _buildStatsHeader(isDark, allStops),
              
              // Stops list (train-style)
              Expanded(
                child: FutureBuilder<Widget>(
                  // Force rebuild when currentLocation changes by using it as key
                  key: ValueKey('${currentLocation?.latitude}_${currentLocation?.longitude}_${currentLocation?.timestamp}'),
                  future: _buildStopsTimeline(allStops, isDark, currentLocation),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return snapshot.data!;
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
              
              // Bottom status bar
              if (currentLocation != null)
                _buildBottomStatusBar(isDark, allStops, currentLocation),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Manage Stop Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await _showStopPassengersSheet(allStops[_currentStopIndex]);
                    // Reload ride details after managing stop
                    if (result == true && mounted) {
                      await ref.read(driverRideNotifierProvider.notifier).loadRideDetails(widget.rideId);
                      setState(() {}); // Trigger rebuild with updated data
                    }
                  },
                  icon: const Icon(Icons.people, size: 18),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Manage Stop',
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              // Complete Trip Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _completeTrip,
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Complete Trip',
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<TrainStop> _buildStopsList() {
    final stops = <TrainStop>[];
    double cumulativeDistance = 0;
    
    // Get intermediate stops data from tracking state (has lat/lng)
    final trackingState = ref.read(locationTrackingProvider);
    final intermediateStopDataList = trackingState.intermediateStops;
    
    // Helper to find coordinates for a location
    Map<String, double>? findCoordinates(String? locationId, String locationName) {
      final normalized = locationName.split(',').first.trim().toLowerCase();

      // 1. Pre-fetched coordinates (ride entity coords + location API results)
      if (_stopCoordinates.containsKey(normalized)) {
        final c = _stopCoordinates[normalized]!;
        debugPrint('✅ Found pre-fetched coords for $locationName: ${c['lat']}, ${c['lng']}');
        return c;
      }

      // 2. Exact ID match from passenger data
      if (locationId != null && locationId.isNotEmpty) {
        for (var passenger in rideDetails.passengers) {
          if (passenger.pickupLocationId == locationId &&
              passenger.pickupLatitude != null &&
              passenger.pickupLongitude != null) {
            debugPrint('✅ Found coords from passenger pickup (by ID) for $locationName');
            return {'lat': passenger.pickupLatitude!, 'lng': passenger.pickupLongitude!};
          }
          if (passenger.dropoffLocationId == locationId &&
              passenger.dropoffLatitude != null &&
              passenger.dropoffLongitude != null) {
            debugPrint('✅ Found coords from passenger dropoff (by ID) for $locationName');
            return {'lat': passenger.dropoffLatitude!, 'lng': passenger.dropoffLongitude!};
          }
        }
      }

      // 3. Name match from tracking state intermediate stop data
      for (var stopData in intermediateStopDataList) {
        if (stopData.locationName.split(',').first.trim().toLowerCase() == normalized) {
          debugPrint('✅ Found coords for $locationName from tracking state');
          return {'lat': stopData.latitude, 'lng': stopData.longitude};
        }
      }

      // 4. Name match from passenger pickup/dropoff coordinates
      for (var passenger in rideDetails.passengers) {
        if (passenger.pickupLocation.split(',').first.trim().toLowerCase() == normalized &&
            passenger.pickupLatitude != null &&
            passenger.pickupLongitude != null) {
          debugPrint('✅ Found coords from passenger pickup (by name) for $locationName');
          return {'lat': passenger.pickupLatitude!, 'lng': passenger.pickupLongitude!};
        }
        if (passenger.dropoffLocation.split(',').first.trim().toLowerCase() == normalized &&
            passenger.dropoffLatitude != null &&
            passenger.dropoffLongitude != null) {
          debugPrint('✅ Found coords from passenger dropoff (by name) for $locationName');
          return {'lat': passenger.dropoffLatitude!, 'lng': passenger.dropoffLongitude!};
        }
      }

      debugPrint('⚠️  No coordinates found for: $locationName (ID: $locationId)');
      return null;
    }
    
    // Parse departure time
    final departureTime = DateTime.tryParse(rideDetails.departureTime) ?? DateTime.now();
    
    // Build ordered route: pickup -> intermediateStops -> dropoff
    final List<Map<String, String?>> orderedRoute = [];
    orderedRoute.add({
      'name': rideDetails.pickupLocation,
      'id': rideDetails.pickupLocationId,
    });
    
    if (rideDetails.intermediateStops != null && rideDetails.intermediateStops!.isNotEmpty) {
      for (int i = 0; i < rideDetails.intermediateStops!.length; i++) {
        orderedRoute.add({
          'name': rideDetails.intermediateStops![i],
          'id': rideDetails.intermediateStopsIds != null && i < rideDetails.intermediateStopsIds!.length 
              ? rideDetails.intermediateStopsIds![i] 
              : null,
        });
      }
    }
    
    orderedRoute.add({
      'name': rideDetails.dropoffLocation,
      'id': rideDetails.dropoffLocationId,
    });
    
    // Helper function to normalize location for comparison
    String normalizeLocation(String location) {
      // Remove ", State" suffix and trim
      return location.split(',').first.trim().toLowerCase();
    }

    final normalizedOrigin = normalizeLocation(rideDetails.pickupLocation);

    // Count pickups and dropoffs at each location
    final Map<String, int> pickupCounts = {};
    final Map<String, int> dropoffCounts = {};
    
    print('👥 Total passengers: ${rideDetails.passengers.length}');
    print('🏁 Ride pickup: ${rideDetails.pickupLocation}');
    print('🏁 Ride dropoff: ${rideDetails.dropoffLocation}');
    
    for (var passenger in rideDetails.passengers) {
      print('  👤 Passenger: ${passenger.passengerName}');
      print('     📍 Pickup: ${passenger.pickupLocation} (${passenger.pickupLatitude}, ${passenger.pickupLongitude})');
      print('     📍 Dropoff: ${passenger.dropoffLocation} (${passenger.dropoffLatitude}, ${passenger.dropoffLongitude})');
    }
    
    // Count for origin
    int originPickupCount = rideDetails.passengers.where((p) => 
      p.pickupLocationId == rideDetails.pickupLocationId || 
      normalizeLocation(p.pickupLocation) == normalizedOrigin
    ).length;
    
    // Count for destination
    final normalizedDestination = normalizeLocation(rideDetails.dropoffLocation);
    int destinationDropoffCount = rideDetails.passengers.where((p) => 
      p.dropoffLocationId == rideDetails.dropoffLocationId ||
      normalizeLocation(p.dropoffLocation) == normalizedDestination
    ).length;
    
    for (var passenger in rideDetails.passengers) {
      final normalizedPassengerPickup = normalizeLocation(passenger.pickupLocation);
      final normalizedPassengerDropoff = normalizeLocation(passenger.dropoffLocation);

      // Determine if this passenger boards at the origin stop.
      // Use ID match when both IDs are non-empty; always also check by name.
      final idMatchesOrigin = passenger.pickupLocationId.isNotEmpty &&
          rideDetails.pickupLocationId.isNotEmpty &&
          passenger.pickupLocationId == rideDetails.pickupLocationId;
      final isPickupAtOrigin = idMatchesOrigin || normalizedPassengerPickup == normalizedOrigin;

      // Count pickups at each intermediate stop (excluding main origin)
      if (!isPickupAtOrigin) {
        // Find matching stop in orderedRoute
        for (var stop in orderedRoute) {
          final stopName = stop['name'] ?? '';
          if ((passenger.pickupLocationId.isNotEmpty && passenger.pickupLocationId == stop['id']) ||
              normalizeLocation(stopName) == normalizedPassengerPickup) {
            pickupCounts[stopName] = (pickupCounts[stopName] ?? 0) + 1;
            break;
          }
        }
      }

      // Determine if this passenger alights at the destination stop.
      final idMatchesDest = passenger.dropoffLocationId.isNotEmpty &&
          rideDetails.dropoffLocationId.isNotEmpty &&
          passenger.dropoffLocationId == rideDetails.dropoffLocationId;
      final isDropoffAtDestination = idMatchesDest || normalizedPassengerDropoff == normalizedDestination;

      // Count dropoffs at each intermediate stop (excluding main destination)
      if (!isDropoffAtDestination) {
        // Find matching stop in orderedRoute
        for (var stop in orderedRoute) {
          final stopName = stop['name'] ?? '';
          if ((passenger.dropoffLocationId.isNotEmpty && passenger.dropoffLocationId == stop['id']) ||
              normalizeLocation(stopName) == normalizedPassengerDropoff) {
            dropoffCounts[stopName] = (dropoffCounts[stopName] ?? 0) + 1;
            break;
          }
        }
      }
    }
    
    // Calculate segment distances from backend predefined data
    double? getSegmentDistance(String from, String to) {
      // Try to extract from backend distance/duration data
      // For now, we'll calculate proportionally if total distance is available
      return null; // Will be calculated below
    }

    // Create stops based on ordered route
    int cumulativeDuration = 0;
    for (int i = 0; i < orderedRoute.length; i++) {
      final location = orderedRoute[i]['name'] ?? '';
      final locationId = orderedRoute[i]['id'];
      final isFirst = i == 0;
      final isLast = i == orderedRoute.length - 1;
      
      final pickupCount = isFirst ? originPickupCount : (pickupCounts[location] ?? 0);
      final dropoffCount = isLast ? destinationDropoffCount : (dropoffCounts[location] ?? 0);
      
      // Calculate segment distance and duration
      double? segmentDist;
      int? segmentDur;
      
      if (!isFirst) {
        // Use actual segment distance from backend if available
        if (rideDetails.segmentDistances != null && i - 1 < rideDetails.segmentDistances!.length) {
          segmentDist = rideDetails.segmentDistances![i - 1];
          print('   ✅ Using backend segment distance: ${segmentDist.toStringAsFixed(1)}km');
        } else if (rideDetails.distance != null && rideDetails.duration != null) {
          // Fallback: Distribute total distance/duration equally among segments
          final totalSegments = orderedRoute.length - 1;
          segmentDist = rideDetails.distance! / totalSegments;
          segmentDur = (rideDetails.duration! / totalSegments).round();
          print('   ⚠️ Using proportional distance: ${segmentDist.toStringAsFixed(1)}km');
        } else {
          // Fallback: estimate based on position
          segmentDist = 10.0;
          segmentDur = 15;
          print('   ⚠️ Using fallback distance: ${segmentDist.toStringAsFixed(1)}km');
        }
        
        // For duration, always calculate proportionally or use fallback
        if (segmentDur == null) {
          if (rideDetails.duration != null) {
            final totalSegments = orderedRoute.length - 1;
            segmentDur = (rideDetails.duration! / totalSegments).round();
          } else {
            segmentDur = 15;
          }
        }
      }
      
      print('🚏 Stop: $location (ID: $locationId) - Pickup: $pickupCount, Dropoff: $dropoffCount, SegDist: ${segmentDist?.toStringAsFixed(1)}km, SegDur: ${segmentDur}min');
      
      // Find coordinates for this stop
      final coords = findCoordinates(locationId, location);
      print('   🎯 Coordinates for $location: ${coords?['lat']}, ${coords?['lng']}');
      
      stops.add(TrainStop(
        id: locationId,
        name: location,
        distance: cumulativeDistance,
        time: departureTime.add(Duration(minutes: cumulativeDuration)),
        type: isFirst ? StopType.start : (isLast ? StopType.end : StopType.intermediate),
        pickupCount: pickupCount,
        dropoffCount: dropoffCount,
        segmentDistance: segmentDist,
        segmentDuration: segmentDur,
        latitude: coords?['lat'],
        longitude: coords?['lng'],
      ));
      
      if (!isLast && segmentDist != null) {
        cumulativeDistance += segmentDist;
        cumulativeDuration += segmentDur ?? 15;
      }
    }
    
    print('📊 Total stops created: ${stops.length}');
    print('📊 Origin pickup count: $originPickupCount');
    print('📊 Destination dropoff count: $destinationDropoffCount');
    
    // Log all stops
    print('\n📍 ========== ROUTE STOPS ==========');
    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      print('Stop ${i + 1}/${stops.length}: ${stop.name}');
      print('  🚶 Pickups: ${stop.pickupCount}, Dropoffs: ${stop.dropoffCount}');
      print('');
    }
    print('================================================\n');
    
    return stops;
  }

  
  void _showPassengersBottomSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.radiusXL),
            topRight: Radius.circular(AppSpacing.radiusXL),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: AppSpacing.md),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Passengers (${rideDetails.passengers.length})',
                    style: TextStyles.headingMedium.copyWith(
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            Divider(height: 1),
            
            // Passengers list
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.all(AppSpacing.lg),
                itemCount: rideDetails.passengers.length,
                separatorBuilder: (context, index) => SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final passenger = rideDetails.passengers[index];
                  return _buildPassengerCard(passenger, isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerCard(PassengerInfo passenger, bool isDark) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and call button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Passenger count circle
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${passenger.passengerCount}',
                        style: TextStyles.bodyLarge.copyWith(
                          color: AppColors.primaryYellow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            passenger.passengerName,
                            style: TextStyles.bodyLarge.copyWith(
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            passenger.phoneNumber,
                            style: TextStyles.bodyMedium.copyWith(
                              color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Call button
              IconButton(
                onPressed: () => _makePhoneCall(passenger.phoneNumber),
                icon: Icon(
                  Icons.phone,
                  color: AppColors.success,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.success.withOpacity(0.1),
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppSpacing.md),
          
          // Pickup and dropoff locations
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.trip_origin,
                          size: 16,
                          color: AppColors.success,
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          'Pickup',
                          style: TextStyles.bodySmall.copyWith(
                            color: isDark ? Colors.white60 : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      passenger.pickupLocation,
                      style: TextStyles.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppColors.error,
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          'Dropoff',
                          style: TextStyles.bodySmall.copyWith(
                            color: isDark ? Colors.white60 : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      passenger.dropoffLocation,
                      style: TextStyles.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppSpacing.md),
          
          // Boarding status
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: passenger.boardingStatus.toLowerCase() == 'boarded'
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  passenger.boardingStatus.toLowerCase() == 'boarded'
                      ? Icons.check_circle
                      : Icons.access_time,
                  size: 16,
                  color: passenger.boardingStatus.toLowerCase() == 'boarded'
                      ? AppColors.success
                      : AppColors.warning,
                ),
                SizedBox(width: AppSpacing.xs),
                Text(
                  passenger.boardingStatus.toLowerCase() == 'boarded'
                      ? 'Boarded'
                      : 'Pending',
                  style: TextStyles.bodySmall.copyWith(
                    color: passenger.boardingStatus.toLowerCase() == 'boarded'
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: AppSpacing.md),
          
          // Fare and payment status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fare Amount',
                    style: TextStyles.bodySmall.copyWith(
                      color: isDark ? Colors.white60 : AppColors.lightTextSecondary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '₹${passenger.totalAmount.toStringAsFixed(0)}',
                    style: TextStyles.headingSmall.copyWith(
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: passenger.paymentStatus.toLowerCase() == 'paid'
                      ? AppColors.success.withOpacity(0.1)
                      : passenger.paymentStatus.toLowerCase() == 'pending'
                          ? AppColors.warning.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      passenger.paymentStatus.toLowerCase() == 'paid'
                          ? Icons.check_circle
                          : passenger.paymentStatus.toLowerCase() == 'pending'
                              ? Icons.schedule
                              : Icons.error,
                      size: 14,
                      color: passenger.paymentStatus.toLowerCase() == 'paid'
                          ? AppColors.success
                          : passenger.paymentStatus.toLowerCase() == 'pending'
                              ? AppColors.warning
                              : AppColors.error,
                    ),
                    SizedBox(width: 4),
                    Text(
                      passenger.paymentStatus.toUpperCase(),
                      style: TextStyles.bodySmall.copyWith(
                        color: passenger.paymentStatus.toLowerCase() == 'paid'
                            ? AppColors.success
                            : passenger.paymentStatus.toLowerCase() == 'pending'
                                ? AppColors.warning
                                : AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot make phone call'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _updateCurrentStop(Position currentLocation, List<TrainStop> stops) async {
    if (stops.isEmpty) return;
    
    print('\n🎯 ========== LOCATION UPDATE ==========');
    print('📍 Current Device Location:');
    print('   Latitude: ${currentLocation.latitude}');
    print('   Longitude: ${currentLocation.longitude}');
    print('   Accuracy: ${currentLocation.accuracy.toStringAsFixed(1)}m');
    print('\n🚗 Current Stop: ${_currentStopIndex + 1}/${stops.length} - ${stops[_currentStopIndex].name}');
    
    // Find which stop the vehicle is closest to
    double minDistance = double.infinity;
    int closestStopIndex = _currentStopIndex;
    
    print('\n🔍 Checking distances to all stops:');
    for (int i = 0; i < stops.length; i++) {
      // Get coordinates from stop object
      if (stops[i].latitude != null && stops[i].longitude != null) {
        final distance = _calculateDistance(
          currentLocation.latitude,
          currentLocation.longitude,
          stops[i].latitude!,
          stops[i].longitude!,
        );
        
        final status = distance < 0.5 ? '✅' : (i == _currentStopIndex ? '🔵' : '⏸️');
        print('$status Stop ${i + 1}: ${stops[i].name}');
        print('     Distance: ${distance.toStringAsFixed(2)}km');
        
        if (distance < minDistance) {
          minDistance = distance;
          closestStopIndex = i;
        }
      } else {
        print('⚠️  Stop ${i + 1}: ${stops[i].name} - No coordinates found!');
      }
    }
    
    print('\n🔶 Closest Stop: ${closestStopIndex + 1} - ${stops[closestStopIndex].name}');
    print('   Distance: ${minDistance.toStringAsFixed(3)}km');
    print('   Threshold: 4.0km');
    
    // If within 4km of a stop, consider it reached (accounts for GPS accuracy and city radius)
    final isDestination = closestStopIndex == stops.length - 1;
    if (minDistance < 4.0 && (closestStopIndex > _currentStopIndex || (isDestination && closestStopIndex >= _currentStopIndex))) {
      print('\n✨ STOP REACHED! Moving from Stop ${_currentStopIndex + 1} to Stop ${closestStopIndex + 1}');
      setState(() {
        // Mark previous stops as passed and record arrival time
        for (int i = _currentStopIndex; i < closestStopIndex; i++) {
          if (!stops[i].isPassed) {
            stops[i].isPassed = true;
            stops[i].actualArrivalTime = DateTime.now();
          }
        }
        _currentStopIndex = closestStopIndex;
        
        // Record arrival time for current stop
        if (stops[closestStopIndex].actualArrivalTime == null) {
          stops[closestStopIndex].actualArrivalTime = DateTime.now();
        }
      });
    } else if (minDistance < 4.0 && closestStopIndex == _currentStopIndex) {
      // Update current stop arrival time
      setState(() {
        if (stops[closestStopIndex].actualArrivalTime == null) {
          stops[closestStopIndex].actualArrivalTime = DateTime.now();
        }
      });
    }
  }
  
  // Get coordinates for a location using geocoding or API
  Future<Map<String, double>?> _getCoordinatesForLocation(String locationName) async {
    // First try to extract coordinates if they're embedded in the location string
    // Format: "Location Name (lat, lng)"
    final coordPattern = RegExp(r'\((-?\d+\.?\d*),\s*(-?\d+\.?\d*)\)');
    final match = coordPattern.firstMatch(locationName);
    
    if (match != null) {
      try {
        return {
          'lat': double.parse(match.group(1)!),
          'lng': double.parse(match.group(2)!)
        };
      } catch (e) {
        print('Error parsing embedded coordinates: $e');
      }
    }
    
    // If no embedded coordinates, use geocoding service (Google Maps or similar)
    // This would require implementing a geocoding service call
    // For now, return null to indicate coordinates need to be fetched
    return null;
  }
  
  // Calculate distance between two coordinates in km (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth's radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }
  
  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  Widget _buildStatsHeader(bool isDark, List<TrainStop> stops) {
    final totalDistance = rideDetails.distance ?? stops.last.distance;
    final totalDuration = rideDetails.duration;
    final passedStops = stops.where((s) => s.isPassed).length;
    final totalStops = stops.length;
    
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Distance',
              '${totalDistance.toStringAsFixed(1)} km',
              Icons.straighten,
              AppColors.info,
              isDark,
            ),
          ),
          if (totalDuration != null)
            Expanded(
              child: _buildStatItem(
                'ETA',
                '${totalDuration} min',
                Icons.access_time,
                AppColors.warning,
                isDark,
              ),
            ),
          Expanded(
            child: _buildStatItem(
              'Stops',
              '$passedStops/$totalStops',
              Icons.location_on,
              AppColors.primaryYellow,
              isDark,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Passengers',
              '${rideDetails.passengers.length}',
              Icons.people,
              AppColors.success,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: TextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyles.bodySmall.copyWith(
            color: isDark ? Colors.white60 : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Future<Widget> _buildStopsTimeline(List<TrainStop> stops, bool isDark, Position? currentLocation) async {
    // Calculate vehicle position between stops
    Map<String, dynamic>? vehiclePosition;
    if (currentLocation != null) {
      vehiclePosition = await _calculateVehiclePosition(currentLocation, stops);
    }
    
    return ListView.builder(
      itemCount: stops.length,
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      itemBuilder: (context, index) {
        final stop = stops[index];
        final isCurrentStop = index == _currentStopIndex;
        
        // A stop is fully "passed" and checked off if we are strictly past it.
        // Or if we are AT this current stop and have "arrived".
        // For the sake of the track lines:
        // Everything before `_currentStopIndex` is fully green.
        final isPassed = index <= _currentStopIndex;
        // BUT the line coming OUT of the current stop should only be green if we are tracking BETWEEN stops.
        
        final isNext = index == _currentStopIndex + 1;
        
        // Check if vehicle is between this stop and the next
        final showVehicleBetween = vehiclePosition != null && 
                                    vehiclePosition['atNodeIndex'] == null &&
                                    vehiclePosition['segmentIndex'] == index &&
                                    vehiclePosition['progress'] < 1.0;
                                    
        // Show vehicle ON the node if it's currently at this stop
        final showVehicleHere = vehiclePosition != null && vehiclePosition['atNodeIndex'] == index;
        
        // Is vehicle departing dynamically?
        final isVehicleDeparting = showVehicleBetween && index == _currentStopIndex;
        
        return Column(
          children: [
            _buildStopItem(stop, isCurrentStop, isPassed, isNext, isDark, index == stops.length - 1, showVehicleHere, isVehicleDeparting),
            
            // Show vehicle between stops if applicable
            if (showVehicleBetween && index < stops.length - 1)
              _buildVehicleBetweenStops(vehiclePosition['progress'], isDark),
          ],
        );
      },
    );
  }
  
  /// Calculate vehicle position relative to stops
  Future<Map<String, dynamic>?> _calculateVehiclePosition(Position currentLocation, List<TrainStop> stops) async {
    if (stops.length < 2) return {'atNodeIndex': _currentStopIndex};
    
    // Check if we have coordinates for stops
    bool hasCoordinates = false;
    for (var stop in stops) {
      if (stop.latitude != null && stop.longitude != null) {
        hasCoordinates = true;
        break;
      }
    }
    
    // If no stop coordinates available, just show vehicle at current stop index
    if (!hasCoordinates) {
      return {'atNodeIndex': _currentStopIndex};
    }
    
    // Check if we are physically close to ANY node (under 4km radius)
    // Find the tightest overlapping node in case multiple nodes are close in dense areas
    int? closestNodeIndex;
    double minNodeDistance = 4.0;
    for (int i = 0; i < stops.length; i++) {
        if (stops[i].latitude != null && stops[i].longitude != null) {
            final dist = _calculateDistance(
               currentLocation.latitude, currentLocation.longitude, 
               stops[i].latitude!, stops[i].longitude!
            );
            if (dist < minNodeDistance) {
                minNodeDistance = dist;
                closestNodeIndex = i;
            }
        }
    }
    
    // Lock tracker directly onto this node if one matches
    if (closestNodeIndex != null) {
       return {'atNodeIndex': closestNodeIndex};
    }

    // Find closest segment (pair of stops) since we are 'between' nodes
    double minDistanceToSegment = double.infinity;
    int closestSegmentIndex = _currentStopIndex < stops.length - 1 ? _currentStopIndex : stops.length - 2;
    double progressOnSegment = 0.0;
    
    for (int i = 0; i < stops.length - 1; i++) {
      if (stops[i].latitude != null && stops[i].longitude != null &&
          stops[i + 1].latitude != null && stops[i + 1].longitude != null) {
        
        final distToFrom = _calculateDistance(
          currentLocation.latitude, currentLocation.longitude,
          stops[i].latitude!, stops[i].longitude!,
        );
        final distToTo = _calculateDistance(
          currentLocation.latitude, currentLocation.longitude,
          stops[i + 1].latitude!, stops[i + 1].longitude!,
        );
        final segmentLength = _calculateDistance(
          stops[i].latitude!, stops[i].longitude!,
          stops[i + 1].latitude!, stops[i + 1].longitude!,
        );
        
        final totalDist = distToFrom + distToTo;
        final deviation = (totalDist - segmentLength).abs();
        
        if (deviation < minDistanceToSegment) {
          minDistanceToSegment = deviation;
          closestSegmentIndex = i;
          progressOnSegment = segmentLength > 0 ? distToFrom / segmentLength : 0.0;
        }
      }
    }
    
    // Ensure the segment is actually one we haven't fully passed or aren't far behind
    if (closestSegmentIndex < _currentStopIndex) {
        closestSegmentIndex = _currentStopIndex;
        progressOnSegment = 0.0;
    }
    
    return {
      'segmentIndex': closestSegmentIndex,
      'progress': progressOnSegment.clamp(0.0, 1.0),
      'atNodeIndex': null,
    };
  }
  
  /// Build vehicle icon between stops
  Widget _buildVehicleBetweenStops(double progress, bool isDark) {
    final vehicleY = (progress * 48).clamp(0.0, 48.0);
    final vehicleCenterY = vehicleY + 12; // center point of the 24px icon

    return SizedBox(
      height: 60,
      child: Row(
        children: [
          SizedBox(width: 55), // Distance column
          SizedBox(
            width: 35,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Top half of line (green)
                Positioned(
                  left: 16,
                  top: 0,
                  height: vehicleCenterY,
                  child: Container(
                    width: 3,
                    color: AppColors.success,
                  ),
                ),
                // Bottom half of line (grey)
                Positioned(
                  left: 16,
                  top: vehicleCenterY,
                  bottom: 0,
                  child: Container(
                    width: 3,
                    color: Colors.grey[300],
                  ),
                ),
                // Vehicle icon at progress position
                Positioned(
                  left: 5.5,
                  top: vehicleY,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryOrange,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryOrange.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(Icons.directions_car, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildStopItem(TrainStop stop, bool isCurrent, bool isPassed, bool isNext, bool isDark, bool isLast, bool showVehicleHere, bool isVehicleDeparting) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Distance column
          Container(
            width: 55,
            alignment: Alignment.topCenter,
            padding: EdgeInsets.only(top: AppSpacing.md),
            child: stop.segmentDistance != null
                ? Text(
                    '${stop.segmentDistance!.toStringAsFixed(0)}km',
                    style: TextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.primaryYellow : AppColors.primaryOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  )
                : Text(
                    '${stop.distance.toStringAsFixed(0)}km',
                    style: TextStyles.bodySmall.copyWith(
                      color: isDark ? Colors.white60 : AppColors.lightTextSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
          ),
          
          // Timeline column
          SizedBox(
            width: 35,
            child: Column(
              children: [
                // Top line
                if (stop.type != StopType.start)
                  Container(
                    width: 3,
                    height: 20,
                    color: isPassed ? AppColors.success : Colors.grey[300],
                  ),
                
                // Stop indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isPassed 
                        ? AppColors.success 
                        : Colors.grey[300],
                    shape: stop.type == StopType.intermediate ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: stop.type != StopType.intermediate ? BorderRadius.circular(4) : null,
                    border: Border.all(
                      color: isPassed 
                          ? AppColors.success 
                          : Colors.grey[400]!,
                      width: showVehicleHere ? 3 : 2,
                    ),
                  ),
                  child: showVehicleHere 
                      ? Icon(Icons.directions_car, size: 14, color: Colors.white)
                      : isPassed 
                          ? Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                ),
                
                // Bottom line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 3,
                      // The line below the node connects to the next segment.
                      // If the vehicle has completely passed this node (`!isCurrent`), it's green.
                      // If the vehicle is currently departing this node towards the next (`isCurrent` && `isVehicleDeparting`), it must be green to connect to the top of the next segment.
                      // If the vehicle is definitively parked AT this node (`isCurrent` && `!isVehicleDeparting`), it remains grey.
                      // If the node hasn't been reached at all (`!isPassed`), it's grey.
                      color: isPassed && (!isCurrent || isVehicleDeparting) 
                          ? AppColors.success 
                          : Colors.grey[300],
                    ),
                  ),
              ],
            ),
          ),
          
          // Stop info column
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              margin: EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isCurrent 
                    ? AppColors.primaryYellow.withOpacity(0.1) 
                    : isNext
                        ? AppColors.info.withOpacity(0.05)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stop.name,
                              style: TextStyles.bodyLarge.copyWith(
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            // Scheduled ETA below stop name
                            Text(
                              _formatTime(stop.time),
                              style: TextStyles.bodySmall.copyWith(
                                color: isDark ? Colors.white54 : Colors.grey[500],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryYellow,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                          ),
                          child: Text(
                            'CURRENT',
                            style: TextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xs),
                  // Pickup/Dropoff counts row (separate row to prevent overflow)
                  if (stop.pickupCount > 0 || stop.dropoffCount > 0) ...[
                    SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        if (stop.pickupCount > 0) ...[
                          Icon(Icons.arrow_circle_up, size: 14, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            '${stop.pickupCount} pickup',
                            style: TextStyles.bodySmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (stop.pickupCount > 0 && stop.dropoffCount > 0)
                          SizedBox(width: AppSpacing.md),
                        if (stop.dropoffCount > 0) ...[
                          Icon(Icons.arrow_circle_down, size: 14, color: AppColors.error),
                          SizedBox(width: 4),
                          Text(
                            '${stop.dropoffCount} drop',
                            style: TextStyles.bodySmall.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Actual arrival time column
          Container(
            width: 55,
            alignment: Alignment.topCenter,
            padding: EdgeInsets.only(top: AppSpacing.md),
            child: _buildActualArrivalTime(stop, isPassed, isCurrent, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStatusBar(bool isDark, List<TrainStop> stops, Position currentLocation) {
    final nextStop = _currentStopIndex < stops.length - 1 ? stops[_currentStopIndex + 1] : null;
    final currentSpeed = (currentLocation.speed * 3.6).toStringAsFixed(0);
    
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.update, color: Colors.white, size: 20),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nextStop != null 
                      ? '${nextStop.name} is next'
                      : 'En route to destination',
                  style: TextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Speed: $currentSpeed km/h',
                  style: TextStyles.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Updated now',
            style: TextStyles.bodySmall.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<bool?> _showStopPassengersSheet(TrainStop stop) async {
    // Normalize location for comparison
    String normalizeLocation(String location) {
      return location.split(',').first.trim().toLowerCase();
    }
    
    final normalizedStopLocation = normalizeLocation(stop.name);
    
    // Get passengers picking up at this stop
    final pickupPassengers = rideDetails.passengers.where((p) =>
      normalizeLocation(p.pickupLocation) == normalizedStopLocation
    ).toList();
    
    // Get passengers dropping off at this stop
    final dropoffPassengers = rideDetails.passengers.where((p) =>
      normalizeLocation(p.dropoffLocation) == normalizedStopLocation
    ).toList();
    
    if (pickupPassengers.isEmpty && dropoffPassengers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No passengers at this stop'),
          backgroundColor: AppColors.info,
        ),
      );
      return null;
    }
    
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StopPassengersBottomSheet(
          stopLocation: stop.name,
          rideId: widget.rideId,
          pickupPassengers: pickupPassengers,
          dropoffPassengers: dropoffPassengers,
        ),
      ),
    );
    
    return result;
  }

  Future<void> _completeTrip() async {
    // Get current location
    final trackingState = ref.read(locationTrackingProvider);
    final currentLocation = trackingState.currentLocation;
    
    // Check if driver is at final destination
    final allStops = _buildStopsList();
    if (allStops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to verify location. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    final finalStop = allStops.last;
    final currentStopIndex = _currentStopIndex;
    
    // Verify driver is at the last stop
    if (currentStopIndex < allStops.length - 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please reach the final destination (${finalStop.name}) before completing the trip.'),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
    
    // Stop tracking
    await ref.read(locationTrackingProvider.notifier).stopTracking();
    
    // Create the complete trip request with current location or default to 0,0
    final request = CompleteTripRequest(
      endLocation: LocationDto(
        latitude: currentLocation?.latitude ?? 0.0,
        longitude: currentLocation?.longitude ?? 0.0,
        address: rideDetails.dropoffLocation,
      ),
      actualArrivalTime: DateTime.now().toUtc().toIso8601String(),
      actualDistance: rideDetails.distance ?? 0.0,
    );
    
    // Complete trip via API
    final tripEndTime = DateTime.now();
    final success = await ref.read(driverRideNotifierProvider.notifier).completeTrip(widget.rideId, request);
    
    if (success && mounted) {
      // Navigate to trip summary screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DriverTripSummaryScreen(
            rideId: widget.rideId,
            rideNumber: rideDetails.rideNumber,
            rideDetails: rideDetails,
            tripStartTime: _tripStartTime,
            tripEndTime: tripEndTime,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete trip. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildActualArrivalTime(TrainStop stop, bool isPassed, bool isCurrent, bool isDark) {
    // If stop hasn't been reached yet, show '-'
    if (!isPassed && !isCurrent) {
      return Text(
        '-',
        style: TextStyles.bodyLarge.copyWith(
          color: isDark ? Colors.white38 : Colors.grey[400],
          fontWeight: FontWeight.w500,
        ),
      );
    }

    // For current stop, use current time as actual arrival
    final actualTime = stop.actualArrivalTime ?? (isCurrent ? DateTime.now() : null);
    
    if (actualTime == null) {
      return Text(
        '-',
        style: TextStyles.bodyLarge.copyWith(
          color: isDark ? Colors.white38 : Colors.grey[400],
          fontWeight: FontWeight.w500,
        ),
      );
    }

    // Calculate delay in minutes
    final delayMinutes = actualTime.difference(stop.time).inMinutes;
    
    // Determine color based on delay
    Color textColor;
    if (delayMinutes <= 0) {
      // On time or early - Green
      textColor = AppColors.success;
    } else if (delayMinutes <= 5) {
      // Slightly late (1-5 min) - Orange
      textColor = Colors.orange;
    } else {
      // Very late (>5 min) - Red
      textColor = AppColors.error;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(actualTime),
          style: TextStyles.bodySmall.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        if (delayMinutes > 0)
          Text(
            '+${delayMinutes}m',
            style: TextStyles.bodySmall.copyWith(
              color: textColor,
              fontSize: 9,
            ),
          ),
      ],
    );
  }
}

// Data models for train-style stops
class TrainStop {
  final String? id;
  final String name;
  final double distance;
  final DateTime time; // Scheduled ETA
  final StopType type;
  int pickupCount;
  int dropoffCount;
  bool isPassed;
  final double? segmentDistance; // Distance from previous stop
  final int? segmentDuration; // Duration from previous stop in minutes
  DateTime? actualArrivalTime; // Actual time vehicle reached this stop
  final double? latitude; // Stop coordinates
  final double? longitude; // Stop coordinates
  
  TrainStop({
    this.id,
    required this.name,
    required this.distance,
    required this.time,
    required this.type,
    required this.pickupCount,
    required this.dropoffCount,
    this.isPassed = false,
    this.segmentDistance,
    this.segmentDuration,
    this.actualArrivalTime,
    this.latitude,
    this.longitude,
  });
}

enum StopType {
  start,
  intermediate,
  end,
}
