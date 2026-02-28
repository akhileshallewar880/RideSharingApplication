import 'package:flutter/material.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';

/// Cancellation confirmation screen with animation
class CancellationConfirmationScreen extends StatefulWidget {
  final String bookingNumber;
  final double? refundAmount;
  
  const CancellationConfirmationScreen({
    super.key,
    required this.bookingNumber,
    this.refundAmount,
  });
  
  @override
  State<CancellationConfirmationScreen> createState() => _CancellationConfirmationScreenState();
}

class _CancellationConfirmationScreenState extends State<CancellationConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    
    // Start animation
    _controller.forward();
    
    // Auto redirect after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _navigateToRideHistory();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _navigateToRideHistory() {
    // Pop all screens and go to ride history with initialTab set to 0 (Upcoming)
    Navigator.of(context).popUntil((route) => route.isFirst);
    // The home screen should have the ride history tab
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  AppSpacing.xl * 2,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated checkmark icon
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Builder(
                    builder: (context) {
                      final iconSize = (MediaQuery.of(context).size.width * 0.28).clamp(80.0, 120.0);
                      return Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cancel,
                          size: iconSize * 0.65,
                          color: AppColors.error,
                        ),
                      );
                    },
                  ),
                ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Success message
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'Ride Cancelled',
                      style: TextStyles.headingLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: AppSpacing.md),
                    
                    Text(
                      'Your ride has been cancelled successfully',
                      style: TextStyles.bodyLarge.copyWith(
                        color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Booking details
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            'Booking Number',
                            widget.bookingNumber,
                            isDark,
                          ),
                          if (widget.refundAmount != null && widget.refundAmount! > 0) ...[
                            const SizedBox(height: AppSpacing.sm),
                            const Divider(),
                            const SizedBox(height: AppSpacing.sm),
                            _buildInfoRow(
                              'Refund Amount',
                              '₹${widget.refundAmount!.toStringAsFixed(0)}',
                              isDark,
                              valueColor: AppColors.success,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Refund will be processed within 5-7 business days',
                              style: TextStyles.bodySmall.copyWith(
                                color: isDark ? Colors.white60 : AppColors.lightTextSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Redirecting message
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? Colors.white70 : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Redirecting to ride history...',
                          style: TextStyles.bodyMedium.copyWith(
                            color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Manual navigation button
                    TextButton(
                      onPressed: _navigateToRideHistory,
                      child: Text(
                        'Go to Ride History Now',
                        style: TextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
  
  Widget _buildInfoRow(String label, String value, bool isDark, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: TextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? (isDark ? Colors.white : AppColors.lightTextPrimary),
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
