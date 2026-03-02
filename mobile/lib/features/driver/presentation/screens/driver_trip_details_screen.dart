import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/core/models/driver_models.dart';
import 'package:allapalli_ride/core/providers/driver_ride_provider.dart';
import 'package:allapalli_ride/features/driver/presentation/screens/active_trip_screen.dart';
import 'package:allapalli_ride/features/driver/presentation/screens/driver_tracking_screen.dart';

/// Driver trip details screen with edit options
class DriverTripDetailsScreen extends ConsumerStatefulWidget {
  final DriverRide ride;
  
  const DriverTripDetailsScreen({
    super.key,
    required this.ride,
  });

  @override
  ConsumerState<DriverTripDetailsScreen> createState() => _DriverTripDetailsScreenState();
}

class _DriverTripDetailsScreenState extends ConsumerState<DriverTripDetailsScreen> {
  late DateTime departureDateTime;
  Duration? timeUntilDeparture;
  RideDetailsWithPassengers? _rideDetails;
  DriverRide? _latestRideData;
  
  @override
  void initState() {
    super.initState();
    _latestRideData = widget.ride;
    _parseDateTime();
    _startCountdown();
    // Load ride details after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRideDetails();
      _refreshRideData();
    });
  }
  
  Future<void> _refreshRideData() async {
    // Reload active rides to get latest booking counts
    await ref.read(driverRideNotifierProvider.notifier).loadActiveRides();
    
    if (!mounted) return;
    
    // Find the updated ride in the active rides list
    final state = ref.read(driverRideNotifierProvider);
    final updatedRide = state.activeRides.firstWhere(
      (r) => r.rideId == widget.ride.rideId,
      orElse: () => widget.ride,
    );
    
    if (mounted) {
      setState(() {
        _latestRideData = updatedRide;
      });
      print('🔄 Updated ride data - Booked seats: ${updatedRide.bookedSeats}');
    }
  }
  
  Future<void> _loadRideDetails() async {
    if (!mounted) return;
    
    try {
      print('🔄 Loading ride details for rideId: ${widget.ride.rideId}');
      await ref.read(driverRideNotifierProvider.notifier).loadRideDetails(widget.ride.rideId);
      
      if (!mounted) return;
      
      // Wait a bit for the provider state to update
      await Future.delayed(const Duration(milliseconds: 100));
      
      final state = ref.read(driverRideNotifierProvider);
      if (mounted) {
        setState(() {
          _rideDetails = state.currentRideDetails;
        });
        
        if (_rideDetails != null) {
          print('✅ Ride details loaded: ${_rideDetails!.passengers.length} passengers');
        } else {
          print('⚠️ Ride details is null after loading');
        }
      }
    } catch (e) {
      print('❌ Error loading ride details: $e');
    }
  }
  
  void _parseDateTime() {
    try {
      final dateParts = widget.ride.date.split('-');
      final rideDate = DateTime(
        int.parse(dateParts[2]),
        int.parse(dateParts[1]),
        int.parse(dateParts[0]),
      );
      
      final timeStr = widget.ride.departureTime.replaceAll(RegExp(r'[APap][Mm]'), '').trim();
      final timeParts = timeStr.split(':');
      var hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      if (widget.ride.departureTime.toUpperCase().contains('PM') && hour != 12) {
        hour += 12;
      } else if (widget.ride.departureTime.toUpperCase().contains('AM') && hour == 12) {
        hour = 0;
      }
      
      departureDateTime = DateTime(
        rideDate.year,
        rideDate.month,
        rideDate.day,
        hour,
        minute,
      );
    } catch (e) {
      departureDateTime = DateTime.now().add(const Duration(hours: 1));
    }
  }
  
  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          timeUntilDeparture = departureDateTime.difference(DateTime.now());
        });
        _startCountdown();
      }
    });
  }
  
  void _showPassengerListDialog() async {
    print('👆 Tapped on booked seats card');
    
    // Refresh data first to ensure we have latest bookings
    await _refreshRideData();
    
    final currentRide = _latestRideData ?? widget.ride;
    print('   Booked seats: ${currentRide.bookedSeats}');
    print('   Ride details loaded: ${_rideDetails != null}');
    
    if (_rideDetails == null) {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading passenger details...'),
          duration: Duration(seconds: 2),
          backgroundColor: AppColors.info,
        ),
      );
      
      // Try loading again and wait
      await _loadRideDetails();
      
      // Check again after loading
      if (_rideDetails == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load passenger details. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }
    
    print('   Passengers count: ${_rideDetails!.passengers.length}');
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PassengerListBottomSheet(
        passengers: _rideDetails!.passengers,
        rideNumber: widget.ride.rideNumber,
      ),
    );
  }
  
  String _formatCountdown(Duration duration) {
    if (duration.isNegative) return 'In Progress';
    
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    
    if (days > 0) {
      return '$days day${days > 1 ? 's' : ''}, $hours hr${hours > 1 ? 's' : ''}';
    } else if (hours > 0) {
      return '$hours hr${hours > 1 ? 's' : ''}, $minutes min';
    } else {
      return '$minutes min';
    }
  }
  
  Color _getStatusColor() {
    if (timeUntilDeparture == null) return AppColors.info;
    
    if (timeUntilDeparture!.isNegative) {
      return AppColors.success;
    } else if (timeUntilDeparture!.inHours < 2) {
      return AppColors.warning;
    } else {
      return AppColors.info;
    }
  }
  
  bool _canEditRide() {
    final currentRide = _latestRideData ?? widget.ride;
    // Cannot edit if passengers have booked
    if (currentRide.bookedSeats > 0) {
      return false;
    }
    
    // Cannot edit if within 15 minutes of departure
    if (timeUntilDeparture != null && 
        !timeUntilDeparture!.isNegative && 
        timeUntilDeparture!.inMinutes < 15) {
      return false;
    }
    
    return true;
  }
  
  bool _canStartTrip() {
    // Can start trip if within 15 minutes before departure
    if (timeUntilDeparture != null && 
        !timeUntilDeparture!.isNegative && 
        timeUntilDeparture!.inMinutes <= 15) {
      return true;
    }
    return false;
  }
  
  bool _isRideActive() {
    final statusLower = widget.ride.status.toLowerCase();
    return statusLower == 'active' || 
           statusLower == 'in-progress' || 
           statusLower == 'inprogress' || 
           statusLower == 'in_progress';
  }
  
  Future<void> _navigateToLiveTracking() async {
    if (_rideDetails == null) {
      // Load ride details if not already loaded
      await _loadRideDetails();
    }
    
    if (!mounted || _rideDetails == null) return;
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverTrackingScreen(
          rideId: widget.ride.rideId,
          rideDetails: _rideDetails!,
        ),
      ),
    );
  }
  
  Future<void> _startTrip() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Trip'),
        content: const Text('Are you sure you want to start this trip now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Start Trip'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    // Navigate to ActiveTripScreen
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveTripScreen(
          ride: widget.ride,
          scheduledDepartureTime: departureDateTime,
        ),
      ),
    );
  }
  
  String _getEditDisabledReason() {
    if (widget.ride.bookedSeats > 0) {
      return 'Cannot edit after passengers have booked';
    }
    
    if (timeUntilDeparture != null && 
        !timeUntilDeparture!.isNegative && 
        timeUntilDeparture!.inMinutes < 15) {
      return 'Cannot edit within 15 minutes of departure';
    }
    
    return '';
  }
  
  void _showEditScheduleDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditScheduleBottomSheet(
        currentDate: widget.ride.date,
        currentTime: widget.ride.departureTime,
        onEdit: () {
          Navigator.pop(context);
          _navigateToEditSchedule();
        },
      ),
    );
  }
  
  void _navigateToEditSchedule() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _ScheduleEditDialog(
        currentDate: widget.ride.date,
        currentTime: widget.ride.departureTime,
      ),
    );

    if (result != null) {
      await _updateSchedule(result['date']!, result['time']!);
    }
  }

  Future<void> _updateSchedule(String newDate, String newTime) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await ref.read(driverRideNotifierProvider.notifier)
          .updateRideSchedule(widget.ride.rideId, newDate, newTime);

      // Close loading
      if (mounted) Navigator.pop(context);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Schedule updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          // Go back to refresh the list
          Navigator.pop(context);
        }
      } else {
        final error = ref.read(driverRideNotifierProvider).errorMessage;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to update schedule'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);
      
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
  
  void _showEditPriceDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditPriceBottomSheet(
        currentPrice: widget.ride.pricePerSeat,
        onUpdate: (newPrice) {
          Navigator.pop(context);
          _updatePrice(newPrice);
        },
      ),
    );
  }
  
  void _showEditSegmentPricesDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditSegmentPricesBottomSheet(
        segmentPrices: widget.ride.segmentPrices,
        onEdit: () {
          Navigator.pop(context);
          _navigateToEditSegmentPrices();
        },
      ),
    );
  }

  void _showEditIntermediateStopsDialog() async {
    final currentStops = List<String>.from(widget.ride.intermediateStops ?? []);
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => _IntermediateStopsEditorDialog(currentStops: currentStops),
    );

    if (result != null) {
      await _updateIntermediateStops(result);
    }
  }

  Future<void> _updateIntermediateStops(List<String> newStops) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await ref
          .read(driverRideNotifierProvider.notifier)
          .updateIntermediateStops(
            widget.ride.rideId,
            newStops.isEmpty ? null : newStops,
            null,
          );

      if (mounted) Navigator.pop(context);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Intermediate stops updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        final error = ref.read(driverRideNotifierProvider).errorMessage;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to update stops'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
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

  Future<void> _updatePrice(double newPrice) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await ref.read(driverRideNotifierProvider.notifier)
          .updateRidePrice(widget.ride.rideId, newPrice);

      // Close loading
      if (mounted) Navigator.pop(context);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Price updated to ₹${newPrice.toStringAsFixed(0)} successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          // Go back to refresh the list
          Navigator.pop(context);
        }
      } else {
        final error = ref.read(driverRideNotifierProvider).errorMessage;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to update price'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);
      
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
  
  void _navigateToEditSegmentPrices() async {
    if (widget.ride.segmentPrices == null || widget.ride.segmentPrices!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No segment pricing available for this route'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final result = await showDialog<List<SegmentPrice>>(
      context: context,
      builder: (context) => _SegmentPriceEditor(
        segmentPrices: widget.ride.segmentPrices!,
      ),
    );

    if (result != null) {
      await _updateSegmentPrices(result);
    }
  }

  Future<void> _updateSegmentPrices(List<SegmentPrice> newPrices) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await ref.read(driverRideNotifierProvider.notifier)
          .updateSegmentPrices(widget.ride.rideId, newPrices);

      // Close loading
      if (mounted) Navigator.pop(context);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Segment prices updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          // Go back to refresh the list
          Navigator.pop(context);
        }
      } else {
        final error = ref.read(driverRideNotifierProvider).errorMessage;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to update segment prices'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);
      
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor();
    final currentRide = _latestRideData ?? widget.ride;
    final bookedPercentage = currentRide.totalSeats > 0
        ? (currentRide.bookedSeats / currentRide.totalSeats * 100).round()
        : 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Trip Details', style: TextStyles.headingMedium),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _refreshRideData();
              await _loadRideDetails();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Trip details refreshed'),
                    duration: Duration(seconds: 1),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share feature coming soon'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
            tooltip: 'Share Ride',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshRideData();
          await _loadRideDetails();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card with Countdown
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withOpacity(0.8),
                    statusColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                        ),
                        child: Text(
                          widget.ride.rideNumber,
                          style: TextStyles.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.access_time, color: Colors.white, size: 24),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    timeUntilDeparture != null
                        ? 'Departs in ${_formatCountdown(timeUntilDeparture!)}'
                        : 'Loading...',
                    style: TextStyles.headingLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${widget.ride.date} at ${widget.ride.departureTime}',
                    style: TextStyles.bodyLarge.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms).scale(),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Route Information
            _buildSectionHeader('Route Information', isDark),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBg : Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : Colors.grey[300]!,
                ),
              ),
              child: Column(
                children: [
                  _buildRoutePoint(
                    icon: Icons.trip_origin,
                    iconColor: AppColors.success,
                    label: 'Pickup Location',
                    value: currentRide.pickupLocation,
                    isDark: isDark,
                  ),
                  
                  if (currentRide.intermediateStops != null && currentRide.intermediateStops!.isNotEmpty) ...[
                    _buildRouteDivider(),
                    ...currentRide.intermediateStops!.map((stop) => 
                      _buildRoutePoint(
                        icon: Icons.circle,
                        iconColor: AppColors.warning,
                        label: 'Stop',
                        value: stop,
                        isDark: isDark,
                        isIntermediate: true,
                      ),
                    ),
                  ],
                  
                  _buildRouteDivider(),
                  
                  _buildRoutePoint(
                    icon: Icons.location_on,
                    iconColor: AppColors.error,
                    label: 'Dropoff Location',
                    value: currentRide.dropoffLocation,
                    isDark: isDark,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Booking Statistics
            _buildSectionHeader('Booking Statistics', isDark),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: currentRide.bookedSeats > 0
                        ? () => _showPassengerListDialog()
                        : null,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                    child: _buildStatCard(
                      icon: Icons.people,
                      label: 'Booked Seats',
                      value: '${currentRide.bookedSeats}/${currentRide.totalSeats}',
                      subtitle: currentRide.bookedSeats > 0 ? 'Tap to view' : '$bookedPercentage% filled',
                      color: AppColors.primaryYellow,
                      isDark: isDark,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.event_seat,
                    label: 'Available',
                    value: '${currentRide.availableSeats}',
                    subtitle: 'seats left',
                    color: AppColors.info,
                    isDark: isDark,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 300.ms).scale(),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Earnings Information
            _buildSectionHeader('Earnings', isDark),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBg : Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                    ),
                    child: const Icon(
                      Icons.currency_rupee,
                      color: AppColors.success,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹${widget.ride.estimatedEarnings.toStringAsFixed(0)}',
                          style: TextStyles.headingLarge.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Estimated Earnings',
                          style: TextStyles.bodyMedium.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${widget.ride.pricePerSeat.toStringAsFixed(0)} per seat',
                          style: TextStyles.bodySmall.copyWith(
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.2, end: 0),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Action Buttons
            _buildSectionHeader('Manage Trip', isDark),
            const SizedBox(height: AppSpacing.md),
            
            _ActionButton(
              icon: Icons.edit_calendar,
              title: 'Edit Schedule',
              subtitle: _canEditRide() 
                  ? 'Change departure date and time' 
                  : _getEditDisabledReason(),
              color: _canEditRide() ? AppColors.info : Colors.grey,
              onTap: _canEditRide() ? _showEditScheduleDialog : null,
            ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2, end: 0),
            
            const SizedBox(height: AppSpacing.md),
            
            _ActionButton(
              icon: Icons.payments,
              title: 'Edit Price Per Seat',
              subtitle: _canEditRide() 
                  ? 'Update pricing for all seats' 
                  : _getEditDisabledReason(),
              color: _canEditRide() ? AppColors.warning : Colors.grey,
              onTap: _canEditRide() ? _showEditPriceDialog : null,
            ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2, end: 0),
            
            const SizedBox(height: AppSpacing.md),
            
            _ActionButton(
              icon: Icons.route,
              title: 'Edit Segment Prices',
              subtitle: _canEditRide()
                  ? 'Set prices for route segments'
                  : _getEditDisabledReason(),
              color: _canEditRide() ? AppColors.primaryYellow : Colors.grey,
              onTap: _canEditRide() ? _showEditSegmentPricesDialog : null,
            ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.2, end: 0),

            const SizedBox(height: AppSpacing.md),

            _ActionButton(
              icon: Icons.alt_route,
              title: 'Edit Intermediate Stops',
              subtitle: _canEditRide()
                  ? 'Add or update stops along the route'
                  : _getEditDisabledReason(),
              color: _canEditRide() ? const Color(0xFF7B1FA2) : Colors.grey,
              onTap: _canEditRide() ? _showEditIntermediateStopsDialog : null,
            ).animate().fadeIn(delay: 750.ms).slideX(begin: -0.2, end: 0),

            // Live Tracking Button (appears when trip is active/in-progress)
            if (_isRideActive()) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _navigateToLiveTracking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.navigation, size: 28),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Live Tracking',
                        style: TextStyles.headingSmall.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms).scale().shimmer(delay: 1000.ms, duration: 1500.ms),
            ]
            // Start Trip Button (appears when within 15 minutes)
            else if (_canStartTrip()) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _startTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow, size: 28),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Start Trip',
                        style: TextStyles.headingSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms).scale(),
            ],
            
            const SizedBox(height: AppSpacing.xl),
            
            // Additional Info
            if (widget.ride.distance != null || widget.ride.duration != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Trip Details', isDark),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      if (widget.ride.distance != null)
                        Expanded(
                          child: _buildInfoTile(
                            icon: Icons.straighten,
                            label: 'Distance',
                            value: '${widget.ride.distance!.toStringAsFixed(1)} km',
                            isDark: isDark,
                          ),
                        ),
                      if (widget.ride.distance != null && widget.ride.duration != null)
                        const SizedBox(width: AppSpacing.md),
                      if (widget.ride.duration != null)
                        Expanded(
                          child: _buildInfoTile(
                            icon: Icons.timer,
                            label: 'Duration',
                            value: '${(widget.ride.duration! / 60).toStringAsFixed(1)} hrs',
                            isDark: isDark,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ).animate().fadeIn(delay: 800.ms).scale(),
          ],
        ),
      ),
    ),
    );
  }
  
  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyles.headingSmall.copyWith(
        color: isDark ? Colors.white : AppColors.lightTextPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
  
  Widget _buildRoutePoint({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
    bool isIntermediate = false,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isIntermediate ? 6 : 8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: isIntermediate ? 16 : 20,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyles.bodySmall.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildRouteDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withOpacity(0.3),
                  AppColors.error.withOpacity(0.3),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyles.headingMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyles.bodySmall.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: TextStyles.caption.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.info, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyles.bodySmall.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Passenger list dialog
class _PassengerListBottomSheet extends StatelessWidget {
  final List<PassengerInfo> passengers;
  final String rideNumber;
  
  const _PassengerListBottomSheet({
    required this.passengers,
    required this.rideNumber,
  });
  
  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.radiusXL),
            topRight: Radius.circular(AppSpacing.radiusXL),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkTextTertiary : Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryYellow, AppColors.primaryYellow.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.people, color: Colors.white, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Passenger List',
                        style: TextStyles.headingSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Ride: $rideNumber',
                        style: TextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
            
            // Passenger count badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              color: isDark ? AppColors.darkCardBg : Colors.grey[100],
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: AppColors.success, size: 16),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${passengers.length} Passenger${passengers.length != 1 ? 's' : ''}',
                          style: TextStyles.bodyMedium.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Passenger list
            Flexible(
              child: passengers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No passengers yet',
                              style: TextStyles.bodyLarge.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: passengers.length,
                      separatorBuilder: (context, index) => Divider(
                        height: AppSpacing.lg,
                        color: isDark ? AppColors.darkBorder : Colors.grey[300],
                      ),
                      itemBuilder: (context, index) {
                        final passenger = passengers[index];
                        final isBoarded = passenger.boardingStatus.toLowerCase() == 'boarded';
                        
                        return Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCardBg : Colors.grey[50],
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                            border: Border.all(
                              color: isBoarded
                                  ? AppColors.success.withOpacity(0.3)
                                  : (isDark ? AppColors.darkBorder : Colors.grey[300]!),
                              width: isBoarded ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Passenger name, phone and call button
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(AppSpacing.sm),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryYellow.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: AppColors.primaryYellow,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          passenger.passengerName,
                                          style: TextStyles.bodyLarge.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          passenger.phoneNumber,
                                          style: TextStyles.bodySmall.copyWith(
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Call button
                                  IconButton(
                                    onPressed: () => _makePhoneCall(passenger.phoneNumber),
                                    icon: const Icon(Icons.phone, color: AppColors.success),
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.success.withOpacity(0.1),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  if (isBoarded)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: AppSpacing.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle, color: Colors.white, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Boarded',
                                            style: TextStyles.caption.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              
                              const SizedBox(height: AppSpacing.md),
                              
                              // Route info
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkBackground : Colors.white,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.trip_origin, color: AppColors.success, size: 16),
                                        const SizedBox(width: AppSpacing.xs),
                                        Expanded(
                                          child: Text(
                                            passenger.pickupLocation,
                                            style: TextStyles.bodySmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, color: AppColors.error, size: 16),
                                        const SizedBox(width: AppSpacing.xs),
                                        Expanded(
                                          child: Text(
                                            passenger.dropoffLocation,
                                            style: TextStyles.bodySmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: AppSpacing.sm),
                              
                              // Additional info
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildPassengerInfoChip(
                                      icon: Icons.group,
                                      label: '${passenger.passengerCount} seat${passenger.passengerCount != 1 ? 's' : ''}',
                                      isDark: isDark,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: _buildPassengerInfoChip(
                                      icon: passenger.paymentStatus.toLowerCase() == 'paid'
                                          ? Icons.check_circle
                                          : Icons.pending,
                                      label: passenger.paymentStatus,
                                      isDark: isDark,
                                      color: passenger.paymentStatus.toLowerCase() == 'paid'
                                          ? AppColors.success
                                          : AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPassengerInfoChip({
    required IconData icon,
    required String label,
    required bool isDark,
    Color? color,
  }) {
    final chipColor = color ?? AppColors.info;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: chipColor, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyles.caption.copyWith(
                color: chipColor,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Action button widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  
  const _ActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = onTap == null;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// Schedule edit dialog
class _ScheduleEditDialog extends StatefulWidget {
  final String currentDate;
  final String currentTime;

  const _ScheduleEditDialog({
    required this.currentDate,
    required this.currentTime,
  });

  @override
  State<_ScheduleEditDialog> createState() => _ScheduleEditDialogState();
}

class _ScheduleEditDialogState extends State<_ScheduleEditDialog> {
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.currentDate);
    _timeController = TextEditingController(text: widget.currentTime);

    // Parse current date (dd-MM-yyyy)
    final dateParts = widget.currentDate.split('-');
    _selectedDate = DateTime(
      int.parse(dateParts[2]),
      int.parse(dateParts[1]),
      int.parse(dateParts[0]),
    );

    // Parse current time (hh:mm AM/PM)
    final timeStr = widget.currentTime.replaceAll(RegExp(r'[APap][Mm]'), '').trim();
    final timeParts = timeStr.split(':');
    var hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    if (widget.currentTime.toUpperCase().contains('PM') && hour != 12) {
      hour += 12;
    } else if (widget.currentTime.toUpperCase().contains('AM') && hour == 12) {
      hour = 0;
    }
    
    _selectedTime = TimeOfDay(hour: hour, minute: minute);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        final hour12 = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
        final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
        _timeController.text = '${hour12.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')} $period';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusXL),
          topRight: Radius.circular(AppSpacing.radiusXL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkTextTertiary : Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                const Icon(Icons.edit_calendar, color: AppColors.primaryYellow, size: 28),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Edit Schedule',
                  style: TextStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                TextField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    suffixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: _selectDate,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _timeController,
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    suffixIcon: Icon(Icons.access_time),
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: _selectTime,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Convert time to HH:mm format for API
                          final hour24 = _selectedTime.hour.toString().padLeft(2, '0');
                          final minute = _selectedTime.minute.toString().padLeft(2, '0');
                          final apiTimeFormat = '$hour24:$minute';
                          
                          Navigator.pop(context, {
                            'date': _dateController.text,
                            'time': apiTimeFormat,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primaryYellow,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Update'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ],
        ),
    );
  }
}

/// Segment price editor dialog
class _SegmentPriceEditor extends StatefulWidget {
  final List<SegmentPrice> segmentPrices;

  const _SegmentPriceEditor({required this.segmentPrices});

  @override
  State<_SegmentPriceEditor> createState() => _SegmentPriceEditorState();
}

class _SegmentPriceEditorState extends State<_SegmentPriceEditor> {
  late List<SegmentPrice> _editedPrices;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _editedPrices = widget.segmentPrices.map((s) => s).toList();
    _controllers = _editedPrices
        .map((s) => TextEditingController(text: s.price.toStringAsFixed(0)))
        .toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Segment Prices'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _editedPrices.length,
          itemBuilder: (context, index) {
            final segment = _editedPrices[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${segment.fromLocation} → ${segment.toLocation}',
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _controllers[index],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Price',
                      prefixText: '₹ ',
                      border: const OutlineInputBorder(),
                      helperText: 'Suggested: ₹${segment.suggestedPrice.toStringAsFixed(0)}',
                    ),
                    onChanged: (value) {
                      final newPrice = double.tryParse(value);
                      if (newPrice != null) {
                        _editedPrices[index] = segment.copyWith(
                          price: newPrice,
                          isOverridden: newPrice != segment.suggestedPrice,
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Validate all prices
            bool allValid = true;
            for (var i = 0; i < _editedPrices.length; i++) {
              final price = double.tryParse(_controllers[i].text);
              if (price == null || price <= 0) {
                allValid = false;
                break;
              }
              _editedPrices[i] = _editedPrices[i].copyWith(
                price: price,
                isOverridden: price != _editedPrices[i].suggestedPrice,
              );
            }

            if (allValid) {
              Navigator.pop(context, _editedPrices);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter valid prices for all segments'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryYellow,
            foregroundColor: Colors.black,
          ),
          child: const Text('Update'),
        ),
      ],
    );
  }
}

// Bottom sheet for Edit Schedule
class _EditScheduleBottomSheet extends StatelessWidget {
  final String currentDate;
  final String currentTime;
  final VoidCallback onEdit;

  const _EditScheduleBottomSheet({
    required this.currentDate,
    required this.currentTime,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.radiusXL),
            topRight: Radius.circular(AppSpacing.radiusXL),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkTextTertiary : Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                const Icon(Icons.edit_calendar, color: AppColors.primaryYellow, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Edit Schedule',
                    style: TextStyles.headingSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const Text(
                  'Reschedule this ride to a different date and time.',
                  style: TextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBg : Colors.grey[100],
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, color: AppColors.info),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Current: $currentDate at $currentTime',
                        style: TextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onEdit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryYellow,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Edit Schedule'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}

// Bottom sheet for Edit Price
class _EditPriceBottomSheet extends StatefulWidget {
  final double currentPrice;
  final Function(double) onUpdate;

  const _EditPriceBottomSheet({
    required this.currentPrice,
    required this.onUpdate,
  });

  @override
  State<_EditPriceBottomSheet> createState() => _EditPriceBottomSheetState();
}

class _EditPriceBottomSheetState extends State<_EditPriceBottomSheet> {
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.currentPrice.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.radiusXL),
            topRight: Radius.circular(AppSpacing.radiusXL),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkTextTertiary : Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                const Icon(Icons.currency_rupee, color: AppColors.primaryYellow, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Edit Price Per Seat',
                    style: TextStyles.headingSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Update the price for each seat on this ride.',
                  style: TextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Price Per Seat',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Current price: ₹${widget.currentPrice.toStringAsFixed(0)}',
                  style: TextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final newPrice = double.tryParse(_priceController.text);
                          if (newPrice != null && newPrice > 0) {
                            widget.onUpdate(newPrice);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a valid price'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryYellow,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Update Price'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}

// Bottom sheet for Edit Segment Prices
class _EditSegmentPricesBottomSheet extends StatelessWidget {
  final List<SegmentPrice>? segmentPrices;
  final VoidCallback onEdit;

  const _EditSegmentPricesBottomSheet({
    required this.segmentPrices,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.radiusXL),
            topRight: Radius.circular(AppSpacing.radiusXL),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkTextTertiary : Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                const Icon(Icons.route, color: AppColors.primaryYellow, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Edit Segment Prices',
                    style: TextStyles.headingSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set different prices for each segment of your route.',
                    style: TextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (segmentPrices != null && segmentPrices!.isNotEmpty)
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: segmentPrices!.length,
                        separatorBuilder: (context, index) => const Divider(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final segment = segmentPrices![index];
                          return Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCardBg : Colors.grey[50],
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        segment.fromLocation,
                                        style: TextStyles.bodySmall,
                                      ),
                                      const Icon(Icons.arrow_downward, size: 12, color: AppColors.info),
                                      Text(
                                        segment.toLocation,
                                        style: TextStyles.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹${segment.price.toStringAsFixed(0)}',
                                  style: TextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          'No segment pricing available for this route.',
                          style: TextStyles.bodyMedium.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: segmentPrices != null && segmentPrices!.isNotEmpty ? onEdit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryYellow,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Edit Segments'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

// ─── Intermediate Stops Editor Dialog ────────────────────────────────────────

class _IntermediateStopsEditorDialog extends StatefulWidget {
  final List<String> currentStops;

  const _IntermediateStopsEditorDialog({required this.currentStops});

  @override
  State<_IntermediateStopsEditorDialog> createState() =>
      _IntermediateStopsEditorDialogState();
}

class _IntermediateStopsEditorDialogState
    extends State<_IntermediateStopsEditorDialog> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.currentStops.isNotEmpty
        ? widget.currentStops
            .map((s) => TextEditingController(text: s))
            .toList()
        : [TextEditingController()];
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addStop() {
    setState(() => _controllers.add(TextEditingController()));
  }

  void _removeStop(int index) {
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      title: Row(
        children: [
          const Icon(Icons.alt_route, color: Color(0xFF7B1FA2)),
          const SizedBox(width: 8),
          Text(
            'Intermediate Stops',
            style: TextStyles.headingSmall.copyWith(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add towns/cities the route passes through. Segment prices will be reset.',
                style: TextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...List.generate(_controllers.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B1FA2).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: Color(0xFF7B1FA2),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: _controllers[i],
                          decoration: InputDecoration(
                            hintText: 'Stop name (e.g. Mul)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          style: TextStyle(
                            color:
                                isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: AppColors.error),
                        onPressed: () => _removeStop(i),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: _addStop,
                icon: const Icon(Icons.add_circle_outline,
                    color: Color(0xFF7B1FA2)),
                label: const Text(
                  'Add Stop',
                  style: TextStyle(color: Color(0xFF7B1FA2)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final stops = _controllers
                .map((c) => c.text.trim())
                .where((s) => s.isNotEmpty)
                .toList();
            Navigator.pop(context, stops);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7B1FA2),
            foregroundColor: Colors.white,
          ),
          child: const Text('Save Stops'),
        ),
      ],
    );
  }
}

