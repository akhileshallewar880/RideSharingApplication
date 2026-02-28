import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/core/models/passenger_ride_models.dart';
import 'package:allapalli_ride/core/providers/passenger_ride_provider.dart';
import 'package:allapalli_ride/features/passenger/presentation/screens/cancellation_confirmation_screen.dart';
import 'package:allapalli_ride/features/passenger/presentation/screens/passenger_live_tracking_screen.dart';
import 'package:allapalli_ride/shared/widgets/indian_number_plate.dart';
import 'package:intl/intl.dart';

/// Screen to manage an upcoming booking (cancel or reschedule)
class BookingManagementScreen extends ConsumerStatefulWidget {
  final RideHistoryItem ride;
  
  const BookingManagementScreen({
    super.key,
    required this.ride,
  });
  
  @override
  ConsumerState<BookingManagementScreen> createState() => _BookingManagementScreenState();
}

class _BookingManagementScreenState extends ConsumerState<BookingManagementScreen> {
  bool _isCancelling = false;
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Debug logging
    print('📋 [BookingDetails] Building screen for booking: ${widget.ride.bookingNumber}');
    print('📋 [BookingDetails] selectedSeats: ${widget.ride.selectedSeats}');
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Booking Status Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryGreen,
                          AppColors.primaryGreen.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 64,
                          color: Colors.white,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Booking Confirmed',
                          style: TextStyles.headingLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          widget.ride.bookingNumber,
                          style: TextStyles.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Trip Details Card
                        _buildInfoCard(
                          isDark,
                          'Trip Details',
                          [
                            _buildInfoRow(Icons.location_on, 'Pickup', widget.ride.pickupLocation, isDark),
                            _buildInfoRow(Icons.location_on_outlined, 'Drop-off', widget.ride.dropoffLocation, isDark),
                            _buildInfoRow(Icons.calendar_today, 'Date', _formatDate(widget.ride.travelDate), isDark),
                            _buildInfoRow(Icons.access_time, 'Time', _formatTimeTo12Hour(widget.ride.timeSlot), isDark),
                            // Seat Numbers
                            if (widget.ride.selectedSeats != null && widget.ride.selectedSeats!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.sm),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.event_seat,
                                          size: 20,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text(
                                          'Seat${widget.ride.selectedSeats!.length > 1 ? 's' : ''}',
                                          style: TextStyles.bodyMedium.copyWith(
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: widget.ride.selectedSeats!.map((seat) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryYellow.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: AppColors.primaryYellow,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Text(
                                          seat,
                                          style: TextStyles.bodyMedium.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isDark 
                                                ? AppColors.primaryYellow 
                                                : const Color(0xFFF57C00),
                                          ),
                                        ),
                                      )).toList(),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // Vehicle Details Card
                  _buildInfoCard(
                    isDark,
                    'Vehicle Details',
                    [
                      if (widget.ride.vehicleNumber != null && widget.ride.vehicleNumber!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Row(
                            children: [
                              Icon(Icons.directions_car, size: 20, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Vehicle Number',
                                  style: TextStyles.bodyMedium.copyWith(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              IndianNumberPlate(
                                vehicleNumber: widget.ride.vehicleNumber!,
                                scale: 0.65,
                                backgroundColor: const Color(0xFFFFC107),
                              ),
                            ],
                          ),
                        ),
                      if (widget.ride.vehicleModel != null)
                        _buildInfoRow(Icons.car_rental, 'Model', widget.ride.vehicleModel!, isDark),
                      _buildInfoRow(Icons.category, 'Type', widget.ride.vehicleType, isDark),
                    ],
                  ),
                        
                        const SizedBox(height: AppSpacing.md),
                        
                        // Driver Details Card
                        if (widget.ride.driverName != null && widget.ride.driverName!.isNotEmpty)
                          _buildInfoCard(
                            isDark,
                            'Driver Details',
                            [
                              _buildInfoRow(Icons.person, 'Name', widget.ride.driverName!, isDark),
                            ],
                          ),
                        
                        const SizedBox(height: AppSpacing.md),
                        
                        // Payment Details Card
                        _buildInfoCard(
                          isDark,
                          'Payment Details',
                          [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Fare',
                                  style: TextStyles.headingMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₹${widget.ride.totalFare.toStringAsFixed(0)}',
                                  style: TextStyles.headingMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Fixed action buttons at bottom
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _navigateToLiveTracking,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Live Tracking'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                        side: BorderSide(color: AppColors.primaryGreen),
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isCancelling ? null : _showCancelDialog,
                      icon: _isCancelling 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.cancel),
                      label: const Text('Cancel Ride'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard(bool isDark, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: TextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
  
  String _formatTimeTo12Hour(String time24) {
    try {
      // Handle formats like "10:00:00" or "10:00"
      final parts = time24.split(':');
      if (parts.isEmpty) return time24;
      
      int hour = int.parse(parts[0]);
      final minute = parts.length > 1 ? parts[1] : '00';
      
      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) {
        hour -= 12;
      } else if (hour == 0) {
        hour = 12;
      }
      
      return '$hour:$minute $period';
    } catch (e) {
      return time24;
    }
  }
  
  void _navigateToLiveTracking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PassengerLiveTrackingScreen(
          rideId: widget.ride.rideId ?? '',
          bookingNumber: widget.ride.bookingNumber,
          rideDetails: widget.ride,
        ),
      ),
    );
  }
  
  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Ride'),
        content: const Text('Are you sure you want to cancel this ride? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelRide();
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
  
  Future<void> _cancelRide() async {
    setState(() => _isCancelling = true);
    
    try {
      // Use bookingId if available, otherwise fall back to bookingNumber
      final bookingIdentifier = widget.ride.bookingId ?? widget.ride.bookingNumber;
      final success = await ref
          .read(passengerRideNotifierProvider.notifier)
          .cancelBooking(bookingIdentifier, 'User requested cancellation');
      
      if (mounted) {
        if (success) {
          // Refresh ride history
          await ref.read(passengerRideNotifierProvider.notifier).loadRideHistory();
          
          // Navigate to cancellation confirmation screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CancellationConfirmationScreen(
                bookingNumber: widget.ride.bookingNumber,
                refundAmount: widget.ride.totalFare,
              ),
            ),
          );
        } else {
          final state = ref.read(passengerRideNotifierProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Failed to cancel ride'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }
}
