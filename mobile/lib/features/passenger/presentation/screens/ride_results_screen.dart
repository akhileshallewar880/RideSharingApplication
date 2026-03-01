import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/core/providers/passenger_ride_provider.dart';
import 'package:allapalli_ride/core/models/passenger_ride_models.dart';
import 'package:allapalli_ride/features/passenger/presentation/screens/ride_checkout_screen.dart';
import 'package:intl/intl.dart';

/// Full-screen ride results matching RedBus design
class RideResultsScreen extends ConsumerStatefulWidget {
  final Location pickupLocation;
  final Location dropoffLocation;
  final DateTime travelDate;
  final int passengerCount;
  
  const RideResultsScreen({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.travelDate,
    required this.passengerCount,
  });
  
  @override
  ConsumerState<RideResultsScreen> createState() => _RideResultsScreenState();
}

class _RideResultsScreenState extends ConsumerState<RideResultsScreen> {
  String _sortBy = 'departure'; // departure, price, duration, rating
  late DateTime _selectedDate;
  int? _selectedSeatCapacity; // null means all capacities
  
  @override
  void initState() {
    super.initState();
    _selectedDate = widget.travelDate;
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(passengerRideNotifierProvider);
    final rides = _getSortedRides(state.availableRides);
    
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
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header with route info
          _buildHeader(isDark),
          
          // Filter buttons
          _buildFilterBar(isDark),
          
          // Rides list or loading/error state
          Expanded(
            child: _buildContent(isDark, state, rides),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Back button
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 24),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Route and rides count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.pickupLocation.address,
                          style: TextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: isDark 
                              ? AppColors.darkTextSecondary 
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          widget.dropoffLocation.address,
                          style: TextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ref.watch(passengerRideNotifierProvider).availableRides.length} Rides',
                    style: TextStyles.caption.copyWith(
                      color: isDark 
                          ? AppColors.darkTextSecondary 
                          : AppColors.lightTextSecondary.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Date badge - clickable
            GestureDetector(
              onTap: () => _showDatePicker(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBg : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('dd MMM').format(_selectedDate),
                          style: TextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          DateFormat('E').format(_selectedDate),
                          style: TextStyles.caption.copyWith(
                            color: isDark 
                                ? AppColors.darkTextSecondary 
                                : AppColors.lightTextSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: isDark 
                          ? AppColors.darkTextSecondary 
                          : AppColors.lightTextSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              'Filter & Sort',
              Icons.tune,
              isDark,
              onTap: _showSortOptions,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              '4 Seater',
              Icons.directions_car_outlined,
              isDark,
              isActive: _selectedSeatCapacity == 4,
              onTap: () => _filterBySeatCapacity(4),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              '7 Seater',
              Icons.airport_shuttle_outlined,
              isDark,
              isActive: _selectedSeatCapacity == 7,
              onTap: () => _filterBySeatCapacity(7),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              '8+ Seater',
              Icons.airport_shuttle_outlined,
              isDark,
              isActive: _selectedSeatCapacity == 8,
              onTap: () => _filterBySeatCapacity(8),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterChip(String label, IconData icon, bool isDark, {bool isActive = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive 
              ? AppColors.primaryYellow.withOpacity(0.15)
              : (isDark ? AppColors.darkCardBg : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive 
                ? AppColors.primaryYellow
                : (isDark ? AppColors.darkBorder : const Color(0xFFE0E0E0)),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive 
                  ? AppColors.primaryYellow
                  : (isDark ? AppColors.darkTextPrimary : const Color(0xFF424242)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyles.bodySmall.copyWith(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
                color: isActive 
                    ? AppColors.primaryYellow
                    : (isDark ? AppColors.darkTextPrimary : const Color(0xFF424242)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContent(bool isDark, PassengerRideState state, List<AvailableRide> rides) {
    if (state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.primaryYellow,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Searching for rides...',
              style: TextStyles.bodyMedium.copyWith(
                color: isDark 
                    ? AppColors.darkTextSecondary 
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }
    
    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Search Failed',
                style: TextStyles.headingMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                state.errorMessage!,
                style: TextStyles.bodyMedium.copyWith(
                  color: isDark 
                      ? AppColors.darkTextSecondary 
                      : AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    if (rides.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: AppColors.warning,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'No Rides Available',
                style: TextStyles.headingMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No rides found for the selected date and route',
                style: TextStyles.bodyMedium.copyWith(
                  color: isDark 
                      ? AppColors.darkTextSecondary 
                      : AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: rides.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ride = rides[index];
        return _buildRideCard(ride, isDark, index);
      },
    );
  }
  
  Widget _buildRideCard(AvailableRide ride, bool isDark, int index) {
    // Calculate discount badge
    String? discountBadge;
    Color? badgeColor;
    if (index == 0) {
      discountBadge = 'Last min. 10% OFF';
      badgeColor = const Color(0xFFFFF4E6);
    } else if (index == 1) {
      discountBadge = 'Exclusive 12.5% OFF';
      badgeColor = const Color(0xFFFFF4E6);
    }
    
    return InkWell(
      onTap: () => _selectRide(ride),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row with available seats (left) and discount badge (right)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Available seats on the left
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? AppColors.primaryGreen.withOpacity(0.2)
                          : AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.primaryGreen.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.airline_seat_recline_normal,
                          size: 16,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${ride.availableSeats} Seats Left',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark 
                                ? AppColors.primaryGreen.withOpacity(0.9)
                                : AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Discount badge on the right
                  if (discountBadge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        discountBadge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE65100),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "STARTING" label
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF3949AB).withOpacity(0.2) : const Color(0xFFE8EAF6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'STARTING',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF9FA8DA) : const Color(0xFF3949AB),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Route display with intermediate stops
                  _buildCompactRoute(ride, isDark),
                  
                  const SizedBox(height: 16),
                  
                  // Time and Price row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Departure time - Duration - Arrival time with locations
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              _formatTimeTo12Hour(ride.departureTime),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: isDark 
                                    ? AppColors.darkTextPrimary 
                                    : const Color(0xFF212121),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                '—',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark 
                                      ? AppColors.darkTextSecondary 
                                      : const Color(0xFF9E9E9E),
                                ),
                              ),
                            ),
                            Text(
                              _getJourneyDuration(ride),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark 
                                    ? AppColors.darkTextSecondary 
                                    : const Color(0xFF757575),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                '—',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark 
                                      ? AppColors.darkTextSecondary 
                                      : const Color(0xFF9E9E9E),
                                ),
                              ),
                            ),
                            Text(
                              _getArrivalTime(ride),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: isDark 
                                    ? AppColors.darkTextPrimary 
                                    : const Color(0xFF212121),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${ride.pricePerSeat.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark 
                                  ? AppColors.darkTextPrimary 
                                  : const Color(0xFF212121),
                            ),
                          ),
                          Text(
                            'Onwards',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark 
                                  ? AppColors.darkTextSecondary 
                                  : const Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Service provider and rating
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    ride.driverName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isDark 
                                          ? AppColors.darkTextPrimary 
                                          : const Color(0xFF212121),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: isDark ? const Color(0xFF64B5F6) : const Color(0xFF2196F3),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${ride.vehicleType} ${ride.vehicleModel}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark 
                                    ? AppColors.darkTextSecondary 
                                    : const Color(0xFF616161),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            _buildNumberPlate(ride.vehicleNumber, isDark),
                          ],
                        ),
                      ),
                      
                      // Rating badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ride.driverRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Review count
                      Text(
                        '(${ride.driverRatingCount})',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark 
                              ? AppColors.darkTextSecondary 
                              : const Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                  
                  // Special note (for some rides)
                  if (index == 1) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? const Color(0xFFE1BEE7).withOpacity(0.2) 
                            : const Color(0xFFFCE4EC),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Exclusive discounts available for women passengers',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark 
                              ? const Color(0xFFCE93D8) 
                              : const Color(0xFFC2185B),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
  
  void _filterBySeatCapacity(int seatCapacity) {
    setState(() {
      if (_selectedSeatCapacity == seatCapacity) {
        // Deselect if clicking the same filter
        _selectedSeatCapacity = null;
        print('🔍 Filter cleared');
      } else {
        _selectedSeatCapacity = seatCapacity;
        print('🔍 Filter applied: $seatCapacity seater');
      }
    });
  }
  
  Future<void> _showDatePicker(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: AppColors.primaryGreen,
                    onPrimary: Colors.white,
                    surface: AppColors.darkSurface,
                    onSurface: Colors.white,
                  )
                : ColorScheme.light(
                    primary: AppColors.primaryGreen,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      
      // Search for rides on the new date
      await _searchRidesForDate(picked);
    }
  }
  
  Future<void> _searchRidesForDate(DateTime date) async {
    final request = SearchRidesRequest(
      pickupLocationId: widget.pickupLocation.id,
      dropoffLocationId: widget.dropoffLocation.id,
      travelDate: DateFormat('yyyy-MM-dd').format(date),
      passengerCount: widget.passengerCount,
    );
    
    await ref.read(passengerRideNotifierProvider.notifier).searchRides(request);
    
    // Show feedback to user
    if (mounted) {
      final state = ref.read(passengerRideNotifierProvider);
      if (state.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Found ${state.availableRides.length} rides for ${DateFormat('dd MMM yyyy').format(date)}',
            ),
            backgroundColor: AppColors.primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  String _calculateArrivalTime(String departureTime, String? estimatedDuration) {
    try {
      if (estimatedDuration == null || estimatedDuration.isEmpty) return 'N/A';
      
      // Parse departure time (format: "HH:mm")
      final depParts = departureTime.split(':');
      if (depParts.length != 2) return 'N/A';
      
      int depHour = int.parse(depParts[0]);
      int depMinute = int.parse(depParts[1]);
      
      // Parse duration - handle both "H:mm" format (e.g., "5:08") and "Xh Ym" format
      int durationMinutes = 0;
      
      if (estimatedDuration.contains(':')) {
        // Format: "H:mm" or "HH:mm" (e.g., "5:08" for 5 hours 8 minutes)
        final durationParts = estimatedDuration.split(':');
        if (durationParts.length == 2) {
          final hours = int.tryParse(durationParts[0]) ?? 0;
          final minutes = int.tryParse(durationParts[1]) ?? 0;
          durationMinutes = hours * 60 + minutes;
        }
      } else {
        // Format: "Xh Ym" or similar
        if (estimatedDuration.contains('h')) {
          final hours = int.tryParse(estimatedDuration.split('h')[0].trim()) ?? 0;
          durationMinutes += hours * 60;
        }
        if (estimatedDuration.contains('m')) {
          final minutesPart = estimatedDuration.contains('h') 
              ? estimatedDuration.split('h')[1] 
              : estimatedDuration;
          final minutes = int.tryParse(minutesPart.replaceAll('m', '').trim()) ?? 0;
          durationMinutes += minutes;
        }
      }
      
      // Calculate arrival time
      int totalMinutes = depHour * 60 + depMinute + durationMinutes;
      int arrHour = (totalMinutes ~/ 60) % 24;
      int arrMinute = totalMinutes % 60;
      
      String arrivalTime24 = '${arrHour.toString().padLeft(2, '0')}:${arrMinute.toString().padLeft(2, '0')}';
      return _formatTimeTo12Hour(arrivalTime24);
    } catch (e) {
      return 'N/A';
    }
  }
  
  String _getArrivalTime(AvailableRide ride) {
    // Debug: Log the route stops
    if (ride.routeStopsWithTiming != null && ride.routeStopsWithTiming!.isNotEmpty) {
      print('🚕 Ride ${ride.rideId} route stops:');
      for (var stop in ride.routeStopsWithTiming!) {
        print('   ${stop.location} → ${stop.arrivalTime} (${stop.cumulativeDurationMinutes}min)');
      }
      print('   Passenger dropoff search: ${widget.dropoffLocation.address}');
      
      // For passenger-specific routes (2 stops), the last stop is always the dropoff
      if (ride.routeStopsWithTiming!.length == 2) {
        final dropoffStop = ride.routeStopsWithTiming!.last;
        print('✅ Using passenger dropoff time: ${dropoffStop.arrivalTime}');
        return _formatTimeTo12Hour(dropoffStop.arrivalTime);
      }
      
      // For routes with more stops, try to find the matching dropoff
      // Strategy 1: Exact match (case-insensitive)
      for (var stop in ride.routeStopsWithTiming!) {
        if (stop.location.toLowerCase() == widget.dropoffLocation.address.toLowerCase()) {
          print('🎯 Exact match found for dropoff: ${stop.location}');
          return _formatTimeTo12Hour(stop.arrivalTime);
        }
      }
      
      // Strategy 2: Contains match (either direction)
      for (var stop in ride.routeStopsWithTiming!) {
        if (stop.location.toLowerCase().contains(widget.dropoffLocation.address.toLowerCase()) ||
            widget.dropoffLocation.address.toLowerCase().contains(stop.location.toLowerCase())) {
          print('🎯 Contains match found for dropoff: ${stop.location}');
          return _formatTimeTo12Hour(stop.arrivalTime);
        }
      }
      
      // Strategy 3: Partial city/landmark match (split by comma and match first part)
      final searchDropoffParts = widget.dropoffLocation.address.split(',');
      final searchDropoffCity = searchDropoffParts.isNotEmpty ? searchDropoffParts.first.trim().toLowerCase() : '';
      
      for (var stop in ride.routeStopsWithTiming!) {
        final stopParts = stop.location.split(',');
        final stopCity = stopParts.isNotEmpty ? stopParts.first.trim().toLowerCase() : '';
        
        if (searchDropoffCity.isNotEmpty && stopCity.isNotEmpty && searchDropoffCity == stopCity) {
          print('🎯 City match found for dropoff: ${stop.location}');
          return _formatTimeTo12Hour(stop.arrivalTime);
        }
      }
      
      // If no match found, use the last stop as fallback
      print('⚠️ No exact match for dropoff "${widget.dropoffLocation.address}", using last stop');
      final lastStop = ride.routeStopsWithTiming!.last;
      return _formatTimeTo12Hour(lastStop.arrivalTime);
    }
    
    // Fallback to calculating from departure time and duration
    print('⚠️ No route stops available, calculating from departure + duration');
    return _calculateArrivalTime(ride.departureTime, ride.estimatedDuration);
  }

  String _getJourneyDuration(AvailableRide ride) {
    // If routeStopsWithTiming is available, calculate passenger's journey duration
    if (ride.routeStopsWithTiming != null && ride.routeStopsWithTiming!.isNotEmpty) {
      
      // For passenger-specific routes (2 stops), use the cumulative duration of last stop
      if (ride.routeStopsWithTiming!.length == 2) {
        final durationMinutes = ride.routeStopsWithTiming!.last.cumulativeDurationMinutes;
        print('✅ Passenger journey duration (2-stop): ${durationMinutes}min');
        
        final hours = durationMinutes ~/ 60;
        final minutes = durationMinutes % 60;
        
        if (hours > 0 && minutes > 0) {
          return '${hours}hr ${minutes}m';
        } else if (hours > 0) {
          return '${hours}hr';
        } else if (minutes > 0) {
          return '${minutes}m';
        }
      }
      
      // For routes with more stops, calculate from pickup to dropoff
      int? pickupDuration;
      int? dropoffDuration;
      
      // Find pickup and dropoff cumulative durations using multiple matching strategies
      for (var stop in ride.routeStopsWithTiming!) {
        // Match pickup location
        if (pickupDuration == null) {
          // Exact match
          if (stop.location.toLowerCase() == widget.pickupLocation.address.toLowerCase()) {
            pickupDuration = stop.cumulativeDurationMinutes;
            print('🎯 Exact match found for pickup: ${stop.location} at ${pickupDuration}min');
          }
          // Contains match
          else if (stop.location.toLowerCase().contains(widget.pickupLocation.address.toLowerCase()) ||
              widget.pickupLocation.address.toLowerCase().contains(stop.location.toLowerCase())) {
            pickupDuration = stop.cumulativeDurationMinutes;
            print('🎯 Contains match found for pickup: ${stop.location} at ${pickupDuration}min');
          }
          // City match (first part before comma)
          else {
            final searchPickupCity = widget.pickupLocation.address.split(',').first.trim().toLowerCase();
            final stopCity = stop.location.split(',').first.trim().toLowerCase();
            if (searchPickupCity.isNotEmpty && searchPickupCity == stopCity) {
              pickupDuration = stop.cumulativeDurationMinutes;
              print('🎯 City match found for pickup: ${stop.location} at ${pickupDuration}min');
            }
          }
        }
        
        // Match dropoff location
        if (dropoffDuration == null) {
          // Exact match
          if (stop.location.toLowerCase() == widget.dropoffLocation.address.toLowerCase()) {
            dropoffDuration = stop.cumulativeDurationMinutes;
            print('🎯 Exact match found for dropoff: ${stop.location} at ${dropoffDuration}min');
          }
          // Contains match
          else if (stop.location.toLowerCase().contains(widget.dropoffLocation.address.toLowerCase()) ||
              widget.dropoffLocation.address.toLowerCase().contains(stop.location.toLowerCase())) {
            dropoffDuration = stop.cumulativeDurationMinutes;
            print('🎯 Contains match found for dropoff: ${stop.location} at ${dropoffDuration}min');
          }
          // City match (first part before comma)
          else {
            final searchDropoffCity = widget.dropoffLocation.address.split(',').first.trim().toLowerCase();
            final stopCity = stop.location.split(',').first.trim().toLowerCase();
            if (searchDropoffCity.isNotEmpty && searchDropoffCity == stopCity) {
              dropoffDuration = stop.cumulativeDurationMinutes;
              print('🎯 City match found for dropoff: ${stop.location} at ${dropoffDuration}min');
            }
          }
        }
      }
      
      // Calculate the difference
      if (pickupDuration != null && dropoffDuration != null) {
        final durationMinutes = dropoffDuration - pickupDuration;
        print('✅ Journey duration calculated: ${durationMinutes}min (pickup: ${pickupDuration}min, dropoff: ${dropoffDuration}min)');
        
        final hours = durationMinutes ~/ 60;
        final minutes = durationMinutes % 60;
        
        if (hours > 0 && minutes > 0) {
          return '${hours}hr ${minutes}m';
        } else if (hours > 0) {
          return '${hours}hr';
        } else if (minutes > 0) {
          return '${minutes}m';
        }
      } else {
        print('⚠️ Could not find matching stops for journey duration calculation');
        print('   Pickup found: ${pickupDuration != null}, Dropoff found: ${dropoffDuration != null}');
      }
    }
    
    // Fallback to ride.estimatedDuration
    print('⚠️ Using estimated duration fallback: ${ride.estimatedDuration}');
    return _formatDuration(ride.estimatedDuration ?? '0:00');
  }

  String _formatDuration(String duration) {
    try {
      // Handle duration format like "5:08" (hours:minutes)
      if (duration.contains(':')) {
        final parts = duration.split(':');
        if (parts.length == 2) {
          final hours = int.tryParse(parts[0]) ?? 0;
          final minutes = int.tryParse(parts[1]) ?? 0;
          
          if (hours > 0 && minutes > 0) {
            return '${hours}hr ${minutes}m';
          } else if (hours > 0) {
            return '${hours}hr';
          } else if (minutes > 0) {
            return '${minutes}m';
          }
        }
      }
      
      // Handle duration format like "5h 8m"
      if (duration.contains('h') || duration.contains('m')) {
        return duration;
      }
      
      return duration;
    } catch (e) {
      return duration;
    }
  }
  
  String _getShortName(String location) {
    final parts = location.split(',');
    return parts.first.trim();
  }
  
  String _calculateDuration(String departureTime, String arrivalTime) {
    // Simple duration calculation (you can enhance this)
    try {
      final depTime = TimeOfDay(
        hour: int.parse(departureTime.split(':')[0]),
        minute: int.parse(departureTime.split(':')[1]),
      );
      final arrTime = TimeOfDay(
        hour: int.parse(arrivalTime.split(':')[0]),
        minute: int.parse(arrivalTime.split(':')[1]),
      );
      
      int depMinutes = depTime.hour * 60 + depTime.minute;
      int arrMinutes = arrTime.hour * 60 + arrTime.minute;
      
      if (arrMinutes < depMinutes) {
        arrMinutes += 24 * 60; // Next day
      }
      
      final diff = arrMinutes - depMinutes;
      final hours = diff ~/ 60;
      final minutes = diff % 60;
      
      return '${hours}h ${minutes}m';
    } catch (e) {
      return 'N/A';
    }
  }
  
  String _getSeatTypeText(int availableSeats) {
    if (availableSeats <= 2) {
      return '$availableSeats Single';
    } else if (availableSeats <= 4) {
      return '${availableSeats ~/ 2} Single';
    } else {
      return '${availableSeats ~/ 2} Single';
    }
  }
  
  List<AvailableRide> _getSortedRides(List<AvailableRide> rides) {
    // First filter by seat capacity if selected
    var filteredRides = rides;
    if (_selectedSeatCapacity != null) {
      print('🚗 Filtering by seat capacity: $_selectedSeatCapacity');
      filteredRides = rides.where((ride) {
        print('  Checking vehicle seating capacity: ${ride.vehicleSeatingCapacity}');
        // For 8+ seater filter, match 8 or more seats. Otherwise exact match.
        final matches = _selectedSeatCapacity == 8 
            ? ride.vehicleSeatingCapacity >= 8 
            : ride.vehicleSeatingCapacity == _selectedSeatCapacity;
        print('  Matches: $matches');
        return matches;
      }).toList();
      print('🚗 Filtered rides count: ${filteredRides.length}');
    }
    
    // Then sort the filtered rides
    final sortedRides = List<AvailableRide>.from(filteredRides);
    
    switch (_sortBy) {
      case 'price':
        sortedRides.sort((a, b) => a.pricePerSeat.compareTo(b.pricePerSeat));
        break;
      case 'duration':
        sortedRides.sort((a, b) {
          final durationA = _parseDurationMinutes(a.estimatedDuration);
          final durationB = _parseDurationMinutes(b.estimatedDuration);
          return durationA.compareTo(durationB);
        });
        break;
      case 'departure':
      default:
        sortedRides.sort((a, b) => a.departureTime.compareTo(b.departureTime));
        break;
    }
    
    return sortedRides;
  }
  
  int _parseDurationMinutes(String? duration) {
    if (duration == null) return 0;
    
    try {
      int totalMinutes = 0;
      if (duration.contains('h')) {
        final hours = int.tryParse(duration.split('h')[0].trim()) ?? 0;
        totalMinutes += hours * 60;
      }
      if (duration.contains('m')) {
        final minutesPart = duration.contains('h') 
            ? duration.split('h')[1] 
            : duration;
        final minutes = int.tryParse(minutesPart.replaceAll('m', '').trim()) ?? 0;
        totalMinutes += minutes;
      }
      return totalMinutes;
    } catch (e) {
      return 0;
    }
  }
  
  int _calculateDurationMinutes(String departureTime, String arrivalTime) {
    try {
      final depTime = TimeOfDay(
        hour: int.parse(departureTime.split(':')[0]),
        minute: int.parse(departureTime.split(':')[1]),
      );
      final arrTime = TimeOfDay(
        hour: int.parse(arrivalTime.split(':')[0]),
        minute: int.parse(arrivalTime.split(':')[1]),
      );
      
      int depMinutes = depTime.hour * 60 + depTime.minute;
      int arrMinutes = arrTime.hour * 60 + arrTime.minute;
      
      if (arrMinutes < depMinutes) {
        arrMinutes += 24 * 60;
      }
      
      return arrMinutes - depMinutes;
    } catch (e) {
      return 0;
    }
  }
  
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sort By',
                style: TextStyles.headingMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                title: const Text('Departure Time'),
                trailing: _sortBy == 'departure' ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _sortBy = 'departure');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Price (Low to High)'),
                trailing: _sortBy == 'price' ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _sortBy = 'price');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Duration'),
                trailing: _sortBy == 'duration' ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _sortBy = 'duration');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildNumberPlate(String vehicleNumber, bool isDark) {
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
  
  void _selectRide(AvailableRide ride) {
    // Navigate directly to checkout screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideCheckoutScreen(
          ride: ride,
          pickupLocation: widget.pickupLocation.address,
          dropoffLocation: widget.dropoffLocation.address,
          travelDate: widget.travelDate,
          passengerCount: widget.passengerCount,
          pickupLocationId: widget.pickupLocation.id,
          dropoffLocationId: widget.dropoffLocation.id,
        ),
      ),
    );
  }
  
  /// Build compact route display showing pickup, first few stops, and "X more stops"
  Widget _buildCompactRoute(AvailableRide ride, bool isDark) {
    // Get relevant stops between passenger's pickup and dropoff
    final relevantStops = _getRelevantStopsForDisplay(ride);
    
    // Extract short names (before comma)
    String getShortName(String location) {
      final parts = location.split(',');
      return parts.first.trim();
    }
    
    return Row(
      children: [
        Expanded(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            text: TextSpan(
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark 
                    ? AppColors.darkTextSecondary 
                    : const Color(0xFF616161),
              ),
              children: [
                TextSpan(text: 'From: '),
                TextSpan(
                  text: getShortName(widget.pickupLocation.address),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark 
                        ? AppColors.darkTextPrimary 
                        : const Color(0xFF212121),
                  ),
                ),
                // Show first intermediate stop if exists
                if (relevantStops.isNotEmpty) ...[
                  TextSpan(text: '  ▸  '),
                  TextSpan(
                    text: getShortName(relevantStops.first),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark 
                          ? AppColors.darkTextPrimary 
                          : const Color(0xFF212121),
                    ),
                  ),
                ],
                // Show "X more stops" if there are more than 1 stop
                if (relevantStops.length > 1) ...[
                  TextSpan(text: '  ▸  '),
                  TextSpan(
                    text: '${relevantStops.length - 1} Other Stop${relevantStops.length - 1 > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark 
                          ? AppColors.primaryYellow 
                          : const Color(0xFFF57C00),
                    ),
                  ),
                ],
                // Show dropoff
                TextSpan(text: '  ▸  '),
                TextSpan(
                  text: getShortName(widget.dropoffLocation.address),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark 
                        ? AppColors.darkTextPrimary 
                        : const Color(0xFF212121),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  /// Get relevant stops for display (between passenger's pickup and dropoff)
  List<String> _getRelevantStopsForDisplay(AvailableRide ride) {
    if (ride.intermediateStops == null || ride.intermediateStops!.isEmpty) {
      print('🔍 No intermediate stops for ride ${ride.rideId}');
      return [];
    }
    
    print('🔍 Processing intermediate stops for ride ${ride.rideId}:');
    print('   Ride route: ${ride.pickupLocation} → ${ride.dropoffLocation}');
    print('   Intermediate stops: ${ride.intermediateStops}');
    print('   Passenger searching: ${widget.pickupLocation.address} → ${widget.dropoffLocation.address}');
    
    // Build complete route
    final completeRoute = [
      ride.pickupLocation,
      ...ride.intermediateStops!,
      ride.dropoffLocation,
    ];
    
    // Extract city/town name for more flexible matching
    String extractCityName(String location) {
      // Extract text before first comma or the whole string
      final parts = location.split(',');
      return parts.first.trim().toLowerCase();
    }
    
    final passengerPickupCity = extractCityName(widget.pickupLocation.address);
    final passengerDropoffCity = extractCityName(widget.dropoffLocation.address);
    
    // Find indices using flexible city name matching
    int passengerPickupIndex = -1;
    int passengerDropoffIndex = -1;
    
    for (int i = 0; i < completeRoute.length; i++) {
      final locationCity = extractCityName(completeRoute[i]);
      
      // Check pickup match
      if (passengerPickupIndex == -1) {
        if (locationCity == passengerPickupCity ||
            locationCity.contains(passengerPickupCity) ||
            passengerPickupCity.contains(locationCity)) {
          passengerPickupIndex = i;
          print('   ✓ Found pickup at index $i: ${completeRoute[i]}');
        }
      }
      
      // Check dropoff match
      if (passengerDropoffIndex == -1) {
        if (locationCity == passengerDropoffCity ||
            locationCity.contains(passengerDropoffCity) ||
            passengerDropoffCity.contains(locationCity)) {
          passengerDropoffIndex = i;
          print('   ✓ Found dropoff at index $i: ${completeRoute[i]}');
        }
      }
    }
    
    // If not found or invalid, return all intermediate stops (fallback)
    if (passengerPickupIndex == -1 || passengerDropoffIndex == -1) {
      print('   ⚠️ Could not match passenger route, showing all intermediate stops');
      return ride.intermediateStops!;
    }
    
    if (passengerDropoffIndex <= passengerPickupIndex) {
      print('   ⚠️ Invalid route order, showing all intermediate stops');
      return ride.intermediateStops!;
    }
    
    // Return stops between pickup and dropoff
    final relevantStops = completeRoute.sublist(
      passengerPickupIndex + 1,
      passengerDropoffIndex,
    );
    print('   → Relevant stops to display: $relevantStops');
    return relevantStops;
  }
}
