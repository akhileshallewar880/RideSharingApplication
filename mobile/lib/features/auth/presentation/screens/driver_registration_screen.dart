import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/shared/widgets/buttons.dart';
import 'package:allapalli_ride/shared/widgets/input_fields.dart';
import 'package:allapalli_ride/shared/widgets/document_upload_card.dart';
import 'package:allapalli_ride/features/passenger/presentation/widgets/location_search_field.dart';
import 'package:allapalli_ride/features/driver/presentation/widgets/vehicle_model_selector_widget.dart';
import 'package:allapalli_ride/core/providers/auth_provider.dart';
import 'package:allapalli_ride/core/providers/location_provider.dart';
import 'package:allapalli_ride/core/models/auth_models.dart';
import 'package:allapalli_ride/features/passenger/domain/models/location_suggestion.dart';
import 'package:allapalli_ride/core/models/vehicle_models.dart';
import 'package:allapalli_ride/core/models/city_model.dart';
import 'package:allapalli_ride/core/services/auth_service.dart';

/// Driver registration screen with comprehensive vehicle and document details
class DriverRegistrationScreen extends ConsumerStatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  ConsumerState<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends ConsumerState<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _cityController = TextEditingController();
  
  DateTime? _dateOfBirth;
  LocationSuggestion? _selectedCity;
  VehicleModel? _selectedVehicleModel;
  List<City> _cities = [];
  // bool _isLoadingCities = false; // Currently unused
  File? _licenseFile;
  File? _rcFile;
  String? _phoneNumber;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _phoneNumber = args['phoneNumber'] as String?;
    }
  }

  Future<void> _loadCities() async {
    // setState(() {
    //   _isLoadingCities = true;
    // });

    try {
      final authService = AuthService();
      final response = await authService.getCities();
      
      if (response.isSuccess && response.data != null) {
        setState(() {
          _cities = (response.data as List)
              .map((json) => City.fromJson(json))
              .toList();
          // _isLoadingCities = false;
        });
      } else {
        // setState(() {
        //   _isLoadingCities = false;
        // });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      // setState(() {
      //   _isLoadingCities = false;
      // });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading cities: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Match selected location with database city to get correct City ID
  String? _getMatchingCityId(String cityName) {
    if (_cities.isEmpty) return null;
    
    // Try exact match first
    City? match = _cities.cast<City?>().firstWhere(
      (city) => city != null && city.name.toLowerCase() == cityName.toLowerCase(),
      orElse: () => null,
    );
    
    // If no exact match, try partial match
    if (match == null) {
      match = _cities.cast<City?>().firstWhere(
        (city) => city != null && (
          cityName.toLowerCase().contains(city.name.toLowerCase()) ||
          city.name.toLowerCase().contains(cityName.toLowerCase())
        ),
        orElse: () => null,
      );
    }
    
    return match?.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _vehicleNumberController.dispose();
    _emergencyContactController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your full name';
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

  void _showVehicleModelSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VehicleModelSelector(
        selectedModel: _selectedVehicleModel,
        onModelSelected: (model) {
          // Filter to only allow car, suv, van, bus (exclude auto and bike)
          if (model.type != 'auto' && model.type != 'bike') {
            setState(() {
              _selectedVehicleModel = model;
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a car, SUV, van, or bus'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
        },
        showBusCategory: true,
      ),
    );
  }

  Future<void> _handleDriverRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate required fields
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your date of birth'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your current city'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedVehicleModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your vehicle type'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_licenseFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your driving license'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_rcFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your vehicle RC'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_phoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not found. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Format emergency contact with +91 prefix if provided
    String? emergencyContact;
    if (_emergencyContactController.text.trim().isNotEmpty) {
      emergencyContact = '+91${_emergencyContactController.text.trim()}';
    }

    final dateOfBirthStr = _dateOfBirth!.toIso8601String().split('T').first;

    // Match selected city with database to get correct City ID
    final matchedCityId = _getMatchingCityId(_selectedCity!.name);
    
    final request = DriverRegistrationRequest(
      name: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      dateOfBirth: dateOfBirthStr,
      phoneNumber: _phoneNumber!,
      currentCityId: matchedCityId ?? _selectedCity!.id,
      currentCityName: _selectedCity!.name,
      vehicleModelId: _selectedVehicleModel!.id,
      vehicleNumber: _vehicleNumberController.text.trim().replaceAll(' ', ''),
      emergencyContact: emergencyContact,
    );

    // Complete driver registration
    await ref.read(authNotifierProvider.notifier).completeDriverRegistration(
      request,
      _phoneNumber!,
      _licenseFile!,
      _rcFile!,
    );

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
        // Navigate to verification pending screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/driver/verification-pending',
          (route) => false,
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
        title: const Text('Driver Registration'),
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
                  'Join as a Driver',
                  style: TextStyles.displayMedium,
                ).animate()
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: -0.2, end: 0),

                const SizedBox(height: AppSpacing.sm),

                Text(
                  'Complete your profile with vehicle details',
                  style: TextStyles.bodyLarge.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ).animate()
                    .fadeIn(delay: 200.ms)
                    .slideX(begin: -0.2, end: 0, delay: 200.ms),

                const SizedBox(height: AppSpacing.xxxl),

                // Basic Information Section
                _buildSectionHeader('Basic Information', Icons.person_outline),
                const SizedBox(height: AppSpacing.lg),

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

                InkWell(
                  onTap: _selectDateOfBirth,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date of Birth *',
                      hintText: 'Select your date of birth',
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(
                        borderRadius: AppSpacing.borderRadiusMD,
                      ),
                    ),
                    child: Text(
                      _dateOfBirth != null
                          ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                          : 'DD/MM/YYYY',
                      style: TextStyles.bodyMedium.copyWith(
                        color: _dateOfBirth == null
                            ? (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary)
                            : null,
                      ),
                    ),
                  ),
                ).animate()
                    .fadeIn(delay: 500.ms)
                    .slideY(begin: 0.2, end: 0, delay: 500.ms),

                const SizedBox(height: AppSpacing.xxxl),

                // Location Section
                _buildSectionHeader('Location', Icons.location_on_outlined),
                const SizedBox(height: AppSpacing.lg),

                LocationSearchField(
                  controller: _cityController,
                  hint: 'Select your current city',
                  locationService: ref.watch(locationServiceProvider),
                  prefixIcon: Icons.location_city,
                  onLocationSelected: (location) {
                    setState(() {
                      _selectedCity = location;
                    });
                  },
                ).animate()
                    .fadeIn(delay: 600.ms)
                    .slideY(begin: 0.2, end: 0, delay: 600.ms),

                const SizedBox(height: AppSpacing.xxxl),

                // Vehicle Details Section
                _buildSectionHeader('Vehicle Details', Icons.directions_car_outlined),
                const SizedBox(height: AppSpacing.lg),

                // Vehicle Model Selector
                InkWell(
                  onTap: _showVehicleModelSelector,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Vehicle Type *',
                      hintText: 'Select your vehicle',
                      prefixIcon: const Icon(Icons.directions_car_outlined),
                      border: OutlineInputBorder(
                        borderRadius: AppSpacing.borderRadiusMD,
                      ),
                    ),
                    child: Text(
                      _selectedVehicleModel != null
                          ? _selectedVehicleModel!.displayName
                          : 'e.g., Car, SUV, Van, Bus',
                      style: TextStyles.bodyMedium.copyWith(
                        color: _selectedVehicleModel == null
                            ? (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary)
                            : null,
                      ),
                    ),
                  ),
                ).animate()
                    .fadeIn(delay: 700.ms)
                    .slideY(begin: 0.2, end: 0, delay: 700.ms),

                const SizedBox(height: AppSpacing.lg),

                VehicleNumberField(
                  controller: _vehicleNumberController,
                ).animate()
                    .fadeIn(delay: 800.ms)
                    .slideY(begin: 0.2, end: 0, delay: 800.ms),

                const SizedBox(height: AppSpacing.xxxl),

                // Document Upload Section
                _buildSectionHeader('Documents', Icons.upload_file_outlined),
                const SizedBox(height: AppSpacing.lg),

                DocumentUploadCard(
                  title: 'Driving License',
                  isRequired: true,
                  onFileSelected: (file) {
                    setState(() {
                      _licenseFile = file;
                    });
                  },
                ).animate()
                    .fadeIn(delay: 900.ms)
                    .slideY(begin: 0.2, end: 0, delay: 900.ms),

                const SizedBox(height: AppSpacing.lg),

                DocumentUploadCard(
                  title: 'Vehicle RC',
                  isRequired: true,
                  onFileSelected: (file) {
                    setState(() {
                      _rcFile = file;
                    });
                  },
                ).animate()
                    .fadeIn(delay: 1000.ms)
                    .slideY(begin: 0.2, end: 0, delay: 1000.ms),

                const SizedBox(height: AppSpacing.xxxl),

                // Emergency Contact Section
                _buildSectionHeader('Emergency Contact', Icons.phone_outlined),
                const SizedBox(height: AppSpacing.lg),

                PhoneField(
                  controller: _emergencyContactController,
                  label: 'Emergency Contact (Optional)',
                  validator: _validateEmergencyContact,
                ).animate()
                    .fadeIn(delay: 1100.ms)
                    .slideY(begin: 0.2, end: 0, delay: 1100.ms),

                const SizedBox(height: AppSpacing.xxxl),

                // Submit button
                PrimaryButton(
                  text: 'Complete Registration',
                  onPressed: authState.isLoading ? null : _handleDriverRegistration,
                  isLoading: authState.isLoading,
                  icon: Icons.check_circle_outline,
                ).animate()
                    .fadeIn(delay: 1200.ms)
                    .slideY(begin: 0.2, end: 0, delay: 1200.ms),

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
                    .fadeIn(delay: 1300.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primaryYellow.withOpacity(0.1),
            borderRadius: AppSpacing.borderRadiusSM,
          ),
          child: Icon(
            icon,
            color: AppColors.primaryYellow,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          title,
          style: TextStyles.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}
