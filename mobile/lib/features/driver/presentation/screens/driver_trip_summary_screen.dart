import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/themes/app_colors.dart';
import '../../../../app/themes/app_spacing.dart';
import '../../../../app/themes/text_styles.dart';
import '../../../../core/models/driver_models.dart';

/// Trip Summary Screen shown after completing a ride or viewing completed ride details
class DriverTripSummaryScreen extends ConsumerStatefulWidget {
  final String rideId;
  final String rideNumber;
  final RideDetailsWithPassengers rideDetails;
  final DateTime? tripStartTime;
  final DateTime? tripEndTime;

  const DriverTripSummaryScreen({
    Key? key,
    required this.rideId,
    required this.rideNumber,
    required this.rideDetails,
    this.tripStartTime,
    this.tripEndTime,
  }) : super(key: key);

  @override
  ConsumerState<DriverTripSummaryScreen> createState() => _DriverTripSummaryScreenState();
}

class _DriverTripSummaryScreenState extends ConsumerState<DriverTripSummaryScreen> {
  double get _totalEarnings {
    return widget.rideDetails.passengers.fold<double>(
      0.0,
      (sum, passenger) => sum + passenger.totalAmount,
    );
  }

  String get _tripDuration {
    if (widget.tripStartTime != null && widget.tripEndTime != null) {
      final duration = widget.tripEndTime!.difference(widget.tripStartTime!);
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      if (hours > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${minutes}m';
    }
    return widget.rideDetails.duration != null ? '${widget.rideDetails.duration}m' : 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('Trip Summary'),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Success header with earnings
            _buildSuccessHeader(isDark),
            
            SizedBox(height: AppSpacing.lg),
            
            // Trip details card
            _buildTripDetailsCard(isDark),
            
            SizedBox(height: AppSpacing.md),
            
            // Route card
            _buildRouteCard(isDark),
            
            SizedBox(height: AppSpacing.md),
            
            // Passengers list card
            _buildPassengersCard(isDark),
            
            SizedBox(height: AppSpacing.md),
            
            // Earnings breakdown card
            _buildEarningsCard(isDark),
            
            SizedBox(height: AppSpacing.xl),
            
            // Action buttons
            _buildActionButtons(isDark),
            
            SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.success, AppColors.success.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Success checkmark
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 50,
              color: AppColors.success,
            ),
          ),
          
          SizedBox(height: AppSpacing.md),
          
          Text(
            'Trip Completed!',
            style: TextStyles.headingLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: AppSpacing.sm),
          
          Text(
            widget.rideNumber,
            style: TextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          
          SizedBox(height: AppSpacing.lg),
          
          // Earnings amount
          Text(
            'Total Earnings',
            style: TextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          
          SizedBox(height: AppSpacing.xs),
          
          Text(
            '₹${_totalEarnings.toStringAsFixed(0)}',
            style: TextStyles.headingLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 48,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetailsCard(bool isDark) {
    final departureTime = DateTime.tryParse(widget.rideDetails.departureTime);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip Details',
            style: TextStyles.headingMedium.copyWith(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: AppSpacing.lg),
          
          // Date and time row
          _buildDetailRow(
            Icons.calendar_today,
            'Date',
            departureTime != null ? DateFormat('dd MMM yyyy').format(departureTime) : 'N/A',
            isDark,
          ),
          
          SizedBox(height: AppSpacing.md),
          
          _buildDetailRow(
            Icons.schedule,
            'Start Time',
            widget.tripStartTime != null 
              ? DateFormat('hh:mm a').format(widget.tripStartTime!) 
              : (departureTime != null ? DateFormat('hh:mm a').format(departureTime) : 'N/A'),
            isDark,
          ),
          
          SizedBox(height: AppSpacing.md),
          
          _buildDetailRow(
            Icons.flag,
            'End Time',
            widget.tripEndTime != null 
              ? DateFormat('hh:mm a').format(widget.tripEndTime!) 
              : 'N/A',
            isDark,
          ),
          
          SizedBox(height: AppSpacing.md),
          
          _buildDetailRow(
            Icons.timer,
            'Duration',
            _tripDuration,
            isDark,
          ),
          
          SizedBox(height: AppSpacing.md),
          
          _buildDetailRow(
            Icons.route,
            'Distance',
            widget.rideDetails.distance != null 
              ? '${widget.rideDetails.distance!.toStringAsFixed(1)} km'
              : 'N/A',
            isDark,
          ),
          
          SizedBox(height: AppSpacing.md),
          
          _buildDetailRow(
            Icons.airline_seat_recline_normal,
            'Passengers',
            '${widget.rideDetails.passengers.length} / ${widget.rideDetails.totalSeats}',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route',
            style: TextStyles.headingMedium.copyWith(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: AppSpacing.lg),
          
          // Pickup location
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.trip_origin, color: AppColors.success),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup',
                      style: TextStyles.bodySmall.copyWith(
                        color: isDark ? Colors.white60 : AppColors.lightTextSecondary,
                      ),
                    ),
                    Text(
                      widget.rideDetails.pickupLocation,
                      style: TextStyles.bodyLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Intermediate stops (if any)
          if (widget.rideDetails.intermediateStops != null && 
              widget.rideDetails.intermediateStops!.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.only(left: 19.5),
              child: Container(
                width: 1,
                height: 30,
                color: Colors.grey[300],
              ),
            ),
            ...widget.rideDetails.intermediateStops!.map((stop) => Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.circle, color: AppColors.info, size: 12),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      stop,
                      style: TextStyles.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            Padding(
              padding: EdgeInsets.only(left: 19.5),
              child: Container(
                width: 1,
                height: 30,
                color: Colors.grey[300],
              ),
            ),
          ] else ...[
            Padding(
              padding: EdgeInsets.only(left: 19.5),
              child: Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
            ),
          ],
          
          // Dropoff location
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.location_on, color: AppColors.error),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dropoff',
                      style: TextStyles.bodySmall.copyWith(
                        color: isDark ? Colors.white60 : AppColors.lightTextSecondary,
                      ),
                    ),
                    Text(
                      widget.rideDetails.dropoffLocation,
                      style: TextStyles.bodyLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassengersCard(bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Passengers',
                style: TextStyles.headingMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                ),
                child: Text(
                  '${widget.rideDetails.passengers.length} Passengers',
                  style: TextStyles.bodySmall.copyWith(
                    color: AppColors.primaryYellow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppSpacing.lg),
          
          // Passenger list
          ...widget.rideDetails.passengers.asMap().entries.map((entry) {
            final index = entry.key;
            final passenger = entry.value;
            return Column(
              children: [
                if (index > 0) SizedBox(height: AppSpacing.md),
                _buildPassengerRow(passenger, isDark),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPassengerRow(PassengerInfo passenger, bool isDark) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Passenger count badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${passenger.passengerCount}',
                  style: TextStyles.bodyLarge.copyWith(
                    color: AppColors.primaryYellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              SizedBox(width: AppSpacing.md),
              
              // Passenger info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passenger.passengerName,
                      style: TextStyles.bodyLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      passenger.phoneNumber,
                      style: TextStyles.bodySmall.copyWith(
                        color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Call button
              IconButton(
                onPressed: () => _makePhoneCall(passenger.phoneNumber),
                icon: Icon(Icons.phone, color: AppColors.success, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.success.withOpacity(0.1),
                  padding: EdgeInsets.all(8),
                  minimumSize: Size(36, 36),
                ),
              ),
              
              SizedBox(width: AppSpacing.xs),
              
              // Fare amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${passenger.totalAmount.toStringAsFixed(0)}',
                    style: TextStyles.bodyLarge.copyWith(
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: passenger.paymentStatus.toLowerCase() == 'paid'
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      passenger.paymentStatus.toUpperCase(),
                      style: TextStyles.bodySmall.copyWith(
                        color: passenger.paymentStatus.toLowerCase() == 'paid'
                            ? AppColors.success
                            : AppColors.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: AppSpacing.sm),
          
          // Route info
          Row(
            children: [
              Icon(Icons.trip_origin, size: 12, color: AppColors.success),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  passenger.pickupLocation,
                  style: TextStyles.bodySmall.copyWith(
                    color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
              SizedBox(width: AppSpacing.sm),
              Icon(Icons.location_on, size: 12, color: AppColors.error),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  passenger.dropoffLocation,
                  style: TextStyles.bodySmall.copyWith(
                    color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(bool isDark) {
    final paidCount = widget.rideDetails.passengers
        .where((p) => p.paymentStatus.toLowerCase() == 'paid')
        .length;
    final pendingCount = widget.rideDetails.passengers.length - paidCount;
    
    final paidAmount = widget.rideDetails.passengers
        .where((p) => p.paymentStatus.toLowerCase() == 'paid')
        .fold<double>(0.0, (sum, p) => sum + p.totalAmount);
    final pendingAmount = _totalEarnings - paidAmount;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earnings Breakdown',
            style: TextStyles.headingMedium.copyWith(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: AppSpacing.lg),
          
          // Total earnings row
          _buildEarningsRow(
            'Total Fare',
            '₹${_totalEarnings.toStringAsFixed(0)}',
            isDark,
            isTotal: true,
          ),
          
          SizedBox(height: AppSpacing.md),
          
          Divider(height: 1),
          
          SizedBox(height: AppSpacing.md),
          
          // Paid amount
          _buildEarningsRow(
            'Received ($paidCount passengers)',
            '₹${paidAmount.toStringAsFixed(0)}',
            isDark,
            color: AppColors.success,
          ),
          
          if (pendingCount > 0) ...[
            SizedBox(height: AppSpacing.sm),
            _buildEarningsRow(
              'Pending ($pendingCount passengers)',
              '₹${pendingAmount.toStringAsFixed(0)}',
              isDark,
              color: AppColors.warning,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEarningsRow(String label, String amount, bool isDark, {Color? color, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyles.bodyLarge.copyWith(
            color: color ?? (isDark ? Colors.white70 : AppColors.lightTextSecondary),
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: TextStyles.bodyLarge.copyWith(
            color: color ?? (isDark ? Colors.white : AppColors.lightTextPrimary),
            fontWeight: FontWeight.bold,
            fontSize: isTotal ? 20 : 16,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryYellow.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryYellow, size: 18),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyles.bodySmall.copyWith(
                  color: isDark ? Colors.white60 : AppColors.lightTextSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyles.bodyLarge.copyWith(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement share functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Share feature coming soon'),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
              icon: Icon(Icons.share),
              label: Text('Share'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryYellow,
                side: BorderSide(color: AppColors.primaryYellow),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate back to rides screen
                Navigator.pop(context);
              },
              icon: Icon(Icons.check),
              label: Text('Done'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot make phone call'),
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
    }
  }
}
