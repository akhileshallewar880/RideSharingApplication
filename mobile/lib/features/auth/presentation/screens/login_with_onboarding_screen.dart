import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/shared/widgets/buttons.dart';
import 'package:allapalli_ride/shared/widgets/input_fields.dart';
import 'package:allapalli_ride/core/providers/auth_provider.dart';
import 'package:allapalli_ride/core/services/firebase_phone_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Merged login and onboarding screen with carousel banners and Google Sign-In
class LoginWithOnboardingScreen extends ConsumerStatefulWidget {
  const LoginWithOnboardingScreen({super.key});
  
  @override
  ConsumerState<LoginWithOnboardingScreen> createState() => _LoginWithOnboardingScreenState();
}

class _LoginWithOnboardingScreenState extends ConsumerState<LoginWithOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final CarouselSliderController _carouselController = CarouselSliderController();
  final FocusNode _phoneFocusNode = FocusNode();
  late final FirebasePhoneService _firebaseAuth;
  
  int _currentBannerIndex = 0;
  bool _isBottomSheetExpanded = false;
  bool _isOtpLoading = false;
  bool _hasShownPhonePicker = false; // Track if picker was already shown
  
  // Premium banners with aesthetic design
  final List<BannerInfo> _fallbackBanners = [
    BannerInfo(
      title: '🎉 First Ride Free!',
      subtitle: 'Welcome to VanYatra',
      highlights: [
        'Get your 1st ride absolutely FREE',
        'No hidden charges',
        'Start your journey today',
      ],
      backgroundColor: Color(0xFFFFF4E6), // Warm peach
      illustrationColor: Color(0xFFFF6B35),
      gradientColors: [Color(0xFFFFF4E6), Color(0xFFFFE5CC)],
    ),
    BannerInfo(
      title: '⏰ On-Time, Every Time',
      subtitle: 'Daily Rides Made Easy',
      highlights: [
        'Punctual pickups guaranteed',
        'Reliable daily commute',
        'Never miss your schedule',
      ],
      backgroundColor: Color(0xFFE8F5E9), // Fresh mint green
      illustrationColor: Color(0xFF4CAF50),
      gradientColors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
    ),
    BannerInfo(
      title: '🚗 Comfortable & Safe',
      subtitle: 'Ride with Peace of Mind',
      highlights: [
        'Premium comfortable vehicles',
        'Live tracking every moment',
        'Verified & trusted drivers',
      ],
      backgroundColor: Color(0xFFE3F2FD), // Cool sky blue
      illustrationColor: Color(0xFF2196F3),
      gradientColors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _firebaseAuth = FirebasePhoneService();
    _phoneFocusNode.addListener(() {
      if (_phoneFocusNode.hasFocus && !_isBottomSheetExpanded) {
        setState(() {
          _isBottomSheetExpanded = true;
        });
      }
    });
  }
  
  void _closeBottomSheet() {
    setState(() {
      _isBottomSheetExpanded = false;
    });
    FocusScope.of(context).unfocus();
  }
  
  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }
  
  /// Show phone number hint picker using Google Play Services Phone Number Hint API
  /// This API doesn't require any runtime permissions - it's privacy-friendly!
  Future<void> _showPhoneNumberPicker() async {
    try {
      print('🔍 Showing Phone Number Hint picker (no permissions needed)...');
      final hint = await SmsAutoFill().hint;
      print('📱 Phone hint received: $hint');
      
      if (hint != null && mounted) {
        // Extract only the phone number digits (remove +91 or any country code)
        String phoneNumber = hint.replaceAll(RegExp(r'[^\d]'), '');
        print('📱 Extracted digits: $phoneNumber');
        
        // If it starts with 91 (country code), remove it
        if (phoneNumber.length > 10 && phoneNumber.startsWith('91')) {
          phoneNumber = phoneNumber.substring(2);
          print('📱 Removed country code: $phoneNumber');
        }
        
        // Take only the last 10 digits
        if (phoneNumber.length > 10) {
          phoneNumber = phoneNumber.substring(phoneNumber.length - 10);
          print('📱 Final 10 digits: $phoneNumber');
        }
        
        setState(() {
          _phoneController.text = phoneNumber;
        });
        
        // Auto-trigger OTP sending after phone selection
        print('🚀 Auto-triggering OTP after phone selection...');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted && _formKey.currentState!.validate()) {
          _handleOtpLogin();
        }
      } else {
        print('⚠️ No phone hint available or widget not mounted');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No saved phone numbers found. Please enter manually.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Silent fail - common on tablets/devices without SIM
      // Phone hint API may not be available on all devices
      print('ℹ️ Phone hint not available (no SIM/not supported): $e');
      // User can still manually enter phone number - no need to show error
    }
  }
  
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    if (value.length != 10) {
      return 'Please enter a valid 10-digit mobile number';
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
      return 'Please enter a valid Indian mobile number';
    }
    return null;
  }
  
  Future<void> _handleOtpLogin() async {
    if (_formKey.currentState!.validate()) {
      final phoneNumber = _phoneController.text.trim();
      final fullPhoneNumber = '+91$phoneNumber';
      
      setState(() {
        _isOtpLoading = true;
      });
      
      // Send OTP using Firebase
      await _firebaseAuth.sendOtp(
        phoneNumber: fullPhoneNumber,
        onAutoVerificationCompleted: (credential) async {
          // Instant verification - sign in immediately
          if (mounted) {
            try {
              final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
              final idToken = await userCredential.user?.getIdToken();
              
              if (idToken != null) {
                setState(() {
                  _isOtpLoading = false;
                });
                
                // Verify with backend
                await ref.read(authNotifierProvider.notifier)
                    .verifyFirebasePhoneAuth(idToken, phoneNumber);
                
                // Navigate based on user type
                if (mounted) {
                  final authState = ref.read(authNotifierProvider);
                  if (authState.isAuthenticated && authState.userType != null) {
                    if (authState.userType == 'passenger') {
                      Navigator.of(context).pushReplacementNamed('/passenger/home');
                    } else if (authState.userType == 'driver') {
                      Navigator.of(context).pushReplacementNamed('/driver/dashboard');
                    }
                  }
                }
              }
            } catch (e) {
              print('❌ Auto-verification error: $e');
            }
          }
        },
        onCodeSent: (verificationId, resendToken) {
          if (mounted) {
            setState(() {
              _isOtpLoading = false;
            });
            
            // Navigate to OTP verification screen immediately
            Navigator.of(context).pushNamed(
              '/otp',
              arguments: {
                'phoneNumber': phoneNumber,
                'verificationId': verificationId,
              },
            );
          }
        },
        onVerificationFailed: (error) {
          if (mounted) {
            setState(() {
              _isOtpLoading = false;
            });
            
            // Check if rate limit error
            final isRateLimited = error.code == 'too-many-requests' ||
                                 error.message?.toLowerCase().contains('too many') == true ||
                                 error.message?.toLowerCase().contains('unusual activity') == true ||
                                 error.message?.toLowerCase().contains('blocked') == true;
            
            final errorMessage = isRateLimited
                ? '⚠️ Too many requests. Use test number +919511803142 with code 123456, or wait 24 hours.'
                : error.message ?? 'Failed to send OTP';
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: AppColors.error,
                duration: Duration(seconds: isRateLimited ? 6 : 4),
                action: isRateLimited
                    ? SnackBarAction(
                        label: 'Got it',
                        textColor: Colors.white,
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        },
                      )
                    : null,
              ),
            );
          }
        },
      );
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SizedBox(
        height: screenHeight,
        width: double.infinity,
        child: Stack(
          children: [
            // Carousel Banner Background (60% of screen)
            SizedBox(
              height: screenHeight * 0.6,
              width: double.infinity,
            child: Stack(
              children: [
                // Banner carousel - using static fallback banners only
                CarouselSlider.builder(
                  carouselController: _carouselController,
                  itemCount: _fallbackBanners.length,
                  itemBuilder: (context, index, realIndex) {
                    return _buildFallbackBannerCard(_fallbackBanners[index]);
                  },
                  options: CarouselOptions(
                    height: screenHeight * 0.6,
                    viewportFraction: 1.0,
                    autoPlay: !_isBottomSheetExpanded,
                    autoPlayInterval: const Duration(seconds: 4),
                    autoPlayAnimationDuration: const Duration(milliseconds: 800),
                    autoPlayCurve: Curves.fastOutSlowIn,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentBannerIndex = index;
                      });
                    },
                  ),
                ),
                
                // Page indicator and Skip button at the top
                Positioned(
                  top: MediaQuery.of(context).padding.top + AppSpacing.sm,
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentBannerIndex + 1}/${_fallbackBanners.length}',
                          style: TextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      
                      // Skip button
                      TextButton(
                        onPressed: () {
                          // Navigate to passenger home screen
                          Navigator.of(context).pushReplacementNamed('/passenger/home');
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Skip',
                          style: TextStyles.buttonMedium.copyWith(
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Sheet with Login Form
          _buildLoginBottomSheet(context, isDark, authState, screenHeight),
        ],
        ),
      ),
    );
  }
  
  Widget _buildLoginBottomSheet(BuildContext context, bool isDark, dynamic authState, double screenHeight) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    // Calculate height to prevent going off screen
    double bottomSheetHeight;
    if (_isBottomSheetExpanded) {
      // Full screen when expanded (minus status bar)
      bottomSheetHeight = screenHeight - statusBarHeight;
    } else {
      // Initial state: 42% to overlap and hide banner bottom edges
      bottomSheetHeight = screenHeight * 0.42;
    }
    
    return AnimatedPositioned(
      duration: Duration.zero,
      curve: Curves.linear,
      left: 0,
      right: 0,
      bottom: 0,
      top: screenHeight - bottomSheetHeight,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          // Swipe down to collapse
          if (details.primaryDelta! > 10 && _isBottomSheetExpanded) {
            _closeBottomSheet();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: _isBottomSheetExpanded 
                ? BorderRadius.zero 
                : const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
            boxShadow: _isBottomSheetExpanded
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
          ),
          child: Column(
            children: [
              // Handle and close button
              Container(
                padding: EdgeInsets.only(
                  top: _isBottomSheetExpanded ? AppSpacing.xs : AppSpacing.sm,
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Drag handle (only show when not expanded)
                    if (!_isBottomSheetExpanded)
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? AppColors.darkTextTertiary 
                                  : AppColors.lightTextTertiary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    
                    // Close button at top-right (only show when expanded)
                    if (_isBottomSheetExpanded)
                      Expanded(child: const SizedBox()),
                    
                    if (_isBottomSheetExpanded)
                      IconButton(
                        onPressed: _closeBottomSheet,
                        icon: Icon(
                          Icons.close,
                          color: isDark 
                              ? AppColors.darkTextPrimary 
                              : AppColors.lightTextPrimary,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
              
              // Scrollable form content
              Flexible(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    _isBottomSheetExpanded ? AppSpacing.md : AppSpacing.sm,
                    AppSpacing.xl,
                    AppSpacing.lg,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        Text(
                          'Log in or create a new account',
                          style: TextStyles.headingMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ).animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.2, end: 0),
                        
                        const SizedBox(height: AppSpacing.md),
                        
                        // Phone input field
                        PhoneField(
                          label: 'Mobile number',
                          controller: _phoneController,
                          validator: _validatePhone,
                          focusNode: _phoneFocusNode,
                          onTap: () {
                            // Only show picker on first tap when field is empty
                            if (!_hasShownPhonePicker && _phoneController.text.isEmpty) {
                              print('🎯 First tap - showing phone picker');
                              _hasShownPhonePicker = true;
                              _showPhoneNumberPicker();
                            }
                          },
                        ).animate()
                            .fadeIn(delay: 200.ms, duration: 400.ms)
                            .slideY(begin: 0.2, end: 0, delay: 200.ms),
                        
                        const SizedBox(height: AppSpacing.md),
                        
                        // Get OTP button
                        PrimaryButton(
                          text: 'Get OTP',
                          onPressed: _isOtpLoading ? null : _handleOtpLogin,
                          isLoading: _isOtpLoading,
                          textColor: Colors.black,
                        ).animate()
                            .fadeIn(delay: 300.ms, duration: 400.ms)
                            .slideY(begin: 0.2, end: 0, delay: 300.ms),
                        
                        const SizedBox(height: AppSpacing.md),
                        
                        // Terms text
                        Text(
                          'By continuing, you agree to our Terms of Service and Privacy Policy',
                          style: TextStyles.caption.copyWith(
                            color: isDark 
                                ? AppColors.darkTextTertiary 
                                : AppColors.lightTextTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ).animate()
                            .fadeIn(delay: 400.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Build premium aesthetic banner card
  Widget _buildFallbackBannerCard(BannerInfo banner) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: banner.gradientColors != null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: banner.gradientColors!,
              )
            : null,
        color: banner.gradientColors == null ? banner.backgroundColor : null,
      ),
      child: Stack(
        children: [
          // Decorative background circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: banner.illustrationColor.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: banner.illustrationColor.withOpacity(0.08),
              ),
            ),
          ),
          
          // Main content - Aligned to center-bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xxl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with emoji
                Text(
                  banner.title,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: banner.illustrationColor,
                    letterSpacing: -0.5,
                    height: 1.1,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 4,
                        color: Colors.black.withOpacity(0.05),
                      ),
                    ],
                  ),
                ),
                
                if (banner.subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    banner.subtitle!,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: banner.illustrationColor.withOpacity(0.7),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
                
                const SizedBox(height: AppSpacing.lg),
                
                // Highlights with premium styling - only show 2
                ...banner.highlights.take(2).toList().asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        // Premium checkmark icon
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: banner.illustrationColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: banner.illustrationColor,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen.withOpacity(0.85),
                              letterSpacing: 0.2,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: (entry.key * 100).ms)
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: -0.2, end: 0);
                }).toList(),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }
  
  // Build premium illustration shapes
  Widget _buildPremiumIllustration(Color color, int index) {
    final illustrations = [
      // Car illustration
      Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 50,
            height: 35,
            decoration: BoxDecoration(
              color: color.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.directions_car_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 45,
            height: 6,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
      // Location pin
      Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 45,
            height: 55,
            decoration: BoxDecoration(
              color: color.withOpacity(0.8),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
                bottomLeft: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.location_on,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
      // Clock/Timer
      Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.8),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.access_time_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 6,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
      // Star/Rating
      Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.star_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 38,
            height: 6,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    ];
    
    return illustrations[index % illustrations.length]
        .animate(delay: (index * 150).ms)
        .fadeIn(duration: 600.ms)
        .scale(begin: Offset(0.5, 0.5), end: Offset(1, 1))
        .then(delay: 200.ms)
        .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3));
  }
  
  Widget _buildIllustrationShape(Color color, int index) {
    // Create diverse silhouette representations
    final shapes = [
      // Person 1 - Circle head + rectangle body
      Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
      // Person 2 - Larger
      Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: color.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 45,
            height: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
      // Person 3 - Medium
      Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.35),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 42,
            height: 75,
            decoration: BoxDecoration(
              color: color.withOpacity(0.55),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
      // Person 4 - Smaller
      Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 38,
            height: 65,
            decoration: BoxDecoration(
              color: color.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    ];
    
    return shapes[index % shapes.length];
  }
}

/// Banner information model with premium design
class BannerInfo {
  final String title;
  final String? subtitle;
  final List<String> highlights;
  final Color backgroundColor;
  final Color illustrationColor;
  final List<Color>? gradientColors;
  
  BannerInfo({
    required this.title,
    this.subtitle,
    required this.highlights,
    required this.backgroundColor,
    required this.illustrationColor,
    this.gradientColors,
  });
}
