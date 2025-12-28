import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/shared/widgets/slide_to_confirm_button.dart';
import 'package:allapalli_ride/shared/widgets/buttons.dart';
import 'package:allapalli_ride/core/models/driver_models.dart';
import 'package:allapalli_ride/core/providers/driver_ride_provider.dart';
import 'package:allapalli_ride/features/driver/presentation/screens/active_trip_screen.dart';
import 'package:allapalli_ride/features/driver/presentation/screens/driver_tracking_screen.dart';

/// Driver pre-trip screen showing passenger details and start trip option
class DriverPreTripScreen extends ConsumerStatefulWidget {
  final DriverRide ride;

  const DriverPreTripScreen({
    super.key,
    required this.ride,
  });

  @override
  ConsumerState<DriverPreTripScreen> createState() => _DriverPreTripScreenState();
}

class _DriverPreTripScreenState extends ConsumerState<DriverPreTripScreen> {
  late DateTime _scheduledDepartureTime;
  bool _canStartTrip = false;
  RideDetailsWithPassengers? _rideDetails;
  bool _isLoadingDetails = true;
  bool _isRouteExpanded = false;
  String _rideStatus = '';

  @override
  void initState() {
    super.initState();
    _rideStatus = widget.ride.status;
    _calculateDepartureTime();
    _checkStartTripAvailability();
    // Load ride details after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRideDetails();
    });
  }
  
  Future<void> _loadRideDetails() async {
    if (!mounted) return;
    setState(() => _isLoadingDetails = true);
    
    try {
      await ref.read(driverRideNotifierProvider.notifier).loadRideDetails(widget.ride.rideId);
      if (!mounted) return;
      
      final state = ref.read(driverRideNotifierProvider);
      setState(() {
        _rideDetails = state.currentRideDetails;
        // Update status from loaded details
        if (_rideDetails != null) {
          _rideStatus = _rideDetails!.status;
        }
        _isLoadingDetails = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingDetails = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load passenger details: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload ride details when returning to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadRideDetails();
      }
    });
  }

  void _calculateDepartureTime() {
    // Parse date from DD-MM-YYYY format
    final dateParts = widget.ride.date.split('-');
    final day = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final year = int.parse(dateParts[2]);
    
    // Parse departure time (e.g., "06:00 AM")
    final timeParts = widget.ride.departureTime.split(' ');
    final hourMinute = timeParts[0].split(':');
    int hour = int.parse(hourMinute[0]);
    final minute = int.parse(hourMinute[1]);
    final isPM = timeParts.length > 1 && timeParts[1].toUpperCase() == 'PM';

    if (isPM && hour != 12) {
      hour += 12;
    } else if (!isPM && hour == 12) {
      hour = 0;
    }

    _scheduledDepartureTime = DateTime(
      year,
      month,
      day,
      hour,
      minute,
    );

    // Check if we can start the trip (15 minutes before scheduled time)
    setState(() {
      final now = DateTime.now();
      final fifteenMinutesBefore = _scheduledDepartureTime.subtract(Duration(minutes: 15));
      _canStartTrip = now.isAfter(fifteenMinutesBefore) || now.isAtSameMomentAs(fifteenMinutesBefore);
      
      // Debug logging
      print('🕒 Current time: $now');
      print('📅 Scheduled departure: $_scheduledDepartureTime');
      print('⏰ 15 min before: $fifteenMinutesBefore');
      print('✅ Can start trip: $_canStartTrip');
    });
  }

  void _checkStartTripAvailability() {
    // Periodic check every 10 seconds for more responsive button
    Future.delayed(Duration(seconds: 10), () {
      if (mounted) {
        _calculateDepartureTime();
        _checkStartTripAvailability();
      }
    });
  }

  void _startTrip() {
    // Navigate to active trip screen for passenger verification
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveTripScreen(
          ride: widget.ride,
          scheduledDepartureTime: _scheduledDepartureTime,
        ),
      ),
    );
  }

  void _viewTracking() {
    // Navigate directly to tracking screen
    if (_rideDetails != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DriverTrackingScreen(
            rideId: widget.ride.rideId,
            rideDetails: _rideDetails!,
          ),
        ),
      );
    }
  }

  Future<void> _endTrip() async {
    // Create the complete trip request with destination location
    // Use dropoff location from the ride
    final request = CompleteTripRequest(
      endLocation: LocationDto(
        latitude: 0.0, // We don't have coordinates in DriverRide model
        longitude: 0.0,
        address: widget.ride.dropoffLocation,
      ),
      actualArrivalTime: DateTime.now().toUtc().toIso8601String(),
      actualDistance: 0.0, // Distance not tracked in pre-trip screen
    );
    
    final success = await ref.read(driverRideNotifierProvider.notifier).completeTrip(widget.ride.rideId, request);
    
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

  String _getTimeUntilDeparture() {
    final now = DateTime.now();
    final difference = _scheduledDepartureTime.difference(now);

    if (difference.isNegative) {
      final delayMinutes = difference.abs().inMinutes;
      return 'Delayed by $delayMinutes min';
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      if (hours > 0) {
        return '$hours hr $minutes min to departure';
      } else {
        return '$minutes min to departure';
      }
    }
  }

  Color _getTimingColor() {
    final now = DateTime.now();
    final difference = _scheduledDepartureTime.difference(now);

    if (difference.isNegative) {
      return AppColors.error; // Delayed
    } else if (difference.inMinutes <= 5) {
      return AppColors.warning; // Very soon
    } else if (difference.inMinutes <= 15) {
      return AppColors.success; // Ready to start
    } else {
      return AppColors.info; // Normal
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookedPassengers = _rideDetails?.passengers ?? [];
    final bookedSeats = widget.ride.bookedSeats;
    final availableSeats = widget.ride.totalSeats - bookedSeats;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('Trip Details', style: TextStyles.headingMedium),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
      ),
      body: _isLoadingDetails
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timing Banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_getTimingColor().withOpacity(0.8), _getTimingColor()],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.schedule,
                    color: Colors.white,
                    size: 48,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    _getTimeUntilDeparture(),
                    style: TextStyles.headingLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Scheduled: ${widget.ride.departureTime}',
                    style: TextStyles.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.2, end: 0),

            Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route Info (Expandable)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isRouteExpanded = !_isRouteExpanded;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                  Container(
                                    width: 3,
                                    height: 40,
                                    color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.2),
                                  ),
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.ride.pickupLocation,
                                      style: TextStyles.headingSmall.copyWith(
                                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    SizedBox(height: AppSpacing.lg + AppSpacing.md),
                                    Text(
                                      widget.ride.dropoffLocation,
                                      style: TextStyles.headingSmall.copyWith(
                                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.ride.intermediateStops != null && widget.ride.intermediateStops!.isNotEmpty)
                                Icon(
                                  _isRouteExpanded ? Icons.expand_less : Icons.expand_more,
                                  color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
                                ),
                            ],
                          ),
                          // Intermediate Stops (Expandable)
                          if (_isRouteExpanded && widget.ride.intermediateStops != null && widget.ride.intermediateStops!.isNotEmpty)
                            AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              margin: EdgeInsets.only(top: AppSpacing.md),
                              padding: EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 16, color: AppColors.info),
                                      SizedBox(width: AppSpacing.xs),
                                      Text(
                                        'Intermediate Stops',
                                        style: TextStyles.bodyMedium.copyWith(
                                          color: AppColors.info,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: AppSpacing.sm),
                                  ...widget.ride.intermediateStops!.asMap().entries.map((entry) {
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: AppSpacing.xs),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: AppColors.warning,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          SizedBox(width: AppSpacing.sm),
                                          Expanded(
                                            child: Text(
                                              '${entry.key + 1}. ${entry.value}',
                                              style: TextStyles.bodyMedium.copyWith(
                                                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0),

                  SizedBox(height: AppSpacing.xl),

                  // Seats Summary
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.event_seat,
                          label: 'Booked',
                          value: '$bookedSeats',
                          color: AppColors.success,
                          isDark: isDark,
                        ).animate().fadeIn(delay: 200.ms).scale(),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.event_available,
                          label: 'Available',
                          value: '$availableSeats',
                          color: AppColors.warning,
                          isDark: isDark,
                        ).animate().fadeIn(delay: 300.ms).scale(),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.groups,
                          label: 'Total',
                          value: '${widget.ride.totalSeats}',
                          color: AppColors.info,
                          isDark: isDark,
                        ).animate().fadeIn(delay: 400.ms).scale(),
                      ),
                    ],
                  ),

                  SizedBox(height: AppSpacing.xl),

                  // Passenger List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Passenger List',
                        style: TextStyles.headingSmall.copyWith(
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                        ),
                        child: Text(
                          '${bookedPassengers.length} Passengers',
                          style: TextStyles.bodySmall.copyWith(
                            color: AppColors.primaryYellow,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 500.ms),

                  SizedBox(height: AppSpacing.md),

                  // Passenger Cards
                  if (bookedPassengers.isEmpty)
                    Container(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                          ),
                          SizedBox(height: AppSpacing.md),
                          Text(
                            'No passengers booked yet',
                            style: TextStyles.bodyMedium.copyWith(
                              color: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 600.ms)
                  else
                    ...bookedPassengers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final passenger = entry.value;
                      return _PassengerCard(
                        passenger: passenger,
                        isDark: isDark,
                      ).animate().fadeIn(delay: (600 + index * 50).ms).slideX(begin: 0.2, end: 0);
                    }).toList(),

                  SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButtons(isDark),
    );
  }

  Widget? _buildBottomButtons(bool isDark) {
    final isActive = _rideStatus.toLowerCase() == 'active' || 
                     _rideStatus.toLowerCase() == 'in_progress' ||
                     _rideStatus.toLowerCase() == 'started';
    
    if (isActive) {
      // Trip has started - show View Tracking and End Trip buttons
      return Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // View Tracking Button
            PrimaryButton(
              text: 'View Live Tracking',
              onPressed: _viewTracking,
              icon: Icons.location_on,
              backgroundColor: AppColors.info,
            ),
            SizedBox(height: AppSpacing.md),
            // End Trip Slider
            SlideToConfirmButton(
              text: 'Slide to End Trip',
              icon: Icons.stop,
              backgroundColor: AppColors.error,
              onConfirmed: _endTrip,
            ),
          ],
        ),
      );
    } else if (_canStartTrip) {
      // Trip can be started
      return Container(
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
        child: SlideToConfirmButton(
          text: 'Slide to Start Trip',
          icon: Icons.play_arrow,
          backgroundColor: AppColors.success,
          onConfirmed: _startTrip,
        ),
      );
    }
    
    return null;
  }
}

/// Info card widget
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyles.headingLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyles.bodySmall.copyWith(
              color: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Passenger card widget
class _PassengerCard extends StatelessWidget {
  final PassengerInfo passenger;
  final bool isDark;

  const _PassengerCard({
    required this.passenger,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Passenger Count Circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${passenger.passengerCount}',
              style: TextStyles.headingMedium.copyWith(
                color: AppColors.primaryYellow,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),

          // Passenger Details
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
                SizedBox(height: 2),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${passenger.pickupLocation} → ${passenger.dropoffLocation}',
                        style: TextStyles.bodySmall.copyWith(
                          color: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary),
                    SizedBox(width: 4),
                    Text(
                      passenger.phoneNumber,
                      style: TextStyles.bodySmall.copyWith(
                        color: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Call Button
          IconButton(
            onPressed: () {
              // TODO: Implement phone call
              // You can use url_launcher package: launch('tel:${passenger.phoneNumber}');
            },
            icon: Icon(Icons.phone, color: AppColors.success),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.success.withOpacity(0.1),
            ),
          ),
          SizedBox(width: AppSpacing.xs),

          // Verified Badge
          if (passenger.boardingStatus.toLowerCase() == 'boarded')
            Container(
              padding: EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }
}
