import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/core/models/passenger_ride_models.dart';
import 'package:allapalli_ride/core/providers/passenger_ride_provider.dart';
import 'package:allapalli_ride/features/passenger/presentation/screens/booking_confirmation_screen.dart';
import 'package:allapalli_ride/features/passenger/presentation/screens/passenger_home_screen.dart';
import 'package:allapalli_ride/features/passenger/presentation/widgets/seat_selection/compact_seat_widget.dart';
import 'package:intl/intl.dart';
import 'dart:async';

/// Single-screen checkout experience for ride booking
class RideCheckoutScreen extends ConsumerStatefulWidget {
  final AvailableRide ride;
  final String pickupLocation;
  final String dropoffLocation;
  final DateTime travelDate;
  final int passengerCount;
  
  final Location pickupCoordinates;
  final Location dropoffCoordinates;
  
  const RideCheckoutScreen({
    super.key,
    required this.ride,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.travelDate,
    required this.passengerCount,
    required this.pickupCoordinates,
    required this.dropoffCoordinates,
  });
  
  @override
  ConsumerState<RideCheckoutScreen> createState() => _RideCheckoutScreenState();
}

class _RideCheckoutScreenState extends ConsumerState<RideCheckoutScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _couponController = TextEditingController();
  
  String _selectedUpiApp = 'cash';
  bool _hasGstNumber = false;
  bool _addInsurance = false;
  bool _addDonation = false;
  bool _isProcessing = false;
  bool _isRouteExpanded = false;
  late int _passengerCount;
  
  // Seat selection state
  List<String> _selectedSeats = [];
  bool _showSeatSelection = true; // TEMP: true for testing
  
  // Timer state
  Timer? _countdownTimer;
  int _remainingSeconds = 300; // 5 minutes = 300 seconds
  
  double get _basePrice => widget.ride.pricePerSeat * _passengerCount;
  double get _insuranceFee => _addInsurance ? (29 * _passengerCount).toDouble() : 0.0;
  double get _donationAmount => _addDonation ? 5.0 : 0.0;
  double get _discount => 0; // TODO: Apply coupon discount
  double get _totalAmount => _basePrice + _insuranceFee + _donationAmount - _discount;
  
  @override
  void initState() {
    super.initState();
    _passengerCount = widget.passengerCount;
    // Pre-fill with user data if available
    _phoneController.text = '+91 9511803142'; // TODO: Get from auth
    _emailController.text = 'akhileshallewar880@gmail.com'; // TODO: Get from auth
    
    // Debug: Check seating layout data
    print('🪑 DEBUG: Seating Layout = ${widget.ride.seatingLayout}');
    print('🪑 DEBUG: Booked Seats = ${widget.ride.bookedSeats}');
    print('🪑 DEBUG: Has Layout = ${widget.ride.seatingLayout != null && widget.ride.seatingLayout!.isNotEmpty}');
    
    // Start countdown timer
    _startCountdownTimer();
  }
  
  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
          _handleTimerExpired();
        }
      });
    });
  }
  
  void _handleTimerExpired() {
    // Show dialog and redirect to home
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Booking Time Expired'),
        content: const Text(
          'Your time to book this ride has ended. Please search for rides again.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const PassengerHomeScreen(),
                ),
                (route) => false,
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  String _formatRemainingTime() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _emailController.dispose();
    _couponController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Passenger Information',
              style: TextStyles.headingSmall.copyWith(fontSize: 18),
            ),
            Text(
              '${widget.pickupLocation} → ${widget.dropoffLocation}',
              style: TextStyles.caption.copyWith(
                color: isDark 
                    ? AppColors.darkTextSecondary 
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          // Countdown timer
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _remainingSeconds <= 60 
                  ? Colors.red.withOpacity(0.15)
                  : AppColors.primaryYellow.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _remainingSeconds <= 60 
                    ? Colors.red 
                    : AppColors.primaryYellow,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: _remainingSeconds <= 60 ? Colors.red : AppColors.primaryYellow,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatRemainingTime(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _remainingSeconds <= 60 
                        ? Colors.red 
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                  const SizedBox(height: AppSpacing.md),
                  
                  // Trip Summary
                  _buildTripSummary(isDark),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // Optional Seat Selection (ALWAYS SHOWN FOR TESTING)
                  _buildSeatSelectionSection(isDark),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // Donation Section
                  _buildDonationSection(isDark),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // Coupon Section
                  _buildCouponSection(isDark),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // Payment Methods
                  _buildPaymentMethods(isDark),
                  
                  const SizedBox(height: 100), // Space for bottom bar
                ],
              ),
            ),
          ),
          
          // Bottom Payment Bar
          _buildBottomPaymentBar(isDark),
        ],
      ),
    );
  }
  
  Widget _buildTripSummary(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Driver and Vehicle Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Driver Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.ride.driverName.substring(0, 1).toUpperCase(),
                    style: TextStyles.headingMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryYellow,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.ride.driverName,
                      style: TextStyles.headingSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.directions_car,
                          size: 14,
                          color: isDark 
                              ? AppColors.darkTextSecondary 
                              : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.ride.vehicleModel,
                            style: TextStyles.bodySmall.copyWith(
                              color: isDark 
                                  ? AppColors.darkTextSecondary 
                                  : AppColors.lightTextSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.ride.vehicleType,
                      style: TextStyles.caption.copyWith(
                        color: isDark 
                            ? AppColors.darkTextSecondary 
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 12,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          widget.ride.driverRating.toStringAsFixed(1),
                          style: TextStyles.caption.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Vehicle Number Plate
          _buildNumberPlate(widget.ride.vehicleNumber, isDark),
          
          const SizedBox(height: AppSpacing.md),
          
          Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Date and Time - Highlighted
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primaryGreen.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      DateFormat('EEE, dd MMM').format(widget.travelDate),
                      style: TextStyles.bodySmall.copyWith(
                        color: isDark ? Colors.white : AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 20,
                  width: 1,
                  color: AppColors.primaryGreen.withOpacity(0.3),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _formatTimeTo12Hour(widget.ride.departureTime),
                      style: TextStyles.bodySmall.copyWith(
                        color: isDark ? Colors.white : AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Route Information Card
          _buildRouteInformationCard(isDark),
          
          const SizedBox(height: AppSpacing.md),
          
          // Seats with increment/decrement buttons
          Row(
            children: [
              Icon(
                Icons.airline_seat_recline_normal,
                size: 18,
                color: isDark 
                    ? AppColors.darkTextSecondary 
                    : AppColors.lightTextSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Seats:',
                style: TextStyles.bodyMedium,
              ),
              const SizedBox(width: AppSpacing.sm),
              // Decrement button
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed: _passengerCount > 1
                      ? () {
                          setState(() {
                            _passengerCount--;
                          });
                        }
                      : null,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Count display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$_passengerCount',
                  style: TextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Increment button
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: _passengerCount < widget.ride.availableSeats
                      ? () {
                          setState(() {
                            _passengerCount++;
                          });
                        }
                      : null,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _formatTimeTo12Hour(String time24) {
    try {
      final parts = time24.split(':');
      if (parts.length != 2) return time24;
      
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      
      String period = hour >= 12 ? 'PM' : 'AM';
      hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time24;
    }
  }
  
  Widget _buildNumberPlate(String vehicleNumber, bool isDark) {
    // Indian number plate format with yellow background
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: Colors.black,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Left color stripe (Indian flag colors)
          Container(
            width: 2,
            height: 14,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF138808), // Saffron
                  Color(0xFFFFFFFF), // White
                  Color(0xFF000080), // Blue
                ],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 4),
          // IND text
          Text(
            'IND',
            style: TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 4),
          // Separator
          Container(
            width: 1,
            height: 12,
            color: Colors.black,
          ),
          const SizedBox(width: 4),
          // Vehicle number
          Text(
            vehicleNumber.isNotEmpty 
                ? vehicleNumber.toUpperCase() 
                : 'MH12AB1234',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: 0.5,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContactDetails(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Contact Details',
                style: TextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Edit contact details
                },
                child: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Ticket details will be sent to',
            style: TextStyles.bodySmall.copyWith(
              color: isDark 
                  ? AppColors.darkTextSecondary 
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.phone, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _phoneController.text,
                style: TextStyles.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.email, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _emailController.text,
                  style: TextStyles.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'WhatsApp communication enabled',
                    style: TextStyles.bodySmall.copyWith(
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInsuranceSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Trip Insurance',
                style: TextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '₹29 per passenger',
                  style: TextStyles.caption.copyWith(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'If your bus gets cancelled, you get',
                  style: TextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '₹1,500',
                  style: TextStyles.headingLarge.copyWith(
                    color: const Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹1,000 + ₹500 (extra cashback)',
                  style: TextStyles.bodySmall.copyWith(
                    color: isDark 
                        ? AppColors.darkTextSecondary 
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Includes coverage of ₹75,000 for hospitalisation and ₹5,00,000 in case of death, PTD or PPD.',
            style: TextStyles.caption.copyWith(
              color: isDark 
                  ? AppColors.darkTextSecondary 
                  : AppColors.lightTextSecondary,
            ),
          ),
          TextButton(
            onPressed: () {
              // Show terms and conditions
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
            ),
            child: const Text('Terms and conditions'),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildRadioOption(
            'Add Trip Insurance\n₹29 for ${widget.passengerCount} passenger${widget.passengerCount > 1 ? 's' : ''}',
            _addInsurance,
            () => setState(() => _addInsurance = true),
            isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildRadioOption(
            'Don\'t add Trip Insurance',
            !_addInsurance,
            () => setState(() => _addInsurance = false),
            isDark,
          ),
        ],
      ),
    );
  }
  
  Widget _buildGstSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _hasGstNumber,
            onChanged: (value) {
              setState(() => _hasGstNumber = value ?? false);
            },
          ),
          Expanded(
            child: Text(
              'I have a GST number (optional)?',
              style: TextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSeatSelectionSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with expand/collapse
          GestureDetector(
            onTap: () {
              setState(() {
                _showSeatSelection = !_showSeatSelection;
              });
            },
            child: Row(
              children: [
                Icon(
                  Icons.event_seat,
                  size: 22,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Your Seats (Optional)',
                        style: TextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedSeats.isEmpty 
                            ? 'Choose specific seats for your journey'
                            : '${_selectedSeats.length} seat(s) selected',
                        style: TextStyles.bodySmall.copyWith(
                          color: isDark 
                              ? AppColors.darkTextSecondary 
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _showSeatSelection 
                      ? Icons.keyboard_arrow_up 
                      : Icons.keyboard_arrow_down,
                  color: isDark 
                      ? AppColors.darkTextSecondary 
                      : AppColors.lightTextSecondary,
                ),
              ],
            ),
          ),
          
          // Seat selection widget (expandable)
          if (_showSeatSelection) ...[
            const SizedBox(height: AppSpacing.lg),
            CompactSeatSelectionWidget(
              seatingLayoutJson: widget.ride.seatingLayout,
              bookedSeats: widget.ride.bookedSeats ?? [],
              maxSelectableSeats: _passengerCount,
              pricePerSeat: widget.ride.pricePerSeat,
              onSeatsSelected: (selectedSeats) {
                setState(() {
                  _selectedSeats = selectedSeats;
                });
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            // Info text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seat selection is optional. If you skip, seats will be assigned automatically.',
                      style: TextStyles.bodySmall.copyWith(
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildDonationSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite,
              color: Colors.red.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vanyatra Cares Donation',
                  style: TextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Donate ₹5 to support responsible tourism initiatives',
                  style: TextStyles.caption.copyWith(
                    color: isDark 
                        ? AppColors.darkTextSecondary 
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _addDonation,
            onChanged: (value) {
              setState(() => _addDonation = value);
            },
            activeColor: AppColors.primaryYellow,
          ),
        ],
      ),
    );
  }
  
  Widget _buildCouponSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Have a coupon code?',
                style: TextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  decoration: InputDecoration(
                    hintText: 'Coupon code',
                    filled: true,
                    fillColor: isDark 
                        ? AppColors.darkBackground 
                        : const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ElevatedButton(
                onPressed: () {
                  // Apply coupon
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark 
                      ? AppColors.darkBorder 
                      : Colors.grey.shade300,
                  foregroundColor: isDark 
                      ? AppColors.darkTextSecondary 
                      : AppColors.lightTextSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentMethods(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Method',
            style: TextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildPaymentOption(
            'Cash',
            'cash',
            Icons.money,
            const Color(0xFF4CAF50),
            isDark,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentOption(
    String name,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    final isSelected = _selectedUpiApp == value;
    return InkWell(
      onTap: () => setState(() => _selectedUpiApp = value),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkBorder : const Color(0xFFF5F5F5))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryYellow
                : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                name,
                style: TextStyles.bodyMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedUpiApp,
              onChanged: (value) {
                setState(() => _selectedUpiApp = value!);
              },
              activeColor: AppColors.primaryYellow,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRadioOption(
    String label,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkBorder : const Color(0xFFF5F5F5))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryYellow
                : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyles.bodyMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (value) => onTap(),
              activeColor: AppColors.primaryYellow,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBottomPaymentBar(bool isDark) {
    return Container(
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
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Amount',
                          style: TextStyles.bodyMedium.copyWith(
                            color: isDark 
                                ? AppColors.darkTextSecondary 
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '₹${_totalAmount.toStringAsFixed(0)}',
                          style: TextStyles.headingMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _showPriceBreakup(context, isDark),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    Text(
                      'Tax excluded',
                      style: TextStyles.caption.copyWith(
                        color: isDark 
                            ? AppColors.darkTextSecondary 
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Pay now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
  
  void _showPriceBreakup(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Price breakup',
                  style: TextStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            _buildPriceRow(
              'Seat (${widget.passengerCount} x ₹${widget.ride.pricePerSeat.toStringAsFixed(0)})',
              _basePrice,
              isDark,
            ),
            if (_discount > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildPriceRow(
                'Last min. discount',
                -_discount,
                isDark,
                isDiscount: true,
              ),
            ],
            if (_insuranceFee > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildPriceRow('Insurance', _insuranceFee, isDark),
            ],
            if (_donationAmount > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildPriceRow('Donation', _donationAmount, isDark),
            ],
            const Divider(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: TextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tax excluded',
                      style: TextStyles.caption.copyWith(
                        color: isDark 
                            ? AppColors.darkTextSecondary 
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${_totalAmount.toStringAsFixed(0)}',
                  style: TextStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPriceRow(String label, double amount, bool isDark, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyles.bodyMedium,
        ),
        Text(
          '${isDiscount ? '- ' : ''}₹${amount.abs().toStringAsFixed(0)}',
          style: TextStyles.bodyMedium.copyWith(
            color: isDiscount ? const Color(0xFF4CAF50) : null,
            fontWeight: isDiscount ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }
  
  Future<void> _processPayment() async {
    // Check if time has expired
    if (_remainingSeconds <= 0) {
      _showErrorDialog(
        'Booking Time Expired',
        'Your time to book this ride has ended. Please search for rides again.',
      );
      return;
    }
    
    // Check if ride is departing in less than 5 minutes
    final now = DateTime.now();
    final rideDepartureDateTime = DateTime(
      widget.travelDate.year,
      widget.travelDate.month,
      widget.travelDate.day,
    ).add(_parseDepartureTime(widget.ride.departureTime));
    
    final minutesUntilDeparture = rideDepartureDateTime.difference(now).inMinutes;
    
    if (minutesUntilDeparture < 5) {
      _showErrorDialog(
        'Too Late to Book',
        'This ride is departing in less than 5 minutes. Please search for another ride.',
      );
      return;
    }
    
    setState(() => _isProcessing = true);
    
    try {
      // First, verify the ride is still available and not cancelled
      final verificationRequest = SearchRidesRequest(
        pickupLocation: widget.pickupCoordinates,
        dropoffLocation: widget.dropoffCoordinates,
        travelDate: DateFormat('yyyy-MM-dd').format(widget.travelDate),
        passengerCount: _passengerCount,
      );
      
      // Search for rides to check if this ride still exists
      await ref.read(passengerRideNotifierProvider.notifier).searchRides(verificationRequest);
      
      final availableRides = ref.read(passengerRideNotifierProvider).availableRides;
      final currentRide = availableRides.firstWhere(
        (ride) => ride.rideId == widget.ride.rideId,
        orElse: () => throw Exception('Ride not found or has been cancelled'),
      );
      
      // Check if enough seats are available
      if (currentRide.availableSeats < _passengerCount) {
        if (mounted) {
          _showErrorDialog(
            'Not Enough Seats',
            'Only ${currentRide.availableSeats} seat(s) available. You requested $_passengerCount seat(s).',
          );
        }
        return;
      }
      
      // Proceed with booking
      final bookRequest = BookRideRequest(
        rideId: widget.ride.rideId,
        passengerCount: _passengerCount,
        pickupLocation: widget.pickupCoordinates,
        dropoffLocation: widget.dropoffCoordinates,
        paymentMethod: _selectedUpiApp,
        selectedSeats: _selectedSeats.isEmpty ? null : _selectedSeats,
      );
      
      final success = await ref
          .read(passengerRideNotifierProvider.notifier)
          .bookRide(bookRequest);
      
      if (mounted) {
        if (success) {
          final state = ref.read(passengerRideNotifierProvider);
          if (state.currentBooking != null) {
            // Navigate to confirmation screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => BookingConfirmationScreen(
                  bookingId: state.currentBooking!.bookingNumber,
                  otp: state.currentBooking!.otp,
                ),
              ),
            );
          } else {
            _showErrorDialog(
              'Booking Failed',
              'Unable to retrieve booking details. Please try again.',
            );
          }
        } else {
          final state = ref.read(passengerRideNotifierProvider);
          _showErrorDialog(
            'Booking Failed',
            state.errorMessage ?? 'Something went wrong. Please try again.',
          );
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        _showErrorDialog(
          'Ride Not Available',
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          'Error',
          'An unexpected error occurred. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
  
  void _showErrorDialog(String title, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: TextStyles.headingMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyles.bodyMedium.copyWith(
            color: isDark 
                ? AppColors.darkTextSecondary 
                : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              // Navigate to home page
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const PassengerHomeScreen(initialTab: 0),
                ),
                (route) => false,
              );
            },
            child: Text(
              'Go to Home',
              style: TextStyles.bodyMedium.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build comprehensive route information card
  Widget _buildRouteInformationCard(bool isDark) {
    // Get intermediate stops between passenger's pickup and dropoff
    final relevantStops = _getRelevantIntermediateStops();
    final hasIntermediateStops = relevantStops.isNotEmpty;
    
    // Debug logging
    print('🚗 Route Card Debug:');
    print('  Driver pickup: ${widget.ride.pickupLocation}');
    print('  Driver dropoff: ${widget.ride.dropoffLocation}');
    print('  Intermediate stops: ${widget.ride.intermediateStops}');
    print('  Intermediate stops count: ${widget.ride.intermediateStops?.length ?? 0}');
    print('  Relevant stops count: ${relevantStops.length}');
    print('  Passenger pickup: ${widget.pickupLocation}');
    print('  Passenger dropoff: ${widget.dropoffLocation}');
    
    return InkWell(
      onTap: () {
        setState(() {
          _isRouteExpanded = !_isRouteExpanded;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.route,
                  size: 18,
                  color: isDark ? AppColors.primaryYellow : const Color(0xFFF57C00),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Your Journey Route',
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF212121),
                  ),
                ),
                const Spacer(),
                if (hasIntermediateStops && !_isRouteExpanded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${relevantStops.length} stop${relevantStops.length > 1 ? 's' : ''}',
                      style: TextStyles.caption.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  _isRouteExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF757575),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            // Compact view when collapsed
            if (!_isRouteExpanded) ...[
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      widget.pickupLocation,
                      style: TextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const SizedBox(width: 4),
                  Icon(
                    Icons.more_vert,
                    size: 14,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF9E9E9E),
                  ),
                  const SizedBox(width: 6),
                  if (hasIntermediateStops)
                    Expanded(
                      child: Text(
                        '${relevantStops.length} intermediate stop${relevantStops.length > 1 ? 's' : ''}',
                        style: TextStyles.caption.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF757575),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      widget.dropoffLocation,
                      style: TextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            
            // Expanded view with full timeline
            if (_isRouteExpanded) ...[
          
              // Route Timeline
              IntrinsicHeight(
                child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline indicator column
                  Column(
                    children: [
                      // Pickup indicator
                      _buildRouteIndicator(
                        icon: Icons.trip_origin,
                        color: AppColors.primaryGreen,
                        isLarge: true,
                      ),
                      
                      // Vertical line for intermediate stops
                      if (hasIntermediateStops) ...[
                        for (int i = 0; i < relevantStops.length; i++) ...[
                          _buildVerticalLine(isDark),
                          _buildRouteIndicator(
                            icon: Icons.location_on,
                            color: AppColors.primaryYellow,
                            isLarge: false,
                          ),
                        ],
                      ],
                      
                      // Vertical line to dropoff
                      _buildVerticalLine(isDark),
                      
                      // Dropoff indicator
                      _buildRouteIndicator(
                        icon: Icons.location_on,
                        color: AppColors.error,
                        isLarge: true,
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: AppSpacing.md),
                  
                  // Location details column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Use routeStopsWithTiming if available to get accurate times
                        if (widget.ride.routeStopsWithTiming != null && widget.ride.routeStopsWithTiming!.isNotEmpty) ...[
                          // Filter stops to show only passenger's journey (from pickup to dropoff)
                          ...() {
                            final passengerStops = <Widget>[];
                            bool foundPickup = false;
                            bool foundDropoff = false;
                            
                            for (int i = 0; i < widget.ride.routeStopsWithTiming!.length; i++) {
                              final stop = widget.ride.routeStopsWithTiming![i];
                              final isPickup = stop.location.toLowerCase().contains(widget.pickupLocation.toLowerCase()) ||
                                               widget.pickupLocation.toLowerCase().contains(stop.location.toLowerCase());
                              final isDropoff = stop.location.toLowerCase().contains(widget.dropoffLocation.toLowerCase()) ||
                                                widget.dropoffLocation.toLowerCase().contains(stop.location.toLowerCase());
                              
                              if (isPickup) {
                                foundPickup = true;
                                passengerStops.add(_buildLocationItem(
                                  label: 'Pickup',
                                  location: widget.pickupLocation,
                                  time: stop.arrivalTime,
                                  isDark: isDark,
                                  isHighlight: true,
                                ));
                              } else if (isDropoff) {
                                foundDropoff = true;
                                passengerStops.add(_buildLocationItem(
                                  label: 'Dropoff',
                                  location: widget.dropoffLocation,
                                  time: stop.arrivalTime,
                                  isDark: isDark,
                                  isHighlight: true,
                                ));
                                break; // Stop after dropoff
                              } else if (foundPickup && !foundDropoff) {
                                // This is an intermediate stop between pickup and dropoff
                                passengerStops.add(_buildLocationItem(
                                  label: 'Stop',
                                  location: stop.location,
                                  time: stop.arrivalTime,
                                  isDark: isDark,
                                  isHighlight: false,
                                ));
                              }
                            }
                            
                            return passengerStops;
                          }(),
                        ] else ...[
                          // Fallback to old method if routeStopsWithTiming not available
                          _buildLocationItem(
                            label: 'Pickup',
                            location: widget.pickupLocation,
                            time: widget.ride.departureTime,
                            isDark: isDark,
                            isHighlight: true,
                          ),
                          
                          // Intermediate stops with arrival times
                          if (hasIntermediateStops) ...[
                            for (int i = 0; i < relevantStops.length; i++)
                              _buildLocationItem(
                                label: 'Stop',
                                location: relevantStops[i],
                                time: _getStopArrivalTime(relevantStops[i]),
                                isDark: isDark,
                                isHighlight: false,
                              ),
                          ],
                          
                          // Dropoff location with arrival time
                          _buildLocationItem(
                            label: 'Dropoff',
                            location: widget.dropoffLocation,
                            time: _getStopArrivalTime(widget.dropoffLocation),
                            isDark: isDark,
                            isHighlight: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                ),
              ),
              
              // Journey summary
              if (hasIntermediateStops) ...[
                const SizedBox(height: AppSpacing.md),
                Divider(
                  color: isDark 
                      ? AppColors.darkBorder.withOpacity(0.5)
                      : AppColors.lightBorder.withOpacity(0.5),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: isDark ? AppColors.darkTextSecondary : const Color(0xFF757575),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Driver has scheduled ${relevantStops.length} intermediate stop${relevantStops.length > 1 ? 's' : ''} on this route',
                        style: TextStyles.caption.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF757575),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
  
  /// Build route indicator icon
  Widget _buildRouteIndicator({
    required IconData icon,
    required Color color,
    required bool isLarge,
  }) {
    final size = isLarge ? 24.0 : 16.0;
    final containerSize = isLarge ? 32.0 : 24.0;
    
    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: isLarge ? 2 : 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: size * 0.7,
          color: color,
        ),
      ),
    );
  }
  
  /// Build vertical line connector
  Widget _buildVerticalLine(bool isDark) {
    return Container(
      width: 2,
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withOpacity(0.5),
            AppColors.primaryYellow.withOpacity(0.5),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
  
  /// Build location item with label and details
  Widget _buildLocationItem({
    required String label,
    required String location,
    required String? time,
    required bool isDark,
    required bool isHighlight,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Text(
            label.toUpperCase(),
            style: TextStyles.caption.copyWith(
              color: isHighlight
                  ? (isDark ? AppColors.primaryYellow : const Color(0xFFF57C00))
                  : (isDark ? AppColors.darkTextSecondary : const Color(0xFF9E9E9E)),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          
          // Location
          Text(
            location,
            style: TextStyles.bodyMedium.copyWith(
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF212121),
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Time if provided
          if (time != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF757575),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTimeTo12Hour(time),
                  style: TextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  /// Get intermediate stops that are relevant to passenger's journey
  /// (between their pickup and dropoff locations)
  List<String> _getRelevantIntermediateStops() {
    // If ride has no intermediate stops, return empty list
    if (widget.ride.intermediateStops == null || 
        widget.ride.intermediateStops!.isEmpty) {
      return [];
    }
    
    // Build complete route: driver's pickup -> all stops -> driver's dropoff
    final completeRoute = [
      widget.ride.pickupLocation,
      ...widget.ride.intermediateStops!,
      widget.ride.dropoffLocation,
    ];
    
    print('🔍 Complete route: $completeRoute');
    
    // Find indices using flexible matching (contains check)
    int passengerPickupIndex = -1;
    int passengerDropoffIndex = -1;
    
    for (int i = 0; i < completeRoute.length; i++) {
      final location = completeRoute[i].toLowerCase();
      if (location.contains(widget.pickupLocation.toLowerCase()) ||
          widget.pickupLocation.toLowerCase().contains(location)) {
        passengerPickupIndex = i;
        print('✅ Found pickup at index $i: ${completeRoute[i]}');
      }
      if (location.contains(widget.dropoffLocation.toLowerCase()) ||
          widget.dropoffLocation.toLowerCase().contains(location)) {
        passengerDropoffIndex = i;
        print('✅ Found dropoff at index $i: ${completeRoute[i]}');
      }
    }
    
    // If passenger's locations are not found in route, return all stops
    if (passengerPickupIndex == -1 || 
        passengerDropoffIndex == -1 ||
        passengerDropoffIndex <= passengerPickupIndex) {
      print('⚠️ Could not find valid pickup/dropoff indices, returning all stops');
      return widget.ride.intermediateStops!;
    }
    
    // Extract stops between passenger's pickup and dropoff
    // (Excluding pickup and dropoff themselves)
    final relevantStops = completeRoute.sublist(
      passengerPickupIndex + 1,
      passengerDropoffIndex,
    );
    
    print('✅ Filtered ${relevantStops.length} relevant stops: $relevantStops');
    
    return relevantStops;
  }

  /// Get arrival time for a specific stop from route timing information
  String? _getStopArrivalTime(String location) {
    if (widget.ride.routeStopsWithTiming == null) {
      return null;
    }

    // Find the stop matching this location
    for (var stop in widget.ride.routeStopsWithTiming!) {
      if (stop.location.toLowerCase() == location.toLowerCase() ||
          stop.location.toLowerCase().contains(location.toLowerCase()) ||
          location.toLowerCase().contains(stop.location.toLowerCase())) {
        return stop.arrivalTime;
      }
    }

    return null;
  }
  
  /// Parse departure time string (HH:mm format) to Duration
  Duration _parseDepartureTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        return Duration(hours: hours, minutes: minutes);
      }
    } catch (e) {
      print('Error parsing departure time: $e');
    }
    return Duration.zero;
  }
}
