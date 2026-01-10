import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/shared/widgets/buttons.dart';
import 'package:allapalli_ride/shared/widgets/input_fields.dart';
import 'package:allapalli_ride/core/services/firebase_auth_service.dart';

/// Login screen with phone number input
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _firebaseAuth = FirebaseAuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
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
          _handleLogin();
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
      print('❌ Error getting phone hint: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access phone numbers: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
  
  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final phoneNumber = _phoneController.text.trim();
      // Ensure phone number has country code
      final fullPhoneNumber = phoneNumber.startsWith('+') 
          ? phoneNumber 
          : '+91$phoneNumber';
      
      try {
        // Send OTP using Firebase
        await _firebaseAuth.sendOtp(
          phoneNumber: fullPhoneNumber,
          onCodeSent: (verificationId) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              // Navigate to OTP screen with verificationId
              Navigator.of(context).pushNamed(
                '/otp',
                arguments: {
                  'phoneNumber': phoneNumber,
                  'verificationId': verificationId,
                },
              );
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          onAutoVerify: (credential) async {
            // Auto verification successful (Android only)
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              // You can handle auto verification here
              // For now, just show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Phone verified automatically!'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
        );
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.massive),
                  
                  // Header
                  Text(
                    'Welcome Back!',
                    style: TextStyles.displayMedium,
                  ).animate()
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: -0.2, end: 0),
                  
                  const SizedBox(height: AppSpacing.sm),
                  
                  Text(
                    'Enter your phone number to continue',
                    style: TextStyles.bodyLarge.copyWith(
                      color: isDark 
                          ? AppColors.darkTextSecondary 
                          : AppColors.lightTextSecondary,
                    ),
                  ).animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideX(begin: -0.2, end: 0, delay: 200.ms),
                  
                  const SizedBox(height: AppSpacing.massive),
                  
                  // Logo
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_taxi,
                        size: 50,
                        color: AppColors.primaryYellow,
                      ),
                    ).animate()
                        .scale(delay: 300.ms, duration: 500.ms)
                        .fadeIn(delay: 300.ms),
                  ),
                  
                  const SizedBox(height: AppSpacing.massive),
                  
                  // Phone input with tap gesture to trigger phone hint
                  PhoneField(
                    label: 'Mobile Number',
                    controller: _phoneController,
                    validator: _validatePhone,
                    onTap: () {
                      print('🎯 PhoneField tapped!');
                      // Always show picker on tap for better UX
                      _showPhoneNumberPicker();
                    },
                  ).animate()
                      .fadeIn(delay: 400.ms)
                      .slideY(begin: 0.2, end: 0, delay: 400.ms),
                
                const SizedBox(height: AppSpacing.sm),
                
                // Info text
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'We will send you an OTP to verify your number',
                        style: TextStyles.caption.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ).animate()
                    .fadeIn(delay: 500.ms),
                
                const SizedBox(height: AppSpacing.xxxl),
                
                // Login button
                PrimaryButton(
                  text: 'Send OTP',
                  onPressed: _isLoading ? null : _handleLogin,
                  isLoading: _isLoading,
                  icon: Icons.arrow_forward,
                ).animate()
                    .fadeIn(delay: 600.ms)
                    .slideY(begin: 0.2, end: 0, delay: 600.ms),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Divider with text
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: isDark 
                            ? AppColors.darkBorder 
                            : AppColors.lightBorder,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text(
                        'OR',
                        style: TextStyles.caption.copyWith(
                          color: isDark 
                              ? AppColors.darkTextSecondary 
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: isDark 
                            ? AppColors.darkBorder 
                            : AppColors.lightBorder,
                      ),
                    ),
                  ],
                ).animate()
                    .fadeIn(delay: 700.ms),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Terms and conditions
                Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                  style: TextStyles.caption.copyWith(
                    color: isDark 
                        ? AppColors.darkTextTertiary 
                        : AppColors.lightTextTertiary,
                  ),
                  textAlign: TextAlign.center,
                ).animate()
                    .fadeIn(delay: 800.ms),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
