import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/app/constants/app_constants.dart';
import 'package:allapalli_ride/shared/widgets/buttons.dart';
import 'package:allapalli_ride/core/providers/auth_provider.dart';
import 'package:allapalli_ride/core/providers/user_profile_provider.dart';

/// Verification pending screen shown after driver registration
class VerificationPendingScreen extends ConsumerStatefulWidget {
  const VerificationPendingScreen({super.key});

  @override
  ConsumerState<VerificationPendingScreen> createState() => _VerificationPendingScreenState();
}

class _VerificationPendingScreenState extends ConsumerState<VerificationPendingScreen> {
  bool _isCheckingStatus = false;
  bool _hasPendingUploads = false;

  @override
  void initState() {
    super.initState();
    _checkPendingUploads();
    // Load profile to get current verification status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProfileNotifierProvider.notifier).loadProfile();
    });
  }

  Future<void> _checkPendingUploads() async {
    final hasPending = await ref.read(authNotifierProvider.notifier).hasPendingDocumentUploads();
    setState(() {
      _hasPendingUploads = hasPending;
    });
  }

  Future<void> _retryDocumentUploads() async {
    setState(() {
      _isCheckingStatus = true;
    });

    await ref.read(authNotifierProvider.notifier).retryDocumentUploads();

    await _checkPendingUploads();

    setState(() {
      _isCheckingStatus = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_hasPendingUploads 
              ? 'Upload retry in progress. Please check back later.'
              : 'Documents uploaded successfully!'),
          backgroundColor: _hasPendingUploads ? AppColors.warning : AppColors.success,
        ),
      );
    }
  }

  Future<void> _checkVerificationStatus() async {
    setState(() {
      _isCheckingStatus = true;
    });

    try {
      // Load user profile to check verification status
      await ref.read(userProfileNotifierProvider.notifier).loadProfile();

      if (mounted) {
        final profileState = ref.read(userProfileNotifierProvider);
        
        setState(() {
          _isCheckingStatus = false;
        });

        if (profileState.profile != null) {
          final verificationStatus = profileState.profile!.verificationStatus;
          
          if (verificationStatus == 'approved') {
            // Navigate to driver dashboard
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/driver/dashboard',
                (route) => false,
              );
            }
          } else if (verificationStatus == 'rejected') {
            // Don't show snackbar if navigating away
            if (mounted && Navigator.canPop(context)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Your application has been rejected. Please contact support for more information.'),
                  backgroundColor: AppColors.error,
                  duration: Duration(seconds: 6),
                ),
              );
            }
          } else {
            // Don't show snackbar if navigating away
            if (mounted && Navigator.canPop(context)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Verification still pending. We will notify you once approved.'),
                  backgroundColor: AppColors.info,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        } else if (profileState.errorMessage != null) {
          if (mounted && Navigator.canPop(context)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(profileState.errorMessage!),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking status: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _makePhoneCall() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: AppConstants.supportPhoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to make phone call'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _openMaps() async {
    // Coordinates for Allapalli, Gadchiroli
    final Uri mapsUri = Uri.parse('https://maps.google.com/?q=Allapalli,Gadchiroli,Maharashtra');
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open maps'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'pending':
      default:
        return AppColors.warning;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'pending':
      default:
        return Icons.pending_outlined;
    }
  }

  String _getStatusTitle(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Verification Approved!';
      case 'rejected':
        return 'Application Rejected';
      case 'pending':
      default:
        return 'Verification Pending';
    }
  }

  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Congratulations! Your driver profile has been approved';
      case 'rejected':
        return 'Your application was not approved';
      case 'pending':
      default:
        return 'Your vehicle details are currently being verified';
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'You can now start accepting ride requests. Click the button below to go to your driver dashboard.';
      case 'rejected':
        return 'Your application has been rejected. Please contact support using the details below to understand the reason and reapply if possible.';
      case 'pending':
      default:
        return 'Please call on the below number or visit the address. We will call you in case of additional info within 24-48 hrs.\n\nThanks for showing interest!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileState = ref.watch(userProfileNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    
    // If user is a passenger, redirect to passenger home
    if (authState.userType == 'passenger') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/passenger/home');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final currentStatus = profileState.profile?.verificationStatus ?? 'pending';

    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.massive),

                // Pending icon animation with dynamic color based on status
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _getStatusColor(currentStatus).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(currentStatus),
                    size: 60,
                    color: _getStatusColor(currentStatus),
                  ),
                ).animate()
                    .scale(duration: 600.ms)
                    .fadeIn(),

                const SizedBox(height: AppSpacing.xxxl),

                // Title with dynamic text based on status
                Text(
                  _getStatusTitle(currentStatus),
                  style: TextStyles.displayMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ).animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: 0.2, end: 0, delay: 200.ms),

                const SizedBox(height: AppSpacing.lg),

                // Description
                Text(
                  _getStatusDescription(currentStatus),
                  style: TextStyles.bodyLarge.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ).animate()
                    .fadeIn(delay: 400.ms)
                    .slideY(begin: 0.2, end: 0, delay: 400.ms),

                const SizedBox(height: AppSpacing.xl),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(currentStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(currentStatus).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: _getStatusColor(currentStatus),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Status: ${currentStatus.toUpperCase()}',
                        style: TextStyles.labelMedium.copyWith(
                          color: _getStatusColor(currentStatus),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ).animate()
                    .fadeIn(delay: 500.ms)
                    .scale(delay: 500.ms),

                const SizedBox(height: AppSpacing.xl),

                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    borderRadius: AppSpacing.borderRadiusMD,
                    border: Border.all(
                      color: _getStatusColor(currentStatus).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getStatusMessage(currentStatus),
                    style: TextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate()
                    .fadeIn(delay: 600.ms)
                    .slideY(begin: 0.2, end: 0, delay: 600.ms),

                const SizedBox(height: AppSpacing.xxxl),

                // Contact number card
                _buildInfoCard(
                  icon: Icons.phone,
                  title: 'Contact Number',
                  subtitle: AppConstants.supportPhoneNumber,
                  actionText: 'Call Now',
                  onAction: _makePhoneCall,
                  color: AppColors.success,
                ).animate()
                    .fadeIn(delay: 800.ms)
                    .slideX(begin: -0.2, end: 0, delay: 800.ms),

                const SizedBox(height: AppSpacing.lg),

                // Office address card
                _buildInfoCard(
                  icon: Icons.location_on,
                  title: 'Office Address',
                  subtitle: AppConstants.officeAddress,
                  actionText: 'Get Directions',
                  onAction: _openMaps,
                  color: AppColors.primaryYellow,
                ).animate()
                    .fadeIn(delay: 1000.ms)
                    .slideX(begin: 0.2, end: 0, delay: 1000.ms),

                const SizedBox(height: AppSpacing.xxxl),

                // Retry document upload button if pending
                if (_hasPendingUploads) ...[
                  OutlinedButton(
                    onPressed: _isCheckingStatus ? null : _retryDocumentUploads,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh),
                        SizedBox(width: 8),
                        Text('Retry Document Upload'),
                      ],
                    ),
                  ).animate()
                      .fadeIn(delay: 1200.ms)
                      .slideY(begin: 0.2, end: 0, delay: 1200.ms),
                  
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Check status button
                PrimaryButton(
                  text: currentStatus == 'approved' ? 'Go to Dashboard' : 'Check Status',
                  onPressed: _isCheckingStatus ? null : _checkVerificationStatus,
                  isLoading: _isCheckingStatus,
                  icon: currentStatus == 'approved' ? Icons.dashboard : Icons.refresh,
                ).animate()
                    .fadeIn(delay: 1400.ms)
                    .slideY(begin: 0.2, end: 0, delay: 1400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppSpacing.borderRadiusMD,
        border: Border.all(
          color: color.withOpacity(0.3),
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
                  color: color.withOpacity(0.1),
                  borderRadius: AppSpacing.borderRadiusSM,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyles.labelMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon),
                  SizedBox(width: 8),
                  Text(actionText),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
