import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/shared/widgets/buttons.dart';
import 'package:allapalli_ride/core/providers/auth_provider.dart';
import 'package:allapalli_ride/core/providers/user_profile_provider.dart';
import 'package:allapalli_ride/core/services/firebase_auth_service.dart';

/// OTP verification screen with Firebase Auth and Auto OTP fetch
class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String? verificationId;
  
  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.verificationId,
  });
  
  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> with CodeAutoFill {
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();
  final _firebaseAuth = FirebaseAuthService();
  
  bool _canResend = false;
  int _resendTimer = 30;
  int _resendAttempts = 0;
  int _baseResendDelay = 30; // Base delay in seconds
  bool _hasSimSupport = false; // Track if device supports SIM/SMS
  bool _isVerifying = false; // Prevent duplicate verification attempts
  
  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _setupAutoOtpFetch();
    
    // Auto-focus on first input box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpFocusNode.requestFocus();
    });
  }
  
  /// Setup SMS auto-fetch for Android (only on devices with SIM)
  Future<void> _setupAutoOtpFetch() async {
    try {
      // Try to get app signature to check if SMS is supported
      final signature = await SmsAutoFill().getAppSignature;
      
      if (signature.isNotEmpty) {
        // Device supports SMS, enable auto-fill
        _hasSimSupport = true;
        listenForCode();
        print('📱 SMS Auto-fetch initialized - Signature: $signature');
        if (mounted) setState(() {}); // Update UI if needed
      } else {
        print('ℹ️ SMS not supported (no SIM card) - Manual OTP entry only');
        _hasSimSupport = false;
      }
    } catch (e) {
      // Silent fail for no-SIM devices (common on tablets/WiFi-only devices)
      print('ℹ️ SMS Auto-fetch not available: $e');
      _hasSimSupport = false;
      // Don't show error to user - manual OTP entry will work fine
    }
  }
  
  @override
  void codeUpdated() {
    // This is called when SMS is received and code is extracted
    // Only process if device has SIM support
    if (_hasSimSupport && code != null && code!.length >= 6) {
      print('✅ Auto-fetched OTP: $code');
      
      // Take first 6 digits as Firebase expects 6-digit OTP
      final otp = code!.substring(0, 6);
      _otpController.text = otp;
      
      // Auto-verify after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _otpController.text.length == 6) {
          _handleVerify();
        }
      });
    }
  }
  
  @override
  void dispose() {
    if (_hasSimSupport) {
      cancel(); // Cancel SMS listener only if it was initialized
    }
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }
  
  void _startResendTimer() {
    // Exponential backoff: 30s, 60s, 120s, 240s (max 4 minutes)
    final delay = _baseResendDelay * (1 << _resendAttempts.clamp(0, 3));
    
    if (!mounted) return;
    
    setState(() {
      _canResend = false;
      _resendTimer = delay;
    });
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      
      setState(() {
        _resendTimer--;
      });
      
      if (_resendTimer == 0) {
        if (!mounted) return false;
        setState(() {
          _canResend = true;
        });
        return false;
      }
      return true;
    });
  }
  
  Future<void> _handleVerify() async {
    // Prevent duplicate verification attempts
    if (_isVerifying) {
      print('⚠️ Verification already in progress, ignoring duplicate call');
      return;
    }
    
    // Firebase expects 6-digit OTP
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit OTP'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    if (_otpController.text.isEmpty || !RegExp(r'^\d{6}$').hasMatch(_otpController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    if (widget.verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification session expired. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    // Set verifying flag
    _isVerifying = true;
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      // First, verify OTP with Firebase
      // Don't show any Firebase errors - only show final result
      final userCredential = await _firebaseAuth.verifyOtp(
        verificationId: widget.verificationId!,
        smsCode: _otpController.text,
        onError: (error) {
          // Silently log error - don't show snackbar
          print('🔴 Firebase OTP verification error (will retry with backend): $error');
        },
      );
      
      if (userCredential == null) {
        // Firebase verification failed - this is a REAL error
        if (mounted) {
          Navigator.pop(context); // Close loading
          _otpController.clear();
          _isVerifying = false;
          
          // Show error - OTP is genuinely invalid
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid OTP. Please check and try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      
      // Get Firebase ID token
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) {
        if (mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to get authentication token'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      
      print('✅ Firebase OTP verified, phone: ${userCredential.user?.phoneNumber}');
      print('🔐 Sending Firebase token to backend...');
      
      // Now authenticate with backend using Firebase ID token
      final result = await ref.read(authNotifierProvider.notifier)
          .verifyFirebasePhoneAuth(idToken, userCredential.user!.phoneNumber!.substring(3)); // Remove +91
      
      if (!mounted) return;
      
      // Close loading dialog
      Navigator.pop(context);
      
      print('🔐 OTP Verification Result: $result');
      print('🔐 Result is null: ${result == null}');
      
      // Check for success FIRST before checking error messages
      if (result != null) {
        // Success! Clear any stale error messages in state IMMEDIATELY
        print('✅ OTP verification successful!');
        print('🔐 Result is NOT null - isNewUser: ${result.isNewUser}');
        
        // CRITICAL: Clear error message in state to prevent it from showing
        // Do this synchronously before any navigation or UI updates
        ref.read(authNotifierProvider.notifier).clearError();
        
        // Get current auth state AFTER clearing errors
        final authState = ref.read(authNotifierProvider);
        
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
              
              if (!mounted) return;
              
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
        // Only show error if result is null (authentication failed)
        print('🔐 ERROR: Result is NULL - Authentication failed');
        
        // Get auth state to check for error messages
        final authState = ref.read(authNotifierProvider);
        
        if (authState.errorMessage != null) {
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
        } else {
          // No error message but result is null
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification failed. Please try again.'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      // Handle any unexpected errors
      print('🔴 Error during verification: $e');
      _isVerifying = false;
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  Future<void> _handleResend() async {
    if (!_canResend) return;
    
    // Check if too many attempts
    if (_resendAttempts >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.block, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Too many attempts. Please try again after 24 hours or use test phone numbers.'),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 6),
        ),
      );
      return;
    }
    
    final phoneNumber = '+91${widget.phoneNumber}';
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    // Resend OTP using Firebase
    await _firebaseAuth.sendOtp(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId) {
        if (mounted) {
          Navigator.pop(context); // Close loading
          
          // Increment resend attempts
          _resendAttempts++;
          
          // Start timer with exponential backoff
          _startResendTimer();
          _otpController.clear();
          
          final nextDelay = _baseResendDelay * (1 << _resendAttempts.clamp(0, 3));
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'OTP sent! Attempt ${_resendAttempts}/5. Next resend in ${nextDelay}s.',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      onError: (error) {
        if (mounted) {
          Navigator.pop(context); // Close loading
          
          // Check if rate limit error
          final isRateLimited = error.toLowerCase().contains('too many') ||
                               error.toLowerCase().contains('unusual activity') ||
                               error.toLowerCase().contains('blocked');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isRateLimited
                          ? '⚠️ Rate limit reached. Use test number +919511803142 with code 123456, or wait 24 hours.'
                          : error,
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 6),
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
              
              // OTP Input (6 digits for Firebase)
              LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate responsive field size
                  // Leave space for padding between fields
                  final availableWidth = constraints.maxWidth;
                  final fieldWidth = ((availableWidth - 50) / 6).clamp(40.0, 56.0);
                  final fieldHeight = fieldWidth;
                  
                  return PinCodeTextField(
                    appContext: context,
                    length: 6,
                    controller: _otpController,
                    focusNode: _otpFocusNode,
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    autoFocus: true,
                    enablePinAutofill: _hasSimSupport, // Only enable on devices with SIM
                    useExternalAutoFillGroup: false,
                    autoDismissKeyboard: false,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: AppSpacing.borderRadiusMD,
                      fieldHeight: fieldHeight,
                      fieldWidth: fieldWidth,
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
                    textInputAction: TextInputAction.done,
                    autovalidateMode: AutovalidateMode.disabled,
                    onCompleted: (code) {
                      _handleVerify();
                    },
                    onChanged: (value) {
                      // Check if OTP is complete
                      if (value.length == 6) {
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted && _otpController.text.length == 6) {
                            _handleVerify();
                          }
                        });
                      }
                    },
                  );
                },
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
