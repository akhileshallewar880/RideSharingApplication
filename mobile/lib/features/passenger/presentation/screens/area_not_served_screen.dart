import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/app/constants/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen shown when user's location is not in served areas
class AreaNotServedScreen extends StatelessWidget {
  final String? currentLocation;
  
  const AreaNotServedScreen({
    super.key,
    this.currentLocation,
  });

  Future<void> _makePhoneCall() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: AppConstants.supportPhoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _openWhatsApp() async {
    final Uri whatsappUri = Uri.parse('https://wa.me/${AppConstants.supportPhoneNumber.replaceAll(RegExp(r'[^0-9]'), '')}');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with logo
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ShaderMask(
                  shaderCallback: (bounds) => AppColors.greenGradient.createShader(bounds),
                  child: Text(
                    'VanYatra',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 32,
                      letterSpacing: -1.0,
                      height: 0.95,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms),
              
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        // Icon
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: AppColors.greenGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_off_outlined,
                            size: 60,
                            color: Colors.white,
                          ),
                        ).animate().scale(delay: 200.ms, duration: 600.ms),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Title
                        Text(
                          'Service Not Available',
                          style: TextStyles.displaySmall.copyWith(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 400.ms),
                        
                        const SizedBox(height: AppSpacing.md),
                        
                        // Current Location (if available)
                        if (currentLocation != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentBeige.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: AppColors.primaryGreen,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Flexible(
                                  child: Text(
                                    currentLocation!,
                                    style: TextStyles.bodySmall.copyWith(
                                      color: AppColors.primaryGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 600.ms),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Message Card
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCardBg : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 48,
                                color: AppColors.primaryLight,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                'We\'re not serving in your area yet',
                                style: TextStyles.headingSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.primaryGreen,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'But don\'t worry! We\'re expanding our services. Reach out to us and we\'ll notify you when we start serving your area.',
                                style: TextStyles.bodyMedium.copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),
                        
                        const SizedBox(height: AppSpacing.xxl),
                        
                        // Contact Card
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            gradient: AppColors.cardGradient,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primaryLight.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(AppSpacing.sm),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.greenGradient,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.contact_phone,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Text(
                                    'Contact Us',
                                    style: TextStyles.headingSmall.copyWith(
                                      color: AppColors.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: AppSpacing.xl),
                              
                              // Office Address
                              _buildContactItem(
                                context,
                                isDark,
                                Icons.location_city,
                                'Office Address',
                                AppConstants.officeAddress,
                                onTap: () => _copyToClipboard(context, AppConstants.officeAddress, 'Address'),
                              ),
                              
                              const SizedBox(height: AppSpacing.lg),
                              
                              // Phone Number
                              _buildContactItem(
                                context,
                                isDark,
                                Icons.phone,
                                'Phone',
                                AppConstants.supportPhoneNumber,
                                onTap: _makePhoneCall,
                              ),
                              
                              const SizedBox(height: AppSpacing.lg),
                              
                              // WhatsApp
                              _buildContactItem(
                                context,
                                isDark,
                                Icons.chat_bubble,
                                'WhatsApp',
                                AppConstants.supportPhoneNumber,
                                onTap: _openWhatsApp,
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2, end: 0),
                        
                        const SizedBox(height: AppSpacing.xxl),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _makePhoneCall,
                                icon: const Icon(Icons.phone),
                                label: const Text('Call Us'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                  backgroundColor: AppColors.primaryGreen,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _openWhatsApp,
                                icon: const Icon(Icons.chat),
                                label: const Text('WhatsApp'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                  side: BorderSide(color: AppColors.primaryGreen, width: 2),
                                  foregroundColor: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 1200.ms),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Back button
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Go Back'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    bool isDark,
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkSurface : AppColors.accentBeige).withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.primaryGreen,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyles.labelSmall.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.primaryGreen.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
