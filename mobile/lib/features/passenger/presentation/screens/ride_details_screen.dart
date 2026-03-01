import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/shared/widgets/buttons.dart';
import 'package:allapalli_ride/features/passenger/domain/models/vehicle_option.dart';
import 'package:allapalli_ride/core/models/passenger_ride_models.dart';

/// Ride details screen with booking confirmation information
class RideDetailsScreen extends StatefulWidget {
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

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String get _bookingId => widget.bookingResponse?.bookingNumber ?? 'ALR${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  String get _dateStr => '${widget.travelDate.day}/${widget.travelDate.month}/${widget.travelDate.year}';
  int get _estimatedPrice => widget.bookingResponse?.totalFare.toInt() ?? (widget.vehicle.basePrice + (5 * widget.vehicle.pricePerKm));

  Future<void> _playCancellationSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/ride_cancellation.mp3'));
    } catch (e) {
      print('Error playing cancellation sound: $e');
    }
  }

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
            onPressed: () async {
              Navigator.pop(context);

              // Play cancellation sound
              await _playCancellationSound();

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

            // Booking Summary Section
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
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
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.directions_car,
                        size: 44,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Your ride is booked!',
                      style: TextStyles.headingMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Booking ID: $_bookingId',
                      style: TextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSummaryRow(Icons.location_on, 'From', widget.pickupLocation, AppColors.success, isDark),
                    const SizedBox(height: AppSpacing.md),
                    _buildSummaryRow(Icons.location_on, 'To', widget.dropoffLocation, AppColors.error, isDark),
                    const SizedBox(height: AppSpacing.md),
                    _buildSummaryRow(Icons.calendar_today, 'Date', _dateStr, AppColors.info, isDark),
                    const SizedBox(height: AppSpacing.md),
                    _buildSummaryRow(Icons.access_time, 'Time', widget.timeSlot, AppColors.info, isDark),
                    const SizedBox(height: AppSpacing.md),
                    _buildSummaryRow(Icons.payments, 'Fare', '₹$_estimatedPrice (Cash)', AppColors.primaryGreen, isDark),
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
                          icon: widget.vehicle.icon,
                          iconColor: AppColors.primaryYellow,
                          label: '${widget.vehicle.name} • ${widget.passengerCount} pax',
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
                      'Arrive 15 min early at the pickup point',
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

  Widget _buildSummaryRow(IconData icon, String label, String value, Color iconColor, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: TextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyles.bodyMedium.copyWith(
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
