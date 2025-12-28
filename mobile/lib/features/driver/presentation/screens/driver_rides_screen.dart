import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/core/providers/driver_ride_provider.dart';
import 'package:allapalli_ride/core/models/driver_models.dart';
import 'package:allapalli_ride/features/driver/presentation/screens/driver_tracking_screen.dart';
import 'package:allapalli_ride/features/driver/presentation/screens/driver_trip_details_screen.dart';
import 'package:allapalli_ride/features/driver/presentation/widgets/rate_ride_bottom_sheet.dart';

/// Driver's scheduled rides list screen
class DriverRidesScreen extends ConsumerStatefulWidget {
  const DriverRidesScreen({super.key});

  @override
  ConsumerState<DriverRidesScreen> createState() => _DriverRidesScreenState();
}

class _DriverRidesScreenState extends ConsumerState<DriverRidesScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  bool _hasLoadedData = false;
  String _rideTypeFilter = 'all'; // 'all', 'straight', 'return'

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  void _loadRidesIfNeeded() {
    if (!_hasLoadedData) {
      print('🚀 Loading rides for the first time...');
      _hasLoadedData = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(driverRideNotifierProvider.notifier).loadActiveRides();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCancelDialog(BuildContext context, DriverRide ride) {
    final reasonController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: Text(
          'Cancel Ride',
          style: TextStyles.headingSmall.copyWith(
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel ride ${ride.rideNumber}?',
              style: TextStyles.bodyMedium.copyWith(
                color: isDark ? Colors.white.withOpacity(0.8) : AppColors.lightTextSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Cancellation Reason',
                hintText: 'Optional: Provide a reason',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep Ride'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              print('🚫 Attempting to cancel ride: ${ride.rideId}');
              print('🚫 Cancellation reason: "${reasonController.text.trim()}"');
              
              final success = await ref
                  .read(driverRideNotifierProvider.notifier)
                  .cancelRide(ride.rideId, reasonController.text.trim());
              
              print('🚫 Cancel result: $success');
              
              if (!mounted) return;
              
              if (success) {
                print('✅ Ride cancelled successfully');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ride cancelled successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
                // Reload rides
                ref.read(driverRideNotifierProvider.notifier).loadActiveRides();
              } else {
                final errorMsg = ref.read(driverRideNotifierProvider).errorMessage;
                print('❌ Cancel failed: $errorMsg');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMsg ?? 'Failed to cancel ride'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text('Cancel Ride'),
          ),
        ],
      ),
    );
  }

  List<DriverRide> _getFilteredRides(String status) {
    final rideState = ref.watch(driverRideNotifierProvider);
    final allRides = rideState.activeRides;
    
    print('🔍 Filtering rides for status: $status, Total rides: ${allRides.length}');
    for (var ride in allRides) {
      print('  - ${ride.rideNumber}: status="${ride.status}", date="${ride.date}"');
    }
    
    final today = DateTime.now();
    final todayStr = '${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}';
    
    List<DriverRide> filtered;
    switch (status) {
      case 'upcoming':
        // Show only rides scheduled for TODAY (active or scheduled status)
        filtered = allRides.where((r) {
          final isToday = r.date == todayStr;
          final isActiveOrScheduled = r.status.toLowerCase() == 'active' || r.status.toLowerCase() == 'scheduled';
          return isToday && isActiveOrScheduled;
        }).toList();
        break;
      case 'scheduled':
        // Show all scheduled rides (future dates)
        filtered = allRides.where((r) => r.status.toLowerCase() == 'scheduled').toList();
        break;
      case 'completed':
        // Show completed rides
        filtered = allRides.where((r) => r.status.toLowerCase() == 'completed' || r.status.toLowerCase() == 'cancelled').toList();
        break;
      default:
        filtered = allRides;
    }
    
    // Apply ride type filter
    if (_rideTypeFilter == 'straight') {
      filtered = filtered.where((r) => !r.isReturnTrip).toList();
    } else if (_rideTypeFilter == 'return') {
      filtered = filtered.where((r) => r.isReturnTrip).toList();
    }
    
    print('✅ Filtered result: ${filtered.length} rides for $status (filter: $_rideTypeFilter)');
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    _loadRidesIfNeeded(); // Load data when widget is first built
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rideState = ref.watch(driverRideNotifierProvider);
    
    final upcomingRides = _getFilteredRides('upcoming');
    final scheduledRides = _getFilteredRides('scheduled');
    final completedRides = _getFilteredRides('completed');
    
    print('📊 Rides Summary:');
    print('   Upcoming: ${upcomingRides.length}');
    print('   Scheduled: ${scheduledRides.length}');
    print('   Completed: ${completedRides.length}');
    if (completedRides.isNotEmpty) {
      print('   First completed ride: ${completedRides.first.rideNumber}, status: ${completedRides.first.status}');
    }

    // Note: Auto rating prompt disabled for drivers to avoid errors
    // Drivers can rate passengers manually from the completed rides list
    
    if (rideState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (rideState.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(rideState.errorMessage!, style: TextStyles.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(driverRideNotifierProvider.notifier).loadActiveRides(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          color: isDark ? AppColors.darkSurface : Colors.white,
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primaryYellow,
                labelColor: isDark ? Colors.white : AppColors.lightTextPrimary,
                unselectedLabelColor: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                tabs: [
                  Tab(text: 'Upcoming (${upcomingRides.length})'),
                  Tab(text: 'Scheduled (${scheduledRides.length})'),
                  Tab(text: 'Completed (${completedRides.length})'),
                ],
              ),
              // Ride type filter chips
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Text(
                      'Ride Type:',
                      style: TextStyles.bodySmall.copyWith(
                        color: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    ChoiceChip(
                      label: Text('All Rides'),
                      selected: _rideTypeFilter == 'all',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _rideTypeFilter = 'all');
                        }
                      },
                      selectedColor: AppColors.primaryYellow,
                      labelStyle: TextStyle(
                        color: _rideTypeFilter == 'all' ? Colors.black : (isDark ? Colors.white : AppColors.lightTextPrimary),
                        fontWeight: _rideTypeFilter == 'all' ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    ChoiceChip(
                      label: Text('Straight'),
                      selected: _rideTypeFilter == 'straight',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _rideTypeFilter = 'straight');
                        }
                      },
                      selectedColor: AppColors.primaryYellow,
                      labelStyle: TextStyle(
                        color: _rideTypeFilter == 'straight' ? Colors.black : (isDark ? Colors.white : AppColors.lightTextPrimary),
                        fontWeight: _rideTypeFilter == 'straight' ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    ChoiceChip(
                      label: Text('Return'),
                      selected: _rideTypeFilter == 'return',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _rideTypeFilter = 'return');
                        }
                      },
                      selectedColor: AppColors.primaryYellow,
                      labelStyle: TextStyle(
                        color: _rideTypeFilter == 'return' ? Colors.black : (isDark ? Colors.white : AppColors.lightTextPrimary),
                        fontWeight: _rideTypeFilter == 'return' ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRidesList(upcomingRides, isDark, 'upcoming'),
              _buildRidesList(scheduledRides, isDark, 'scheduled'),
              _buildRidesList(completedRides, isDark, 'completed'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRidesList(List<DriverRide> rides, bool isDark, String tabStatus) {
    print('🎯 _buildRidesList: tabStatus=$tabStatus, rides.length=${rides.length}');
    
    if (rides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 80,
              color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'No rides scheduled',
              style: TextStyles.headingMedium.copyWith(
                color: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Tap + to schedule a new ride',
              style: TextStyles.bodyMedium.copyWith(
                color: isDark ? Colors.white.withOpacity(0.4) : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).scale(delay: 200.ms),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(AppSpacing.md),
      itemCount: rides.length,
      itemBuilder: (context, index) {
        final ride = rides[index];
        return _RideCard(
          ride: ride,
          isDark: isDark,
          isUpcoming: tabStatus == 'upcoming',
          onCancel: (tabStatus != 'completed') ? () {
            _showCancelDialog(context, ride);
          } : null,
          onTap: () async {
            final statusLower = ride.status.toLowerCase();
            
            // Handle active/in-progress rides - navigate to tracking
            if (statusLower == 'active' || statusLower == 'in-progress' || statusLower == 'inprogress' || statusLower == 'in_progress') {
              // Load ride details first
              await ref.read(driverRideNotifierProvider.notifier).loadRideDetails(ride.rideId);
              final rideDetails = ref.read(driverRideNotifierProvider).currentRideDetails;
              
              if (rideDetails != null && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DriverTrackingScreen(
                      rideId: ride.rideId,
                      rideDetails: rideDetails,
                    ),
                  ),
                );
              }
            }
            // Handle all other rides (scheduled/upcoming/completed) - navigate to trip details
            else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DriverTripDetailsScreen(ride: ride),
                ),
              );
            }
          },
        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.2, end: 0);
      },
    );
  }
}

/// Ride card widget
class _RideCard extends ConsumerWidget {
  final DriverRide ride;
  final bool isDark;
  final bool isUpcoming;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const _RideCard({
    required this.ride,
    required this.isDark,
    this.isUpcoming = false,
    required this.onTap,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fillPercentage = (ride.bookedSeats / ride.totalSeats * 100).toInt();
    
    // Debug: Log ride status
    print('🎫 Ride ${ride.rideNumber} status: "${ride.status}" (lowercase: "${ride.status.toLowerCase()}")');
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.md),
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
          ),
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
            // Header: ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      ride.rideNumber,
                      style: TextStyles.bodySmall.copyWith(
                        color: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (ride.linkedReturnRideId != null) ...[
                      SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sync_alt,
                              size: 10,
                              color: AppColors.primaryYellow,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'Return',
                              style: TextStyles.bodySmall.copyWith(
                                fontSize: 9,
                                color: AppColors.primaryYellow,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                _StatusBadge(status: ride.status),
              ],
            ),
            SizedBox(height: AppSpacing.md),

            // Route
            Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 30,
                      color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.2),
                    ),
                    Container(
                      width: 12,
                      height: 12,
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
                        ride.pickupLocation,
                        style: TextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg + AppSpacing.sm),
                      Text(
                        ride.dropoffLocation,
                        style: TextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Intermediate stops
            if (ride.intermediateStops != null && ride.intermediateStops!.isNotEmpty) ...[
              SizedBox(height: AppSpacing.sm),
              Padding(
                padding: EdgeInsets.only(left: AppSpacing.lg + AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Via: ${ride.intermediateStops!.join(', ')}',
                        style: TextStyles.bodySmall.copyWith(
                          color: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            SizedBox(height: AppSpacing.md),

            // Divider
            Divider(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
            ),
            SizedBox(height: AppSpacing.md),

            // Date, Time, Vehicle
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppColors.primaryYellow),
                SizedBox(width: AppSpacing.xs),
                Text(
                  ride.date,
                  style: TextStyles.bodySmall.copyWith(
                    color: isDark ? Colors.white.withOpacity(0.8) : AppColors.lightTextPrimary,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Icon(Icons.access_time, size: 16, color: AppColors.primaryYellow),
                SizedBox(width: AppSpacing.xs),
                Text(
                  ride.departureTime,
                  style: TextStyles.bodySmall.copyWith(
                    color: isDark ? Colors.white.withOpacity(0.8) : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),

            SizedBox(height: AppSpacing.md),

            // Seats Status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Seats: ${ride.bookedSeats}/${ride.totalSeats}',
                            style: TextStyles.bodyMedium.copyWith(
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$fillPercentage% Full',
                            style: TextStyles.bodySmall.copyWith(
                              color: AppColors.primaryYellow,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.xs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                        child: LinearProgressIndicator(
                          value: ride.bookedSeats / ride.totalSeats,
                          backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            fillPercentage >= 80 ? AppColors.success : AppColors.primaryYellow,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: AppSpacing.md),

            // Segment Pricing (if available)
            if (ride.segmentPrices != null && ride.segmentPrices!.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : AppColors.primaryYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                  border: Border.all(
                    color: AppColors.primaryYellow.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.route,
                          size: 16,
                          color: AppColors.primaryYellow,
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          'Segment Pricing',
                          style: TextStyles.bodySmall.copyWith(
                            color: isDark ? Colors.white.withOpacity(0.8) : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xs),
                    ...ride.segmentPrices!.map((segment) => Padding(
                      padding: EdgeInsets.only(top: AppSpacing.xs, left: AppSpacing.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${segment.fromLocation} → ${segment.toLocation}',
                              style: TextStyles.bodySmall.copyWith(
                                color: isDark ? Colors.white.withOpacity(0.7) : AppColors.lightTextSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '₹${segment.price.toStringAsFixed(0)}',
                            style: TextStyles.bodySmall.copyWith(
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.md),
            ],

            // Earnings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estimated Earnings',
                  style: TextStyles.bodySmall.copyWith(
                    color: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  '₹${ride.bookedSeats * ride.pricePerSeat}',
                  style: TextStyles.headingMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Tap indicator for upcoming rides
            if (isUpcoming && ride.status.toLowerCase() == 'scheduled') ...[
              SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Tap to view passenger details',
                    style: TextStyles.bodySmall.copyWith(
                      color: AppColors.primaryYellow,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppColors.primaryYellow,
                  ),
                ],
              ),
            ],
            
            // Rating section for completed rides
            if (ride.status.toLowerCase() == 'completed') ...[
              SizedBox(height: AppSpacing.md),
              Divider(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
              ),
              SizedBox(height: AppSpacing.sm),
              _RatingSection(ride: ride, isDark: isDark),
            ]
            else if (ride.status.toLowerCase() == 'cancelled') ...[
              // For cancelled rides, show cancellation info instead of rating
              SizedBox(height: AppSpacing.md),
              Divider(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
              ),
              SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.cancel, color: AppColors.error, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Ride was cancelled',
                    style: TextStyles.bodyMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            
            // Cancel button for non-completed rides
            if (onCancel != null) ...[
              SizedBox(height: AppSpacing.md),
              Divider(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
              ),
              SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Show tracking button for active/in-progress rides
                  if (ride.status.toLowerCase() == 'in_progress' || 
                      ride.status.toLowerCase() == 'active' || 
                      ride.status.toLowerCase() == 'inprogress' || 
                      ride.status.toLowerCase() == 'in-progress')
                    Expanded(
                      child: _ViewTrackingButton(ride: ride),
                    )
                  else
                    Spacer(),
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: Icon(Icons.cancel, color: AppColors.error, size: 18),
                    label: Text(
                      'Cancel Ride',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'upcoming':
        backgroundColor = AppColors.warning.withOpacity(0.1);
        textColor = AppColors.warning;
        label = 'Starting Soon';
        icon = Icons.access_time;
        break;
      case 'scheduled':
        backgroundColor = AppColors.info.withOpacity(0.1);
        textColor = AppColors.info;
        label = 'Scheduled';
        icon = Icons.event;
        break;
      case 'completed':
        backgroundColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        label = 'Completed';
        icon = Icons.check_circle;
        break;
      default:
        backgroundColor = AppColors.info.withOpacity(0.1);
        textColor = AppColors.info;
        label = status;
        icon = Icons.info;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyles.bodySmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// View Tracking Button with loading state
class _ViewTrackingButton extends ConsumerStatefulWidget {
  final DriverRide ride;

  const _ViewTrackingButton({required this.ride});

  @override
  ConsumerState<_ViewTrackingButton> createState() => _ViewTrackingButtonState();
}

class _ViewTrackingButtonState extends ConsumerState<_ViewTrackingButton> {
  bool _isLoading = false;

  Future<void> _handleViewTracking() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    print('🚗 View Tracking clicked for ride: ${widget.ride.rideId}');

    // Store context before async operations
    final navContext = context;

    try {
      print('📡 Loading ride details directly from service...');
      
      // Call service directly to avoid provider rebuild issues
      final service = ref.read(driverRideServiceProvider);
      final response = await service.getRideDetails(widget.ride.rideId);
      
      print('📦 Loaded: ${response.success}');
      if (response.success && response.data != null) {
        final rideDetails = response.data!;
        print('📦 Passengers: ${rideDetails.passengers.length}');
        print('📦 Ride status: ${rideDetails.status}');
        
        print('🎯 Navigating to tracking screen...');
        await Navigator.of(navContext).push(
          MaterialPageRoute(
            builder: (context) => DriverTrackingScreen(
              rideId: widget.ride.rideId,
              rideDetails: rideDetails,
            ),
          ),
        );
        print('✅ Returned from tracking screen');
        
        if (mounted) {
          setState(() => _isLoading = false);
        }
      } else {
        print('⚠️ No ride details: ${response.message}');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        ScaffoldMessenger.of(navContext).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Error: $e');
      print('❌ Stack: $stackTrace');
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
      ScaffoldMessenger.of(navContext).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _handleViewTracking,
      icon: _isLoading 
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          )
        : Icon(Icons.navigation, size: 18),
      label: Text(_isLoading ? 'Loading...' : 'View Live Tracking'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryYellow,
        foregroundColor: Colors.black,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
}
/// Rating section widget for completed rides
class _RatingSection extends StatefulWidget {
  final DriverRide ride;
  final bool isDark;

  const _RatingSection({
    required this.ride,
    required this.isDark,
  });

  @override
  State<_RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends State<_RatingSection> {
  int _hoveredStar = 0;
  bool _hasRated = false;

  void _handleStarTap(int rating) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RateRideBottomSheet(
        rideId: widget.ride.rideId,
        rideNumber: widget.ride.rideNumber,
        onSubmit: (rating, feedback) async {
          // TODO: Call API to submit rating
          print('Rating: $rating, Feedback: $feedback');
          setState(() => _hasRated = true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasRated) {
      return Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 20,
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            'Thank you for your rating!',
            style: TextStyles.bodyMedium.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How was your trip?',
          style: TextStyles.bodyMedium.copyWith(
            color: widget.isDark ? Colors.white : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Row(
          children: List.generate(5, (index) {
            final starValue = index + 1;
            return GestureDetector(
              onTap: () => _handleStarTap(starValue),
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoveredStar = starValue),
                onExit: (_) => setState(() => _hoveredStar = 0),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    _hoveredStar >= starValue
                        ? Icons.star
                        : Icons.star_border,
                    size: 32,
                    color: _hoveredStar >= starValue
                        ? AppColors.primaryYellow
                        : (widget.isDark ? Colors.white38 : Colors.grey[400]),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}