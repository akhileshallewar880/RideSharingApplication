import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/shared/widgets/buttons.dart';
import 'package:allapalli_ride/shared/widgets/indian_number_plate.dart';
import 'package:allapalli_ride/features/passenger/domain/models/vehicle_option.dart';
import 'package:allapalli_ride/features/passenger/domain/models/location_suggestion.dart';
import 'package:allapalli_ride/features/passenger/presentation/screens/ride_details_screen.dart';
import 'package:allapalli_ride/features/passenger/presentation/screens/profile_screen.dart';
import 'package:allapalli_ride/features/passenger/presentation/screens/ride_history_screen.dart';
import 'package:allapalli_ride/features/passenger/presentation/screens/location_search_screen.dart';
import 'package:allapalli_ride/features/passenger/presentation/screens/ride_results_screen.dart';
import 'package:allapalli_ride/features/passenger/presentation/screens/area_not_served_screen.dart';
import 'package:allapalli_ride/features/passenger/presentation/screens/passenger_live_tracking_screen.dart';
import 'package:allapalli_ride/features/passenger/presentation/widgets/location_search_field.dart';
import 'package:allapalli_ride/features/passenger/presentation/widgets/ride_search_loading_screen.dart';
import 'package:allapalli_ride/features/passenger/presentation/widgets/rate_ride_bottom_sheet.dart';
import 'package:allapalli_ride/core/providers/location_provider.dart';
import 'package:allapalli_ride/core/services/location_service.dart';
import 'package:allapalli_ride/core/providers/passenger_ride_provider.dart';
import 'package:allapalli_ride/core/models/passenger_ride_models.dart';
import 'package:allapalli_ride/core/utils/dynamic_status_bar.dart';
import 'package:intl/intl.dart';

/// Passenger home screen with map and ride booking
class PassengerHomeScreen extends ConsumerStatefulWidget {
  final int initialTab;
  
  const PassengerHomeScreen({super.key, this.initialTab = 0});
  
  @override
  ConsumerState<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends ConsumerState<PassengerHomeScreen> with DynamicStatusBarMixin {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  LocationSuggestion? _selectedPickup;
  LocationSuggestion? _selectedDropoff;
  DateTime _selectedDate = DateTime.now(); // Default today
  int _passengerCount = 1; // Default 1 passenger
  int _selectedNavIndex = 0; // Bottom navigation index
  Timer? _pollingTimer; // Timer for periodic ride status refresh
  
  // Cache DateFormat instances to avoid recreating on every build
  static final _dateFormatYMD = DateFormat('yyyy-MM-dd');
  static final _dateFormatDay = DateFormat('dd');
  static final _dateFormatMonth = DateFormat('MMM');
  
  // Vehicle options with real names
  final List<VehicleOption> _vehicles = [
    VehicleOption(
      id: 'auto',
      name: 'Bajaj Auto',
      model: 'RE Compact',
      icon: Icons.electric_rickshaw,
      seats: 3,
      basePrice: 30,
      pricePerKm: 10,
    ),
    VehicleOption(
      id: 'bike',
      name: 'Two Wheeler',
      model: 'Honda Activa / Hero Splendor',
      icon: Icons.two_wheeler,
      seats: 1,
      basePrice: 20,
      pricePerKm: 8,
    ),
    VehicleOption(
      id: 'sedan',
      name: 'Maruti Suzuki Dzire',
      model: 'Sedan',
      icon: Icons.directions_car,
      seats: 4,
      basePrice: 50,
      pricePerKm: 15,
    ),
    VehicleOption(
      id: 'suv',
      name: 'Mahindra Bolero',
      model: 'SUV',
      icon: Icons.local_shipping,
      seats: 7,
      basePrice: 80,
      pricePerKm: 20,
    ),
    VehicleOption(
      id: 'ertiga',
      name: 'Maruti Suzuki Ertiga',
      model: 'MUV',
      icon: Icons.airport_shuttle,
      seats: 6,
      basePrice: 70,
      pricePerKm: 18,
    ),
    VehicleOption(
      id: 'innova',
      name: 'Toyota Innova Crysta',
      model: 'Premium MUV',
      icon: Icons.directions_car_filled,
      seats: 7,
      basePrice: 100,
      pricePerKm: 25,
    ),
  ];
  
  bool _hasShownRatingPrompt = false;

  @override
  void initState() {
    super.initState();
    _selectedNavIndex = widget.initialTab;
    _startHeaderAnimation();
    // Check user's location on app launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserLocation();
      // Load ride history to check for scheduled rides
      ref.read(passengerRideNotifierProvider.notifier).loadRideHistory();
      // Load banners from server
      _loadBanners();
      // Show rating prompt after data loads
      _showRatingPromptIfNeeded();
      // Start periodic polling to refresh ride status every 10 seconds
      _startPeriodicRefresh();
    });
  }
  
  void _startHeaderAnimation() {
    // Temporarily disabled to fix hit testing issues
    // _headerAnimationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
    //   if (mounted) {
    //     setState(() {
    //       _showPromoInHeader = !_showPromoInHeader;
    //     });
    //   }
    // });
  }

  Future<void> _loadBanners() async {
    // Banner loading disabled - carousel temporarily disabled to fix layout issues
    // Can be re-enabled once layout constraints are properly configured
    print('🎨 Banner loading skipped (carousel disabled)');
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); // Cancel timer when widget is disposed
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  /// Start periodic refresh to detect trip status changes
  void _startPeriodicRefresh() {
    print('🔄 Starting periodic ride status refresh (every 30 seconds)');
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        print('🔄 Refreshing ride history...');
        ref.read(passengerRideNotifierProvider.notifier).loadRideHistory();
      }
    });
  }

  void _showRatingPromptIfNeeded() {
    // Wait for data to load
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || _hasShownRatingPrompt) return;
      
      final rideState = ref.read(passengerRideNotifierProvider);
      final lastCompletedUnratedRide = rideState.rideHistory.firstWhere(
        (r) => r.status.toLowerCase() == 'completed' && r.rating == null,
        orElse: () => RideHistoryItem(
          bookingNumber: '',
          pickupLocation: '',
          dropoffLocation: '',
          travelDate: '',
          timeSlot: '',
          vehicleType: '',
          totalFare: 0,
          status: '',
        ),
      );
      
      if (lastCompletedUnratedRide.bookingNumber.isNotEmpty) {
        _hasShownRatingPrompt = true;
        _showRatingBottomSheet(lastCompletedUnratedRide);
      }
    });
  }

  void _showRatingBottomSheet(RideHistoryItem ride) {
    // Save the parent context to use after modal is closed
    final parentContext = context;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (modalContext) => RateRideBottomSheet(
        rideId: ride.rideId ?? ride.bookingNumber,
        bookingNumber: ride.bookingNumber,
        driverName: ride.driverName,
        driverRating: ride.driverRating,
        vehicleModel: ride.vehicleModel,
        vehicleNumber: ride.vehicleNumber,
        onSubmit: (rating, feedback) async {
          if (ride.driverId == null || ride.driverId!.isEmpty) {
            throw Exception('Driver ID not available for this ride');
          }
          
          final request = RateRideRequest(
            rating: rating,
            review: feedback.isNotEmpty ? feedback : null,
            driverId: ride.driverId!,
          );
          
          final bookingId = ride.bookingId ?? ride.bookingNumber;
          print('🌟 Submitting rating for booking: $bookingId');
          
          // Close the bottom sheet BEFORE making the API call
          Navigator.of(modalContext).pop(true);
          
          // Now make the API call after the modal is closed
          final success = await ref
              .read(passengerRideNotifierProvider.notifier)
              .rateRide(bookingId, request);
          
          if (!mounted) return;
          
          // Use parent context for SnackBars (not the modal context)
          if (success) {
            print('✅ Rating submitted successfully');
            // Reset flag so prompt can show again for next unrated ride
            _hasShownRatingPrompt = false;
            ScaffoldMessenger.of(parentContext).showSnackBar(
              const SnackBar(
                content: Text('✓ Rating submitted successfully!'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 2),
              ),
            );
            // rateRide already calls loadRideHistory internally
          } else {
            final errorMessage = ref.read(passengerRideNotifierProvider).errorMessage;
            ScaffoldMessenger.of(parentContext).showSnackBar(
              SnackBar(
                content: Text(errorMessage ?? 'Failed to submit rating'),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      ),
    );
  }
  
  Future<void> _checkUserLocation() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      
      print('🔍 Starting location detection...');
      
      // Get current position
      final position = await locationService.getCurrentPosition();
      
      if (position == null) {
        // Permission denied or location unavailable
        // Show a subtle message but allow app to continue
        print('⚠️ Location unavailable - permission denied or service disabled');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please enable location services and grant permission to auto-detect your location. You can manually enter pickup location.'),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _checkUserLocation(),
              ),
            ),
          );
        }
        return;
      }
      
      print('✅ Location detected: ${position.latitude}, ${position.longitude}');
      
      // Check if location is in service area
      final isInServiceArea = locationService.isLocationInServiceArea(
        position.latitude,
        position.longitude,
      );
      
      print('🌍 Service area check: ${isInServiceArea ? "INSIDE" : "OUTSIDE"}');
      
      if (!isInServiceArea) {
        // User is outside service area
        final address = await locationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        
        print('❌ User outside service area: $address');
        
        if (mounted) {
          // Navigate to "Not Served" screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => AreaNotServedScreen(
                currentLocation: address ?? 'Current Location',
              ),
            ),
          );
        }
      } else {
        // User is in service area - auto-populate pickup location
        final nearestLocation = locationService.findNearestLocation(
          position.latitude,
          position.longitude,
        );
        
        print('📍 Nearest location: ${nearestLocation?.name}');
        
        if (nearestLocation != null && mounted) {
          setState(() {
            _selectedPickup = nearestLocation;
            _pickupController.text = nearestLocation.name;
          });
          
          // Show success message after frame is built
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ Pickup location set to ${nearestLocation.name}'),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          });
        }
      }
    } catch (e) {
      print('❌ Error checking user location: $e');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Location error: ${e.toString()}. You can manually enter pickup location.'),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        });
      }
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: today,
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryYellow,
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
    }
  }
  
  Future<void> _handleBookRide() async {
    print('🔍 _handleBookRide called');
    
    if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty) {
      print('❌ Validation failed: empty fields');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter pickup and dropoff locations'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    if (_selectedPickup == null || _selectedDropoff == null) {
      print('❌ Validation failed: no locations selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select locations from suggestions'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    // Format date as YYYY-MM-DD for API
    final formattedDate = _dateFormatYMD.format(_selectedDate);
    
    print('📍 Pickup: ${_selectedPickup!.name} (lat: ${_selectedPickup!.latitude}, lng: ${_selectedPickup!.longitude})');
    print('📍 Dropoff: ${_selectedDropoff!.name} (lat: ${_selectedDropoff!.latitude}, lng: ${_selectedDropoff!.longitude})');
    print('📅 Date: $formattedDate');
    print('👥 Passengers: $_passengerCount');
    
    // Show skeleton loading screen immediately
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RideSearchLoadingScreen(
            pickupLocation: _selectedPickup!.name,
            dropoffLocation: _selectedDropoff!.name,
            travelDate: _selectedDate,
          ),
        ),
      );
    }
    
    // Search for available rides
    final searchRequest = SearchRidesRequest(
      pickupLocation: Location(
        address: _selectedPickup!.fullAddress,
        latitude: _selectedPickup!.latitude ?? 0.0,
        longitude: _selectedPickup!.longitude ?? 0.0,
      ),
      dropoffLocation: Location(
        address: _selectedDropoff!.fullAddress,
        latitude: _selectedDropoff!.latitude ?? 0.0,
        longitude: _selectedDropoff!.longitude ?? 0.0,
      ),
      travelDate: formattedDate,
      passengerCount: _passengerCount,
    );
    
    print('🚀 Search Request: ${searchRequest.toJson()}');
    print('🚀 Calling searchRides API...');
    await ref.read(passengerRideNotifierProvider.notifier).searchRides(searchRequest);
    
    // Navigate to ride results screen after loading
    if (mounted) {
      final state = ref.read(passengerRideNotifierProvider);
      print('✅ Search completed. Found ${state.availableRides.length} rides');
      
      // Replace the loading screen with results screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RideResultsScreen(
            pickupLocation: Location(
              address: _selectedPickup!.fullAddress,
              latitude: _selectedPickup!.latitude ?? 0.0,
              longitude: _selectedPickup!.longitude ?? 0.0,
            ),
            dropoffLocation: Location(
              address: _selectedDropoff!.fullAddress,
              latitude: _selectedDropoff!.latitude ?? 0.0,
              longitude: _selectedDropoff!.longitude ?? 0.0,
            ),
            travelDate: _selectedDate,
            passengerCount: _passengerCount,
          ),
        ),
      );
    }
  }
  
  void _showAvailableRides() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Rides',
                          style: TextStyles.headingMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Consumer(
                          builder: (context, ref, child) {
                            final state = ref.watch(passengerRideNotifierProvider);
                            return Text(
                              '${state.availableRides.length} rides found',
                              style: TextStyles.bodySmall.copyWith(
                                color: isDark 
                                    ? AppColors.darkTextSecondary 
                                    : AppColors.lightTextSecondary,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Rides list
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final state = ref.watch(passengerRideNotifierProvider);
                  
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
                  
                  // Show error state
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
                            const SizedBox(height: AppSpacing.lg),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _handleBookRide();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry Search'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryYellow,
                                foregroundColor: AppColors.lightTextPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xl,
                                  vertical: AppSpacing.md,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  // Show empty state
                  if (state.availableRides.isEmpty) {
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
                              'No rides scheduled for:',
                              style: TextStyles.bodyMedium.copyWith(
                                color: isDark 
                                    ? AppColors.darkTextSecondary 
                                    : AppColors.lightTextSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? AppColors.darkCardBg 
                                    : AppColors.lightCardBg,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: AppColors.success,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _selectedPickup!.name,
                                          style: TextStyles.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: AppColors.error,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _selectedDropoff!.name,
                                          style: TextStyles.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: AppColors.info,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat('dd MMM yyyy').format(_selectedDate),
                                        style: TextStyles.bodySmall.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Try searching for a different date or route',
                              style: TextStyles.bodySmall.copyWith(
                                color: isDark 
                                    ? AppColors.darkTextTertiary 
                                    : AppColors.lightTextTertiary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  // Show rides list
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: state.availableRides.length,
                    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final ride = state.availableRides[index];
                      return _buildRideCard(ride, isDark);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRideCard(AvailableRide ride, bool isDark) {
    return GestureDetector(
      onTap: () => _selectRide(ride),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryYellow.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    color: AppColors.primaryYellow,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.driverName,
                        style: TextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ride.driverRating.toStringAsFixed(1),
                            style: TextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${(ride.pricePerSeat * _passengerCount).toStringAsFixed(0)}',
                      style: TextStyles.headingSmall.copyWith(
                        color: AppColors.primaryYellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'for $_passengerCount seat${_passengerCount > 1 ? 's' : ''}',
                      style: TextStyles.caption.copyWith(
                        color: isDark 
                            ? AppColors.darkTextTertiary 
                            : AppColors.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            
            // Vehicle info
            Row(
              children: [
                Icon(
                  Icons.directions_car,
                  size: 18,
                  color: isDark 
                      ? AppColors.darkTextSecondary 
                      : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${ride.vehicleModel} • ${ride.vehicleNumber}',
                  style: TextStyles.bodySmall.copyWith(
                    color: isDark 
                        ? AppColors.darkTextSecondary 
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            // Departure time and seats
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 18,
                  color: isDark 
                      ? AppColors.darkTextSecondary 
                      : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Departs at ${ride.departureTime}',
                  style: TextStyles.bodySmall.copyWith(
                    color: isDark 
                        ? AppColors.darkTextSecondary 
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.event_seat,
                  size: 18,
                  color: ride.availableSeats >= _passengerCount
                      ? AppColors.success
                      : AppColors.error,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${ride.availableSeats} seats left',
                  style: TextStyles.bodySmall.copyWith(
                    color: ride.availableSeats >= _passengerCount
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _selectRide(AvailableRide ride) {
    if (ride.availableSeats < _passengerCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough seats available. Only ${ride.availableSeats} seats left.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    Navigator.pop(context);
    _confirmRideBooking(ride);
  }
  
  void _confirmRideBooking(AvailableRide ride) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: const Text('Confirm Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Driver: ${ride.driverName}'),
            Text('Vehicle: ${ride.vehicleModel}'),
            Text('Departure: ${ride.departureTime}'),
            Text('Seats: $_passengerCount'),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Total: ₹${(ride.pricePerSeat * _passengerCount).toStringAsFixed(0)}',
              style: TextStyles.headingSmall.copyWith(
                color: AppColors.primaryYellow,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _bookRide(ride);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
            ),
            child: const Text('Confirm Booking'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _bookRide(AvailableRide ride) async {
    final bookRequest = BookRideRequest(
      rideId: ride.rideId,
      passengerCount: _passengerCount,
      pickupLocation: Location(
        address: _selectedPickup!.fullAddress,
        latitude: _selectedPickup!.latitude ?? 0.0,
        longitude: _selectedPickup!.longitude ?? 0.0,
      ),
      dropoffLocation: Location(
        address: _selectedDropoff!.fullAddress,
        latitude: _selectedDropoff!.latitude ?? 0.0,
        longitude: _selectedDropoff!.longitude ?? 0.0,
      ),
      paymentMethod: 'cash',
    );
    
    final success = await ref.read(passengerRideNotifierProvider.notifier).bookRide(bookRequest);
    
    if (mounted) {
      final state = ref.read(passengerRideNotifierProvider);
      if (success && state.currentBooking != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking confirmed! OTP: ${state.currentBooking!.otp}'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 5),
          ),
        );
        
        // Navigate to booking details with the actual booking response
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RideDetailsScreen(
              pickupLocation: state.currentBooking!.pickupLocation,
              dropoffLocation: state.currentBooking!.dropoffLocation,
              vehicle: VehicleOption(
                id: 'auto',
                name: state.currentBooking!.driverDetails.vehicleModel,
                model: state.currentBooking!.driverDetails.vehicleModel,
                icon: Icons.directions_car,
                seats: state.currentBooking!.passengerCount,
                basePrice: state.currentBooking!.totalFare.toInt(),
                pricePerKm: 0,
              ),
              passengerCount: state.currentBooking!.passengerCount,
              travelDate: DateTime.now(), // TODO: Parse from booking
              timeSlot: state.currentBooking!.departureTime,
              bookingResponse: BookingResponse(
                bookingNumber: state.currentBooking!.bookingNumber,
                status: state.currentBooking!.status,
                otp: state.currentBooking!.otp,
                rideId: state.currentBooking!.rideId,
                pickupLocation: state.currentBooking!.pickupLocation,
                dropoffLocation: state.currentBooking!.dropoffLocation,
                departureTime: state.currentBooking!.departureTime,
                passengerCount: state.currentBooking!.passengerCount,
                totalFare: state.currentBooking!.totalFare,
                paymentMethod: state.currentBooking!.paymentStatus,
                paymentStatus: state.currentBooking!.paymentStatus,
                driverDetails: state.currentBooking!.driverDetails,
                bookedAt: '',
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage ?? 'Booking failed'),
            backgroundColor: AppColors.error,
          ),

        );
      }
    }
  }
  
  void _showVehicleOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VehicleTypeSelectionSheet(
        vehicles: _vehicles,
        passengerCount: _passengerCount,
        onVehicleSelected: (vehicle) {
          Navigator.pop(context);
          _showTimeSlots(vehicle);
        },
      ),
    );
  }
  
  void _showTimeSlots(VehicleOption vehicle) {
    // Generate available time slots
    final timeSlots = [
      '06:00 AM', '07:00 AM', '08:00 AM', '09:00 AM', '10:00 AM',
      '11:00 AM', '12:00 PM', '01:00 PM', '02:00 PM', '03:00 PM',
      '04:00 PM', '05:00 PM', '06:00 PM', '07:00 PM', '08:00 PM',
    ];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TimeSlotSelectionSheet(
        vehicle: vehicle,
        timeSlots: timeSlots,
        selectedDate: _selectedDate,
        passengerCount: _passengerCount,
        onTimeSlotSelected: (timeSlot) {
          Navigator.pop(context);
          _confirmBooking(vehicle, timeSlot);
        },
      ),
    );
  }
  
  void _showBookingModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Title
                  Text(
                    'Plan your ride',
                    style: TextStyles.headingLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Pickup location
                  LocationSearchField(
                    hint: 'Pickup location',
                    controller: _pickupController,
                    locationService: ref.read(locationServiceProvider),
                    prefixIcon: Icons.trip_origin,
                    onLocationSelected: (location) {
                      setState(() {
                        _selectedPickup = location;
                      });
                    },
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // Dropoff location
                  LocationSearchField(
                    hint: 'Where do you want to go?',
                    controller: _dropoffController,
                locationService: ref.read(locationServiceProvider),
                prefixIcon: Icons.location_on,
                onLocationSelected: (location) {
                  setState(() {
                    _selectedDropoff = location;
                  });
                },
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Date selector
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                    borderRadius: AppSpacing.borderRadiusMD,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: AppColors.primaryYellow,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Travel Date',
                              style: TextStyles.caption.copyWith(
                                color: isDark 
                                    ? AppColors.darkTextTertiary 
                                    : AppColors.lightTextTertiary,
                              ),
                            ),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: TextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: isDark 
                            ? AppColors.darkTextTertiary 
                            : AppColors.lightTextTertiary,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Passenger count selector
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                  borderRadius: AppSpacing.borderRadiusMD,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 20,
                      color: AppColors.primaryYellow,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'Passengers',
                      style: TextStyles.bodyMedium,
                    ),
                    const Spacer(),
                    // Decrease button
                    IconButton(
                      onPressed: _passengerCount > 1
                          ? () {
                              setModalState(() {
                                setState(() {
                                  _passengerCount--;
                                });
                              });
                            }
                          : null,
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: _passengerCount > 1
                            ? AppColors.primaryYellow
                            : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                      ),
                    ),
                    // Count display
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow.withOpacity(0.1),
                        borderRadius: AppSpacing.borderRadiusSM,
                      ),
                      child: Text(
                        '$_passengerCount',
                        style: TextStyles.headingSmall.copyWith(
                          color: AppColors.primaryYellow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Increase button
                    IconButton(
                      onPressed: _passengerCount < 7
                          ? () {
                              setModalState(() {
                                setState(() {
                                  _passengerCount++;
                                });
                              });
                            }
                          : null,
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: _passengerCount < 7
                            ? AppColors.primaryYellow
                            : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Search button
              Consumer(
                builder: (context, ref, child) {
                  final isLoading = ref.watch(passengerRideNotifierProvider).isLoading;
                  return PrimaryButton(
                    text: 'Search Vehicles',
                    onPressed: isLoading ? null : () async {
                      Navigator.pop(context);
                      await _handleBookRide();
                    },
                    icon: Icons.search,
                    isLoading: isLoading,
                  );
                },
              ),
            ],
          ),
        ),
      );
        },
      ),
    );
  }
  
  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark 
                ? AppColors.darkBorder 
                : AppColors.lightBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryYellow,
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
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
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
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark 
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
  
  
  Widget _buildSuggestionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark 
                    ? AppColors.darkBackground 
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDark 
                    ? AppColors.darkTextPrimary 
                    : AppColors.lightTextPrimary,
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
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyles.caption.copyWith(
                      color: isDark 
                          ? AppColors.darkTextTertiary 
                          : AppColors.lightTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark 
                  ? AppColors.darkTextTertiary 
                  : AppColors.lightTextTertiary,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHomeContent(bool isDark) {
    // Use select to only rebuild when rideHistory changes, not entire state
    final rideHistory = ref.watch(passengerRideNotifierProvider.select((state) => state.rideHistory));
    
    // Check for active verified trip first (passenger has been verified and trip is in progress)
    final activeTrip = rideHistory.firstWhere(
      (r) {
        final statusLower = r.status.toLowerCase();
        return (r.isVerified == true) && 
               (statusLower == 'active' || 
                statusLower == 'in_progress' ||
                statusLower == 'ongoing' ||
                statusLower == 'started' ||
                statusLower == 'in-progress' ||
                statusLower == 'confirmed');
      },
      orElse: () => RideHistoryItem(
        bookingNumber: '',
        pickupLocation: '',
        dropoffLocation: '',
        travelDate: '',
        timeSlot: '',
        vehicleType: '',
        totalFare: 0,
        status: '',
      ),
    );
    
    // Upcoming rides
    final upcomingRides = rideHistory
        .where((r) {
          final statusLower = r.status.toLowerCase();
          return (statusLower == 'scheduled' || statusLower == 'confirmed') && 
                 (r.isVerified != true);
        })
        .toList();
    
    // New Colors
    final deepForestGreen = const Color(0xFF1B5E20);
    final amber = const Color(0xFFFFC107);
    final offWhite = const Color(0xFFF5F5F5);

    return Container(
      color: isDark ? AppColors.darkBackground : offWhite,
      child: SafeArea(
        top: false, // Allow header to go to top
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(passengerRideNotifierProvider.notifier).loadRideHistory();
          },
          color: amber,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stack for Header and Search Card
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 1. The Header Background
                    ClipPath(
                      clipper: _CurvedHeaderClipper(),
                      child: Container(
                        width: double.infinity,
                        height: 280,
                        decoration: BoxDecoration(
                          color: deepForestGreen,
                        ),
                      ),
                    ),

                    // 2. Header Content (Centered in the space above the card)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 180, // Matches the top padding of the card
                      child: SafeArea(
                        bottom: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'VanYatra',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 42,
                                letterSpacing: -1.0,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Book your Rural Ride',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. The "Search" Card (The Hero Section)
                    Padding(
                      padding: const EdgeInsets.only(top: 180, left: 16, right: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardBg : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // From & To Fields with connecting line
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icons Column
                                Column(
                                  children: [
                                    const SizedBox(height: 12),
                                    Icon(Icons.circle, size: 12, color: deepForestGreen),
                                    Container(
                                      height: 40,
                                      width: 2,
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.3),
                                      ),
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          return Flex(
                                            direction: Axis.vertical,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: List.generate(5, (_) => SizedBox(
                                              width: 2, height: 4,
                                              child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey.withOpacity(0.5))),
                                            )),
                                          );
                                        },
                                      ),
                                    ),
                                    Icon(Icons.location_on, size: 20, color: Colors.red),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                // Inputs Column
                                Expanded(
                                  child: Column(
                                    children: [
                                      // From Field
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () async {
                                          final result = await Navigator.push<LocationSuggestion>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => LocationSearchScreen(
                                                title: 'From',
                                                initialValue: _pickupController.text,
                                                isPickup: true,
                                              ),
                                            ),
                                          );
                                          if (result != null && mounted) {
                                            setState(() {
                                              _selectedPickup = result;
                                              _pickupController.text = result.name;
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _pickupController.text.isEmpty ? 'Pickup Location' : _pickupController.text,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: _pickupController.text.isEmpty ? Colors.grey : (isDark ? Colors.white : Colors.black),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      
                                      // To Field
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () async {
                                          final result = await Navigator.push<LocationSuggestion>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => LocationSearchScreen(
                                                title: 'To',
                                                initialValue: _dropoffController.text,
                                                isPickup: false,
                                              ),
                                            ),
                                          );
                                          if (result != null && mounted) {
                                            setState(() {
                                              _selectedDropoff = result;
                                              _dropoffController.text = result.name;
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _dropoffController.text.isEmpty ? 'Dropoff Location' : _dropoffController.text,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: _dropoffController.text.isEmpty ? Colors.grey : (isDark ? Colors.white : Colors.black),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Swap Button
                                Container(
                                  margin: const EdgeInsets.only(top: 30),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                        ),
                                      ],
                                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.swap_vert, color: Colors.black87),
                                      onPressed: () {
                                        setState(() {
                                          final tempText = _pickupController.text;
                                          _pickupController.text = _dropoffController.text;
                                          _dropoffController.text = tempText;
                                          
                                          final tempLoc = _selectedPickup;
                                          _selectedPickup = _selectedDropoff;
                                          _selectedDropoff = tempLoc;
                                        });
                                      },
                                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                      padding: EdgeInsets.zero,
                                      iconSize: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 16),
                            
                            // 3. The Date Selector with Label
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                                  child: Text(
                                    'Select Travel Date',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildQuickDateButton('Today', DateTime.now(), isDark, deepForestGreen),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildQuickDateButton('Tomorrow', DateTime.now().add(const Duration(days: 1)), isDark, deepForestGreen),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildCustomDateButton(isDark, deepForestGreen),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // 4. The "Search Rides" Button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _handleBookRide,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: amber,
                                  foregroundColor: Colors.black,
                                  elevation: 4,
                                  shadowColor: amber.withOpacity(0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Search Rides',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
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
                
                const SizedBox(height: 24),
                
                // Dynamic Banner Carousel (Offers) - Temporarily disabled to fix hit testing
                // if (_banners.isNotEmpty)
                //   Padding(
                //     padding: const EdgeInsets.only(left: 16, right: 16, top: 24),
                //     child: SizedBox(
                //       height: 220,
                //       child: DynamicBannerCarousel(banners: _banners),
                //     ),
                //   ),
                
                // Active Trip Card
                if (activeTrip.bookingNumber.isNotEmpty)
                  _buildActiveTripCard(activeTrip, isDark),
                  
                // Scheduled Ride Banner
                if (upcomingRides.isNotEmpty && activeTrip.bookingNumber.isEmpty)
                  _buildScheduledRideBanner(upcomingRides.first, isDark),
                
                const SizedBox(height: 100), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuickDateButton(String label, DateTime date, bool isDark, Color primaryColor) {
    final isSelected = _dateFormatYMD.format(_selectedDate) == 
                       _dateFormatYMD.format(date);
    final dayNumber = _dateFormatDay.format(date);
    final monthName = _dateFormatMonth.format(date);
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? primaryColor
              : (isDark ? AppColors.darkSurface : Colors.grey[50]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? primaryColor
                : (isDark ? AppColors.darkBorder : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              dayNumber,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected 
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            Text(
              monthName,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: isSelected 
                    ? Colors.white.withOpacity(0.9)
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCustomDateButton(bool isDark, Color primaryColor) {
    final now = DateTime.now();
    final isCustomDate = _dateFormatYMD.format(_selectedDate) != 
                         _dateFormatYMD.format(now) &&
                         _dateFormatYMD.format(_selectedDate) != 
                         _dateFormatYMD.format(now.add(const Duration(days: 1)));
    
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 90)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: primaryColor,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null && mounted) {
          setState(() {
            _selectedDate = picked;
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: isCustomDate 
              ? primaryColor
              : (isDark ? AppColors.darkSurface : Colors.grey[50]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCustomDate 
                ? primaryColor
                : (isDark ? AppColors.darkBorder : Colors.grey[300]!),
            width: isCustomDate ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month,
              size: 16,
              color: isCustomDate 
                  ? Colors.white
                  : (isDark ? Colors.white70 : primaryColor),
            ),
            const SizedBox(height: 1),
            Text(
              isCustomDate ? _dateFormatDay.format(_selectedDate) : 'Pick',
              style: TextStyle(
                fontSize: isCustomDate ? 14 : 11,
                fontWeight: FontWeight.bold,
                color: isCustomDate 
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            Text(
              isCustomDate ? _dateFormatMonth.format(_selectedDate) : 'Date',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: isCustomDate 
                    ? Colors.white.withOpacity(0.9)
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOfferCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required bool isDark,
  }) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColor,
            bgColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Icon
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              icon,
              size: 100,
              color: Colors.white.withOpacity(0.15),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: bgColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Title
              Text(
                title,
                style: TextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              // Amount - Large and Bold
              Text(
                amount,
                style: TextStyles.displaySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 32,
                  height: 1.1,
                ),
              ),
              const Spacer(),
              // Subtitle
              Text(
                subtitle,
                style: TextStyles.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildServicesContent(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.grid_view,
            size: 80,
            color: AppColors.primaryYellow,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Services',
            style: TextStyles.headingLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Coming soon',
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
  
  /// Build rating prompt card for last completed unrated ride
  Widget _buildRatingPromptCard(RideHistoryItem ride, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => RateRideBottomSheet(
              rideId: ride.rideId ?? ride.bookingNumber,
              bookingNumber: ride.bookingNumber,
              onSubmit: (rating, feedback) async {
                try {
                  if (ride.driverId == null || ride.driverId!.isEmpty) {
                    throw Exception('Driver ID not available for this ride');
                  }
                  
                  final request = RateRideRequest(
                    rating: rating,
                    review: feedback.isNotEmpty ? feedback : null,
                    driverId: ride.driverId!,
                  );
                  
                  final bookingId = ride.bookingId ?? ride.bookingNumber;
                  print('🌟 Submitting rating for booking: $bookingId');
                  
                  final success = await ref
                      .read(passengerRideNotifierProvider.notifier)
                      .rateRide(bookingId, request);
                  
                  if (!success) {
                    final errorMessage = ref.read(passengerRideNotifierProvider).errorMessage;
                    throw Exception(errorMessage ?? 'Failed to submit rating');
                  }
                  
                  print('✅ Rating submitted successfully');
                } catch (e) {
                  print('❌ Error submitting rating: $e');
                  rethrow;
                }
              },
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryYellow,
                AppColors.primaryYellow.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryYellow.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rate Your Last Trip',
                            style: TextStyles.headingSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tell us about your experience',
                            style: TextStyles.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride.bookingNumber,
                              style: TextStyles.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${ride.pickupLocation} → ${ride.dropoffLocation}',
                              style: TextStyles.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            Icons.star_border,
                            size: 20,
                            color: Colors.white,
                          );
                        }),
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
  
  /// Build active trip card for when passenger is verified and trip is in progress
  Widget _buildActiveTripCard(RideHistoryItem ride, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1B5E20), // Deep Forest Green
              const Color(0xFF2E7D32), // Medium Green
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B5E20).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
            onTap: () {
              // Navigate to passenger live tracking screen
              if (ride.rideId == null || ride.rideId!.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ride information not available')),
                );
                return;
              }
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PassengerLiveTrackingScreen(
                    rideId: ride.rideId!,
                    bookingNumber: ride.bookingNumber,
                    rideDetails: ride,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC107).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.directions_car,
                          color: Color(0xFFFFC107),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LIVE NOW',
                              style: TextStyles.bodySmall.copyWith(
                                color: const Color(0xFFFFC107),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Trip in Progress',
                              style: TextStyles.headingMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.8),
                        size: 16,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // Route
                  Row(
                    children: [
                      Icon(
                        Icons.trip_origin,
                        color: Colors.white.withOpacity(0.9),
                        size: 14,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          ride.pickupLocation,
                          style: TextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Container(
                      width: 2,
                      height: 16,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                  
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.white.withOpacity(0.9),
                        size: 14,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          ride.dropoffLocation,
                          style: TextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Driver info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride.driverName ?? 'Driver',
                              style: TextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${ride.vehicleModel ?? 'Vehicle'} • ${ride.vehicleNumber ?? ''}',
                              style: TextStyles.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Call',
                              style: TextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.sm),
                  
                  // Prominent "Tap to Track" button with animation
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                      horizontal: AppSpacing.lg,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.gps_fixed,
                          color: Colors.greenAccent,
                          size: 20,
                        ).animate(
                          onPlay: (controller) => controller.repeat(),
                        ).shimmer(
                          duration: const Duration(milliseconds: 2000),
                          color: Colors.white,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'TAP TO VIEW LIVE TRACKING',
                          style: TextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ).animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  ).scale(
                    duration: const Duration(milliseconds: 1500),
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.02, 1.02),
                    curve: Curves.easeInOut,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildScheduledRideBanner(RideHistoryItem ride, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1B5E20), // Deep Forest Green
              const Color(0xFF2E7D32), // Medium Green
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B5E20).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
            onTap: () {
              // Navigate to ride history screen to see full details
              setState(() {
                _selectedNavIndex = 2; // Bookings tab
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC107).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.schedule,
                          color: Color(0xFFFFC107),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Upcoming Ride',
                          style: TextStyles.headingMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.8),
                        size: 16,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // Route
                  Row(
                    children: [
                      Icon(
                        Icons.trip_origin,
                        color: Colors.white.withOpacity(0.9),
                        size: 14,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          ride.pickupLocation,
                          style: TextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Container(
                      width: 2,
                      height: 16,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                  
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.white.withOpacity(0.9),
                        size: 14,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          ride.dropoffLocation,
                          style: TextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Time remaining until ride
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _getTimeRemaining(ride.travelDate, ride.timeSlot),
                          style: TextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // OTP and Vehicle Details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // OTP
                      if (ride.otp != null && ride.otp!.isNotEmpty)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'OTP',
                                style: TextStyles.bodySmall.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                                ),
                                child: Text(
                                  ride.otp!,
                                  style: TextStyles.headingMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(width: AppSpacing.md),
                      
                      // Vehicle Number Plate or Model
                      if (ride.vehicleNumber != null && ride.vehicleNumber!.isNotEmpty)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Vehicle',
                                style: TextStyles.bodySmall.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Yellow number plate
                              Transform.scale(
                                scale: 0.85,
                                alignment: Alignment.centerRight,
                                child: IndianNumberPlate(
                                  vehicleNumber: ride.vehicleNumber!,
                                  scale: 0.8,
                                  showShadow: true,
                                  backgroundColor: const Color(0xFFFFC107),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (ride.vehicleModel != null)
                        // Fallback to vehicle model if number not available
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Vehicle',
                                style: TextStyles.bodySmall.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ride.vehicleModel!,
                                style: TextStyles.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.sm),
                  
                  // Tap hint
                  Center(
                    child: Text(
                      'Tap to view full details',
                      style: TextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
    );
  }
  
  String _getTimeRemaining(String travelDate, String timeSlot) {
    try {
      // Parse the travel date
      final date = DateTime.parse(travelDate);
      
      // Parse the time slot (e.g., "10:00:00" or "10:00")
      final timeParts = timeSlot.split(':');
      if (timeParts.isEmpty) return 'Starts soon';
      
      final hour = int.parse(timeParts[0]);
      final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
      
      // Combine date and time
      final rideDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      );
      
      // Calculate difference
      final now = DateTime.now();
      final difference = rideDateTime.difference(now);
      
      if (difference.isNegative) {
        return 'Starting now';
      }
      
      final days = difference.inDays;
      final hours = difference.inHours % 24;
      final minutes = difference.inMinutes % 60;
      
      if (days > 0) {
        if (days == 1 && hours > 0) {
          return 'Starts in 1 day $hours hr';
        }
        return 'Starts in $days days';
      } else if (hours > 0) {
        if (minutes > 0) {
          return 'Starts in $hours hr $minutes min';
        }
        return 'Starts in $hours hr';
      } else if (minutes > 0) {
        return 'Starts in $minutes min';
      } else {
        return 'Starting now';
      }
    } catch (e) {
      return 'Upcoming';
    }
  }
  
  void _showTimeSlots_OLD(VehicleOption vehicle) {
    // Generate available time slots
    final timeSlots = [
      '06:00 AM', '07:00 AM', '08:00 AM', '09:00 AM', '10:00 AM',
      '11:00 AM', '12:00 PM', '01:00 PM', '02:00 PM', '03:00 PM',
      '04:00 PM', '05:00 PM', '06:00 PM', '07:00 PM', '08:00 PM',
    ];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TimeSlotSelectionSheet(
        vehicle: vehicle,
        timeSlots: timeSlots,
        selectedDate: _selectedDate,
        passengerCount: _passengerCount,
        onTimeSlotSelected: (timeSlot) {
          Navigator.pop(context);
          _confirmBooking(vehicle, timeSlot);
        },
      ),
    );
  }
  
  void _confirmBooking(VehicleOption vehicle, String timeSlot) {
    // Navigate to ride details screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideDetailsScreen(
          pickupLocation: _pickupController.text,
          dropoffLocation: _dropoffController.text,
          vehicle: vehicle,
          passengerCount: _passengerCount,
          travelDate: _selectedDate,
          timeSlot: timeSlot,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    print('🔄 BUILD METHOD CALLED at ${DateTime.now().toIso8601String()}');
    print('🔄 Pickup text: ${_pickupController.text}');
    print('🔄 Dropoff text: ${_dropoffController.text}');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deepForestGreen = const Color(0xFF1B5E20);
    
    // Automatically set status bar color to match deep forest green header
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateStatusBarWithColor(deepForestGreen);
    });
    
    // Set navigation bar colors
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: isDark ? AppColors.darkSurface : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
    
    return Scaffold(
      body: IndexedStack(
        index: _selectedNavIndex,
        children: [
          // Home Screen Content
          KeyedSubtree(
            key: const ValueKey('home_tab'),
            child: _buildHomeContent(isDark),
          ),
          // Services Screen (placeholder)
          KeyedSubtree(
            key: const ValueKey('services_tab'),
            child: _buildServicesContent(isDark),
          ),
          // Activity/Ride History Screen
          KeyedSubtree(
            key: const ValueKey('history_tab'),
            child: RideHistoryScreen(),
          ),
          // Account/Profile Screen
          KeyedSubtree(
            key: const ValueKey('profile_tab'),
            child: ProfileScreen(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        selectedItemColor: deepForestGreen,
        unselectedItemColor: isDark 
            ? AppColors.darkTextTertiary 
            : AppColors.lightTextTertiary,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 12,
        onTap: (index) {
          setState(() {
            _selectedNavIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

// Vehicle type selection bottom sheet
class _VehicleTypeSelectionSheet extends StatelessWidget {
  final List<VehicleOption> vehicles;
  final int passengerCount;
  final Function(VehicleOption) onVehicleSelected;
  
  const _VehicleTypeSelectionSheet({
    required this.vehicles,
    required this.passengerCount,
    required this.onVehicleSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Filter vehicles that can accommodate the requested passengers
    final availableVehicles = vehicles.where((v) => v.seats >= passengerCount).toList();
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppSpacing.borderRadiusTopXL,
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Title
            Text(
              'Select Vehicle Type',
              style: TextStyles.headingLarge,
            ),
            
            const SizedBox(height: AppSpacing.xs),
            
            Text(
              'Vehicles available for $passengerCount ${passengerCount == 1 ? "passenger" : "passengers"}',
              style: TextStyles.bodySmall.copyWith(
                color: isDark 
                    ? AppColors.darkTextSecondary 
                    : AppColors.lightTextSecondary,
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Vehicle list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: availableVehicles.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final vehicle = availableVehicles[index];
                final estimatedPrice = vehicle.basePrice + (5 * vehicle.pricePerKm);
                
                return InkWell(
                  onTap: () => onVehicleSelected(vehicle),
                  borderRadius: AppSpacing.borderRadiusMD,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                      borderRadius: AppSpacing.borderRadiusMD,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Vehicle icon
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primaryYellow.withOpacity(0.1),
                            borderRadius: AppSpacing.borderRadiusMD,
                          ),
                          child: Icon(
                            vehicle.icon,
                            size: 32,
                            color: AppColors.primaryYellow,
                          ),
                        ),
                        
                        const SizedBox(width: AppSpacing.md),
                        
                        // Vehicle details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle.name,
                                style: TextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                vehicle.model,
                                style: TextStyles.bodySmall.copyWith(
                                  color: isDark 
                                      ? AppColors.darkTextSecondary 
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 14,
                                    color: isDark 
                                        ? AppColors.darkTextTertiary 
                                        : AppColors.lightTextTertiary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${vehicle.seats} seats',
                                    style: TextStyles.caption.copyWith(
                                      color: isDark 
                                          ? AppColors.darkTextTertiary 
                                          : AppColors.lightTextTertiary,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: isDark 
                                        ? AppColors.darkTextTertiary 
                                        : AppColors.lightTextTertiary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '2 min away',
                                    style: TextStyles.caption.copyWith(
                                      color: isDark 
                                          ? AppColors.darkTextTertiary 
                                          : AppColors.lightTextTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Price
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹$estimatedPrice',
                              style: TextStyles.headingMedium.copyWith(
                                color: AppColors.primaryYellow,
                              ),
                            ),
                            Text(
                              '~5 km',
                              style: TextStyles.caption.copyWith(
                                color: isDark 
                                    ? AppColors.darkTextTertiary 
                                    : AppColors.lightTextTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate()
                    .fadeIn(delay: (50 * index).ms)
                    .slideX(begin: 0.2, end: 0, delay: (50 * index).ms);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleTypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _VehicleTypeChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusMD,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryYellow
              : (isDark ? AppColors.darkCardBg : AppColors.lightBorder.withOpacity(0.5)),
          borderRadius: AppSpacing.borderRadiusMD,
          border: Border.all(
            color: isSelected
                ? AppColors.primaryYellow
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primaryDark
                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              size: AppSpacing.iconMD,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: TextStyles.labelSmall.copyWith(
                color: isSelected
                    ? AppColors.primaryDark
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Time slot selection bottom sheet
class _TimeSlotSelectionSheet extends StatefulWidget {
  final VehicleOption vehicle;
  final List<String> timeSlots;
  final DateTime selectedDate;
  final int passengerCount;
  final Function(String) onTimeSlotSelected;
  
  const _TimeSlotSelectionSheet({
    required this.vehicle,
    required this.timeSlots,
    required this.selectedDate,
    required this.passengerCount,
    required this.onTimeSlotSelected,
  });

  @override
  State<_TimeSlotSelectionSheet> createState() => _TimeSlotSelectionSheetState();
}

class _TimeSlotSelectionSheetState extends State<_TimeSlotSelectionSheet> {
  String? _selectedTimeSlot;
  bool _isLoading = false;

  void _confirmTimeSlot() async {
    if (_selectedTimeSlot == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // Simulate finding driver
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      widget.onTimeSlotSelected(_selectedTimeSlot!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppSpacing.borderRadiusTopXL,
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Vehicle info
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow.withOpacity(0.1),
                borderRadius: AppSpacing.borderRadiusMD,
              ),
              child: Row(
                children: [
                  Icon(
                    widget.vehicle.icon,
                    size: 32,
                    color: AppColors.primaryYellow,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.vehicle.name,
                          style: TextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.vehicle.seats} seats • ${widget.passengerCount} ${widget.passengerCount == 1 ? "passenger" : "passengers"}',
                          style: TextStyles.bodySmall.copyWith(
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
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Title
            Text(
              'Select Time Slot',
              style: TextStyles.headingLarge,
            ),
            
            const SizedBox(height: AppSpacing.xs),
            
            Text(
              'Available times for ${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
              style: TextStyles.bodySmall.copyWith(
                color: isDark 
                    ? AppColors.darkTextSecondary 
                    : AppColors.lightTextSecondary,
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Time slots grid
            SizedBox(
              height: 300,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                ),
                itemCount: widget.timeSlots.length,
                itemBuilder: (context, index) {
                  final timeSlot = widget.timeSlots[index];
                  final isSelected = _selectedTimeSlot == timeSlot;
                  
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTimeSlot = timeSlot;
                      });
                    },
                    borderRadius: AppSpacing.borderRadiusMD,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryYellow
                            : (isDark ? AppColors.darkCardBg : AppColors.lightCardBg),
                        borderRadius: AppSpacing.borderRadiusMD,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryYellow
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          timeSlot,
                          style: TextStyles.bodySmall.copyWith(
                            color: isSelected
                                ? AppColors.primaryDark
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ).animate(
                    delay: (50 * index).ms,
                  ).fadeIn().scale(begin: const Offset(0.8, 0.8));
                },
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Confirm button
            PrimaryButton(
              text: _isLoading ? 'Looking for driver...' : 'Confirm Time',
              onPressed: (_selectedTimeSlot != null && !_isLoading)
                  ? _confirmTimeSlot
                  : null,
              isLoading: _isLoading,
              icon: _isLoading ? null : Icons.check_circle_outline,
            ),
          ],
        ),
      ),
    );
  }
}

// Route stop model
class RouteStop {
  final String name;
  final String time;
  final bool isPickup;
  final bool isDropoff;
  final bool isPassed;
  
  RouteStop({
    required this.name,
    required this.time,
    this.isPickup = false,
    this.isDropoff = false,
    this.isPassed = false,
  });
}

// Upcoming ride view widget
class _UpcomingRideView extends StatefulWidget {
  final bool isDark;
  
  const _UpcomingRideView({
    required this.isDark,
  });
  
  @override
  State<_UpcomingRideView> createState() => _UpcomingRideViewState();
}

class _UpcomingRideViewState extends State<_UpcomingRideView> {
  // bool _isExpanded = false; // Unused for now
  
  // Sample route data - Allapalli to Chandrapur route
  final List<RouteStop> _routeStops = [
    RouteStop(name: 'Allapalli', time: '06:00 AM', isPickup: true, isPassed: true),
    RouteStop(name: 'Palasgad', time: '06:25 AM', isPassed: true),
    RouteStop(name: 'Etapalli', time: '06:50 AM', isPassed: true),
    RouteStop(name: 'Jimalgatta', time: '07:15 AM', isPassed: false),
    RouteStop(name: 'Aheri', time: '07:40 AM', isPassed: false),
    RouteStop(name: 'Sironcha', time: '08:10 AM', isPassed: false),
    RouteStop(name: 'Kelapur', time: '08:40 AM', isPassed: false),
    RouteStop(name: 'Bramhapuri', time: '09:15 AM', isPassed: false),
    RouteStop(name: 'Mul', time: '09:50 AM', isPassed: false),
    RouteStop(name: 'Ballarpur', time: '10:25 AM', isPassed: false),
    RouteStop(name: 'Chandrapur', time: '11:00 AM', isDropoff: true, isPassed: false),
  ];
  
  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailedRouteScreen(
              routeStops: _routeStops,
              isDark: isDark,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryYellow,
              AppColors.primaryYellow.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppSpacing.borderRadiusMD,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryYellow.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with vehicle info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: AppSpacing.borderRadiusSM,
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Ride',
                        style: TextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Toyota Innova Crysta',
                        style: TextStyles.headingSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppSpacing.borderRadiusSM,
                  ),
                  child: Text(
                    'MH 34 AB 1234',
                    style: TextStyles.bodyMedium.copyWith(
                      color: AppColors.primaryYellow,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Origin and Destination with progress
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: AppSpacing.borderRadiusMD,
              ),
              child: Column(
                children: [
                  // Origin to Destination
                  Row(
                    children: [
                      // Origin
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _routeStops.first.name,
                              style: TextStyles.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _routeStops.first.time,
                              style: TextStyles.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Arrow
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      
                      // Destination
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _routeStops.last.name,
                              style: TextStyles.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            Text(
                              _routeStops.last.time,
                              style: TextStyles.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // Live tracking progress bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.2),
                              borderRadius: AppSpacing.borderRadiusSM,
                              border: Border.all(
                                color: AppColors.success,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'In Transit',
                                  style: TextStyles.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Reached Ettapalli • 34 km to Chandrapur',
                              style: TextStyles.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      
                      // Progress bar
                      Stack(
                        children: [
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: 0.4, // 40% progress
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Tap to view details indicator
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tap to view full route & driver details',
                    style: TextStyles.caption.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.touch_app,
                    color: Colors.white.withOpacity(0.9),
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate()
          .fadeIn(duration: 400.ms)
          .slideY(begin: -0.2, end: 0),
    );
  }
}

// Info chip widget
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: AppSpacing.borderRadiusSM,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              style: TextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Horizontal route stop item widget
class _HorizontalRouteStopItem extends StatelessWidget {
  final RouteStop stop;
  final bool isFirst;
  final bool isLast;
  final bool previousStopPassed;
  final bool isDark;
  
  const _HorizontalRouteStopItem({
    required this.stop,
    required this.isFirst,
    required this.isLast,
    required this.previousStopPassed,
    required this.isDark,
  });
  
  @override
  Widget build(BuildContext context) {
    final stopColor = stop.isPassed
        ? (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary)
        : stop.isPickup || stop.isDropoff
            ? AppColors.primaryYellow
            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    
    return Container(
      width: 95,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkCardBg : Colors.white).withOpacity(0.95),
        borderRadius: AppSpacing.borderRadiusMD,
        border: Border.all(
          color: stop.isPassed
              ? AppColors.success
              : stop.isPickup || stop.isDropoff
                  ? AppColors.primaryYellow
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (stop.isPassed
                    ? AppColors.success
                    : stop.isPickup || stop.isDropoff
                        ? AppColors.primaryYellow
                        : Colors.black)
                .withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stop indicator
          Container(
            width: stop.isPickup || stop.isDropoff ? 32 : 24,
            height: stop.isPickup || stop.isDropoff ? 32 : 24,
            decoration: BoxDecoration(
              color: stop.isPassed
                  ? AppColors.success
                  : stop.isPickup || stop.isDropoff
                      ? AppColors.primaryYellow
                      : (isDark ? AppColors.darkBorder.withOpacity(0.3) : AppColors.lightBorder),
              shape: BoxShape.circle,
            ),
            child: stop.isPassed
                ? Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Colors.white,
                  )
                : stop.isPickup || stop.isDropoff
                    ? Icon(
                        stop.isPickup ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          
          // Stop name
          Text(
            stop.name,
            style: TextStyles.bodySmall.copyWith(
              color: stopColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              decoration: stop.isPassed ? TextDecoration.lineThrough : null,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          
          // Time
          Text(
            stop.time,
            style: TextStyles.caption.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          // Badge
          if (stop.isPickup || stop.isDropoff)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: (stop.isPickup ? AppColors.success : AppColors.error).withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                stop.isPickup ? 'Pickup' : 'Drop',
                style: TextStyles.caption.copyWith(
                  color: stop.isPickup ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 8,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Detailed Route Screen with vertical timeline
class DetailedRouteScreen extends StatelessWidget {
  final List<RouteStop> routeStops;
  final bool isDark;
  
  const DetailedRouteScreen({
    super.key,
    required this.routeStops,
    required this.isDark,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Details'),
        centerTitle: true,
      ),
      body: Container(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Driver Details Card
              Container(
                margin: const EdgeInsets.all(AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryYellow,
                      AppColors.primaryYellow.withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppSpacing.borderRadiusMD,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryYellow.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Driver Avatar
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: AppColors.primaryYellow,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        
                        // Driver Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rajesh Kumar',
                                style: TextStyles.headingMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '4.8',
                                    style: TextStyles.bodyMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    '•',
                                    style: TextStyles.bodyMedium.copyWith(
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    '234 trips',
                                    style: TextStyles.bodyMedium.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Toyota Innova Crysta • MH 34 AB 1234',
                                style: TextStyles.bodySmall.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Call Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.phone,
                              color: AppColors.primaryYellow,
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.md),
                    
                    // Ride Info Chips
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: AppSpacing.borderRadiusSM,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.event,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Today',
                                    style: TextStyles.caption.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: AppSpacing.borderRadiusSM,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '4 Passengers',
                                    style: TextStyles.caption.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: AppSpacing.borderRadiusSM,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.payments,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '₹850',
                                    style: TextStyles.caption.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.2, end: 0),
              // Status and Route Title
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                  borderRadius: AppSpacing.borderRadiusMD,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.route,
                      color: AppColors.primaryYellow,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Journey Route',
                      style: TextStyles.headingSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: AppSpacing.borderRadiusSM,
                        border: Border.all(
                          color: AppColors.success,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'In Transit',
                            style: TextStyles.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate()
                  .fadeIn(delay: 100.ms)
                  .slideX(begin: -0.2, end: 0, delay: 100.ms),
              
              const SizedBox(height: AppSpacing.md),
              
              // Vertical timeline
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                  borderRadius: AppSpacing.borderRadiusMD,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: routeStops.length,
                  itemBuilder: (context, index) {
                    final stop = routeStops[index];
                    final isFirst = index == 0;
                    final isLast = index == routeStops.length - 1;
                    final previousStopPassed = index > 0 ? routeStops[index - 1].isPassed : false;
                    
                    return _VerticalRouteStopItem(
                      stop: stop,
                      isFirst: isFirst,
                      isLast: isLast,
                      previousStopPassed: previousStopPassed,
                      isDark: isDark,
                    ).animate()
                        .fadeIn(delay: (50 * index).ms)
                        .slideX(begin: -0.2, end: 0, delay: (50 * index).ms);
                  },
                ),
              ).animate()
                  .fadeIn(delay: 200.ms)
                  .slideY(begin: 0.1, end: 0, delay: 200.ms),
            
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    ),
    );
  }
}

// Features Showcase View - shown when no upcoming bookings
class _FeaturesShowcaseView extends StatefulWidget {
  final bool isDark;
  
  const _FeaturesShowcaseView({
    required this.isDark,
  });
  
  @override
  State<_FeaturesShowcaseView> createState() => _FeaturesShowcaseViewState();
}

class _FeaturesShowcaseViewState extends State<_FeaturesShowcaseView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<FeatureItem> _features = [
    FeatureItem(
      icon: Icons.route,
      title: 'Live Route Tracking',
      description: 'Track your ride in real-time with detailed stop information',
      color: Colors.blue,
    ),
    FeatureItem(
      icon: Icons.payment,
      title: 'Easy Payments',
      description: 'Multiple payment options including UPI, cards & wallets',
      color: Colors.green,
    ),
    FeatureItem(
      icon: Icons.people,
      title: 'Share Rides',
      description: 'Travel together and save money on shared rides',
      color: Colors.orange,
    ),
    FeatureItem(
      icon: Icons.star,
      title: 'Verified Drivers',
      description: 'All drivers are verified with ratings and reviews',
      color: Colors.purple,
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    // Auto-scroll features
    Future.delayed(const Duration(seconds: 3), _autoScroll);
  }
  
  void _autoScroll() {
    if (!mounted) return;
    final nextPage = (_currentPage + 1) % _features.length;
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(seconds: 3), _autoScroll);
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Upcoming Rides',
                  style: TextStyles.headingLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate()
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: -0.2, end: 0),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Discover what makes us special',
                  style: TextStyles.bodyLarge.copyWith(
                    color: isDark 
                        ? AppColors.darkTextSecondary 
                        : AppColors.lightTextSecondary,
                  ),
                ).animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideX(begin: -0.2, end: 0, delay: 200.ms),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Features carousel
          SizedBox(
            height: 320,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _features.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: _FeatureCard(
                    feature: _features[index],
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _features.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? AppColors.primaryYellow
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ).animate()
              .fadeIn(delay: 400.ms)
              .slideY(begin: 0.2, end: 0, delay: 400.ms),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Quick stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.people_outline,
                    label: 'Active Users',
                    value: '10K+',
                    isDark: isDark,
                  ).animate()
                      .fadeIn(delay: 500.ms)
                      .scale(begin: const Offset(0.8, 0.8), delay: 500.ms),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatCard(
                    icon: Icons.star_outline,
                    label: 'Average Rating',
                    value: '4.8',
                    isDark: isDark,
                  ).animate()
                      .fadeIn(delay: 600.ms)
                      .scale(begin: const Offset(0.8, 0.8), delay: 600.ms),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatCard(
                    icon: Icons.route,
                    label: 'Daily Rides',
                    value: '500+',
                    isDark: isDark,
                  ).animate()
                      .fadeIn(delay: 700.ms)
                      .scale(begin: const Offset(0.8, 0.8), delay: 700.ms),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // CTA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryYellow,
                    AppColors.primaryYellow.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppSpacing.borderRadiusMD,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryYellow.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ready to travel?',
                          style: TextStyles.headingSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Book your first ride now',
                          style: TextStyles.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 32,
                  ),
                ],
              ),
            ).animate()
                .fadeIn(delay: 800.ms)
                .slideY(begin: 0.2, end: 0, delay: 800.ms),
          ),
          
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// Feature Item Model
class FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  
  FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

// Feature Card Widget
class _FeatureCard extends StatelessWidget {
  final FeatureItem feature;
  final bool isDark;
  
  const _FeatureCard({
    required this.feature,
    required this.isDark,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: AppSpacing.borderRadiusXL,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: feature.color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: feature.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              feature.icon,
              size: 60,
              color: feature.color,
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              feature.title,
              style: TextStyles.headingMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              feature.description,
              style: TextStyles.bodyMedium.copyWith(
                color: isDark 
                    ? AppColors.darkTextSecondary 
                    : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
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
          Icon(
            icon,
            color: AppColors.primaryYellow,
            size: 32,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyles.headingMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyles.caption.copyWith(
              color: isDark 
                  ? AppColors.darkTextTertiary 
                  : AppColors.lightTextTertiary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Vertical route stop item for detailed screen
class _VerticalRouteStopItem extends StatelessWidget {
  final RouteStop stop;
  final bool isFirst;
  final bool isLast;
  final bool previousStopPassed;
  final bool isDark;
  
  const _VerticalRouteStopItem({
    required this.stop,
    required this.isFirst,
    required this.isLast,
    required this.previousStopPassed,
    required this.isDark,
  });
  
  @override
  Widget build(BuildContext context) {
    final stopColor = stop.isPassed
        ? (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary)
        : stop.isPickup || stop.isDropoff
            ? AppColors.primaryYellow
            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    
    final lineColor = stop.isPassed
        ? AppColors.success
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 40,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 3,
                      color: previousStopPassed
                          ? AppColors.success
                          : lineColor,
                    ),
                  ),
                Container(
                  width: stop.isPickup || stop.isDropoff ? 24 : 18,
                  height: stop.isPickup || stop.isDropoff ? 24 : 18,
                  decoration: BoxDecoration(
                    color: stop.isPassed
                        ? AppColors.success
                        : stop.isPickup || stop.isDropoff
                            ? AppColors.primaryYellow
                            : (isDark ? AppColors.darkCardBg : AppColors.lightCardBg),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: stop.isPassed
                          ? AppColors.success
                          : stop.isPickup || stop.isDropoff
                              ? AppColors.primaryYellow
                              : lineColor,
                      width: stop.isPickup || stop.isDropoff ? 3 : 2,
                    ),
                  ),
                  child: stop.isPassed
                      ? Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        )
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 3,
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          
          // Stop details
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                stop.name,
                                style: TextStyles.bodyLarge.copyWith(
                                  color: stopColor,
                                  fontWeight: stop.isPickup || stop.isDropoff
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  decoration: stop.isPassed
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            if (stop.isPickup)
                              Container(
                                margin: const EdgeInsets.only(left: AppSpacing.xs),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: AppSpacing.borderRadiusSM,
                                  border: Border.all(
                                    color: AppColors.success,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Pickup',
                                  style: TextStyles.caption.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            if (stop.isDropoff)
                              Container(
                                margin: const EdgeInsets.only(left: AppSpacing.xs),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: AppSpacing.borderRadiusSM,
                                  border: Border.all(
                                    color: AppColors.error,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Dropoff',
                                  style: TextStyles.caption.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: isDark 
                                  ? AppColors.darkTextTertiary 
                                  : AppColors.lightTextTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              stop.time,
                              style: TextStyles.bodyMedium.copyWith(
                                color: isDark 
                                    ? AppColors.darkTextTertiary 
                                    : AppColors.lightTextTertiary,
                              ),
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
        ],
      ),
    );
  }
}

// Draggable Booking Sheet Widget
class _DraggableBookingSheet extends StatefulWidget {
  final TextEditingController pickupController;
  final TextEditingController dropoffController;
  final DateTime selectedDate;
  final int passengerCount;
  final Function(DateTime) onDateChanged;
  final Function(int) onPassengerCountChanged;
  final Function(LocationSuggestion) onPickupSelected;
  final Function(LocationSuggestion) onDropoffSelected;
  final VoidCallback onSearchPressed;
  final LocationService locationService;

  const _DraggableBookingSheet({
    required this.pickupController,
    required this.dropoffController,
    required this.selectedDate,
    required this.passengerCount,
    required this.onDateChanged,
    required this.onPassengerCountChanged,
    required this.onPickupSelected,
    required this.onDropoffSelected,
    required this.onSearchPressed,
    required this.locationService,
  });

  @override
  State<_DraggableBookingSheet> createState() => _DraggableBookingSheetState();
}

class _DraggableBookingSheetState extends State<_DraggableBookingSheet> {
  final DraggableScrollableController _dragController = DraggableScrollableController();
  bool _isExpanded = false;

  @override
  void dispose() {
    _dragController.dispose();
    super.dispose();
  }

  void _toggleSheet() {
    if (_isExpanded) {
      _dragController.animateTo(
        0.15,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _dragController.animateTo(
        0.9,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      controller: _dragController,
      initialChildSize: 0.15,
      minChildSize: 0.15,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: const [0.15, 0.9],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: (isDark ? AppColors.darkShadow : AppColors.lightShadow).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // Drag Handle and collapsed content
              GestureDetector(
                onTap: _toggleSheet,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      // Drag Handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark 
                              ? AppColors.darkTextTertiary.withOpacity(0.5)
                              : AppColors.lightTextTertiary.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      // Minimized "Where to?" search bar
                      if (!_isExpanded)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? AppColors.darkCardBg 
                                : AppColors.lightBackground,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: isDark 
                                  ? AppColors.darkBorder 
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: AppColors.primaryYellow,
                                size: 24,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  'Where to?',
                                  style: TextStyles.bodyLarge.copyWith(
                                    color: isDark 
                                        ? AppColors.darkTextSecondary 
                                        : AppColors.lightTextSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryYellow.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: AppColors.primaryYellow,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Expanded content
              if (_isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        'Plan your ride',
                        style: TextStyles.headingLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Pickup location
                      LocationSearchField(
                        hint: 'Pickup location',
                        controller: widget.pickupController,
                        locationService: widget.locationService,
                        prefixIcon: Icons.trip_origin,
                        onLocationSelected: widget.onPickupSelected,
                      ),
                      
                      const SizedBox(height: AppSpacing.md),
                      
                      // Dropoff location
                      LocationSearchField(
                        hint: 'Where do you want to go?',
                        controller: widget.dropoffController,
                        locationService: widget.locationService,
                        prefixIcon: Icons.location_on,
                        onLocationSelected: widget.onDropoffSelected,
                      ),
                      
                      const SizedBox(height: AppSpacing.lg),
                      
                      // Date selector
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: widget.selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (date != null) {
                            widget.onDateChanged(date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                            borderRadius: AppSpacing.borderRadiusMD,
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 20,
                                color: AppColors.primaryYellow,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Travel Date',
                                      style: TextStyles.caption.copyWith(
                                        color: isDark 
                                            ? AppColors.darkTextTertiary 
                                            : AppColors.lightTextTertiary,
                                      ),
                                    ),
                                    Text(
                                      '${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
                                      style: TextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: isDark 
                                    ? AppColors.darkTextTertiary 
                                    : AppColors.lightTextTertiary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.lg),
                      
                      // Passenger count selector
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                          borderRadius: AppSpacing.borderRadiusMD,
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 20,
                              color: AppColors.primaryYellow,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              'Passengers',
                              style: TextStyles.bodyMedium,
                            ),
                            const Spacer(),
                            // Decrease button
                            IconButton(
                              onPressed: widget.passengerCount > 1
                                  ? () => widget.onPassengerCountChanged(widget.passengerCount - 1)
                                  : null,
                              icon: Icon(
                                Icons.remove_circle_outline,
                                color: widget.passengerCount > 1
                                    ? AppColors.primaryYellow
                                    : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                              ),
                            ),
                            // Count display
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryYellow.withOpacity(0.1),
                                borderRadius: AppSpacing.borderRadiusSM,
                              ),
                              child: Text(
                                '${widget.passengerCount}',
                                style: TextStyles.headingSmall.copyWith(
                                  color: AppColors.primaryYellow,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Increase button
                            IconButton(
                              onPressed: widget.passengerCount < 7
                                  ? () => widget.onPassengerCountChanged(widget.passengerCount + 1)
                                  : null,
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: widget.passengerCount < 7
                                    ? AppColors.primaryYellow
                                    : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Search button
                      PrimaryButton(
                        text: 'Search Vehicles',
                        onPressed: widget.onSearchPressed,
                        icon: Icons.search,
                      ),
                      
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Custom clipper for curved header
class _CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    
    // Create a smooth curve at the bottom
    final firstControlPoint = Offset(size.width / 4, size.height);
    final firstEndPoint = Offset(size.width / 2, size.height - 10);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    
    final secondControlPoint = Offset(size.width * 3 / 4, size.height - 20);
    final secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    
    path.lineTo(size.width, 0);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Custom painter for dotted line connector between location fields
class _DottedLinePainter extends CustomPainter {
  final Color color;

  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashHeight = 4.0;
    const dashSpace = 4.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
