import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/core/providers/auth_provider.dart';
import 'package:allapalli_ride/core/providers/user_profile_provider.dart';

/// Animated splash screen with logo transition
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    
    // Make status bar transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _controller.forward();
    
    // Check authentication and navigate
    _checkAuthAndNavigate();
  }
  
  Future<void> _checkAuthAndNavigate() async {
    // Wait for animation to complete
    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (!mounted) return;
    
    // Wait a bit more to ensure auth state is initialized
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted) return;
    
    // Get auth state from provider (this will be initialized by AuthNotifier constructor)
    final authState = ref.read(authNotifierProvider);
    
    print('🔍 Splash Screen - Auth State Check:');
    print('   Is Authenticated: ${authState.isAuthenticated}');
    print('   User Type: ${authState.userType}');
    print('   User ID: ${authState.userId}');
    
    if (authState.isAuthenticated && authState.userType != null) {
      print('🟢 Auto-login detected - checking user type: ${authState.userType}');
      
      if (!mounted) return;
      
      // User is logged in, navigate to appropriate home screen
      if (authState.userType == 'passenger') {
        Navigator.of(context).pushReplacementNamed('/passenger/home');
      } else if (authState.userType == 'driver') {
        // For drivers, check verification status before navigating
        print('🚗 Driver detected - checking verification status...');
        
        try {
          // Load profile to get verification status
          await ref.read(userProfileNotifierProvider.notifier).loadProfile();
          
          if (!mounted) return;
          
          final profileState = ref.read(userProfileNotifierProvider);
          final verificationStatus = profileState.profile?.verificationStatus;
          
          print('   Verification Status: $verificationStatus');
          
          if (verificationStatus == 'approved') {
            print('✅ Driver approved - navigating to dashboard');
            Navigator.of(context).pushReplacementNamed('/driver/dashboard');
          } else {
            // Pending or rejected - show verification pending screen
            print('⏳ Driver not approved (status: $verificationStatus) - showing verification screen');
            Navigator.of(context).pushReplacementNamed('/driver/verification-pending');
          }
        } catch (e) {
          print('❌ Error checking driver verification status: $e');
          // On error, default to verification pending screen to be safe
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/driver/verification-pending');
          }
        }
      } else {
        print('⚠️ Unknown user type, redirecting to login-onboarding');
        Navigator.of(context).pushReplacementNamed('/login-onboarding');
      }
    } else {
      print('🔴 No valid session found, redirecting to login-onboarding');
      // User not logged in, go to new merged login-onboarding screen
      Navigator.of(context).pushReplacementNamed('/login-onboarding');
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B5E20), // deepForestGreen
              Color(0xFF2E7D32),
              Color(0xFF388E3C),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // VanYatra Logo - Simple fade in
            Image.asset(
              'assets/images/vanyatra_new_logo.png',
              width: 250,
              height: 250,
              fit: BoxFit.contain,
            ).animate(controller: _controller)
                .fadeIn(duration: 800.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  duration: 800.ms,
                  curve: Curves.easeOut,
                ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Tagline - Simple fade in
            // Text(
            //   'Rural Rides, Reliable Rides',
            //   style: TextStyles.headingSmall.copyWith(
            //     color: const Color(0xFF2D5F3E),
            //     fontWeight: FontWeight.w600,
            //     letterSpacing: 0.5,
            //   ),
            //   textAlign: TextAlign.center,
            // ).animate(controller: _controller)
            //     .fadeIn(delay: 400.ms, duration: 600.ms),
          ],
        ),
      ),
        ),
      ),
    );
  }
}
