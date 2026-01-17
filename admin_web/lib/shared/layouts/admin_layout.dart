import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/theme/admin_theme.dart';
import '../../core/providers/admin_auth_provider.dart';
import '../../core/providers/sidebar_provider.dart';
import '../../core/providers/current_screen_provider.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/utils/toast_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/analytics/analytics_dashboard_screen.dart';
import '../../features/drivers/driver_verification_list_screen.dart';
import '../../features/rides/ride_monitoring_screen.dart';
import '../../features/rides/admin_ride_management_screen.dart';
import '../../features/tracking/live_tracking_screen.dart';
import '../../features/users/user_management_screen.dart';
import '../../screens/locations_management_screen.dart';
import '../../screens/banner_management_screen.dart';
import '../../screens/otp_banner_management_screen.dart';
import '../../screens/notification_management_screen.dart';
import '../../screens/vehicle_models_management_screen.dart';

class AdminLayout extends ConsumerStatefulWidget {
  final Widget child;
  final String currentRoute;
  final String? pageTitle;
  final List<String>? breadcrumbs;

  const AdminLayout({
    Key? key,
    required this.child,
    required this.currentRoute,
    this.pageTitle,
    this.breadcrumbs,
  }) : super(key: key);

  // Helper method to get screen widget based on route
  static Widget _getScreenForRoute(String route) {
    switch (route) {
      case '/dashboard':
      case '/analytics':
        return AnalyticsDashboardScreen();
      case '/drivers/verification':
        return DriverVerificationListScreen();
      case '/rides/monitoring':
        return RideMonitoringScreen();
      case '/rides/management':
        return AdminRideManagementScreen();
      case '/tracking':
      case '/tracking/live':
        return LiveTrackingScreen();
      case '/users':
        return UserManagementScreen();
      case '/locations':
        return LocationsManagementScreen();
      case '/banners':
        return BannerManagementScreen();
      case '/otp-banners':
        return OTPBannerManagementScreen();
      case '/vehicle-types':
        return VehicleModelsManagementScreen();
      case '/notifications':
        return NotificationManagementScreen();
      case '/finance':
        return Center(child: Text('Finance - Coming Soon'));
      case '/settings':
        return Center(child: Text('Settings - Coming Soon'));
      default:
        return AnalyticsDashboardScreen();
    }
  }

  @override
  ConsumerState<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends ConsumerState<AdminLayout> {
  Timer? _sidebarExitDebounce;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  @override
  void initState() {
    super.initState();
    // Initialize toast helper and set initial screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ToastHelper.init(context);
      // Set the initial screen route
      ref.read(currentScreenProvider.notifier).state = widget.currentRoute;
      
      // Set sidebar collapsed by default on tablets
      final isTablet = ResponsiveHelper.isTablet(context);
      if (isTablet) {
        ref.read(sidebarCollapsedProvider.notifier).state = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(adminAuthProvider);
    final isSidebarCollapsed = ref.watch(sidebarCollapsedProvider);
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    // Safety check: Redirect to login if user is null or incomplete
    if (authState.user == null || 
        authState.user!.name.isEmpty || 
        authState.user!.email.isEmpty) {
      print('⚠️ AdminLayout: User is null or incomplete, redirecting to login');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading user data...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AdminTheme.backgroundColor,
      drawer: isMobile ? _buildDrawer(authState) : null,
      body: (isDesktop || isTablet)
          ? Stack(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 70),
                    // Main Content
                    Expanded(
                      child: Column(
                        children: [
                          _buildTopBar(context, isMobile, authState),
                          if (widget.breadcrumbs != null && widget.breadcrumbs!.isNotEmpty)
                            _buildBreadcrumbs(),
                          Expanded(
                            child: Consumer(
                              builder: (context, ref, _) {
                                final currentScreen = ref.watch(currentScreenProvider);
                                return AdminLayout._getScreenForRoute(currentScreen);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Backdrop overlay for tablet when sidebar is expanded
                if (isTablet && !isSidebarCollapsed)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(sidebarCollapsedProvider.notifier).state = true;
                      },
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: MouseRegion(
                    onEnter: isDesktop ? (_) {
                      _sidebarExitDebounce?.cancel();
                      if (ref.read(sidebarCollapsedProvider)) {
                        ref.read(sidebarCollapsedProvider.notifier).state = false;
                      }
                    } : null,
                    onExit: isDesktop ? (_) {
                      _sidebarExitDebounce?.cancel();
                      _sidebarExitDebounce = Timer(const Duration(milliseconds: 300), () {
                        if (!mounted) return;
                        if (!ref.read(sidebarCollapsedProvider)) {
                          ref.read(sidebarCollapsedProvider.notifier).state = true;
                        }
                      });
                    } : null,
                    child: RepaintBoundary(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.fastOutSlowIn,
                      width: isSidebarCollapsed ? 70 : 250,
                      decoration: BoxDecoration(
                        color: AdminTheme.sidebarBackground,
                        boxShadow: isSidebarCollapsed
                            ? const []
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 16,
                                  offset: const Offset(2, 0),
                                ),
                              ],
                      ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // During the width animation, avoid rendering expanded ListTiles
                            // until we actually have enough width, otherwise ListTile can
                            // assert under tight constraints.
                            final collapsed = constraints.maxWidth < 160;
                            return _buildSidebarContent(authState, collapsed: collapsed);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                // Main Content (mobile uses Drawer)
                Expanded(
                  child: Column(
                    children: [
                      _buildTopBar(context, isMobile, authState),
                      if (widget.breadcrumbs != null && widget.breadcrumbs!.isNotEmpty)
                        _buildBreadcrumbs(),
                      Expanded(child: widget.child),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _sidebarExitDebounce?.cancel();
    super.dispose();
  }

  Widget _buildSidebarContent(AdminAuthState authState, {required bool collapsed}) {
    return Column(
      children: [
        // Logo/Header - fixed height container to prevent menu shift
        Container(
          height: 116,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo - always visible, same size
              Image.asset(
                'assets/images/vanyatra_new_logo_home.png',
                width: 44,
                height: 44,
              ),
              const SizedBox(height: 5),
              // App name - only visible when expanded, clipped during animation
              ClipRect(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  opacity: collapsed ? 0.0 : 1.0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'VanYatra',
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Admin Control Center',
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white24, height: 1),

        // Navigation Menu
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _buildMenuItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                title: 'Dashboard',
                route: '/dashboard',
                isCollapsedOverride: collapsed,
              ),
              _buildMenuItem(
                icon: Icons.verified_user_outlined,
                activeIcon: Icons.verified_user,
                title: 'Driver Verification',
                route: '/drivers/verification',
                isCollapsedOverride: collapsed,
              ),
              _buildMenuItem(
                icon: Icons.directions_car_outlined,
                activeIcon: Icons.directions_car,
                title: 'Active Rides',
                route: '/rides/monitoring',
                isCollapsedOverride: collapsed,
              ),
              _buildMenuItem(
                icon: Icons.event_available_outlined,
                activeIcon: Icons.event_available,
                title: 'Ride Management',
                route: '/rides/management',
                isCollapsedOverride: collapsed,
              ),
              _buildMenuItem(
                icon: Icons.map_outlined,
                activeIcon: Icons.map,
                title: 'Live Tracking',
                route: '/tracking',
                isCollapsedOverride: collapsed,
              ),
              _buildMenuItem(
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                title: 'User Management',
                route: '/users',
                isCollapsedOverride: collapsed,
              ),
              _buildMenuItem(
                icon: Icons.location_on_outlined,
                activeIcon: Icons.location_on,
                title: 'Locations',
                route: '/locations',
                isCollapsedOverride: collapsed,
              ),
              _buildMenuItem(
                icon: Icons.view_carousel_outlined,
                activeIcon: Icons.view_carousel,
                title: 'Banners',
                route: '/banners',
                isCollapsedOverride: collapsed,
              ),
              _buildMenuItem(
                icon: Icons.phone_android_outlined,
                activeIcon: Icons.phone_android,
                title: 'OTP Banners',
                route: '/otp-banners',
                isCollapsedOverride: collapsed,
              ),
              _buildMenuItem(
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications,
                title: 'Notifications',
                route: '/notifications',
                isCollapsedOverride: collapsed,
              ),
              _buildMenuItem(
                icon: Icons.directions_car_outlined,
                activeIcon: Icons.directions_car,
                title: 'Vehicle Types',
                route: '/vehicle-types',
                isCollapsedOverride: collapsed,
              ),
              _buildMenuItem(
                icon: Icons.analytics_outlined,
                activeIcon: Icons.analytics,
                title: 'Analytics',
                route: '/analytics',
                isCollapsedOverride: collapsed,
              ),
              _buildMenuItem(
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet,
                title: 'Finance',
                route: '/finance',
                isCollapsedOverride: collapsed,
              ),
              const Divider(color: Colors.white24, height: 24),
              _buildMenuItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                title: 'Settings',
                route: '/settings',
                isCollapsedOverride: collapsed,
              ),
            ],
          ),
        ),

        // User Info & Logout (only expanded)
        if (!collapsed) ...[
          const Divider(color: Colors.white24, height: 1),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (authState.user != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AdminTheme.sidebarHover,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AdminTheme.accentColor,
                          child: Text(
                            authState.user!.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authState.user!.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                authState.user!.role.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Logout'),
                    onPressed: () => _handleLogout(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.errorColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  // Build top app bar
  Widget _buildTopBar(BuildContext context, bool isMobile, AdminAuthState authState) {
    final isTablet = ResponsiveHelper.isTablet(context);
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Menu button (mobile and tablet)
          if (isMobile || isTablet)
            IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Open Menu',
              onPressed: () {
                if (isMobile) {
                  _scaffoldKey.currentState?.openDrawer();
                } else {
                  // Toggle sidebar for tablet
                  final isCollapsed = ref.read(sidebarCollapsedProvider);
                  ref.read(sidebarCollapsedProvider.notifier).state = !isCollapsed;
                }
              },
            ),
          
          // Page title
          if (widget.pageTitle != null)
            Expanded(
              child: Text(
                widget.pageTitle!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AdminTheme.textPrimary,
                ),
              ),
            )
          else
            const Expanded(child: SizedBox()),
          
          // Search bar (desktop)
          if (ResponsiveHelper.isDesktop(context))
            Container(
              width: 300,
              height: 40,
              margin: const EdgeInsets.only(right: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AdminTheme.borderGray),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AdminTheme.borderGray),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AdminTheme.primaryColor),
                  ),
                  filled: true,
                  fillColor: AdminTheme.backgroundColor,
                ),
              ),
            ),
          
          // Notifications
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AdminTheme.errorColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
          
          // User menu (desktop)
          if (ResponsiveHelper.isDesktop(context) && authState.user != null)
            PopupMenuButton<String>(
              offset: const Offset(0, 50),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AdminTheme.primaryColor,
                    child: Text(
                      authState.user!.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    authState.user!.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.person_outline, size: 20),
                      SizedBox(width: 12),
                      Text('Profile'),
                    ],
                  ),
                  onTap: () {
                    // TODO: Navigate to profile
                  },
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.settings_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Settings'),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).pushNamed('/settings');
                  },
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.logout, size: 20, color: AdminTheme.errorColor),
                      SizedBox(width: 12),
                      Text('Logout', style: TextStyle(color: AdminTheme.errorColor)),
                    ],
                  ),
                  onTap: () => _handleLogout(),
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  // Build breadcrumbs
  Widget _buildBreadcrumbs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AdminTheme.borderGray, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.home, size: 16, color: AdminTheme.textSecondary),
          const SizedBox(width: 8),
          ...List.generate(
            widget.breadcrumbs!.length,
            (index) {
              final isLast = index == widget.breadcrumbs!.length - 1;
              return Row(
                children: [
                  Text(
                    widget.breadcrumbs![index],
                    style: TextStyle(
                      fontSize: 14,
                      color: isLast ? AdminTheme.primaryColor : AdminTheme.textSecondary,
                      fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (!isLast) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AdminTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
  
  // Build mobile drawer
  Widget _buildDrawer(AdminAuthState authState) {
    return Drawer(
      child: Container(
        color: AdminTheme.sidebarBackground,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AdminTheme.sidebarBackground,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/vanyatra_new_logo_home.png',
                    width: 52,
                    height: 52,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'VanYatra',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Admin Control Center',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    title: 'Dashboard',
                    route: '/dashboard',
                    isCollapsedOverride: false,
                  ),
                  _buildMenuItem(
                    icon: Icons.verified_user_outlined,
                    activeIcon: Icons.verified_user,
                    title: 'Driver Verification',
                    route: '/drivers/verification',
                    isCollapsedOverride: false,
                  ),
                  _buildMenuItem(
                    icon: Icons.directions_car_outlined,
                    activeIcon: Icons.directions_car,
                    title: 'Active Rides',
                    route: '/rides/monitoring',
                    isCollapsedOverride: false,
                  ),
                  _buildMenuItem(
                    icon: Icons.event_available_outlined,
                    activeIcon: Icons.event_available,
                    title: 'Ride Management',
                    route: '/rides/management',
                    isCollapsedOverride: false,
                  ),
                  _buildMenuItem(
                    icon: Icons.map_outlined,
                    activeIcon: Icons.map,
                    title: 'Live Tracking',
                    route: '/tracking',
                    isCollapsedOverride: false,
                  ),
                  _buildMenuItem(
                    icon: Icons.people_outline,
                    activeIcon: Icons.people,
                    title: 'User Management',
                    route: '/users',
                    isCollapsedOverride: false,
                  ),
                  _buildMenuItem(
                    icon: Icons.location_on_outlined,
                    activeIcon: Icons.location_on,
                    title: 'Locations',
                    route: '/locations',
                    isCollapsedOverride: false,
                  ),
                  _buildMenuItem(
                    icon: Icons.view_carousel_outlined,
                    activeIcon: Icons.view_carousel,
                    title: 'Banners',
                    route: '/banners',
                    isCollapsedOverride: false,
                  ),
                  _buildMenuItem(
                    icon: Icons.phone_android_outlined,
                    activeIcon: Icons.phone_android,
                    title: 'OTP Banners',
                    route: '/otp-banners',
                    isCollapsedOverride: false,
                  ),
                  _buildMenuItem(
                    icon: Icons.notifications_outlined,
                    activeIcon: Icons.notifications,
                    title: 'Notifications',
                    route: '/notifications',
                    isCollapsedOverride: false,
                  ),
                  _buildMenuItem(
                    icon: Icons.directions_car_outlined,
                    activeIcon: Icons.directions_car,
                    title: 'Vehicle Types',
                    route: '/vehicle-types',
                    isCollapsedOverride: false,
                  ),
                  _buildMenuItem(
                    icon: Icons.analytics_outlined,
                    activeIcon: Icons.analytics,
                    title: 'Analytics',
                    route: '/analytics',
                    isCollapsedOverride: false,
                  ),
                  _buildMenuItem(
                    icon: Icons.account_balance_wallet_outlined,
                    activeIcon: Icons.account_balance_wallet,
                    title: 'Finance',
                    route: '/finance',
                    isCollapsedOverride: false,
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings,
                    title: 'Settings',
                    route: '/settings',
                    isCollapsedOverride: false,
                  ),
                ],
              ),
            ),
            if (authState.user != null) ...[
              const Divider(color: Colors.white24),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Logout'),
                  onPressed: () => _handleLogout(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.errorColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // Handle logout
  Future<void> _handleLogout() async {
    try {
      await ref.read(adminAuthProvider.notifier).logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
        ToastHelper.success('Logged out successfully');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.error('Failed to logout: $e');
      }
    }
  }

  Widget _buildMenuItem({
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required String route,
    bool? isCollapsedOverride,
  }) {
    final currentScreen = ref.watch(currentScreenProvider);
    final isActive = currentScreen == route;
    final bool isCollapsed = isCollapsedOverride ?? ref.read(sidebarCollapsedProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: isCollapsed
          ? Tooltip(
              message: title,
              child: Material(
                color: isActive ? AdminTheme.sidebarActive : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  hoverColor: AdminTheme.sidebarHover,
                  onTap: () {
                    if (!isActive) {
                      // Cancel exit debounce to prevent sidebar from collapsing
                      _sidebarExitDebounce?.cancel();
                      
                      // Just update the screen state - no full navigation needed
                      ref.read(currentScreenProvider.notifier).state = route;
                      
                      if (ResponsiveHelper.isMobile(context)) {
                        Navigator.of(context).pop(); // Close drawer on mobile
                      }
                    }
                  },
                  child: SizedBox(
                    height: 48,
                    child: Center(
                      child: Icon(
                        isActive ? activeIcon : icon,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : ListTile(
              leading: Icon(
                isActive ? activeIcon : icon,
                color: Colors.white,
                size: 22,
              ),
              title: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
              selected: isActive,
              selectedTileColor: AdminTheme.sidebarActive,
              hoverColor: AdminTheme.sidebarHover,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onTap: () {
                if (!isActive) {
                  // Cancel exit debounce to prevent sidebar from collapsing
                  _sidebarExitDebounce?.cancel();
                  
                  // Just update the screen state - no full navigation needed
                  ref.read(currentScreenProvider.notifier).state = route;
                  
                  if (ResponsiveHelper.isMobile(context)) {
                    Navigator.of(context).pop(); // Close drawer on mobile
                  }
                }
              },
            ),
    );
  }
}
