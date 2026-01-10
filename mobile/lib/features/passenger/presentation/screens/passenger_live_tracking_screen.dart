import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/passenger_ride_models.dart';
import '../../../../core/providers/location_tracking_provider.dart';
import '../../../../app/themes/app_colors.dart';
import '../../../../app/themes/app_spacing.dart';
import '../../../../app/themes/text_styles.dart';
import 'package:geolocator/geolocator.dart';
import 'booking_management_screen.dart';

/// Passenger live tracking screen - shows live ride tracking with beautiful passenger-focused UI
class PassengerLiveTrackingScreen extends ConsumerStatefulWidget {
  final String rideId;
  final String bookingNumber;
  final RideHistoryItem rideDetails;

  const PassengerLiveTrackingScreen({
    super.key,
    required this.rideId,
    required this.bookingNumber,
    required this.rideDetails,
  });

  @override
  ConsumerState<PassengerLiveTrackingScreen> createState() => _PassengerLiveTrackingScreenState();
}

class _PassengerLiveTrackingScreenState extends ConsumerState<PassengerLiveTrackingScreen> {
  int _currentStopIndex = 0;
  
  @override
  void initState() {
    super.initState();
    // Join ride as passenger for real-time updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationTrackingProvider.notifier).joinRideAsPassenger(widget.rideId);
    });
  }
  
  @override
  void dispose() {
    // Stop tracking when screen is closed
    ref.read(locationTrackingProvider.notifier).stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(locationTrackingProvider);
    final driverLocation = trackingState.driverLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Build list of stops
    final allStops = _buildStopsList();
    
    // Check if driver has started the ride - must have location AND ride must be active/in-progress
    final rideStatus = widget.rideDetails.status.toLowerCase();
    final isRideActive = rideStatus == 'active' || rideStatus == 'in-progress' || rideStatus == 'in_progress';
    final hasDriverStarted = driverLocation != null && trackingState.isSocketConnected && isRideActive;
    
    // Find current stop based on driver location
    if (hasDriverStarted) {
      _updateCurrentStop(driverLocation, allStops);
    }
    
    // Calculate next stop and arrival time
    final nextStop = _getNextStop(allStops);
    final destinationStop = _getPassengerDestination(allStops);
    final arrivalTime = _getArrivalTime(allStops, destinationStop);
    final statusText = hasDriverStarted 
        ? (nextStop != null ? 'Heading towards' : 'Preparing to start')
        : 'Driver yet to start';
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Zomato-style header
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primaryGreen,
            title: Text(
              'Live Tracking',
              style: TextStyles.headingSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.share, color: Colors.white),
                onPressed: _shareTrip,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.primaryGreen.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.rideDetails.pickupLocation,
                          style: TextStyles.headingMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'to ${widget.rideDetails.dropoffLocation}',
                          style: TextStyles.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: AppSpacing.lg),
                        Text(
                          statusText,
                          style: TextStyles.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (hasDriverStarted) ...[
                          SizedBox(height: 4),
                          Text(
                            nextStop?.name ?? widget.rideDetails.pickupLocation,
                            style: TextStyles.headingLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ] else ...[
                          SizedBox(height: 4),
                          Text(
                            'Waiting for driver to begin',
                            style: TextStyles.headingMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Icon(
                              hasDriverStarted ? Icons.schedule : Icons.access_time,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              hasDriverStarted 
                                  ? 'Arriving at ${_formatTime(arrivalTime)}'
                                  : 'Scheduled: ${_formatTime(arrivalTime)}',
                              style: TextStyles.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: AppSpacing.md),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: AppSpacing.md),
                            Text(
                              hasDriverStarted ? 'On time' : 'Not started',
                              style: TextStyles.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Stops timeline
          SliverToBoxAdapter(
            child: _buildStopsTimeline(allStops, isDark, driverLocation),
          ),
          
          // Spacer for bottom card
          SliverToBoxAdapter(
            child: SizedBox(height: 200),
          ),
        ],
      ),
      bottomSheet: _buildDriverActionsCard(isDark),
    );
  }

  TrainStop? _getNextStop(List<TrainStop> stops) {
    // Get the next stop after current position
    if (_currentStopIndex < stops.length - 1) {
      return stops[_currentStopIndex + 1];
    }
    return null;
  }

  TrainStop _getPassengerDestination(List<TrainStop> stops) {
    // Find passenger's dropoff location
    final passengerDropoff = widget.rideDetails.dropoffLocation;
    final destinationStop = stops.firstWhere(
      (stop) => stop.name == passengerDropoff,
      orElse: () => stops.last,
    );
    return destinationStop;
  }

  DateTime _getArrivalTime(List<TrainStop> stops, TrainStop destination) {
    // Calculate actual arrival time to passenger's destination
    return destination.time;
  }

  Widget _buildStopsTimeline(List<TrainStop> stops, bool isDark, Position? driverLocation) {
    final hasDriverStarted = driverLocation != null;
    
    return Container(
      margin: EdgeInsets.all(AppSpacing.lg),
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.route,
                color: AppColors.primaryGreen,
                size: 24,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Trip Timeline',
                style: TextStyles.headingMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!hasDriverStarted) ...[
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Waiting',
                        style: TextStyles.bodySmall.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          ...stops.asMap().entries.map((entry) {
            final index = entry.key;
            final stop = entry.value;
            final isFirst = index == 0;
            final isLast = index == stops.length - 1;
            final isCurrent = index == _currentStopIndex;
            final isPast = index < _currentStopIndex;
            
            return _buildStopItem(
              stop,
              isFirst,
              isLast,
              isCurrent,
              isPast,
              isDark,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStopItem(
    TrainStop stop,
    bool isFirst,
    bool isLast,
    bool isCurrent,
    bool isPast,
    bool isDark,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              // Stop circle/icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCurrent 
                      ? AppColors.primaryGreen 
                      : isPast 
                          ? AppColors.success 
                          : (isDark ? Colors.white12 : Colors.grey[200]),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrent || isPast
                        ? Colors.white
                        : (isDark ? Colors.white24 : Colors.grey[300]!),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isFirst 
                      ? Icons.trip_origin 
                      : isLast 
                          ? Icons.location_on 
                          : Icons.circle,
                  size: isFirst || isLast ? 20 : 12,
                  color: isCurrent || isPast
                      ? Colors.white
                      : (isDark ? Colors.white38 : Colors.grey[400]),
                ),
              ),
              
              // Connecting line
              if (!isLast)
                Container(
                  width: 2,
                  height: 50,
                  margin: EdgeInsets.symmetric(vertical: 4),
                  color: isPast ? AppColors.success : (isDark ? Colors.white12 : Colors.grey[300]),
                ),
            ],
          ),
          
          SizedBox(width: AppSpacing.lg),
          
          // Stop details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        stop.name,
                        style: TextStyles.bodyLarge.copyWith(
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                          fontSize: isCurrent ? 16 : 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.xs),
                if (isCurrent)
                  Container(
                    margin: EdgeInsets.only(top: AppSpacing.xs),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          isFirst ? 'Picking up' : 'Current location',
                          style: TextStyles.bodySmall.copyWith(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isPast)
                  Container(
                    margin: EdgeInsets.only(top: AppSpacing.xs),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: AppColors.success,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: TextStyles.bodySmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!isCurrent && !isPast && stop.segmentDuration != null)
                  Container(
                    margin: EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      'ETA: ${stop.segmentDuration} mins',
                      style: TextStyles.bodySmall.copyWith(
                        color: isDark ? Colors.white54 : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverActionsCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusXL),
          topRight: Radius.circular(AppSpacing.radiusXL),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Driver info
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 28,
                    color: AppColors.primaryGreen,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.rideDetails.driverName ?? 'Your Driver',
                        style: TextStyles.bodyLarge.copyWith(
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: AppColors.primaryYellow,
                          ),
                          SizedBox(width: 4),
                          Text(
                            widget.rideDetails.rating?.toStringAsFixed(1) ?? '5.0',
                            style: TextStyles.bodySmall.copyWith(
                              color: isDark ? Colors.white70 : Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            '•',
                            style: TextStyles.bodySmall.copyWith(
                              color: isDark ? Colors.white38 : Colors.grey[400],
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            widget.rideDetails.vehicleModel ?? 'Vehicle',
                            style: TextStyles.bodySmall.copyWith(
                              color: isDark ? Colors.white54 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    widget.rideDetails.vehicleNumber ?? 'MH12AB1234',
                    style: TextStyles.bodySmall.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: AppSpacing.lg),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _callDriver,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Call Driver',
                          style: TextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _viewBookingDetails,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: BorderSide(color: AppColors.primaryGreen),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'View Details',
                          style: TextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<TrainStop> _buildStopsList() {
    final stops = <TrainStop>[];
    double cumulativeDistance = 0;
    
    // Parse departure time from scheduled time
    final departureTime = widget.rideDetails.scheduledDeparture != null
        ? DateTime.tryParse(widget.rideDetails.scheduledDeparture!) ?? DateTime.now()
        : DateTime.now();
    
    // Debug: Print intermediate stops
    print('🚏 Building stops list:');
    print('   Pickup: ${widget.rideDetails.pickupLocation}');
    print('   Dropoff: ${widget.rideDetails.dropoffLocation}');
    print('   Intermediate stops: ${widget.rideDetails.intermediateStops}');
    
    // Build route: pickup -> intermediate stops -> dropoff
    final List<String> orderedRoute = [
      widget.rideDetails.pickupLocation,
    ];
    
    // Add intermediate stops if available
    if (widget.rideDetails.intermediateStops != null && 
        widget.rideDetails.intermediateStops!.isNotEmpty) {
      print('   ✅ Adding ${widget.rideDetails.intermediateStops!.length} intermediate stops');
      orderedRoute.addAll(widget.rideDetails.intermediateStops!);
    } else {
      print('   ⚠️ No intermediate stops available');
    }
    
    orderedRoute.add(widget.rideDetails.dropoffLocation);
    
    print('   📍 Total stops in route: ${orderedRoute.length}');
    
    int cumulativeDuration = 0;
    for (int i = 0; i < orderedRoute.length; i++) {
      final location = orderedRoute[i];
      final isFirst = i == 0;
      final isLast = i == orderedRoute.length - 1;
      
      double? segmentDist;
      int? segmentDur;
      
      if (!isFirst) {
        // Estimate distance and duration
        segmentDist = 20.0; // Default estimate
        segmentDur = 30; // Default estimate
      }
      
      stops.add(TrainStop(
        name: location,
        distance: cumulativeDistance,
        time: departureTime.add(Duration(minutes: cumulativeDuration)),
        type: isFirst ? StopType.start : (isLast ? StopType.end : StopType.intermediate),
        pickupCount: isFirst ? 1 : 0,
        dropoffCount: isLast ? 1 : 0,
        segmentDistance: segmentDist,
        segmentDuration: segmentDur,
      ));
      
      if (!isLast && segmentDist != null) {
        cumulativeDistance += segmentDist;
        cumulativeDuration += segmentDur ?? 30;
      }
    }
    
    return stops;
  }

  void _updateCurrentStop(Position driverLocation, List<TrainStop> stops) {
    // Find the stop closest to driver's current location using real GPS distance
    if (stops.isEmpty) return;
    
    // Get intermediate stops with coordinates from tracking state
    final trackingState = ref.read(locationTrackingProvider);
    final intermediateStopDataList = trackingState.intermediateStops;
    
    // Helper to find coordinates for a location
    Map<String, double>? findCoordinates(String locationName) {
      final normalized = locationName.split(',').first.trim().toLowerCase();
      
      for (var stopData in intermediateStopDataList) {
        if (stopData.locationName.split(',').first.trim().toLowerCase() == normalized) {
          return {
            'lat': stopData.latitude,
            'lng': stopData.longitude,
          };
        }
      }
      return null;
    }
    
    // Find closest stop by GPS distance
    double minDistance = double.infinity;
    int closestStopIndex = _currentStopIndex;
    
    for (int i = 0; i < stops.length; i++) {
      final coords = findCoordinates(stops[i].name);
      
      if (coords != null) {
        final distance = _calculateDistance(
          driverLocation.latitude,
          driverLocation.longitude,
          coords['lat']!,
          coords['lng']!,
        );
        
        if (distance < minDistance) {
          minDistance = distance;
          closestStopIndex = i;
        }
      }
    }
    
    // If within 1km of a stop ahead, consider it reached
    if (minDistance < 1.0 && closestStopIndex >= _currentStopIndex) {
      if (_currentStopIndex != closestStopIndex) {
        setState(() {
          _currentStopIndex = closestStopIndex;
        });
      }
    }
  }
  
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert to km
  }

  double _calculateProgress(List<TrainStop> stops, Position driverLocation) {
    if (stops.isEmpty) return 0.0;
    return min(1.0, (_currentStopIndex + 0.5) / stops.length);
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  void _callDriver() async {
    print('🔍 Debug Call Driver:');
    print('   Driver Name: ${widget.rideDetails.driverName}');
    print('   Driver ID: ${widget.rideDetails.driverId}');
    print('   Driver Phone: ${widget.rideDetails.driverPhoneNumber}');
    print('   Driver Rating: ${widget.rideDetails.driverRating}');
    
    final driverPhone = widget.rideDetails.driverPhoneNumber;
    if (driverPhone == null || driverPhone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Driver phone number not available. Name: ${widget.rideDetails.driverName}')),
        );
      }
      return;
    }
    
    // Clean the phone number - remove spaces, dashes, brackets
    String cleanPhone = driverPhone.replaceAll(RegExp(r'[\s\-().]'), '');
    
    final Uri phoneUri = Uri.parse('tel:$cleanPhone');
    try {
      await launchUrl(phoneUri);
    } catch (e) {
      print('Error launching phone dialer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch phone dialer: ${e.toString()}')),
        );
      }
    }
  }

  void _viewBookingDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingManagementScreen(ride: widget.rideDetails),
      ),
    );
  }

  void _shareTrip() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share feature coming soon')),
    );
  }
}

// Train stop model
class TrainStop {
  final String name;
  final double distance;
  final DateTime time;
  final StopType type;
  final int pickupCount;
  final int dropoffCount;
  final double? segmentDistance;
  final int? segmentDuration;

  TrainStop({
    required this.name,
    required this.distance,
    required this.time,
    required this.type,
    required this.pickupCount,
    required this.dropoffCount,
    this.segmentDistance,
    this.segmentDuration,
  });
}

enum StopType { start, intermediate, end }
