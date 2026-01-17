import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'app/themes/app_theme.dart';
import 'core/data/local/ride_cache.dart';
import 'core/services/notification_service.dart';
import 'core/services/saved_location_service.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/onboarding_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/login_with_onboarding_screen.dart';
import 'features/auth/presentation/screens/otp_verification_screen.dart';
import 'features/auth/presentation/screens/registration_screen.dart';
import 'features/auth/presentation/screens/driver_registration_screen.dart';
import 'features/auth/presentation/screens/verification_pending_screen.dart';
import 'features/auth/presentation/screens/user_type_selection_screen.dart';
import 'features/auth/presentation/screens/phone_number_entry_screen.dart';
import 'features/passenger/presentation/screens/passenger_home_screen.dart';
import 'features/passenger/presentation/screens/ride_history_screen.dart';
import 'features/passenger/presentation/screens/passenger_tracking_screen.dart';
import 'features/driver/presentation/screens/driver_dashboard_screen.dart';
import 'features/driver/presentation/screens/driver_earnings_screen.dart';
import 'features/driver/presentation/screens/driver_tracking_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with platform-specific options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('⚠️ Firebase initialization failed: $e');
    print('   Notifications will not work until Firebase is configured');
  }
  
  // Set up FCM background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Initialize Hive for offline caching
  await Hive.initFlutter();
  
  // Register Hive type adapters for ride tracking
  Hive.registerAdapter(CachedRideAdapter());
  Hive.registerAdapter(CachedPassengerAdapter());
  Hive.registerAdapter(IntermediateStopDataAdapter());
  
  // Initialize saved location service
  final savedLocationService = SavedLocationService();
  await savedLocationService.init();
  print('✅ Saved Location Service initialized');
  
  // Initialize notification service
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    print('✅ Notification Service initialized');
  } catch (e) {
    print('⚠️ Notification Service initialization failed: $e');
  }
  
  runApp(
    const ProviderScope(
      child: VanYatraApp(),
    ),
  );
}

class VanYatraApp extends StatelessWidget {
  const VanYatraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VanYatra',
      debugShowCheckedModeBanner: false,
      
      // Themes
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      
      // Initial route - skip splash and login for web, go directly to passenger home
      home: kIsWeb ? const PassengerHomeScreen() : const SplashScreen(),
      
      // Routes (simplified routing - can be replaced with GoRouter later)
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/login-onboarding': (context) => const LoginWithOnboardingScreen(),
        '/registration': (context) => const RegistrationScreen(),
        '/driver-registration': (context) => const DriverRegistrationScreen(),
        '/driver/verification-pending': (context) => const VerificationPendingScreen(),
        '/user-type': (context) => const UserTypeSelectionScreen(),
        '/passenger/home': (context) => const PassengerHomeScreen(),
        '/passenger/history': (context) => const RideHistoryScreen(),
        '/driver/dashboard': (context) => const DriverDashboardScreen(),
        '/driver/earnings': (context) => const DriverEarningsScreen(),
      },
      
      // Route generator for routes with arguments
      onGenerateRoute: (settings) {
        // Phone number entry for Google Sign-In users
        if (settings.name == '/phone-entry') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null) {
            return MaterialPageRoute(
              builder: (_) => PhoneNumberEntryScreen(
                email: args['email'] as String,
                name: args['name'] as String,
                photoUrl: args['photoUrl'] as String?,
                googleIdToken: args['googleIdToken'] as String,
              ),
            );
          }
        }
        
        // OTP verification with phone number and Firebase verificationId
        if (settings.name == '/otp') {
          // Support both String (backward compatibility) and Map (new Firebase flow)
          final args = settings.arguments;
          if (args is Map<String, dynamic>) {
            return MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                phoneNumber: args['phoneNumber'] as String,
                verificationId: args['verificationId'] as String?,
              ),
            );
          } else if (args is String) {
            // Backward compatibility for old flow
            return MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(phoneNumber: args),
            );
          }
        }
        
        // Driver tracking screen with ride data
        if (settings.name == '/driver-tracking') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null) {
            return MaterialPageRoute(
              builder: (_) => DriverTrackingScreen(
                rideId: args['rideId'] as String,
                rideDetails: args['ride'],
              ),
            );
          }
        }
        
        // Passenger tracking screen with ride data
        if (settings.name == '/passenger-tracking') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null) {
            return MaterialPageRoute(
              builder: (_) => PassengerTrackingScreen(
                bookingId: args['bookingId'] as String? ?? '',
                bookingDetails: args['ride'],
              ),
            );
          }
        }
        
        return null;
      },
    );
  }
}
