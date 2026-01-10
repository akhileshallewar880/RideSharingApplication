import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/themes/app_colors.dart';
import '../../../../app/themes/app_spacing.dart';
import '../../../../app/themes/text_styles.dart';
import '../../../../core/providers/user_profile_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/models/user_profile_models.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  
  // User data controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  DateTime? _dateOfBirth;
  
  @override
  void initState() {
    super.initState();
    // Load profile data
    Future.microtask(() {
      ref.read(userProfileNotifierProvider.notifier).loadProfile();
    });
  }
  
  void _updateControllers(UserProfile profile) {
    _nameController.text = profile.name;
    _emailController.text = profile.email ?? '';
    _emergencyContactController.text = profile.emergencyContact ?? '';
    if (profile.dateOfBirth != null) {
      _dateOfBirth = DateTime.tryParse(profile.dateOfBirth!);
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }
  
  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }
  
  Future<void> _saveProfile() async {
    final request = UpdateProfileRequest(
      name: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      emergencyContact: _emergencyContactController.text.trim().isEmpty 
          ? null 
          : _emergencyContactController.text.trim(),
      dateOfBirth: _dateOfBirth?.toIso8601String(),
    );
    
    final success = await ref.read(userProfileNotifierProvider.notifier).updateProfile(request);
    
    if (mounted) {
      setState(() {
        _isEditing = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final profileState = ref.read(userProfileNotifierProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileState.errorMessage ?? 'Failed to update profile'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 6570)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileState = ref.watch(userProfileNotifierProvider);
    
    // Set white status bar
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: isDark ? AppColors.darkSurface : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
    
    // Update controllers when profile is loaded
    if (profileState.profile != null && !_isEditing) {
      _updateControllers(profileState.profile!);
    }
    
    // Show loading
    if (profileState.isLoading && profileState.profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    final profile = profileState.profile;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEdit,
              tooltip: 'Edit Profile',
            )
          else
            TextButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Save'),
              onPressed: _saveProfile,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.success,
              ),
            ),
          if (_isEditing)
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  // Reset values from current profile
                  final profileState = ref.read(userProfileNotifierProvider);
                  if (profileState.profile != null) {
                    _updateControllers(profileState.profile!);
                  }
                });
              },
              child: const Text('Cancel'),
            ),
        ],
      ),
      body: Container(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryYellow,
                      AppColors.primaryYellow.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    // Profile Picture
                    Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 58,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: AppColors.primaryYellow,
                            ),
                          ),
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryYellow,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ).animate()
                        .fadeIn(duration: 400.ms)
                        .scale(begin: const Offset(0.8, 0.8)),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Name
                    Text(
                      _nameController.text,
                      style: TextStyles.headingLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate()
                        .fadeIn(delay: 200.ms)
                        .slideY(begin: 0.2, end: 0, delay: 200.ms),
                    
                    const SizedBox(height: AppSpacing.xs),
                    
                    // Phone (non-editable)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.phone,
                          color: Colors.white.withOpacity(0.9),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          profile?.phoneNumber ?? 'Not available',
                          style: TextStyles.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            'Verified',
                            style: TextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ).animate()
                        .fadeIn(delay: 300.ms)
                        .slideY(begin: 0.2, end: 0, delay: 300.ms),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Profile Details Form
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Information',
                      style: TextStyles.headingMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate()
                        .fadeIn(delay: 400.ms)
                        .slideX(begin: -0.2, end: 0, delay: 400.ms),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Name Field
                    _ProfileField(
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      controller: _nameController,
                      isEditing: _isEditing,
                      isDark: isDark,
                    ).animate()
                        .fadeIn(delay: 500.ms)
                        .slideX(begin: -0.2, end: 0, delay: 500.ms),
                    
                    const SizedBox(height: AppSpacing.md),
                    
                    // Email Field
                    _ProfileField(
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      controller: _emailController,
                      isEditing: _isEditing,
                      isDark: isDark,
                      keyboardType: TextInputType.emailAddress,
                    ).animate()
                        .fadeIn(delay: 600.ms)
                        .slideX(begin: -0.2, end: 0, delay: 600.ms),
                    
                    const SizedBox(height: AppSpacing.md),
                    
                    // Date of Birth Field
                    _buildDateField(
                      label: 'Date of Birth',
                      icon: Icons.cake_outlined,
                      date: _dateOfBirth,
                      isEditing: _isEditing,
                      isDark: isDark,
                      onTap: _isEditing ? _selectDate : null,
                    ).animate()
                        .fadeIn(delay: 700.ms)
                        .slideX(begin: -0.2, end: 0, delay: 700.ms),
                    
                    const SizedBox(height: AppSpacing.md),
                    
                    // Address field removed - not in current API spec
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    Text(
                      'Emergency Contact',
                      style: TextStyles.headingMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate()
                        .fadeIn(delay: 900.ms)
                        .slideX(begin: -0.2, end: 0, delay: 900.ms),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Emergency Contact Field
                    _ProfileField(
                      label: 'Emergency Contact Number',
                      icon: Icons.contact_phone_outlined,
                      controller: _emergencyContactController,
                      isEditing: _isEditing,
                      isDark: isDark,
                      keyboardType: TextInputType.phone,
                    ).animate()
                        .fadeIn(delay: 1000.ms)
                        .slideX(begin: -0.2, end: 0, delay: 1000.ms),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.directions_car,
                            label: 'Total Rides',
                            value: '24',
                            color: AppColors.primaryYellow,
                            isDark: isDark,
                          ).animate()
                              .fadeIn(delay: 1100.ms)
                              .scale(begin: const Offset(0.8, 0.8), delay: 1100.ms),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.star,
                            label: 'Rating',
                            value: '4.8',
                            color: AppColors.success,
                            isDark: isDark,
                          ).animate()
                              .fadeIn(delay: 1200.ms)
                              .scale(begin: const Offset(0.8, 0.8), delay: 1200.ms),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleLogout(context),
                        icon: const Icon(Icons.logout),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ).animate()
                        .fadeIn(delay: 1300.ms)
                        .slideY(begin: 0.2, end: 0, delay: 1300.ms),
                    
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Perform logout
      await ref.read(authNotifierProvider.notifier).logout();
      
      // Clear user profile state
      ref.read(userProfileNotifierProvider.notifier).clearProfile();
      
      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);
        
        // Navigate to login with onboarding screen and clear entire navigation stack
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login-onboarding',
          (route) => false,
        );
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? date,
    required bool isEditing,
    required bool isDark,
    required VoidCallback? onTap,
  }) {
    final dateText = date != null 
        ? '${date.day}/${date.month}/${date.year}' 
        : 'Not provided';
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
          borderRadius: AppSpacing.borderRadiusMD,
          border: Border.all(
            color: isEditing 
                ? AppColors.primaryYellow 
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isEditing ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: AppColors.primaryYellow,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: TextStyles.bodySmall.copyWith(
                    color: isDark 
                        ? AppColors.darkTextSecondary 
                        : AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (isEditing)
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.primaryYellow,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              dateText,
              style: TextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: date == null && !isEditing
                    ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Profile Field Widget
class _ProfileField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool isEditing;
  final bool isDark;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final IconData? suffixIcon;
  
  const _ProfileField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.isEditing,
    required this.isDark,
    this.keyboardType,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: AppSpacing.borderRadiusMD,
        border: Border.all(
          color: isEditing 
              ? AppColors.primaryYellow 
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isEditing ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: AppColors.primaryYellow,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: TextStyles.bodySmall.copyWith(
                  color: isDark 
                      ? AppColors.darkTextSecondary 
                      : AppColors.lightTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: controller,
            enabled: isEditing,
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              suffixIcon: suffixIcon != null
                  ? Icon(
                      suffixIcon,
                      size: 20,
                      color: AppColors.primaryYellow,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: AppSpacing.borderRadiusMD,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: TextStyles.headingLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyles.caption.copyWith(
              color: isDark 
                  ? AppColors.darkTextTertiary 
                  : AppColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
