import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/shared/widgets/buttons.dart';
import 'package:allapalli_ride/features/passenger/domain/models/vehicle_option.dart';
import 'package:allapalli_ride/core/models/passenger_ride_models.dart';

/// Ride details screen with QR code and booking information
class RideDetailsScreen extends StatelessWidget {
  final String pickupLocation;
  final String dropoffLocation;
  final VehicleOption vehicle;
  final int passengerCount;
  final DateTime travelDate;
  final String timeSlot;
  final BookingResponse? bookingResponse;
  
  const RideDetailsScreen({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.vehicle,
    required this.passengerCount,
    required this.travelDate,
    required this.timeSlot,
    this.bookingResponse,
  });
  
  String get _bookingId => bookingResponse?.bookingNumber ?? 'ALR${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  String get _otp => bookingResponse?.otp ?? '${DateTime.now().millisecondsSinceEpoch % 10000}'.padLeft(4, '0');
  String get _dateStr => '${travelDate.day}/${travelDate.month}/${travelDate.year}';
  int get _estimatedPrice => bookingResponse?.totalFare.toInt() ?? (vehicle.basePrice + (5 * vehicle.pricePerKm));
  
  void _showRescheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reschedule Ride'),
        content: const Text('Do you want to select a new date and time for this ride?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to home to reschedule
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select new date and time'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
            child: const Text('Reschedule'),
          ),
        ],
      ),
    );
  }
  
  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Ride'),
        content: const Text('Are you sure you want to cancel this ride? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep it'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to home
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ride cancelled successfully'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _copyOtp(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _otp));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OTP copied to clipboard'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.success,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Set white status bar
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: isDark ? AppColors.darkSurface : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Details'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Success message - Compact
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: AppSpacing.borderRadiusMD,
                border: Border.all(color: AppColors.success, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ride Confirmed!',
                          style: TextStyles.bodyLarge.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID: $_bookingId',
                          style: TextStyles.caption.copyWith(
                            color: isDark 
                                ? AppColors.darkTextSecondary 
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
            
            const SizedBox(height: AppSpacing.md),
            
            // QR Code & OTP Section - Compact
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                  borderRadius: AppSpacing.borderRadiusMD,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Show QR Code to Driver',
                      style: TextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppSpacing.borderRadiusMD,
                      ),
                      child: QrImageView(
                        data: 'ALR:$_bookingId:$_otp',
                        version: QrVersions.auto,
                        size: 140.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'OR',
                      style: TextStyles.caption.copyWith(
                        color: isDark 
                            ? AppColors.darkTextSecondary 
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    InkWell(
                      onTap: () => _copyOtp(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow.withOpacity(0.2),
                          borderRadius: AppSpacing.borderRadiusMD,
                          border: Border.all(color: AppColors.primaryYellow, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _otp,
                              style: TextStyles.headingLarge.copyWith(
                                color: AppColors.primaryYellow,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 6,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Icon(Icons.copy, color: AppColors.primaryYellow, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.95, 0.95), delay: 100.ms),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Ride Information - Compact
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                borderRadius: AppSpacing.borderRadiusMD,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _CompactInfoRow(
                          icon: Icons.location_on,
                          iconColor: AppColors.success,
                          label: pickupLocation,
                        ),
                      ),
                      Icon(Icons.arrow_forward, size: 16, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: _CompactInfoRow(
                          icon: Icons.location_on,
                          iconColor: AppColors.error,
                          label: dropoffLocation,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _CompactInfoRow(
                          icon: Icons.calendar_today,
                          iconColor: AppColors.info,
                          label: _dateStr,
                        ),
                      ),
                      Expanded(
                        child: _CompactInfoRow(
                          icon: Icons.access_time,
                          iconColor: AppColors.info,
                          label: timeSlot,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _CompactInfoRow(
                          icon: vehicle.icon,
                          iconColor: AppColors.primaryYellow,
                          label: '${vehicle.name} • $passengerCount pax',
                        ),
                      ),
                      Expanded(
                        child: _CompactInfoRow(
                          icon: Icons.payments,
                          iconColor: AppColors.success,
                          label: '₹$_estimatedPrice (Cash)',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0, delay: 200.ms),
            
            const SizedBox(height: AppSpacing.md),
            
            // Important Note - Compact
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow.withOpacity(0.1),
                borderRadius: AppSpacing.borderRadiusMD,
                border: Border.all(color: AppColors.primaryYellow, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primaryYellow, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Arrive 15 min early at bus stop • Show QR/OTP to driver',
                      style: TextStyles.caption.copyWith(
                        color: AppColors.primaryYellow,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),
            
            const SizedBox(height: AppSpacing.md),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: 'Reschedule',
                    onPressed: () => _showRescheduleDialog(context),
                    icon: Icons.edit_calendar,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showCancelDialog(context),
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.borderRadiusMD,
                      ),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0, delay: 400.ms),
          ],
          ),
        ),
      ),
    );
  }
}

// Compact info row widget
class _CompactInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  
  const _CompactInfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: TextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
