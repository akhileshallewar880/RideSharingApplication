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
  final _emailController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  
  final String _selectedUserType = 'passenger'; // Always passenger, drivers use separate flow
  DateTime? _dateOfBirth;
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
    _emailController.dispose();
    _emergencyContactController.dispose();
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

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validateEmergencyContact(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Emergency contact is optional
    }
    if (value.length != 10) {
      return 'Please enter a valid 10-digit mobile number';
    }
    return null;
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 6570)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryYellow,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  Future<void> _handleRegistration() async {
    if (_formKey.currentState!.validate()) {
      // Format emergency contact with +91 prefix if provided
      String? emergencyContact;
      if (_emergencyContactController.text.trim().isNotEmpty) {
        emergencyContact = '+91${_emergencyContactController.text.trim()}';
      }
      
      final dateOfBirthStr = _dateOfBirth != null
          ? _dateOfBirth!.toIso8601String().split('T').first
          : null;
      
      final request = CompleteRegistrationRequest(
        name: _nameController.text.trim(),
        userType: _selectedUserType,
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        dateOfBirth: dateOfBirthStr,
        emergencyContact: emergencyContact,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Registration'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome aboard!',
                  style: TextStyles.displayMedium,
                ).animate()
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: -0.2, end: 0),

                const SizedBox(height: AppSpacing.sm),

                Text(
                  'Complete your profile to get started',
                  style: TextStyles.bodyLarge.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ).animate()
                    .fadeIn(delay: 200.ms)
                    .slideX(begin: -0.2, end: 0, delay: 200.ms),

                const SizedBox(height: AppSpacing.xxxl),

                // Name field
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name *',
                  hint: 'Enter your full name',
                  validator: _validateName,
                  prefixIcon: Icons.person_outline,
                ).animate()
                    .fadeIn(delay: 300.ms)
                    .slideY(begin: 0.2, end: 0, delay: 300.ms),

                const SizedBox(height: AppSpacing.lg),

                // Email field
                CustomTextField(
                  controller: _emailController,
                  label: 'Email (Optional)',
                  hint: 'Enter your email',
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                ).animate()
                    .fadeIn(delay: 400.ms)
                    .slideY(begin: 0.2, end: 0, delay: 400.ms),

                const SizedBox(height: AppSpacing.lg),

                // Date of birth
                InkWell(
                  onTap: _selectDateOfBirth,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date of Birth (Optional)',
                      hintText: 'Select your date of birth',
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(
                        borderRadius: AppSpacing.borderRadiusMD,
                      ),
                    ),
                    child: Text(
                      _dateOfBirth != null
                          ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                          : '',
                      style: TextStyles.bodyMedium,
                    ),
                  ),
                ).animate()
                    .fadeIn(delay: 700.ms)
                    .slideY(begin: 0.2, end: 0, delay: 700.ms),

                const SizedBox(height: AppSpacing.lg),

                // Emergency contact
                PhoneField(
                  controller: _emergencyContactController,
                  label: 'Emergency Contact (Optional)',
                  validator: _validateEmergencyContact,
                ).animate()
                    .fadeIn(delay: 800.ms)
                    .slideY(begin: 0.2, end: 0, delay: 800.ms),

                const SizedBox(height: AppSpacing.xxxl),

                // Register button
                PrimaryButton(
                  text: 'Complete Registration',
                  onPressed: authState.isLoading ? null : _handleRegistration,
                  isLoading: authState.isLoading,
                  icon: Icons.check_circle_outline,
                ).animate()
                    .fadeIn(delay: 900.ms)
                    .slideY(begin: 0.2, end: 0, delay: 900.ms),

                const SizedBox(height: AppSpacing.lg),

                Center(
                  child: Text(
                    '* Required fields',
                    style: TextStyles.caption.copyWith(
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                  ),
                ).animate()
                    .fadeIn(delay: 1000.ms),

                const SizedBox(height: AppSpacing.xl),

                // Driver registration button
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        '/driver-registration',
                        arguments: {'phoneNumber': _phoneNumber},
                      );
                    },
                    icon: const Icon(Icons.local_taxi),
                    label: const Text('Register as a Driver'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryYellow,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                    ),
                  ),
                ).animate()
                    .fadeIn(delay: 1100.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
