import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/shared/widgets/buttons.dart';
import 'package:allapalli_ride/shared/widgets/input_fields.dart';
import 'package:allapalli_ride/core/providers/auth_provider.dart';

/// Login screen with phone number input
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  
  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
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
      // API requires phone number and country code separately
      final phoneNumber = _phoneController.text.trim();
      
      // Send OTP using auth provider
      await ref.read(authNotifierProvider.notifier).sendOtp(phoneNumber);
      
      if (mounted) {
        final authState = ref.read(authNotifierProvider);
        
        if (authState.errorMessage == null) {
          // Success - navigate to OTP screen
          Navigator.of(context).pushNamed('/otp', arguments: phoneNumber);
        } else {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authState.errorMessage!),
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
    final authState = ref.watch(authNotifierProvider);
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
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
                
                // Phone input
                PhoneField(
                  label: 'Mobile Number',
                  controller: _phoneController,
                  validator: _validatePhone,
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
                  onPressed: authState.isLoading ? null : _handleLogin,
                  isLoading: authState.isLoading,
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
    );
  }
}
