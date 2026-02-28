import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/features/driver/presentation/screens/driver_rides_screen.dart';
import 'package:allapalli_ride/features/driver/presentation/screens/schedule_ride_screen.dart';
import 'package:allapalli_ride/features/driver/presentation/screens/driver_earnings_screen.dart';
import 'package:allapalli_ride/features/driver/presentation/screens/driver_trip_details_screen.dart';
import 'package:allapalli_ride/features/driver/presentation/screens/driver_tracking_screen.dart';
import 'package:allapalli_ride/core/providers/driver_dashboard_provider.dart';
import 'package:allapalli_ride/core/providers/driver_ride_provider.dart';
import 'package:allapalli_ride/core/providers/auth_provider.dart';
import 'package:allapalli_ride/core/providers/user_profile_provider.dart';
import 'package:allapalli_ride/core/models/driver_models.dart';
import 'package:allapalli_ride/shared/utils/permission_manager.dart';

/// Driver dashboard screen
class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});
  
  @override
  ConsumerState<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  int _selectedNavIndex = 0; // Bottom navigation index
  
  @override
  void initState() {
    super.initState();
    // Load dashboard data and active rides
    Future.microtask(() {
      ref.read(driverDashboardNotifierProvider.notifier).loadDashboard();
      ref.read(driverRideNotifierProvider.notifier).loadActiveRides();
    });
    // Request location + notification permissions proactively
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionManager.requestAllPermissions(context);
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning to this screen
    if (ModalRoute.of(context)?.isCurrent == true) {
      Future.microtask(() {
        ref.read(driverRideNotifierProvider.notifier).loadActiveRides();
      });
    }
  }
  
  Future<void> _toggleOnlineStatus(bool newStatus) async {
    final success = await ref.read(driverDashboardNotifierProvider.notifier)
        .updateOnlineStatus(newStatus);
    
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? 'You are now online' : 'You are now offline'),
          backgroundColor: newStatus ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Perform logout
      await ref.read(authNotifierProvider.notifier).logout();
      
      // Clear user profile state
      ref.read(userProfileNotifierProvider.notifier).clearProfile();
      
      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);
        
        // Navigate to login with onboarding screen and clear entire navigation stack
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login-onboarding',
          (route) => false,
        );
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashboardState = ref.watch(driverDashboardNotifierProvider);
    final isOnline = dashboardState.dashboardData?.driver.isOnline ?? false;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedNavIndex == 0 ? 'Dashboard' :
          _selectedNavIndex == 1 ? 'My Rides' :
          _selectedNavIndex == 2 ? 'Earnings' : 'Profile',
          style: TextStyles.headingMedium,
        ),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: _selectedNavIndex == 3 
          ? [] 
          : _selectedNavIndex == 1
            ? [
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () {
                    ref.read(driverRideNotifierProvider.notifier).loadActiveRides();
                  },
                  tooltip: 'Refresh Rides',
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ScheduleRideScreen()),
                    );
                    // Reload rides after returning from schedule screen
                    ref.read(driverRideNotifierProvider.notifier).loadActiveRides();
                  },
                  tooltip: 'Schedule New Ride',
                ),
              ]
            : [
                IconButton(
                  icon: Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // Open notifications
                  },
                ),
              ],
      ),
      body: IndexedStack(
        index: _selectedNavIndex,
        children: [
          _buildHomeContent(isDark, dashboardState, isOnline),
          const DriverRidesScreen(),
          const DriverEarningsScreen(),
          _buildProfileContent(isDark),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        selectedItemColor: AppColors.primaryYellow,
        unselectedItemColor: isDark 
            ? AppColors.darkTextTertiary 
            : AppColors.lightTextTertiary,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: (index) {
          setState(() {
            _selectedNavIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_taxi),
            label: 'Rides',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(bool isDark, DriverDashboardState dashboardState, bool isOnline) {
    final dashboardData = dashboardState.dashboardData;
    final isLoading = dashboardState.isLoading;
    
    // If loading and no data yet, show loading indicator
    if (isLoading && dashboardData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryYellow),
            SizedBox(height: AppSpacing.md),
            Text('Loading dashboard...', style: TextStyles.bodyMedium),
          ],
        ),
      );
    }
    
    // If there's an error and no data, show error message
    if (dashboardState.errorMessage != null && dashboardData == null) {
      final isProfileNotFound = dashboardState.errorMessage?.contains('Driver profile not found') ?? false;
      
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isProfileNotFound ? Icons.person_off : Icons.error_outline, 
                size: 64, 
                color: AppColors.error
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                isProfileNotFound ? 'Driver Profile Not Found' : 'Failed to load dashboard',
                style: TextStyles.headingSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                isProfileNotFound 
                  ? 'Your driver profile hasn\'t been created yet. Please contact support to complete your driver registration.'
                  : (dashboardState.errorMessage ?? 'Unknown error'),
                style: TextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(driverDashboardNotifierProvider.notifier).loadDashboard();
                    },
                    icon: Icon(Icons.refresh),
                    label: Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryYellow,
                      foregroundColor: Colors.black,
                    ),
                  ),
                  if (isProfileNotFound) ...[
                    SizedBox(width: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: () {
                        // Navigate back to user type selection or logout
                        _handleLogout(context);
                      },
                      icon: Icon(Icons.logout),
                      label: Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(driverDashboardNotifierProvider.notifier).loadDashboard();
        await ref.read(driverRideNotifierProvider.notifier).loadActiveRides();
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Online Status Card
            Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isOnline 
                        ? [AppColors.success.withOpacity(0.8), AppColors.success]
                        : [AppColors.error.withOpacity(0.8), AppColors.error],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOnline ? Icons.check_circle : Icons.cancel,
                      color: Colors.white,
                      size: 48,
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOnline ? 'You\'re Online' : 'You\'re Offline',
                            style: TextStyles.headingMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            isOnline 
                                ? 'Ready to accept rides'
                                : 'Go online to receive rides',
                            style: TextStyles.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isOnline,
                      onChanged: isLoading ? null : (value) => _toggleOnlineStatus(value),
                      activeColor: Colors.white,
                      activeTrackColor: Colors.white.withOpacity(0.5),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.2, end: 0),
              
              SizedBox(height: AppSpacing.xl),
              
              // Upcoming Rides Overview
              _buildUpcomingRidesSection(isDark),
              
              SizedBox(height: AppSpacing.xl),
              
              // Today's Stats
              Text(
                'Today\'s Summary',
                style: TextStyles.headingSmall.copyWith(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.event,
                      label: 'Rides',
                      value: '${dashboardData?.todayStats.totalRides ?? 0}',
                      color: AppColors.info,
                    ).animate().fadeIn(delay: 200.ms).scale(),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.currency_rupee,
                      label: 'Earnings',
                      value: '₹${(dashboardData?.todayStats.totalEarnings ?? 0.0).toStringAsFixed(0)}',
                      color: AppColors.success,
                    ).animate().fadeIn(delay: 300.ms).scale(),
                  ),
                ],
              ),
              
              SizedBox(height: AppSpacing.xl),
              
              // Quick Actions
              Text(
                'Quick Actions',
                style: TextStyles.headingSmall.copyWith(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              
              _QuickActionCard(
                icon: Icons.add_circle_outline,
                title: 'Schedule New Ride',
                subtitle: 'Set up a new trip for passengers',
                color: AppColors.primaryYellow,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ScheduleRideScreen()),
                  );
                  // Reload dashboard after returning
                  ref.read(driverDashboardNotifierProvider.notifier).loadDashboard();
                },
              ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2, end: 0),
              
              SizedBox(height: AppSpacing.md),
              
              _QuickActionCard(
                icon: Icons.list_alt,
                title: 'View My Rides',
                subtitle: 'See all scheduled and upcoming trips',
                color: AppColors.info,
                onTap: () {
                  // Switch to rides tab
                  setState(() {
                    _selectedNavIndex = 1;
                  });
                },
              ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2, end: 0),
              
              SizedBox(height: AppSpacing.md),
              
              _QuickActionCard(
                icon: Icons.account_balance_wallet,
                title: 'Earnings & Payouts',
                subtitle: 'Check your earnings and transactions',
                color: AppColors.success,
                onTap: () {
                  // Switch to earnings tab
                  setState(() {
                    _selectedNavIndex = 2;
                  });
                },
              ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2, end: 0),
              
              SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      );
    }

  Widget _buildUpcomingRidesSection(bool isDark) {
    final rideState = ref.watch(driverRideNotifierProvider);
    final activeRides = rideState.activeRides
        .where((ride) => 
            ride.status.toLowerCase() != 'cancelled' && 
            ride.status.toLowerCase() != 'completed')
        .toList();
    
    // Sort by date and time
    activeRides.sort((a, b) {
      try {
        final aDate = _parseRideDateTime(a.date, a.departureTime);
        final bDate = _parseRideDateTime(b.date, b.departureTime);
        return aDate.compareTo(bDate);
      } catch (e) {
        return 0;
      }
    });
    
    if (activeRides.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming Rides',
            style: TextStyles.headingSmall.copyWith(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBg : Colors.grey[100],
              borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_busy,
                  size: 40,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No upcoming rides',
                        style: TextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Schedule a ride to get started',
                        style: TextStyles.bodyMedium.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Rides',
              style: TextStyles.headingSmall.copyWith(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
            if (activeRides.length > 1)
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedNavIndex = 1;
                  });
                },
                child: Text('View All'),
              ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        ...activeRides.take(1).map((ride) => 
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: _UpcomingRideCard(ride: ride, isDark: isDark),
          ),
        ).toList(),
      ],
    );
  }
  
  DateTime _parseRideDateTime(String date, String time) {
    // Parse date (format: dd-MM-yyyy)
    final dateParts = date.split('-');
    final rideDate = DateTime(
      int.parse(dateParts[2]), // year
      int.parse(dateParts[1]), // month
      int.parse(dateParts[0]), // day
    );
    
    // Parse time (format: hh:mm tt or HH:mm)
    final timeStr = time.replaceAll(RegExp(r'[APap][Mm]'), '').trim();
    final timeParts = timeStr.split(':');
    var hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    // Handle 12-hour format
    if (time.toUpperCase().contains('PM') && hour != 12) {
      hour += 12;
    } else if (time.toUpperCase().contains('AM') && hour == 12) {
      hour = 0;
    }
    
    return DateTime(
      rideDate.year,
      rideDate.month,
      rideDate.day,
      hour,
      minute,
    );
  }

  Widget _buildProfileContent(bool isDark) {
    final profileState = ref.watch(userProfileNotifierProvider);
    final dashboardState = ref.watch(driverDashboardNotifierProvider);
    final dashboardData = dashboardState.dashboardData;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),

          // Profile Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryYellow, Color(0xFFFFB800)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: AppColors.primaryYellow,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  dashboardData?.driver.name ?? profileState.profile?.name ?? 'Driver Name',
                  style: TextStyles.headingLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${dashboardData?.driver.rating.toStringAsFixed(1) ?? '0.0'} Rating',
                      style: TextStyles.bodyLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _ProfileStatCard(
                  icon: Icons.local_taxi,
                  label: 'Total Rides',
                  value: '${dashboardData?.driver.totalRides ?? 0}',
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ProfileStatCard(
                  icon: Icons.currency_rupee,
                  label: 'Total Earned',
                  value: '₹${(dashboardData?.todayStats.totalEarnings ?? 0.0).toStringAsFixed(0)}',
                  color: AppColors.success,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Profile Options
          _ProfileOption(
            icon: Icons.person_outline,
            title: 'Personal Information',
            subtitle: 'Update your personal details',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Profile editing coming soon'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
          ),

          _ProfileOption(
            icon: Icons.directions_car_outlined,
            title: 'Vehicle Details',
            subtitle: 'Manage your vehicle information',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Vehicle management coming soon'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
          ),

          _ProfileOption(
            icon: Icons.description_outlined,
            title: 'Documents',
            subtitle: 'View and update your documents',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Document management coming soon'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
          ),

          _ProfileOption(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Notification settings coming soon'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
          ),

          _ProfileOption(
            icon: Icons.support_agent_outlined,
            title: 'Support',
            subtitle: 'Get help and contact support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Support contact: +91-1234567890'),
                  backgroundColor: AppColors.success,
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),

          _ProfileOption(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('About Allapalli Ride'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Version: 1.0.0'),
                      SizedBox(height: 8),
                      Text('Rural taxi booking application'),
                      SizedBox(height: 8),
                      Text('© 2025 Allapalli Ride'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleLogout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyles.bodyLarge.copyWith(
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyles.bodySmall.copyWith(
                      color: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: AppSpacing.borderRadiusLG,
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.darkShadow : AppColors.lightShadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: AppSpacing.borderRadiusSM,
            ),
            child: Icon(
              icon,
              color: color,
              size: AppSpacing.iconMD,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            label,
            style: TextStyles.caption.copyWith(
              color: isDark 
                  ? AppColors.darkTextSecondary 
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: TextStyles.headingMedium,
          ),
        ],
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ProfileStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.darkShadow : AppColors.lightShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyles.headingMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: TextStyles.caption.copyWith(
              color: isDark 
                  ? AppColors.darkTextSecondary 
                  : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.2) 
                : Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primaryYellow.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryYellow,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyles.caption.copyWith(
            color: isDark 
                ? AppColors.darkTextSecondary 
                : AppColors.lightTextSecondary,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDark 
              ? AppColors.darkTextSecondary 
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}

class _PerformanceStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _PerformanceStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primaryYellow,
          size: 28,
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: TextStyles.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyles.caption.copyWith(
            color: isDark 
                ? AppColors.darkTextSecondary 
                : AppColors.lightTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Upcoming ride card with countdown timer
class _UpcomingRideCard extends ConsumerStatefulWidget {
  final DriverRide ride;
  final bool isDark;
  
  const _UpcomingRideCard({
    required this.ride,
    required this.isDark,
  });
  
  @override
  ConsumerState<_UpcomingRideCard> createState() => _UpcomingRideCardState();
}

class _UpcomingRideCardState extends ConsumerState<_UpcomingRideCard> {
  late DateTime departureDateTime;
  Duration? timeUntilDeparture;
  
  @override
  void initState() {
    super.initState();
    _parseDateTime();
    _startCountdown();
  }
  
  void _parseDateTime() {
    try {
      // Parse date (format: dd-MM-yyyy)
      final dateParts = widget.ride.date.split('-');
      final rideDate = DateTime(
        int.parse(dateParts[2]), // year
        int.parse(dateParts[1]), // month
        int.parse(dateParts[0]), // day
      );
      
      // Parse time (format: hh:mm tt or HH:mm)
      final timeStr = widget.ride.departureTime.replaceAll(RegExp(r'[APap][Mm]'), '').trim();
      final timeParts = timeStr.split(':');
      var hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      // Handle 12-hour format
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
      departureDateTime = DateTime.now().add(Duration(hours: 1));
    }
  }
  
  void _startCountdown() {
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          timeUntilDeparture = departureDateTime.difference(DateTime.now());
        });
        _startCountdown();
      }
    });
  }
  
  String _formatCountdown(Duration duration) {
    if (duration.isNegative) {
      return 'In Progress';
    }
    
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
      return AppColors.success; // In progress
    } else if (timeUntilDeparture!.inHours < 2) {
      return AppColors.warning; // Departing soon
    } else {
      return AppColors.info; // Upcoming
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final bookedPercentage = widget.ride.totalSeats > 0
        ? (widget.ride.bookedSeats / widget.ride.totalSeats * 100).round()
        : 0;
    
    return GestureDetector(
      onTap: () async {
        final statusLower = widget.ride.status.toLowerCase();
        
        // If trip is active/in-progress, navigate to tracking screen
        if (statusLower == 'active' || statusLower == 'in-progress' || 
            statusLower == 'inprogress' || statusLower == 'in_progress') {
          // Load ride details first
          await ref.read(driverRideNotifierProvider.notifier).loadRideDetails(widget.ride.rideId);
          final rideDetails = ref.read(driverRideNotifierProvider).currentRideDetails;
          
          if (rideDetails != null && context.mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DriverTrackingScreen(
                  rideId: widget.ride.rideId,
                  rideDetails: rideDetails,
                ),
              ),
            );
          }
        } else {
          // For scheduled rides, navigate to trip details screen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DriverTripDetailsScreen(ride: widget.ride),
            ),
          );
          
          // Always reload active rides after returning to get fresh booking data
          if (mounted) {
            await ref.read(driverRideNotifierProvider.notifier).loadActiveRides();
          }
        }
        
        // Additional reload for safety
        if (mounted) {
          ref.read(driverRideNotifierProvider.notifier).loadActiveRides();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkCardBg : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          border: Border.all(
            color: statusColor.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with countdown
            Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusMD - 2),
                  topRight: Radius.circular(AppSpacing.radiusMD - 2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: statusColor,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      timeUntilDeparture != null
                          ? 'Departs in ${_formatCountdown(timeUntilDeparture!)}'
                          : 'Loading...',
                      style: TextStyles.bodyMedium.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                    ),
                    child: Text(
                      widget.ride.rideNumber,
                      style: TextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Ride details
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  // Route
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.trip_origin,
                          color: AppColors.success,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.ride.pickupLocation,
                              style: TextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Text(
                              '${widget.ride.date} • ${widget.ride.departureTime}',
                              style: TextStyles.bodySmall.copyWith(
                                color: widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 2,
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.success.withOpacity(0.5),
                                AppColors.error.withOpacity(0.5),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: AppColors.error,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          widget.ride.dropoffLocation,
                          style: TextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: AppSpacing.md),
                  Divider(height: 1),
                  SizedBox(height: AppSpacing.md),
                  
                  // Passenger count and earnings
                  Row(
                    children: [
                      // Passengers
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: widget.isDark 
                                ? AppColors.darkBackground 
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people,
                                    color: AppColors.primaryYellow,
                                    size: 20,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '${widget.ride.bookedSeats}/${widget.ride.totalSeats}',
                                    style: TextStyles.headingSmall.copyWith(
                                      color: AppColors.primaryYellow,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Booked ($bookedPercentage%)',
                                style: TextStyles.bodySmall.copyWith(
                                  color: widget.isDark 
                                      ? AppColors.darkTextSecondary 
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(width: AppSpacing.sm),
                      
                      // Earnings
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: widget.isDark 
                                ? AppColors.darkBackground 
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.currency_rupee,
                                    color: AppColors.success,
                                    size: 20,
                                  ),
                                  Text(
                                    '${widget.ride.estimatedEarnings.toStringAsFixed(0)}',
                                    style: TextStyles.headingSmall.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Est. Earnings',
                                style: TextStyles.bodySmall.copyWith(
                                  color: widget.isDark 
                                      ? AppColors.darkTextSecondary 
                                      : AppColors.lightTextSecondary,
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
          ],
        ),
      ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.2, end: 0),
    );
  }
}
