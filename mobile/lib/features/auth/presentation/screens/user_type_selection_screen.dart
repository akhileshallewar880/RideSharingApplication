import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/app/constants/app_constants.dart';
import 'package:allapalli_ride/shared/widgets/buttons.dart';

/// User type selection screen (Passenger or Driver)
class UserTypeSelectionScreen extends StatefulWidget {
  const UserTypeSelectionScreen({super.key});
  
  @override
  State<UserTypeSelectionScreen> createState() => _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen> {
  String? _selectedType;
  
  void _handleContinue() {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select user type'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    // Navigate based on user type
    if (_selectedType == AppConstants.userTypePassenger) {
      Navigator.of(context).pushReplacementNamed('/passenger/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/driver/dashboard');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xxxl),
              
              // Header
              Text(
                'Choose Your Role',
                style: TextStyles.displayMedium,
              ).animate()
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: -0.2, end: 0),
              
              const SizedBox(height: AppSpacing.sm),
              
              Text(
                'Select how you want to use Allapalli Ride',
                style: TextStyles.bodyLarge.copyWith(
                  color: isDark 
                      ? AppColors.darkTextSecondary 
                      : AppColors.lightTextSecondary,
                ),
              ).animate()
                  .fadeIn(delay: 200.ms)
                  .slideX(begin: -0.2, end: 0, delay: 200.ms),
              
              const SizedBox(height: AppSpacing.massive),
              
              // User type cards
              Expanded(
                child: Column(
                  children: [
                    // Passenger option
                    _UserTypeCard(
                      icon: Icons.person_outline,
                      title: 'Passenger',
                      description: 'Book rides and travel comfortably',
                      isSelected: _selectedType == AppConstants.userTypePassenger,
                      onTap: () {
                        setState(() {
                          _selectedType = AppConstants.userTypePassenger;
                        });
                      },
                    ).animate()
                        .fadeIn(delay: 300.ms)
                        .slideY(begin: 0.2, end: 0, delay: 300.ms),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Driver option
                    _UserTypeCard(
                      icon: Icons.drive_eta_outlined,
                      title: 'Driver',
                      description: 'Earn money by providing rides',
                      isSelected: _selectedType == AppConstants.userTypeDriver,
                      onTap: () {
                        setState(() {
                          _selectedType = AppConstants.userTypeDriver;
                        });
                      },
                    ).animate()
                        .fadeIn(delay: 400.ms)
                        .slideY(begin: 0.2, end: 0, delay: 400.ms),
                  ],
                ),
              ),
              
              // Continue button
              PrimaryButton(
                text: 'Continue',
                onPressed: _handleContinue,
                icon: Icons.arrow_forward,
              ).animate()
                  .fadeIn(delay: 500.ms)
                  .slideY(begin: 0.2, end: 0, delay: 500.ms),
              
              const SizedBox(height: AppSpacing.md),
              
              // Info text
              Center(
                child: Text(
                  'You can switch between roles anytime',
                  style: TextStyles.caption.copyWith(
                    color: isDark 
                        ? AppColors.darkTextTertiary 
                        : AppColors.lightTextTertiary,
                  ),
                ),
              ).animate()
                  .fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _UserTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusLG,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryYellow.withOpacity(0.1)
              : (isDark ? AppColors.darkCardBg : AppColors.lightCardBg),
          borderRadius: AppSpacing.borderRadiusLG,
          border: Border.all(
            color: isSelected
                ? AppColors.primaryYellow
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryYellow
                    : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                borderRadius: AppSpacing.borderRadiusMD,
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSelected
                    ? AppColors.primaryDark
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
            ),
            
            const SizedBox(width: AppSpacing.lg),
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyles.headingMedium.copyWith(
                      color: isSelected ? AppColors.primaryYellow : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: TextStyles.bodySmall.copyWith(
                      color: isDark 
                          ? AppColors.darkTextSecondary 
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Check icon
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryYellow,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
