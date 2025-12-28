import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
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
        print('⚠️ Unknown user type, redirecting to onboarding');
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    } else {
      print('🔴 No valid session found, redirecting to onboarding');
      // User not logged in, go to onboarding
      Navigator.of(context).pushReplacementNamed('/onboarding');
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : AppColors.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // VanYatra Text with gradient effect
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFF2D5F3F), // Deep forest green
                    Color(0xFF4A8F63), // Lighter green
                    Color(0xFF2D5F3F), // Deep forest green
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  'VanYatra',
                  style: TextStyle(
                    color: Colors.white, // Will be masked by gradient
                    fontWeight: FontWeight.w900,
                    fontSize: 72,
                    letterSpacing: -1.2,
                    height: 0.95,
                    decoration: TextDecoration.none,
                    shadows: [
                      Shadow(
                        color: const Color(0xFF2D5F3F).withOpacity(0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ).animate(controller: _controller)
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                    duration: 1000.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 800.ms),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Tagline with subtle color
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D5F3F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Your Journey, Our Commitment',
                  style: TextStyles.bodyLarge.copyWith(
                    color: const Color(0xFF2D5F3F),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ).animate(controller: _controller)
                  .fadeIn(delay: 600.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0, delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
