import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'app/config/flavor_config.dart';
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
import 'features/auth/presentation/screens/verification_pending_screen.dart';
import 'features/auth/presentation/screens/user_type_selection_screen.dart';
import 'features/auth/presentation/screens/phone_number_entry_screen.dart';
import 'features/passenger/presentation/screens/passenger_home_screen.dart';
import 'features/passenger/presentation/screens/ride_history_screen.dart';
import 'features/passenger/presentation/screens/passenger_tracking_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.initialize(AppFlavor.passenger);

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('⚠️ Firebase init failed: $e');
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await Hive.initFlutter();
  Hive.registerAdapter(CachedRideAdapter());
  Hive.registerAdapter(CachedPassengerAdapter());
  Hive.registerAdapter(IntermediateStopDataAdapter());

  final savedLocationService = SavedLocationService();
  await savedLocationService.init();

  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
  } catch (e) {
    debugPrint('⚠️ Notification Service init failed: $e');
  }

  runApp(const ProviderScope(child: VanYatraPassengerApp()));
}

class VanYatraPassengerApp extends StatelessWidget {
  const VanYatraPassengerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: FlavorConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/login': (_) => const LoginScreen(),
        '/login-onboarding': (_) => const LoginWithOnboardingScreen(),
        '/registration': (_) => const RegistrationScreen(),
        '/driver-registration': (_) => const VerificationPendingScreen(), // redirect drivers away
        '/driver/verification-pending': (_) => const VerificationPendingScreen(),
        '/user-type': (_) => const UserTypeSelectionScreen(),
        '/passenger/home': (_) => const PassengerHomeScreen(),
        '/passenger/history': (_) => const RideHistoryScreen(),
      },
      onGenerateRoute: (settings) {
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

        if (settings.name == '/otp') {
          final args = settings.arguments;
          if (args is Map<String, dynamic>) {
            return MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                phoneNumber: args['phoneNumber'] as String,
                verificationId: args['verificationId'] as String?,
              ),
            );
          } else if (args is String) {
            return MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(phoneNumber: args),
            );
          }
        }

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
