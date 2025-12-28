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
    
    // Find current stop based on driver location
    if (driverLocation != null) {
      _updateCurrentStop(driverLocation, allStops);
    }
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Trip',
              style: TextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
            Text(
              'Booking: ${widget.bookingNumber}',
              style: TextStyles.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          // Live status indicator
          Container(
            margin: EdgeInsets.only(right: AppSpacing.md),
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: trackingState.isSocketConnected 
                  ? LinearGradient(
                      colors: [AppColors.success, AppColors.success.withOpacity(0.8)],
                    )
                  : LinearGradient(
                      colors: [AppColors.error, AppColors.error.withOpacity(0.8)],
                    ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
              boxShadow: [
                BoxShadow(
                  color: trackingState.isSocketConnected 
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.error.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  trackingState.isSocketConnected ? 'LIVE' : 'OFFLINE',
                  style: TextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Hero header with gradient
          _buildHeroHeader(isDark, allStops, driverLocation),
          
          // Stops timeline
          Expanded(
            child: _buildStopsTimeline(allStops, isDark, driverLocation),
          ),
          
          // Driver info & actions card
          _buildDriverActionsCard(isDark),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(bool isDark, List<TrainStop> allStops, Position? driverLocation) {
    final progress = driverLocation != null ? _calculateProgress(allStops, driverLocation) : 0.0;
    final currentStop = allStops.length > _currentStopIndex ? allStops[_currentStopIndex] : allStops.first;
    final nextStop = allStops.length > _currentStopIndex + 1 ? allStops[_currentStopIndex + 1] : null;
    
    return Container(
      margin: EdgeInsets.all(AppSpacing.lg),
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF667EEA).withOpacity(0.4),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Progress indicator
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.white, size: 20),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Currently at',
                      style: TextStyles.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      currentStop.name,
                      style: TextStyles.headingSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppSpacing.md),
          
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          
          if (nextStop != null) ...[
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.arrow_forward, color: Colors.white70, size: 16),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Next: ${nextStop.name}',
                    style: TextStyles.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (nextStop.segmentDistance != null)
                  Text(
                    '${nextStop.segmentDistance!.toStringAsFixed(1)} km',
                    style: TextStyles.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStopsTimeline(List<TrainStop> stops, bool isDark, Position? driverLocation) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip Timeline',
            style: TextStyles.headingMedium.copyWith(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView.builder(
              itemCount: stops.length,
              itemBuilder: (context, index) {
                final stop = stops[index];
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
              },
            ),
          ),
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
    final stopColor = isPast
        ? AppColors.success
        : isCurrent
            ? AppColors.primaryYellow
            : (isDark ? Colors.white24 : Colors.black26);
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              // Top line
              if (!isFirst)
                Container(
                  width: 2,
                  height: 20,
                  color: isPast ? AppColors.success : (isDark ? Colors.white24 : Colors.black26),
                ),
              
              // Stop circle
              Container(
                width: isCurrent ? 24 : 16,
                height: isCurrent ? 24 : 16,
                decoration: BoxDecoration(
                  color: stopColor,
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: stopColor.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isFirst || isLast
                    ? Icon(
                        isFirst ? Icons.circle : Icons.location_on,
                        size: isCurrent ? 14 : 10,
                        color: Colors.white,
                      )
                    : null,
              ),
              
              // Bottom line
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isPast ? AppColors.success : (isDark ? Colors.white24 : Colors.black26),
                  ),
                ),
            ],
          ),
          
          SizedBox(width: AppSpacing.md),
          
          // Stop details
          Expanded(
            child: Container(
              padding: EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.name,
                    style: TextStyles.bodyLarge.copyWith(
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        _formatTime(stop.time),
                        style: TextStyles.bodySmall.copyWith(
                          color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
                        ),
                      ),
                      if (stop.segmentDistance != null) ...[
                        SizedBox(width: AppSpacing.md),
                        Icon(
                          Icons.straighten,
                          size: 14,
                          color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${stop.segmentDistance!.toStringAsFixed(1)} km',
                          style: TextStyles.bodySmall.copyWith(
                            color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isCurrent && stop.segmentDuration != null)
                    Container(
                      margin: EdgeInsets.only(top: AppSpacing.sm),
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                        border: Border.all(
                          color: AppColors.primaryYellow.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: AppColors.primaryYellow,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'ETA: ${stop.segmentDuration} min',
                            style: TextStyles.bodySmall.copyWith(
                              color: AppColors.primaryYellow,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverActionsCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusXL),
          topRight: Radius.circular(AppSpacing.radiusXL),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Driver info
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    size: 32,
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
                        style: TextStyles.headingSmall.copyWith(
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: AppColors.primaryYellow,
                          ),
                          SizedBox(width: 4),
                          Text(
                            widget.rideDetails.rating?.toStringAsFixed(1) ?? '0.0',
                            style: TextStyles.bodyMedium.copyWith(
                              color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: AppSpacing.md),
                          Text(
                            '${widget.rideDetails.vehicleModel ?? 'Vehicle'} • ${widget.rideDetails.vehicleNumber ?? ''}',
                            style: TextStyles.bodySmall.copyWith(
                              color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: AppSpacing.lg),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _callDriver,
                    icon: Icon(Icons.phone, size: 20),
                    label: Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _messageDriver,
                    icon: Icon(Icons.message, size: 20),
                    label: Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      foregroundColor: isDark ? Colors.white : AppColors.lightTextPrimary,
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: AppSpacing.sm),
            
            // Share trip button
            TextButton.icon(
              onPressed: _shareTrip,
              icon: Icon(Icons.share, size: 18),
              label: Text('Share trip details'),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.white70 : AppColors.lightTextSecondary,
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
    final departureTime = DateTime.now(); // Use current time as fallback
    
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
    // Simple logic: find closest stop to driver
    int closestIndex = 0;
    
    for (int i = 0; i < stops.length; i++) {
      // In a real implementation, you'd calculate distance to each stop
      // For now, assume linear progress
      final stopProgress = i / (stops.length - 1);
      if (stopProgress <= 0.5 && i > closestIndex) {
        closestIndex = i;
      }
    }
    
    if (_currentStopIndex != closestIndex) {
      setState(() {
        _currentStopIndex = closestIndex;
      });
    }
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
    // In real app, use driver's phone number
    final Uri phoneUri = Uri(scheme: 'tel', path: '+1234567890');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _messageDriver() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Messaging feature coming soon')),
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
