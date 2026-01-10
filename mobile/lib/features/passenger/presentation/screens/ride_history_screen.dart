import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/features/passenger/presentation/screens/booking_management_screen.dart';
import 'package:allapalli_ride/features/passenger/presentation/screens/passenger_live_tracking_screen.dart';
import 'package:allapalli_ride/core/providers/passenger_ride_provider.dart';
import 'package:allapalli_ride/core/models/passenger_ride_models.dart';
import 'package:allapalli_ride/shared/widgets/indian_number_plate.dart';
import 'package:allapalli_ride/features/passenger/presentation/widgets/rate_ride_bottom_sheet.dart';

/// Ride history screen showing all past rides
class RideHistoryScreen extends ConsumerStatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  ConsumerState<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends ConsumerState<RideHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0); // Start with Upcoming tab
    
    // Load ride history
    Future.microtask(() {
      ref.read(passengerRideNotifierProvider.notifier).loadRideHistory();
    });
    
    // Listen to tab changes to filter by status
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadRidesForTab(_tabController.index);
      }
    });

    // Don't auto-show rating prompt here - it's handled by home screen to avoid duplicates
  }
  
  void _loadRidesForTab(int index) {
    // Load all rides and filter on client side to avoid missing confirmed/scheduled rides
    ref.read(passengerRideNotifierProvider.notifier).loadRideHistory();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rideState = ref.watch(passengerRideNotifierProvider);
    final allRides = rideState.rideHistory;
    
    // Set white status bar
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: isDark ? AppColors.darkSurface : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
    
    // Filter rides by status
    final completedRides = allRides.where((r) => r.status.toLowerCase() == 'completed').toList();
    final upcomingRides = allRides.where((r) => 
      r.status.toLowerCase() == 'scheduled' || 
      r.status.toLowerCase() == 'confirmed'
    ).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('Ride History', style: TextStyles.headingMedium),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGreen,
          labelColor: isDark ? Colors.white : AppColors.lightTextPrimary,
          unselectedLabelColor: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
          tabs: [
            Tab(text: 'Upcoming (${upcomingRides.length})'),
            Tab(text: 'All (${allRides.length})'),
            Tab(text: 'Completed (${completedRides.length})'),
          ],
        ),
      ),
      body: rideState.isLoading
          ? _buildSkeletonLoader(isDark)
          : rideState.errorMessage != null
              ? _buildErrorState(rideState.errorMessage!, isDark)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRideList(upcomingRides, isDark, 'upcoming'),
                    _buildRideList(allRides, isDark, 'all'),
                    _buildRideList(completedRides, isDark, 'completed'),
                  ],
                ),
    );
  }

  Widget _buildRideList(List<RideHistoryItem> rides, bool isDark, String type) {
    if (rides.isEmpty) {
      String emptyMessage;
      String emptyDescription;
      
      switch (type) {
        case 'completed':
          emptyMessage = 'No completed rides';
          emptyDescription = 'Your completed rides will appear here';
          break;
        case 'upcoming':
          emptyMessage = 'No upcoming rides';
          emptyDescription = 'Book a ride to see it here';
          break;
        default:
          emptyMessage = 'No rides found';
          emptyDescription = 'Your ride history will appear here once you book a ride';
      }
      
      return RefreshIndicator(
        onRefresh: () async {
          await ref.read(passengerRideNotifierProvider.notifier).loadRideHistory();
        },
        color: AppColors.primaryYellow,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    emptyMessage,
                    style: TextStyles.headingMedium.copyWith(
                      color: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    emptyDescription,
                    style: TextStyles.bodyMedium.copyWith(
                      color: isDark ? Colors.white.withOpacity(0.4) : AppColors.lightTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).scale(delay: 200.ms),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(passengerRideNotifierProvider.notifier).loadRideHistory();
      },
      color: AppColors.primaryYellow,
      child: ListView.builder(
        padding: EdgeInsets.all(AppSpacing.md),
        itemCount: rides.length,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final ride = rides[index];
          final isUpcoming = ride.status.toLowerCase() == 'scheduled' || ride.status.toLowerCase() == 'confirmed';
          final isActive = ride.status.toLowerCase() == 'confirmed' && ride.isVerified;
          
          return _RideHistoryCard(
            ride: ride,
            isDark: isDark,
            onTap: isActive 
                ? () => _navigateToLiveTracking(ride)
                : (isUpcoming ? () => _navigateToBookingManagement(ride) : null),
          ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.2, end: 0);
        },
      ),
    );
  }

  Widget _buildErrorState(String errorMessage, bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.error.withOpacity(0.6),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Oops! Something went wrong',
              style: TextStyles.headingMedium.copyWith(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              errorMessage,
              style: TextStyles.bodyMedium.copyWith(
                color: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(passengerRideNotifierProvider.notifier).loadRideHistory();
              },
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                foregroundColor: AppColors.lightTextPrimary,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).scale(delay: 200.ms),
      ),
    );
  }

  /// Navigates to booking management screen
  void _navigateToBookingManagement(RideHistoryItem ride) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingManagementScreen(ride: ride),
      ),
    );
  }

  void _navigateToLiveTracking(RideHistoryItem ride) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PassengerLiveTrackingScreen(
          rideId: ride.rideId ?? '',
          bookingNumber: ride.bookingNumber,
          rideDetails: ride,
        ),
      ),
    );
  }

  /// Build skeleton loader for rides list
  Widget _buildSkeletonLoader(bool isDark) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => _buildSkeletonCard(isDark),
    );
  }

  /// Build skeleton card matching ride card structure
  Widget _buildSkeletonCard(bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge skeleton
            Container(
              height: 24,
              width: 100,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
            
            SizedBox(height: 16),
            
            // Route section skeleton
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dots column
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 40,
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                      margin: EdgeInsets.symmetric(vertical: 4),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
                
                SizedBox(width: 12),
                
                // Location text skeletons
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
                      
                      SizedBox(height: 8),
                      
                      Container(
                        height: 14,
                        width: 150,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
                      
                      SizedBox(height: 24),
                      
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
                      
                      SizedBox(height: 8),
                      
                      Container(
                        height: 14,
                        width: 150,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Date/Time card skeleton
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
                  
                  SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: 100,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                            .animate(onPlay: (controller) => controller.repeat())
                            .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
                        
                        SizedBox(height: 6),
                        
                        Container(
                          height: 16,
                          width: 120,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                            .animate(onPlay: (controller) => controller.repeat())
                            .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // OTP & Vehicle Details skeletons (side by side)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12,
                          width: 60,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                            .animate(onPlay: (controller) => controller.repeat())
                            .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
                        
                        SizedBox(height: 8),
                        
                        Container(
                          height: 20,
                          width: 80,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                            .animate(onPlay: (controller) => controller.repeat())
                            .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(width: 12),
                
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12,
                          width: 60,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                            .animate(onPlay: (controller) => controller.repeat())
                            .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
                        
                        SizedBox(height: 8),
                        
                        Container(
                          height: 20,
                          width: 100,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                            .animate(onPlay: (controller) => controller.repeat())
                            .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Driver info skeleton
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
                
                SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 120,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
                      
                      SizedBox(height: 6),
                      
                      Container(
                        height: 12,
                        width: 80,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[300]),
            
            SizedBox(height: 16),
            
            // Fare skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 14,
                  width: 80,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
                
                Container(
                  height: 20,
                  width: 100,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Ride history card widget
class _RideHistoryCard extends StatelessWidget {
  final RideHistoryItem ride;
  final bool isDark;
  final VoidCallback? onTap;

  const _RideHistoryCard({
    required this.ride,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isClickable = onTap != null;
    print('📅 Building card for booking: ${ride.bookingNumber}');
    print('   travelDate: "${ride.travelDate}"');
    print('   selectedSeats: ${ride.selectedSeats}');
    print('   selectedSeats count: ${ride.selectedSeats?.length ?? 0}');
    
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
            // Header: Booking ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ride.bookingNumber,
                  style: TextStyles.bodySmall.copyWith(
                    color: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _StatusBadge(status: ride.status, isVerified: ride.isVerified),
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
            SizedBox(height: AppSpacing.md),

            // Divider
            Divider(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
            ),
            SizedBox(height: AppSpacing.md),

            // Date and Time Combined Card
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isDark 
                    ? AppColors.primaryGreen.withOpacity(0.15) 
                    : AppColors.primaryGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                border: Border.all(
                  color: AppColors.primaryGreen.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.primaryGreen,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        _formatDate(ride.travelDate),
                        style: TextStyles.bodySmall.copyWith(
                          color: isDark ? Colors.white : AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 20,
                    width: 1,
                    color: AppColors.primaryGreen.withOpacity(0.3),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.primaryGreen,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        _formatTime(ride.timeSlot.isNotEmpty ? ride.timeSlot.split(' - ').first : ''),
                        style: TextStyles.bodySmall.copyWith(
                          color: isDark ? Colors.white : AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.sm),

            // OTP Card - Only for upcoming rides (not active/verified)
            if (isClickable && ride.otp != null && ride.otp!.isNotEmpty && !ride.isVerified)
              Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.primaryGreen.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                          ),
                          child: Icon(
                            Icons.key,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ride OTP',
                              style: TextStyles.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 11,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              ride.otp!,
                              style: TextStyles.headingLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                      ),
                      child: Text(
                        'Share with driver',
                        style: TextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (isClickable && ride.otp != null && ride.otp!.isNotEmpty)
              SizedBox(height: AppSpacing.sm),

            // Seat Numbers - Display if available
            if (ride.selectedSeats != null && ride.selectedSeats!.isNotEmpty)
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isDark 
                      ? AppColors.primaryYellow.withOpacity(0.15)
                      : AppColors.primaryYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                  border: Border.all(
                    color: AppColors.primaryYellow.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_seat,
                      size: 16,
                      color: isDark 
                          ? AppColors.primaryYellow 
                          : const Color(0xFFF57C00),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      'Seat${ride.selectedSeats!.length > 1 ? 's' : ''}: ',
                      style: TextStyles.bodySmall.copyWith(
                        color: isDark 
                            ? Colors.white.withOpacity(0.9) 
                            : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: ride.selectedSeats!.map((seat) => Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? AppColors.primaryYellow.withOpacity(0.2)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.primaryYellow.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            seat,
                            style: TextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark 
                                  ? AppColors.primaryYellow 
                                  : const Color(0xFFF57C00),
                              fontSize: 11,
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            if (ride.selectedSeats != null && ride.selectedSeats!.isNotEmpty)
              SizedBox(height: AppSpacing.sm),

            // System Cancellation Warning - if scheduled ride has passed
            if (_hasRidePassed(ride) && ride.status.toLowerCase() == 'scheduled')
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: AppColors.error,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ride Expired',
                            style: TextStyles.bodySmall.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'This scheduled ride has passed. It will be marked as cancelled by the system.',
                            style: TextStyles.bodySmall.copyWith(
                              color: isDark ? Colors.white.withOpacity(0.8) : AppColors.lightTextSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (_hasRidePassed(ride) && ride.status.toLowerCase() == 'scheduled')
              SizedBox(height: AppSpacing.sm),

            // Vehicle Number Plate and Model
            if (ride.vehicleNumber != null && ride.vehicleNumber!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    CompactIndianNumberPlate(
                      vehicleNumber: ride.vehicleNumber!,
                      showShadow: false,
                      backgroundColor: const Color(0xFFFFC107),
                    ),
                    if (ride.vehicleModel != null) ...[
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        '(${ride.vehicleModel})',
                        style: TextStyles.bodySmall.copyWith(
                          color: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else if (ride.vehicleModel != null)
              // Show vehicle model if number plate not available
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_car,
                      size: 16,
                      color: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      ride.vehicleModel!,
                      style: TextStyles.bodySmall.copyWith(
                        color: isDark ? Colors.white.withOpacity(0.8) : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            if ((ride.vehicleNumber != null && ride.vehicleNumber!.isNotEmpty) || ride.vehicleModel != null)
              SizedBox(height: AppSpacing.xs),

            // Driver Details
            if (ride.driverName != null)
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    'Driver: ${ride.driverName}',
                    style: TextStyles.bodySmall.copyWith(
                      color: isDark ? Colors.white.withOpacity(0.8) : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            if (ride.driverName != null)
              SizedBox(height: AppSpacing.xs),

            // Scheduled Departure
            if (ride.scheduledDeparture != null)
              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 16,
                    color: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    'Departure: ${ride.scheduledDeparture}',
                    style: TextStyles.bodySmall.copyWith(
                      color: isDark ? Colors.white.withOpacity(0.8) : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            if (ride.scheduledDeparture != null)
              SizedBox(height: AppSpacing.xs),

            // Fare
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '₹${ride.totalFare.toStringAsFixed(0)}',
                  style: TextStyles.headingMedium.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Debug: Check rating conditions
            Builder(
              builder: (context) {
                print('⭐ Rating Debug for ${ride.bookingNumber}:');
                print('   Status: "${ride.status}" (lowercase: "${ride.status.toLowerCase()}")');
                print('   Rating: ${ride.rating}');
                print('   Has valid rating: ${ride.rating != null && ride.rating! > 0}');
                print('   Show rating prompt: ${ride.rating == null && ride.status.toLowerCase() == 'completed'}');
                return SizedBox.shrink();
              },
            ),

            // Show rating if available (rating > 0)
            if (ride.rating != null && ride.rating! > 0 && ride.status.toLowerCase() == 'completed') ...[
              SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.star, size: 14, color: Colors.amber),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    'Your rating: ${ride.rating}',
                    style: TextStyles.bodySmall.copyWith(
                      color: isDark ? Colors.white.withOpacity(0.8) : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],

            // Rating prompt for completed rides without rating
            if (ride.rating == null && ride.status.toLowerCase() == 'completed') ...[
              SizedBox(height: AppSpacing.md),
              Consumer(
                builder: (parentContext, ref, child) {
                  return GestureDetector(
                    onTap: () async {
                      await showModalBottomSheet(
                        context: parentContext,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (modalContext) => RateRideBottomSheet(
                          rideId: ride.rideId ?? ride.bookingNumber,
                          bookingNumber: ride.bookingNumber,
                          driverName: ride.driverName,
                          driverRating: ride.driverRating,
                          vehicleModel: ride.vehicleModel,
                          vehicleNumber: ride.vehicleNumber,
                          onSubmit: (rating, feedback) async {
                            if (ride.driverId == null || ride.driverId!.isEmpty) {
                              throw Exception('Driver ID not available for this ride');
                            }
                            final request = RateRideRequest(
                              rating: rating,
                              review: feedback.isNotEmpty ? feedback : null,
                              driverId: ride.driverId!,
                            );
                            final bookingId = ride.bookingId ?? ride.bookingNumber;
                            print('🌟 Submitting rating for booking: $bookingId');
                            
                            // Close bottom sheet BEFORE making API call
                            Navigator.of(modalContext).pop(true);
                            
                            final success = await ref
                                .read(passengerRideNotifierProvider.notifier)
                                .rateRide(bookingId, request);
                            if (!parentContext.mounted) return;
                            
                            // Use parent context for SnackBars (not modal context)
                            if (success) {
                              print('✅ Rating submitted successfully');
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                const SnackBar(
                                  content: Text('✓ Thank you for rating your ride!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              // rateRide already calls loadRideHistory internally
                            } else {
                              final errorMessage = ref.read(passengerRideNotifierProvider).errorMessage;
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage ?? 'Failed to submit rating'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                        ),
                      );
                      // No need for result handling - callback handles everything
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                        border: Border.all(
                          color: AppColors.primaryYellow.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'How was your trip?',
                            style: TextStyles.bodySmall.copyWith(
                              color: isDark ? Colors.white.withOpacity(0.8) : AppColors.lightTextPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  Icons.star_border,
                                  size: 28,
                                  color: AppColors.primaryYellow,
                                ),
                              );
                            }),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            'Tap to rate',
                            style: TextStyles.bodySmall.copyWith(
                              color: AppColors.primaryYellow,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],

            // Tap indicator - only for upcoming rides
            if (isClickable)
              SizedBox(height: AppSpacing.sm),
            if (isClickable)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Tap to view, cancel or reschedule',
                    style: TextStyles.bodySmall.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppColors.primaryGreen,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    print('📅 _formatDate called with: "$dateString"');
    
    if (dateString.isEmpty) {
      print('❌ Date string is empty');
      return 'Date not available';
    }
    
    // Try multiple date formats
    final formats = [
      'yyyy-MM-dd',
      'dd/MM/yyyy',
      'MM/dd/yyyy',
      'yyyy-MM-ddTHH:mm:ss',
      'yyyy-MM-ddTHH:mm:ss.SSS',
      'yyyy-MM-ddTHH:mm:ss.SSSZ',
    ];
    
    for (final format in formats) {
      try {
        final date = DateFormat(format).parse(dateString);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final rideDate = DateTime(date.year, date.month, date.day);
        
        print('✅ Successfully parsed date with format: $format');
        
        if (rideDate == today) {
          return 'Today';
        } else if (rideDate == today.subtract(Duration(days: 1))) {
          return 'Yesterday';
        } else if (rideDate == today.add(Duration(days: 1))) {
          return 'Tomorrow';
        } else {
          return DateFormat('dd/MM/yyyy').format(date);
        }
      } catch (e) {
        // Try next format
        continue;
      }
    }
    
    // If all formats fail, return the original string
    print('⚠️ Could not parse date with any format: $dateString');
    return dateString;
  }

  String _formatTime(String timeString) {
    if (timeString.isEmpty) return 'N/A';
    
    try {
      // Handle HH:mm format
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        
        final period = hour >= 12 ? 'PM' : 'AM';
        hour = hour % 12;
        if (hour == 0) hour = 12;
        
        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
      }
    } catch (e) {
      print('⚠️ Error formatting time: $timeString, error: $e');
    }
    
    return timeString;
  }

  bool _hasRidePassed(RideHistoryItem ride) {
    try {
      // Parse the date
      final formats = [
        'yyyy-MM-dd',
        'yyyy-MM-ddTHH:mm:ss',
        'yyyy-MM-ddTHH:mm:ss.SSS',
        'yyyy-MM-ddTHH:mm:ss.SSSZ',
      ];
      
      DateTime? rideDate;
      for (final format in formats) {
        try {
          rideDate = DateFormat(format).parse(ride.travelDate);
          break;
        } catch (e) {
          continue;
        }
      }
      
      if (rideDate == null) return false;
      
      // Parse the time slot
      if (ride.timeSlot.isNotEmpty) {
        final timeParts = ride.timeSlot.split(':');
        if (timeParts.length >= 2) {
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1].split(' ').first) ?? 0;
          
          // Combine date and time
          final rideDateTime = DateTime(
            rideDate.year,
            rideDate.month,
            rideDate.day,
            hour,
            minute,
          );
          
          // Check if ride date/time has passed
          return DateTime.now().isAfter(rideDateTime);
        }
      }
      
      // If no time available, just check if date has passed
      final today = DateTime.now();
      final rideDateOnly = DateTime(rideDate.year, rideDate.month, rideDate.day);
      final todayDateOnly = DateTime(today.year, today.month, today.day);
      
      return todayDateOnly.isAfter(rideDateOnly);
    } catch (e) {
      print('⚠️ Error checking if ride has passed: $e');
      return false;
    }
  }
}

/// Info item widget
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.primaryGreen.withOpacity(0.15) 
            : AppColors.primaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.primaryGreen,
          ),
          SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              style: TextStyles.bodySmall.copyWith(
                color: isDark ? Colors.white : AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isVerified;

  const _StatusBadge({required this.status, this.isVerified = false});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;

    final statusLower = status.toLowerCase();
    
    // Check if ride is active (confirmed and verified)
    if (statusLower == 'confirmed' && isVerified) {
      backgroundColor = AppColors.primaryGreen.withOpacity(0.1);
      textColor = AppColors.primaryGreen;
      label = 'Active';
    } else if (statusLower == 'active') {
      backgroundColor = AppColors.primaryGreen.withOpacity(0.1);
      textColor = AppColors.primaryGreen;
      label = 'Active';
    } else if (statusLower == 'completed') {
      backgroundColor = AppColors.success.withOpacity(0.1);
      textColor = AppColors.success;
      label = 'Completed';
    } else if (statusLower == 'scheduled' || statusLower == 'confirmed') {
      backgroundColor = AppColors.info.withOpacity(0.1);
      textColor = AppColors.info;
      label = 'Upcoming';
    } else if (statusLower == 'cancelled') {
      backgroundColor = AppColors.error.withOpacity(0.1);
      textColor = AppColors.error;
      label = 'Cancelled';
    } else {
      backgroundColor = Colors.grey.withOpacity(0.1);
      textColor = Colors.grey;
      label = status;
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
      child: Text(
        label,
        style: TextStyles.bodySmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader(bool isDark) {
    return ListView.builder(
      padding: EdgeInsets.all(AppSpacing.md),
      itemCount: 3,
      itemBuilder: (context, index) {
        return _buildSkeletonCard(isDark).animate(
          delay: (index * 100).ms,
        ).fadeIn();
      },
    );
  }

  Widget _buildSkeletonCard(bool isDark) {
    final shimmerColor = isDark 
        ? Colors.white.withOpacity(0.1) 
        : Colors.grey[300]!;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 80,
                height: 24,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ).animate(
                onPlay: (controller) => controller.repeat(),
              ).shimmer(
                duration: 1500.ms,
                color: Colors.white.withOpacity(0.3),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  shape: BoxShape.circle,
                ),
              ).animate(
                onPlay: (controller) => controller.repeat(),
              ).shimmer(
                duration: 1500.ms,
                color: Colors.white.withOpacity(0.3),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 30,
                    color: shimmerColor,
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ).animate(
                      onPlay: (controller) => controller.repeat(),
                    ).shimmer(
                      duration: 1500.ms,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    SizedBox(height: AppSpacing.lg + AppSpacing.sm),
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ).animate(
                      onPlay: (controller) => controller.repeat(),
                    ).shimmer(
                      duration: 1500.ms,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Divider(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ).animate(
                  onPlay: (controller) => controller.repeat(),
                ).shimmer(
                  duration: 1500.ms,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ).animate(
                  onPlay: (controller) => controller.repeat(),
                ).shimmer(
                  duration: 1500.ms,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ).animate(
                  onPlay: (controller) => controller.repeat(),
                ).shimmer(
                  duration: 1500.ms,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Container(
            width: 150,
            height: 14,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ).animate(
            onPlay: (controller) => controller.repeat(),
          ).shimmer(
            duration: 1500.ms,
            color: Colors.white.withOpacity(0.3),
          ),
          SizedBox(height: AppSpacing.xs),
          Container(
            width: 120,
            height: 14,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ).animate(
            onPlay: (controller) => controller.repeat(),
          ).shimmer(
            duration: 1500.ms,
            color: Colors.white.withOpacity(0.3),
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 80,
                height: 24,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ).animate(
                onPlay: (controller) => controller.repeat(),
              ).shimmer(
                duration: 1500.ms,
                color: Colors.white.withOpacity(0.3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}