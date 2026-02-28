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
import 'package:allapalli_ride/app/config/flavor_config.dart';
import 'package:allapalli_ride/core/services/firebase_auth_service.dart';
import 'package:allapalli_ride/shared/widgets/error_dialog.dart';

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
      showErrorPopup(
        context,
        title: 'Invalid OTP',
        message: 'Please enter the complete 6-digit OTP code.',
      );
      return;
    }

    if (_otpController.text.isEmpty || !RegExp(r'^\d{6}$').hasMatch(_otpController.text)) {
      showErrorPopup(
        context,
        title: 'Invalid OTP',
        message: 'Please enter a valid 6-digit OTP code containing only numbers.',
      );
      return;
    }

    if (widget.verificationId == null) {
      showErrorPopup(
        context,
        title: 'Session Expired',
        message: 'Your verification session has expired. Please go back and request a new OTP.',
      );
      return;
    }

    _isVerifying = true;
    // Track whether the loading dialog has already been dismissed to avoid
    // double-popping the OTP screen in the catch block.
    bool dialogClosed = false;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final userCredential = await _firebaseAuth.verifyOtp(
        verificationId: widget.verificationId!,
        smsCode: _otpController.text,
        onError: (error) {
          print('🔴 Firebase OTP verification error: $error');
        },
      );

      if (userCredential == null) {
        if (mounted) {
          Navigator.pop(context);
          dialogClosed = true;
          _otpController.clear();
          _isVerifying = false;
          showErrorPopup(
            context,
            title: 'Invalid OTP',
            message: 'The OTP you entered is incorrect. Please check and try again.',
          );
        }
        return;
      }

      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) {
        if (mounted) {
          Navigator.pop(context);
          dialogClosed = true;
          _isVerifying = false;
          showErrorPopup(
            context,
            title: 'Authentication Error',
            message: 'Failed to get authentication token. Please try again.',
          );
        }
        return;
      }

      print('✅ Firebase OTP verified, phone: ${userCredential.user?.phoneNumber}');
      print('🔐 Sending Firebase token to backend...');

      final result = await ref.read(authNotifierProvider.notifier)
          .verifyFirebasePhoneAuth(idToken, userCredential.user!.phoneNumber!.substring(3));

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);
      dialogClosed = true;

      print('🔐 OTP Verification Result: $result');

      if (result != null) {
        print('✅ OTP verification successful! isNewUser: ${result.isNewUser}');
        ref.read(authNotifierProvider.notifier).clearError();
        final authState = ref.read(authNotifierProvider);

        if (result.isNewUser) {
          print('🔐 New user detected');
          if (!mounted) return;

          if (FlavorConfig.isDriver) {
            // New phone in the driver app → start driver registration
            Navigator.of(context).pushReplacementNamed(
              '/driver-registration',
              arguments: {'phoneNumber': widget.phoneNumber},
            );
          } else {
            // New phone in the passenger app → passenger registration
            Navigator.of(context).pushReplacementNamed(
              '/registration',
              arguments: {
                'phoneNumber': widget.phoneNumber,
                'tempToken': result.tempToken,
              },
            );
          }
        } else {
          final userType = result.user?.userType ?? authState.userType;
          print('🔐 Existing user - userType: $userType');

          // Flavor guard: phone belongs to the other app's user type
          final expectedType = FlavorConfig.isDriver ? 'driver' : 'passenger';
          if (userType != null && userType != expectedType) {
            print('⚠️ User type "$userType" does not match ${FlavorConfig.appName}');
            await ref.read(authNotifierProvider.notifier).logout();
            if (!mounted) return;
            _showWrongAppDialog();
            return;
          }

          if (userType == 'passenger') {
            print('🔐 Passenger - navigating to home');
            if (!mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/passenger/home',
              (route) => false,
            );
          } else if (userType == 'driver') {
            print('🔐 Driver detected - checking verification status');
            try {
              await ref.read(userProfileNotifierProvider.notifier).loadProfile();
              if (!mounted) return;

              final profileState = ref.read(userProfileNotifierProvider);
              final verificationStatus = profileState.profile?.verificationStatus;
              print('🔐 Driver verification status: $verificationStatus');

              if (verificationStatus == 'approved') {
                print('🔐 Driver approved - navigating to dashboard');
                if (!mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/driver/dashboard',
                  (route) => false,
                );
              } else {
                print('🔐 Driver not approved ($verificationStatus) - verification pending');
                if (!mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/driver/verification-pending',
                  (route) => false,
                );
              }
            } catch (e) {
              print('🔐 Error loading driver profile: $e');
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/driver/verification-pending',
                  (route) => false,
                );
              }
            }
          } else {
            print('🔐 User type not set - navigating to user type selection');
            if (!mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/user-type',
              (route) => false,
            );
          }
        }
      } else {
        print('🔐 ERROR: Authentication failed (result is null)');
        _isVerifying = false;

        final authState = ref.read(authNotifierProvider);
        final errorMsg = authState.errorMessage;

        showErrorPopup(
          context,
          title: 'Verification Failed',
          message: errorMsg != null
              ? ErrorMessages.fromRawError(errorMsg)
              : 'Verification failed. Please try again.',
        );
      }
    } catch (e) {
      print('🔴 Error during verification: $e');
      _isVerifying = false;
      if (mounted) {
        if (!dialogClosed) {
          Navigator.pop(context);
        }
        showErrorPopup(
          context,
          title: 'Verification Error',
          message: ErrorMessages.fromRawError(e),
        );
      }
    }
  }

  /// Shows a non-dismissible blocking dialog when the phone number belongs to
  /// the wrong app type (e.g. a passenger phone in the driver app).
  void _showWrongAppDialog() {
    if (!mounted) return;
    _isVerifying = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text('Wrong App'),
          ],
        ),
        content: Text(
          FlavorConfig.isDriver
              ? 'This app is for drivers only.\n\nYour phone number is registered as a passenger. Please use the VanYatra app to book your rides.'
              : 'This app is for passengers only.\n\nYour phone number is registered as a driver. Please use the VanYatra Driver app.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close this dialog
              if (mounted) {
                // Return to the main login/onboarding screen — user cannot proceed
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login-onboarding',
                  (route) => false,
                );
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _handleResend() async {
    if (!_canResend) return;
    
    // Check if too many attempts
    if (_resendAttempts >= 5) {
      showErrorPopup(
        context,
        title: 'Too Many Attempts',
        message: 'You have exceeded the maximum number of resend attempts. Please try again after some time.',
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
          
          showErrorPopup(
            context,
            title: 'Resend Failed',
            message: ErrorMessages.fromRawError(error),
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
