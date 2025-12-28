import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/driver_models.dart';
import '../../../../core/providers/driver_ride_provider.dart';
import '../../../../core/providers/location_tracking_provider.dart';
import '../../../../app/themes/app_colors.dart';
import '../../../../app/themes/app_spacing.dart';
import '../../../../app/themes/text_styles.dart';
import '../widgets/stop_passengers_bottom_sheet.dart';

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
  
  // Get the latest ride details from provider, fallback to widget param
  RideDetailsWithPassengers get rideDetails {
    final providerState = ref.read(driverRideNotifierProvider);
    return providerState.currentRideDetails ?? widget.rideDetails;
  }
  
  @override
  void initState() {
    super.initState();
    // Start tracking when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationTrackingProvider.notifier).startTracking(widget.rideId);
    });
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
                child: _buildStopsTimeline(allStops, isDark, currentLocation),
              ),
              
              // Bottom status bar
              if (currentLocation != null)
                _buildBottomStatusBar(isDark, allStops, currentLocation),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
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
                  // Reload ride details if OTP was verified
                  if (result == true && mounted) {
                    await ref.read(driverRideNotifierProvider.notifier).loadRideDetails(widget.rideId);
                    setState(() {}); // Trigger rebuild with updated data
                  }
                },
                icon: Icon(Icons.people, size: 20),
                label: Text(
                  'Manage Stop',
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
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
                icon: Icon(Icons.check_circle, size: 20),
                label: Text(
                  'Complete Trip',
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
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
    );
  }

  List<TrainStop> _buildStopsList() {
    final stops = <TrainStop>[];
    double cumulativeDistance = 0;
    
    // Parse departure time
    final departureTime = DateTime.tryParse(rideDetails.departureTime) ?? DateTime.now();
    
    // Build ordered route: pickup -> intermediateStops -> dropoff
    final List<String> orderedRoute = [];
    orderedRoute.add(rideDetails.pickupLocation);
    
    if (rideDetails.intermediateStops != null && rideDetails.intermediateStops!.isNotEmpty) {
      orderedRoute.addAll(rideDetails.intermediateStops!);
    }
    
    orderedRoute.add(rideDetails.dropoffLocation);
    
    // Helper function to normalize location for comparison
    String normalizeLocation(String location) {
      // Remove ", State" suffix and trim
      return location.split(',').first.trim().toLowerCase();
    }
    
    // Count pickups and dropoffs at each location
    final Map<String, int> pickupCounts = {};
    final Map<String, int> dropoffCounts = {};
    
    print('👥 Total passengers: ${rideDetails.passengers.length}');
    print('🏁 Ride pickup: ${rideDetails.pickupLocation}');
    print('🏁 Ride dropoff: ${rideDetails.dropoffLocation}');
    
    for (var passenger in rideDetails.passengers) {
      print('  👤 Passenger: ${passenger.passengerName}');
      print('     📍 Pickup: ${passenger.pickupLocation}');
      print('     📍 Dropoff: ${passenger.dropoffLocation}');
    }
    
    // Count for origin
    final normalizedOrigin = normalizeLocation(rideDetails.pickupLocation);
    int originPickupCount = rideDetails.passengers.where((p) => 
      normalizeLocation(p.pickupLocation) == normalizedOrigin
    ).length;
    
    // Count for destination
    final normalizedDestination = normalizeLocation(rideDetails.dropoffLocation);
    int destinationDropoffCount = rideDetails.passengers.where((p) => 
      normalizeLocation(p.dropoffLocation) == normalizedDestination
    ).length;
    
    for (var passenger in rideDetails.passengers) {
      final normalizedPassengerPickup = normalizeLocation(passenger.pickupLocation);
      final normalizedPassengerDropoff = normalizeLocation(passenger.dropoffLocation);
      
      // Count pickups at each intermediate stop (excluding main origin)
      if (normalizedPassengerPickup != normalizedOrigin) {
        // Find matching stop in orderedRoute
        for (var stop in orderedRoute) {
          if (normalizeLocation(stop) == normalizedPassengerPickup) {
            pickupCounts[stop] = (pickupCounts[stop] ?? 0) + 1;
            break;
          }
        }
      }
      
      // Count dropoffs at each intermediate stop (excluding main destination)
      if (normalizedPassengerDropoff != normalizedDestination) {
        // Find matching stop in orderedRoute
        for (var stop in orderedRoute) {
          if (normalizeLocation(stop) == normalizedPassengerDropoff) {
            dropoffCounts[stop] = (dropoffCounts[stop] ?? 0) + 1;
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
      final location = orderedRoute[i];
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
      
      print('🚏 Stop: $location - Pickup: $pickupCount, Dropoff: $dropoffCount, SegDist: ${segmentDist?.toStringAsFixed(1)}km, SegDur: ${segmentDur}min');
      
      stops.add(TrainStop(
        name: location,
        distance: cumulativeDistance,
        time: departureTime.add(Duration(minutes: cumulativeDuration)),
        type: isFirst ? StopType.start : (isLast ? StopType.end : StopType.intermediate),
        pickupCount: pickupCount,
        dropoffCount: dropoffCount,
        segmentDistance: segmentDist,
        segmentDuration: segmentDur,
      ));
      
      if (!isLast && segmentDist != null) {
        cumulativeDistance += segmentDist;
        cumulativeDuration += segmentDur ?? 15;
      }
    }
    
    print('📊 Total stops created: ${stops.length}');
    print('📊 Origin pickup count: $originPickupCount');
    print('📊 Destination dropoff count: $destinationDropoffCount');
    
    // Log all stops with their expected coordinates
    print('\n📍 ========== ROUTE STOPS WITH COORDINATES ==========');
    final locationCoords = _getLocationCoordinates();
    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      final coords = locationCoords[stop.name];
      print('Stop ${i + 1}/${stops.length}: ${stop.name}');
      if (coords != null) {
        print('  📌 Latitude: ${coords['lat']}');
        print('  📌 Longitude: ${coords['lng']}');
      } else {
        print('  ⚠️  No coordinates found for this location!');
      }
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
          
          // OTP and boarding status
          Row(
            children: [
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
              SizedBox(width: AppSpacing.md),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                ),
                child: Text(
                  'OTP: ${passenger.otp}',
                  style: TextStyles.bodySmall.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
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

  void _updateCurrentStop(Position currentLocation, List<TrainStop> stops) {
    if (stops.isEmpty) return;
    
    print('\n🎯 ========== LOCATION UPDATE ==========');
    print('📍 Current Device Location:');
    print('   Latitude: ${currentLocation.latitude}');
    print('   Longitude: ${currentLocation.longitude}');
    print('   Accuracy: ${currentLocation.accuracy.toStringAsFixed(1)}m');
    print('\n🚗 Current Stop: ${_currentStopIndex + 1}/${stops.length} - ${stops[_currentStopIndex].name}');
    
    // Get predefined locations coordinates for comparison
    final locationCoords = _getLocationCoordinates();
    
    // Find which stop the vehicle is closest to
    double minDistance = double.infinity;
    int closestStopIndex = _currentStopIndex;
    
    print('\n🔍 Checking distances to all stops:');
    for (int i = 0; i < stops.length; i++) {
      final stopCoords = locationCoords[stops[i].name];
      if (stopCoords != null) {
        final distance = _calculateDistance(
          currentLocation.latitude,
          currentLocation.longitude,
          stopCoords['lat']!,
          stopCoords['lng']!,
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
    print('   Threshold: 1.0km');
    
    // If within 1km of a stop, consider it reached (accounts for GPS accuracy)
    if (minDistance < 1.0 && closestStopIndex > _currentStopIndex) {
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
    } else if (minDistance < 1.0 && closestStopIndex == _currentStopIndex) {
      // Update current stop arrival time
      setState(() {
        if (stops[closestStopIndex].actualArrivalTime == null) {
          stops[closestStopIndex].actualArrivalTime = DateTime.now();
        }
      });
    }
  }
  
  // Helper to get predefined location coordinates
  Map<String, Map<String, double>> _getLocationCoordinates() {
    // This should ideally come from backend or be stored in a constants file
    // Hyderabad Metro stations and Maharashtra cities
    return {
      // Test route - Exact names as they come from backend
      'Asian Living, Gachibowli, Hyderabad': {'lat': 17.4243, 'lng': 78.3463},
      'Wipro Circle, Gachibowli, Hyderabad': {'lat': 17.4410, 'lng': 78.3668},
      
      // Hyderabad Metro - Red Line (with exact backend names)
      'Raidurg Metro Station, Hyderabad': {'lat': 17.4347, 'lng': 78.3473},
      'Hitec City Metro Station, Hyderabad': {'lat': 17.4484, 'lng': 78.3908},
      'Durgam Cheruvu Metro Station, Hyderabad': {'lat': 17.4500, 'lng': 78.3875},
      'Madhapur Metro Station, Hyderabad': {'lat': 17.4481, 'lng': 78.3915},
      
      // Alternative short names (for backward compatibility)
      'Asian Living Gachibowli': {'lat': 17.4243, 'lng': 78.3463},
      'Wipro Circle': {'lat': 17.4410, 'lng': 78.3668},
      'Raidurg': {'lat': 17.4347, 'lng': 78.3473},
      'Hitec City': {'lat': 17.4484, 'lng': 78.3908},
      'Durgam Cheruvu': {'lat': 17.4500, 'lng': 78.3875},
      'Madhapur': {'lat': 17.4481, 'lng': 78.3915},
      'Peddamma Gudi': {'lat': 17.4436, 'lng': 78.3996},
      'Jubilee Hills Checkpost': {'lat': 17.4392, 'lng': 78.4077},
      'Jubilee Hills': {'lat': 17.4327, 'lng': 78.4087},
      'Yousufguda': {'lat': 17.4347, 'lng': 78.4286},
      'Madhura Nagar': {'lat': 17.4347, 'lng': 78.4415},
      'Ameerpet': {'lat': 17.4374, 'lng': 78.4482},
      
      // Hyderabad Metro - Blue Line (Ameerpet to Secunderabad)
      'SR Nagar': {'lat': 17.4423, 'lng': 78.4643},
      'Prakash Nagar': {'lat': 17.4467, 'lng': 78.4767},
      'Begumpet': {'lat': 17.4501, 'lng': 78.4754},
      'Rasoolpura': {'lat': 17.4520, 'lng': 78.4891},
      'Paradise': {'lat': 17.4427, 'lng': 78.4952},
      'Parade Grounds': {'lat': 17.4296, 'lng': 78.5034},
      'Secunderabad': {'lat': 17.4399, 'lng': 78.4983},
      
      // Maharashtra cities
      'Allapalli': {'lat': 19.8333, 'lng': 80.0500},
      'Ballarpur': {'lat': 20.0500, 'lng': 79.3500},
      'Gondpipri': {'lat': 20.0333, 'lng': 80.2000},
      'Chandrapur': {'lat': 19.9615, 'lng': 79.3012},
      'Nagpur': {'lat': 21.1458, 'lng': 79.0882},
      'Mumbai': {'lat': 19.0760, 'lng': 72.8777},
      'Pune': {'lat': 18.5204, 'lng': 73.8567},
    };
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

  Widget _buildStopsTimeline(List<TrainStop> stops, bool isDark, Position? currentLocation) {
    // Calculate vehicle position between stops
    Map<String, dynamic>? vehiclePosition;
    if (currentLocation != null) {
      vehiclePosition = _calculateVehiclePosition(currentLocation, stops);
    }
    
    return ListView.builder(
      itemCount: stops.length,
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      itemBuilder: (context, index) {
        final stop = stops[index];
        final isCurrentStop = index == _currentStopIndex;
        final isPassed = index < _currentStopIndex;
        final isNext = index == _currentStopIndex + 1;
        
        // Check if vehicle is between this stop and the next
        final showVehicleBetween = vehiclePosition != null && 
                                    vehiclePosition['segmentIndex'] == index &&
                                    vehiclePosition['progress'] < 1.0;
        
        return Column(
          children: [
            _buildStopItem(stop, isCurrentStop, isPassed, isNext, isDark, index == stops.length - 1, false),
            
            // Show vehicle between stops if applicable
            if (showVehicleBetween && index < stops.length - 1)
              _buildVehicleBetweenStops(vehiclePosition['progress'], isDark),
          ],
        );
      },
    );
  }
  
  /// Calculate vehicle position relative to stops
  Map<String, dynamic>? _calculateVehiclePosition(Position currentLocation, List<TrainStop> stops) {
    if (stops.length < 2) return null;
    
    final locationCoords = _getLocationCoordinates();
    
    // Find closest segment (pair of stops)
    double minDistanceToSegment = double.infinity;
    int closestSegmentIndex = 0;
    double progressOnSegment = 0.0;
    
    for (int i = 0; i < stops.length - 1; i++) {
      final fromCoords = locationCoords[stops[i].name];
      final toCoords = locationCoords[stops[i + 1].name];
      
      if (fromCoords != null && toCoords != null) {
        // Calculate distance from current position to both stops
        final distToFrom = _calculateDistance(
          currentLocation.latitude, currentLocation.longitude,
          fromCoords['lat']!, fromCoords['lng']!,
        );
        final distToTo = _calculateDistance(
          currentLocation.latitude, currentLocation.longitude,
          toCoords['lat']!, toCoords['lng']!,
        );
        final segmentLength = _calculateDistance(
          fromCoords['lat']!, fromCoords['lng']!,
          toCoords['lat']!, toCoords['lng']!,
        );
        
        // Check if vehicle is roughly on this segment
        final totalDist = distToFrom + distToTo;
        final deviation = (totalDist - segmentLength).abs();
        
        if (deviation < minDistanceToSegment) {
          minDistanceToSegment = deviation;
          closestSegmentIndex = i;
          // Calculate progress along segment (0.0 = at from, 1.0 = at to)
          progressOnSegment = segmentLength > 0 ? distToFrom / segmentLength : 0.0;
        }
      }
    }
    
    debugPrint('🚗 Vehicle on segment $closestSegmentIndex, progress: ${(progressOnSegment * 100).toStringAsFixed(1)}%');
    
    return {
      'segmentIndex': closestSegmentIndex,
      'progress': progressOnSegment.clamp(0.0, 1.0),
    };
  }
  
  /// Build vehicle icon between stops
  Widget _buildVehicleBetweenStops(double progress, bool isDark) {
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
                // Line segment
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 3,
                    color: Colors.grey[300],
                  ),
                ),
                // Vehicle icon at progress position
                Positioned(
                  left: 5.5,
                  top: (progress * 48).clamp(0.0, 48.0), // Clamp to prevent overflow, 48 = 60 - 12 (icon height)
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

  Widget _buildStopItem(TrainStop stop, bool isCurrent, bool isPassed, bool isNext, bool isDark, bool isLast, bool showVehicleHere) {
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
                    color: isCurrent 
                        ? AppColors.primaryYellow 
                        : isPassed 
                            ? AppColors.success 
                            : Colors.grey[300],
                    shape: stop.type == StopType.intermediate ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: stop.type != StopType.intermediate ? BorderRadius.circular(4) : null,
                    border: Border.all(
                      color: isCurrent 
                          ? AppColors.primaryOrange 
                          : isPassed 
                              ? AppColors.success 
                              : Colors.grey[400]!,
                      width: isCurrent ? 3 : 2,
                    ),
                  ),
                  child: isCurrent 
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
                      color: isPassed ? AppColors.success : Colors.grey[300],
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
    final success = await ref.read(driverRideNotifierProvider.notifier).completeTrip(widget.rideId, request);
    
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip completed successfully!'),
          backgroundColor: AppColors.success,
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
  
  TrainStop({
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
  });
}

enum StopType {
  start,
  intermediate,
  end,
}
