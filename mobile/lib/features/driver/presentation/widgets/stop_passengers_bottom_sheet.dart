import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/driver_models.dart';
import '../../../../core/services/driver_ride_service.dart';
import '../../../../app/themes/app_colors.dart';
import '../../../../app/themes/app_spacing.dart';
import '../../../../app/themes/text_styles.dart';

/// Bottom sheet showing passengers at a specific stop for OTP verification and cash collection
class StopPassengersBottomSheet extends ConsumerStatefulWidget {
  final String stopLocation;
  final String rideId;
  final List<PassengerInfo> pickupPassengers;
  final List<PassengerInfo> dropoffPassengers;

  const StopPassengersBottomSheet({
    super.key,
    required this.stopLocation,
    required this.rideId,
    required this.pickupPassengers,
    required this.dropoffPassengers,
  });

  @override
  ConsumerState<StopPassengersBottomSheet> createState() => _StopPassengersBottomSheetState();
}

class _StopPassengersBottomSheetState extends ConsumerState<StopPassengersBottomSheet> {
  final Map<String, TextEditingController> _otpControllers = {};
  final Map<String, bool> _cashCollected = {};
  final Map<String, bool> _verifyingOtp = {}; // Track which OTPs are being verified
  final Map<String, String> _passengerStatuses = {}; // Track local boarding statuses
  bool _hasVerifiedPassenger = false; // Track if any passenger was verified

  @override
  void initState() {
    super.initState();
    // Initialize controllers for each pickup passenger
    for (var passenger in widget.pickupPassengers) {
      _otpControllers[passenger.bookingId] = TextEditingController();
      _verifyingOtp[passenger.bookingId] = false;
      _passengerStatuses[passenger.bookingId] = passenger.boardingStatus;
    }
    // Initialize cash collection status
    for (var passenger in widget.dropoffPassengers) {
      _cashCollected[passenger.bookingId] = false;
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPickups = widget.pickupPassengers.isNotEmpty;
    final hasDropoffs = widget.dropoffPassengers.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLG)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(Icons.location_on, color: AppColors.primaryYellow),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.stopLocation,
                    style: TextStyles.headingMedium.copyWith(
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context, _hasVerifiedPassenger),
                ),
              ],
            ),
          ),
          
          Divider(height: 1),
          
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pickup passengers
                  if (hasPickups) ...[
                    _buildSectionHeader('Boarding Passengers', Icons.arrow_circle_up, AppColors.success, isDark),
                    SizedBox(height: AppSpacing.md),
                    ...widget.pickupPassengers.map((passenger) => 
                      _buildPickupPassengerCard(passenger, isDark)
                    ),
                    if (hasDropoffs) SizedBox(height: AppSpacing.xl),
                  ],
                  
                  // Dropoff passengers
                  if (hasDropoffs) ...[
                    _buildSectionHeader('Alighting Passengers', Icons.arrow_circle_down, AppColors.error, isDark),
                    SizedBox(height: AppSpacing.md),
                    ...widget.dropoffPassengers.map((passenger) => 
                      _buildDropoffPassengerCard(passenger, isDark)
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: TextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPickupPassengerCard(PassengerInfo passenger, bool isDark) {
    final isVerified = _passengerStatuses[passenger.bookingId] == 'boarded';
    final controller = _otpControllers[passenger.bookingId]!;
    final isVerifying = _verifyingOtp[passenger.bookingId] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isVerified 
            ? AppColors.success.withOpacity(0.1)
            : (isDark ? AppColors.darkBackground : AppColors.lightBackground),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        border: Border.all(
          color: isVerified ? AppColors.success : Colors.grey[300]!,
          width: isVerified ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isVerified ? AppColors.success : AppColors.primaryYellow,
                child: Icon(
                  isVerified ? Icons.check : Icons.person,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passenger.passengerName,
                      style: TextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
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
              if (isVerified)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                  ),
                  child: Text(
                    'BOARDED',
                    style: TextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: AppSpacing.md),
          
          // Trip details
          Row(
            children: [
              Icon(Icons.people, size: 16, color: Colors.grey[600]),
              SizedBox(width: AppSpacing.xs),
              Text(
                '${passenger.passengerCount} ${passenger.passengerCount == 1 ? 'seat' : 'seats'}',
                style: TextStyles.bodyMedium.copyWith(
                  color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'To: ${passenger.dropoffLocation}',
                  style: TextStyles.bodyMedium.copyWith(
                    color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          if (!isVerified) ...[
            SizedBox(height: AppSpacing.md),
            
            // OTP Input
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    onChanged: (value) {
                      // Auto-verify when 4 digits are entered
                      if (value.length == 4 && !isVerifying) {
                        _verifyOtp(passenger, value);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Enter OTP',
                      hintText: '4-digit OTP',
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: isVerifying ? null : () => _verifyOtp(passenger, controller.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isVerifying ? Colors.grey : AppColors.success,
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                      ),
                    ),
                    child: isVerifying
                        ? SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Verify',
                            style: TextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            
            // OTP removed from display
          ],
        ],
      ),
    );
  }

  Widget _buildDropoffPassengerCard(PassengerInfo passenger, bool isDark) {
    final cashCollected = _cashCollected[passenger.bookingId] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cashCollected
            ? AppColors.success.withOpacity(0.1)
            : (isDark ? AppColors.darkBackground : AppColors.lightBackground),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        border: Border.all(
          color: cashCollected ? AppColors.success : Colors.grey[300]!,
          width: cashCollected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: cashCollected ? AppColors.success : AppColors.error,
                child: Icon(
                  cashCollected ? Icons.check : Icons.person,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passenger.passengerName,
                      style: TextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
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
              if (cashCollected)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                  ),
                  child: Text(
                    'PAID',
                    style: TextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: AppSpacing.md),
          
          // Trip details
          Row(
            children: [
              Icon(Icons.people, size: 16, color: Colors.grey[600]),
              SizedBox(width: AppSpacing.xs),
              Text(
                '${passenger.passengerCount} ${passenger.passengerCount == 1 ? 'seat' : 'seats'}',
                style: TextStyles.bodyMedium.copyWith(
                  color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'From: ${passenger.pickupLocation}',
                  style: TextStyles.bodyMedium.copyWith(
                    color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppSpacing.md),
          
          // Payment info
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fare Amount',
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  '₹ ${_calculateFare(passenger)}',
                  style: TextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: AppSpacing.sm),
          
          // Cash collection button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: cashCollected ? null : () => _markCashCollected(passenger.bookingId),
              icon: Icon(cashCollected ? Icons.check_circle : Icons.payments),
              label: Text(cashCollected ? 'Cash Collected' : 'Collect Cash'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cashCollected ? Colors.grey : AppColors.success,
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateFare(PassengerInfo passenger) {
    // This is a placeholder - you would calculate actual fare based on segment pricing
    return '250';
  }

  void _markCashCollected(String bookingId) {
    setState(() {
      _cashCollected[bookingId] = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cash collection marked ✓'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _verifyOtp(PassengerInfo passenger, String enteredOtp) async {
    if (enteredOtp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter OTP'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Set loading state
    setState(() {
      _verifyingOtp[passenger.bookingId] = true;
    });

    try {
      print('🔄 Verifying OTP for ${passenger.passengerName}...');
      final service = DriverRideService();
      await service.verifyPassengerOtp(
        widget.rideId,
        passenger.bookingId,
        VerifyOtpRequest(otp: enteredOtp),
      );
      
      print('✅ OTP verified successfully for ${passenger.passengerName}');
      
      if (mounted) {
        // Clear loading state and update passenger status
        setState(() {
          _verifyingOtp[passenger.bookingId] = false;
          _passengerStatuses[passenger.bookingId] = 'boarded';
          _hasVerifiedPassenger = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('${passenger.passengerName} verified successfully!'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Clear the OTP field after successful verification
        _otpControllers[passenger.bookingId]?.clear();
      }
    } catch (e) {
      print('❌ OTP verification failed: $e');
      if (mounted) {
        // Clear loading state
        setState(() {
          _verifyingOtp[passenger.bookingId] = false;
        });
      }
    }
  }
}
