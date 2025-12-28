import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/admin_theme.dart';
import 'features/auth/admin_login_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/drivers/driver_verification_list_screen.dart';
import 'features/rides/ride_monitoring_screen.dart';
import 'features/rides/admin_ride_management_screen.dart';
import 'features/analytics/analytics_dashboard_screen.dart';
import 'features/tracking/live_tracking_screen.dart';
import 'features/users/user_management_screen.dart';
import 'screens/locations_management_screen.dart';
import 'screens/banner_management_screen.dart';
import 'shared/layouts/admin_layout.dart';

void main() {
  runApp(
    ProviderScope(
      child: VanYatraAdminApp(),
    ),
  );
}

class VanYatraAdminApp extends StatelessWidget {
  const VanYatraAdminApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VanYatra Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.lightTheme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Handle routes with query parameters (for password reset)
        if (settings.name == '/reset-password') {
          final uri = Uri.parse(settings.name!);
          final args = settings.arguments as Map<String, dynamic>?;
          
          return MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              token: uri.queryParameters['token'] ?? args?['token'],
              email: uri.queryParameters['email'] ?? args?['email'],
            ),
          );
        }
        return null; // Use routes map for other routes
      },
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => AdminLoginScreen(),
        '/forgot-password': (context) => ForgotPasswordScreen(),
        '/reset-password': (context) => ResetPasswordScreen(),
        '/dashboard': (context) => AdminLayout(
              currentRoute: '/dashboard',
              child: AnalyticsDashboardScreen(),
            ),
        '/drivers/verification': (context) => AdminLayout(
              currentRoute: '/drivers/verification',
              child: DriverVerificationListScreen(),
            ),
        '/rides/monitoring': (context) => AdminLayout(
              currentRoute: '/rides/monitoring',
              child: RideMonitoringScreen(),
            ),
        '/rides/management': (context) => AdminLayout(
              currentRoute: '/rides/management',
              child: AdminRideManagementScreen(),
            ),
        '/analytics': (context) => AdminLayout(
              currentRoute: '/analytics',
              child: AnalyticsDashboardScreen(),
            ),
        '/tracking': (context) => AdminLayout(
              currentRoute: '/tracking',
              child: LiveTrackingScreen(),
            ),
        '/users': (context) => AdminLayout(
              currentRoute: '/users',
              child: UserManagementScreen(),
            ),
        '/locations': (context) => AdminLayout(
              currentRoute: '/locations',
              child: LocationsManagementScreen(),
            ),
        '/banners': (context) => AdminLayout(
              currentRoute: '/banners',
              child: BannerManagementScreen(),
            ),
      },
    );
  }
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(Duration(seconds: 1));
    
    // Always redirect to login screen - user must manually click login
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/vanyatra_icon_logo.png',
              width: 110,
              height: 110,
            ),
            SizedBox(height: 24),
            Text(
              'VanYatra',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Admin Dashboard',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
