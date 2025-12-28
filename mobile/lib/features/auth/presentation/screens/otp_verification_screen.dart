import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/shared/widgets/buttons.dart';
import 'package:allapalli_ride/core/providers/auth_provider.dart';
import 'package:allapalli_ride/core/providers/user_profile_provider.dart';

/// OTP verification screen
class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  
  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });
  
  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();
  bool _canResend = false;
  int _resendTimer = 30;
  
  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // Auto-focus on first input box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpFocusNode.requestFocus();
    });
  }
  
  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }
  
  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendTimer = 30;
    });
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      
      setState(() {
        _resendTimer--;
      });
      
      if (_resendTimer == 0) {
        setState(() {
          _canResend = true;
        });
        return false;
      }
      return true;
    });
  }
  
  Future<void> _handleVerify() async {
    // API accepts 4-digit OTP as per documentation
    if (_otpController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 4-digit OTP'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    if (_otpController.text.isEmpty || !RegExp(r'^\d{4}$').hasMatch(_otpController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 4-digit OTP'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    // Verify OTP using auth provider
    final result = await ref.read(authNotifierProvider.notifier)
        .verifyOtp(widget.phoneNumber, _otpController.text);
    
    print('🔐 OTP Verification Result: $result');
    print('🔐 Result is null: ${result == null}');
    
    if (mounted) {
      final authState = ref.read(authNotifierProvider);
      
      print('🔐 Auth State - isAuthenticated: ${authState.isAuthenticated}');
      print('🔐 Auth State - userType: ${authState.userType}');
      print('🔐 Auth State - errorMessage: ${authState.errorMessage}');
      
      if (authState.errorMessage != null) {
        // Clear OTP input on error (especially for wrong OTP)
        _otpController.clear();
        
        // Show error message from API response with more context
        final errorMsg = authState.errorMessage!;
        final isInvalidOtp = errorMsg.toLowerCase().contains('invalid') || 
                            errorMsg.toLowerCase().contains('wrong') || 
                            errorMsg.toLowerCase().contains('expired');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isInvalidOtp ? Icons.error_outline : Icons.warning_amber_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isInvalidOtp 
                        ? 'Invalid or expired OTP. Please try again.' 
                        : errorMsg,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
        return;
      }
      
      if (result != null) {
        print('🔐 Result is NOT null - isNewUser: ${result.isNewUser}');
        
        if (result.isNewUser) {
          // New user - navigate to registration with temp token stored
          // Temp token is already stored in auth service
          print('🔐 New user detected - navigating to registration');
          Navigator.of(context).pushReplacementNamed(
            '/registration',
            arguments: {
              'phoneNumber': widget.phoneNumber,
              'tempToken': result.tempToken,
            },
          );
        } else {
          // Existing user - use the userType from the fresh API response, not from stored state
          final userType = result.user?.userType ?? authState.userType;
          print('🔐 Existing user - userType from API: ${result.user?.userType}');
          print('🔐 Existing user - userType from state: ${authState.userType}');
          print('🔐 Using userType: $userType');
          print('🔐 Auth state details:');
          print('   - isAuthenticated: ${authState.isAuthenticated}');
          print('   - userId: ${authState.userId}');
          
          if (userType == 'passenger') {
            print('🔐 Passenger - navigating to home');
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/passenger/home',
              (route) => false,
            );
          } else if (userType == 'driver') {
            // For drivers, check verification status before navigating
            print('🔐 Driver detected - checking verification status');
            try {
              // Load profile to get verification status
              await ref.read(userProfileNotifierProvider.notifier).loadProfile();
              
              if (mounted) {
                final profileState = ref.read(userProfileNotifierProvider);
                final verificationStatus = profileState.profile?.verificationStatus;
                
                print('🔐 Driver verification status: $verificationStatus');
                print('🔐 Profile loaded: ${profileState.profile != null}');
                
                if (verificationStatus == 'approved') {
                  // Driver approved - go to dashboard
                  print('🔐 Driver approved - navigating to dashboard');
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/driver/dashboard',
                    (route) => false,
                  );
                } else {
                  // Driver pending or rejected - go to verification pending screen
                  print('🔐 Driver not approved ($verificationStatus) - navigating to verification pending');
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/driver/verification-pending',
                    (route) => false,
                  );
                }
              }
            } catch (e) {
              // On error, default to verification pending screen to be safe
              print('🔐 Error loading driver profile: $e');
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/driver/verification-pending',
                  (route) => false,
                );
              }
            }
          } else {
            // User type not set, navigate to user type selection
            print('🔐 User type not set - navigating to user type selection');
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/user-type',
              (route) => false,
            );
          }
        }
      } else {
        print('🔐 ERROR: Result is NULL but no error message!');
        // If result is null and no error message, something went wrong
        if (authState.errorMessage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification failed. Please try again.'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }
  
  Future<void> _handleResend() async {
    if (!_canResend) return;
    
    // Resend OTP using auth provider
    await ref.read(authNotifierProvider.notifier).sendOtp(widget.phoneNumber);
    
    if (mounted) {
      final authState = ref.read(authNotifierProvider);
      
      if (authState.errorMessage == null) {
        _startResendTimer();
        _otpController.clear(); // Clear previous OTP input
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('OTP sent successfully to ${widget.phoneNumber}'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.errorMessage!),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              
              // Header
              Text(
                'Verify OTP',
                style: TextStyles.displayMedium,
              ).animate()
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: -0.2, end: 0),
              
              const SizedBox(height: AppSpacing.sm),
              
              Text(
                authState.isExistingUser == true 
                    ? 'Welcome back! Enter OTP to login' 
                    : 'New here? Enter OTP to register',
                style: TextStyles.bodyMedium.copyWith(
                  color: isDark 
                      ? AppColors.darkTextSecondary 
                      : AppColors.lightTextSecondary,
                ),
              ).animate()
                  .fadeIn(delay: 200.ms)
                  .slideX(begin: -0.2, end: 0, delay: 200.ms),
              
              const SizedBox(height: AppSpacing.xs),
              
              Row(
                children: [
                  Text(
                    '+91 ${widget.phoneNumber}',
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.edit,
                    size: AppSpacing.iconSM,
                    color: AppColors.primaryYellow,
                  ),
                ],
              ).animate()
                  .fadeIn(delay: 300.ms)
                  .slideX(begin: -0.2, end: 0, delay: 300.ms),
              
              const SizedBox(height: AppSpacing.massive),
              
              // OTP Input (4 digits as per API spec)
              PinCodeTextField(
                appContext: context,
                length: 4,
                controller: _otpController,
                focusNode: _otpFocusNode,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                autoFocus: true,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: AppSpacing.borderRadiusMD,
                  fieldHeight: 56,
                  fieldWidth: 56,
                  activeFillColor: isDark 
                      ? AppColors.darkSurface 
                      : AppColors.lightSurface,
                  inactiveFillColor: isDark 
                      ? AppColors.darkSurface 
                      : AppColors.lightSurface,
                  selectedFillColor: isDark 
                      ? AppColors.darkSurface 
                      : AppColors.lightSurface,
                  activeColor: AppColors.primaryYellow,
                  inactiveColor: isDark 
                      ? AppColors.darkBorder 
                      : AppColors.lightBorder,
                  selectedColor: AppColors.primaryYellow,
                ),
                cursorColor: AppColors.primaryYellow,
                animationDuration: const Duration(milliseconds: 300),
                enableActiveFill: true,
                onCompleted: (code) {
                  _handleVerify();
                },
                onChanged: (value) {},
              ).animate()
                  .fadeIn(delay: 400.ms)
                  .slideY(begin: 0.2, end: 0, delay: 400.ms),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Resend OTP
              Center(
                child: _canResend
                    ? TextButton(
                        onPressed: _handleResend,
                        child: const Text('Resend OTP'),
                      )
                    : Text(
                        'Resend OTP in $_resendTimer seconds',
                        style: TextStyles.bodySmall.copyWith(
                          color: isDark 
                              ? AppColors.darkTextSecondary 
                              : AppColors.lightTextSecondary,
                        ),
                      ),
              ).animate()
                  .fadeIn(delay: 500.ms),
              
              const SizedBox(height: AppSpacing.xxxl),
              
              // Verify button
              PrimaryButton(
                text: 'Verify & Continue',
                onPressed: authState.isLoading ? null : _handleVerify,
                isLoading: authState.isLoading,
                icon: Icons.check_circle_outline,
              ).animate()
                  .fadeIn(delay: 600.ms)
                  .slideY(begin: 0.2, end: 0, delay: 600.ms),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Help text
              Center(
                child: Text(
                  'Didn\'t receive the code?\nCheck your SMS or try resending',
                  style: TextStyles.caption.copyWith(
                    color: isDark 
                        ? AppColors.darkTextTertiary 
                        : AppColors.lightTextTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate()
                  .fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }
}
