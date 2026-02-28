import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/shared/widgets/buttons.dart';
import 'package:allapalli_ride/shared/widgets/input_fields.dart';
import 'package:allapalli_ride/core/providers/auth_provider.dart';
import 'package:allapalli_ride/core/providers/user_profile_provider.dart';
import 'package:allapalli_ride/core/models/auth_models.dart';

/// Registration screen for new users
class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  final String _selectedUserType = 'passenger'; // Always passenger, drivers use separate flow
  String? _phoneNumber; // Store phone number from arguments

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get phone number from navigation arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _phoneNumber = args['phoneNumber'] as String?;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

  Future<void> _handleRegistration() async {
    if (_formKey.currentState!.validate()) {
      final request = CompleteRegistrationRequest(
        name: _nameController.text.trim(),
        userType: _selectedUserType,
        email: null,
        dateOfBirth: null,
        emergencyContact: null,
      );

      // Pass phone number to completeRegistration
      if (_phoneNumber == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number not found. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      await ref.read(authNotifierProvider.notifier).completeRegistration(request, _phoneNumber!);

      if (mounted) {
        final authState = ref.read(authNotifierProvider);

        if (authState.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authState.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        if (authState.isAuthenticated) {
          // Auth state now has fresh userType from API response
          // Navigate based on user type
          if (authState.userType == 'driver') {
            // Load profile to get verification status for drivers
            await ref.read(userProfileNotifierProvider.notifier).loadProfile();
            Navigator.of(context).pushNamedAndRemoveUntil('/driver/verification-pending', (route) => false);
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil('/passenger/home', (route) => false);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Decorative top section with gradient and logo — responsive height
            Container(
              height: (screenHeight * 0.35).clamp(240.0, 360.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryDark,  // Deep Forest Green
                    AppColors.primaryGreen, // Medium Green
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  // Content
                  SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // VanYatra Logo with animation
                          Image.asset(
                            'assets/images/vanyatra_new_logo_home.png',
                            height: 100,
                          ).animate()
                              .scale(duration: 600.ms, curve: Curves.elasticOut)
                              .then()
                              .shimmer(duration: 1000.ms),

                          const SizedBox(height: AppSpacing.lg),

                          // Welcome text
                          Text(
                            'Welcome Aboard!',
                            style: TextStyles.displaySmall.copyWith(
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ).animate()
                              .fadeIn(delay: 300.ms)
                              .slideY(begin: 0.3, end: 0, delay: 300.ms),

                          const SizedBox(height: AppSpacing.sm),

                          Text(
                            'Just one step away from your journey',
                            style: TextStyles.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ).animate()
                              .fadeIn(delay: 500.ms)
                              .slideY(begin: 0.3, end: 0, delay: 500.ms),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Form section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),

                    // Title
                    Text(
                      'What should we call you?',
                      style: TextStyles.headingMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.primaryDark,
                      ),
                    ).animate()
                        .fadeIn(delay: 700.ms)
                        .slideX(begin: -0.2, end: 0, delay: 700.ms),

                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      'Enter your full name to continue',
                      style: TextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ).animate()
                        .fadeIn(delay: 800.ms)
                        .slideX(begin: -0.2, end: 0, delay: 800.ms),

                    const SizedBox(height: AppSpacing.xxxl),

                    // Name field with enhanced styling
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : Colors.grey[50],
                        borderRadius: AppSpacing.borderRadiusLG,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreen.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CustomTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        validator: _validateName,
                        prefixIcon: Icons.person,
                      ),
                    ).animate()
                        .fadeIn(delay: 900.ms)
                        .slideY(begin: 0.3, end: 0, delay: 900.ms),

                    const SizedBox(height: AppSpacing.xxxl),

                    // Info card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.08),
                        borderRadius: AppSpacing.borderRadiusMD,
                        border: Border.all(
                          color: AppColors.primaryGreen.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.primaryGreen,
                            size: AppSpacing.iconMD,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'You can update your profile details later from settings',
                              style: TextStyles.bodySmall.copyWith(
                                color: isDark ? Colors.white : AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate()
                        .fadeIn(delay: 1000.ms)
                        .scale(begin: const Offset(0.95, 0.95), delay: 1000.ms),

                    const SizedBox(height: AppSpacing.xxxl),

                    // Register button with green shadow
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: AppSpacing.borderRadiusFull,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreen.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: PrimaryButton(
                        text: 'Continue',
                        onPressed: authState.isLoading ? null : _handleRegistration,
                        isLoading: authState.isLoading,
                        icon: Icons.arrow_forward,
                      ),
                    ).animate()
                        .fadeIn(delay: 1100.ms)
                        .slideY(begin: 0.3, end: 0, delay: 1100.ms),

                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
