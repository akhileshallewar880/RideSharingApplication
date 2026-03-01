import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/shared/widgets/buttons.dart';
import 'package:allapalli_ride/core/providers/driver_ride_provider.dart';
import 'package:allapalli_ride/core/providers/location_provider.dart';
import 'package:allapalli_ride/core/models/driver_models.dart';
import 'package:allapalli_ride/features/passenger/domain/models/location_suggestion.dart';
import 'package:allapalli_ride/features/passenger/presentation/screens/location_search_screen.dart';

/// Enhanced driver ride scheduling screen with intermediate stops and return trip
class ScheduleRideScreen extends ConsumerStatefulWidget {
  const ScheduleRideScreen({super.key});

  @override
  ConsumerState<ScheduleRideScreen> createState() => _ScheduleRideScreenState();
}

class _ScheduleRideScreenState extends ConsumerState<ScheduleRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _totalSeatsController = TextEditingController();
  final _pricePerSeatController = TextEditingController(text: '850');
  
  // Intermediate stops
  final List<TextEditingController> _intermediateStopControllers = [];
  final List<LocationSuggestion?> _intermediateStops = [];
  
  LocationSuggestion? _selectedPickup;
  LocationSuggestion? _selectedDropoff;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _departureTime = const TimeOfDay(hour: 6, minute: 0);
  
  // Return trip
  bool _scheduleReturnTrip = false;
  DateTime? _returnDate;
  TimeOfDay? _returnTime;
  
  // Segment pricing
  bool _showSegmentPricing = false;
  List<SegmentPrice> _segmentPrices = [];
  final Map<int, TextEditingController> _segmentPriceControllers = {};
  
  String _selectedRoute = 'Allapalli - Chandrapur';
  
  final List<String> _popularRoutes = [
    'Allapalli - Chandrapur',
    'Allapalli - Nagpur',
    'Chandrapur - Allapalli',
    'Nagpur - Allapalli',
  ];

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _totalSeatsController.dispose();
    _pricePerSeatController.dispose();
    for (var controller in _intermediateStopControllers) {
      controller.dispose();
    }
    for (var controller in _segmentPriceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addIntermediateStop() {
    setState(() {
      _intermediateStopControllers.add(TextEditingController());
      _intermediateStops.add(null);
    });
  }

  void _removeIntermediateStop(int index) {
    setState(() {
      _intermediateStopControllers[index].dispose();
      _intermediateStopControllers.removeAt(index);
      _intermediateStops.removeAt(index);
      _calculateSegmentPrices();
    });
  }

  void _calculateSegmentPrices() {
    if (_pricePerSeatController.text.isEmpty) {
      _segmentPrices = [];
      return;
    }

    final basePrice = double.tryParse(_pricePerSeatController.text) ?? 0.0;
    if (basePrice <= 0) {
      _segmentPrices = [];
      return;
    }

    final List<String> allStops = [
      _pickupController.text.trim(),
      ..._intermediateStopControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty),
      _dropoffController.text.trim(),
    ].where((s) => s.isNotEmpty).toList();

    if (allStops.length < 2) {
      _segmentPrices = [];
      return;
    }

    final segments = <SegmentPrice>[];
    final totalSegments = allStops.length - 1;

    // Calculate percentage for each segment
    // Use weighted distribution: earlier segments get slightly more weight
    for (int i = 0; i < totalSegments; i++) {
      final percentage = 1.0 / totalSegments;
      final suggestedPrice = basePrice * percentage;
      
      // Check if this segment already has an override
      final existingSegment = _segmentPrices.firstWhere(
        (s) => s.fromLocation == allStops[i] && s.toLocation == allStops[i + 1],
        orElse: () => SegmentPrice(
          fromLocation: allStops[i],
          toLocation: allStops[i + 1],
          price: suggestedPrice,
          suggestedPrice: suggestedPrice,
        ),
      );

      segments.add(existingSegment.isOverridden
          ? existingSegment.copyWith(suggestedPrice: suggestedPrice)
          : SegmentPrice(
              fromLocation: allStops[i],
              toLocation: allStops[i + 1],
              price: suggestedPrice,
              suggestedPrice: suggestedPrice,
            ));
    }

    _segmentPrices = segments;
    
    // Clean up controllers for removed segments
    final controllersToRemove = <int>[];
    _segmentPriceControllers.forEach((key, controller) {
      if (key >= segments.length) {
        controller.dispose();
        controllersToRemove.add(key);
      }
    });
    for (var key in controllersToRemove) {
      _segmentPriceControllers.remove(key);
    }
  }

  void _updateSegmentPrice(int index, double newPrice) {
    if (index < _segmentPrices.length) {
      setState(() {
        _segmentPrices[index] = _segmentPrices[index].copyWith(
          price: newPrice,
          isOverridden: true,
        );
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryYellow,
              onPrimary: Colors.white,
              onSurface: AppColors.lightTextPrimary,
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

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _departureTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryYellow,
              onPrimary: Colors.white,
              onSurface: AppColors.lightTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _departureTime) {
      setState(() {
        _departureTime = picked;
      });
    }
  }

  Future<void> _selectReturnDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _returnDate ?? _selectedDate.add(const Duration(days: 1)),
      firstDate: _selectedDate,
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryYellow,
              onPrimary: Colors.white,
              onSurface: AppColors.lightTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _returnDate = picked;
      });
    }
  }

  Future<void> _selectReturnTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _returnTime ?? const TimeOfDay(hour: 18, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryYellow,
              onPrimary: Colors.white,
              onSurface: AppColors.lightTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _returnTime = picked;
      });
    }
  }

  Future<void> _scheduleRide() async {
    // Store context before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
    if (_selectedPickup == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Please select pickup location'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    if (_selectedDropoff == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Please select dropoff location'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_scheduleReturnTrip && (_returnDate == null || _returnTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select return date and time'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_totalSeatsController.text.trim().isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Please enter total seats'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_pricePerSeatController.text.trim().isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Please enter price per seat'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    // Load active rides to ensure we have latest data for validation
    print('🔍 Loading active rides for time conflict validation...');
    await ref.read(driverRideNotifierProvider.notifier).loadActiveRides();
    
    // **NEW: Validate time conflicts with existing rides (30-minute buffer)**
    final newRideDeparture = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _departureTime.hour,
      _departureTime.minute,
    );
    
    final activeRides = ref.read(driverRideNotifierProvider).activeRides;
    print('📊 Found ${activeRides.length} active rides for validation');
    
    // Helper function to check time conflict
    bool checkTimeConflict(DateTime checkDateTime, String tripType) {
      for (final ride in activeRides) {
        // Skip cancelled or completed rides (case-insensitive)
        final status = ride.status.toLowerCase();
        if (status == 'cancelled' || status == 'completed') continue;
        
        try {
          // Parse date (format: dd-MM-yyyy)
          final dateParts = ride.date.split('-');
          final rideDeparture = DateTime(
            int.parse(dateParts[2]), // year
            int.parse(dateParts[1]), // month
            int.parse(dateParts[0]), // day
          );
          
          // Parse time (format: hh:mm tt or HH:mm)
          final timeStr = ride.departureTime.replaceAll(RegExp(r'[APap][Mm]'), '').trim();
          final timeParts = timeStr.split(':');
          var hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          
          // Handle 12-hour format
          if (ride.departureTime.toUpperCase().contains('PM') && hour != 12) {
            hour += 12;
          } else if (ride.departureTime.toUpperCase().contains('AM') && hour == 12) {
            hour = 0;
          }
          
          final rideDepartureDateTime = rideDeparture.add(Duration(
            hours: hour,
            minutes: minute,
          ));
          
          // Calculate estimated arrival time (departure + duration + 30 min buffer)
          final rideArrival = rideDepartureDateTime.add(
            Duration(minutes: (ride.duration ?? 180) + 30), // Default 3 hours if no duration
          );
          
          // Check if new ride departure is before the existing ride's arrival + buffer
          if (checkDateTime.isBefore(rideArrival) && 
              checkDateTime.isAfter(rideDepartureDateTime.subtract(const Duration(minutes: 15)))) {
            final arrivalTime = rideArrival.subtract(const Duration(minutes: 30));
            final arrivalStr = '${arrivalTime.hour % 12 == 0 ? 12 : arrivalTime.hour % 12}:${arrivalTime.minute.toString().padLeft(2, '0')} ${arrivalTime.hour >= 12 ? 'PM' : 'AM'}';
            final bufferStr = '${rideArrival.hour % 12 == 0 ? 12 : rideArrival.hour % 12}:${rideArrival.minute.toString().padLeft(2, '0')} ${rideArrival.hour >= 12 ? 'PM' : 'AM'}';
            
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(
                  '⚠️ Time Conflict ($tripType)\n\n'
                  'You have an existing ride:\n'
                  'Route: ${ride.pickupLocation} → ${ride.dropoffLocation}\n'
                  'Departure: ${ride.departureTime}\n'
                  'Est. Arrival: $arrivalStr\n\n'
                  '⏰ You can schedule your next ride after $bufferStr\n'
                  '(30-minute buffer after arrival)',
                  style: const TextStyle(fontSize: 14),
                ),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 8),
              ),
            );
            return true;
          }
        } catch (e) {
          print('Error parsing ride time: $e');
        }
      }
      return false;
    }
    
    // Validate outbound trip
    if (checkTimeConflict(newRideDeparture, 'Outbound Trip')) {
      return;
    }
    
    // Validate return trip if scheduled
    if (_scheduleReturnTrip && _returnDate != null && _returnTime != null) {
      final returnRideDeparture = DateTime(
        _returnDate!.year,
        _returnDate!.month,
        _returnDate!.day,
        _returnTime!.hour,
        _returnTime!.minute,
      );
      
      if (checkTimeConflict(returnRideDeparture, 'Return Trip')) {
        return;
      }
    }
    
    if (_formKey.currentState!.validate()) {
      // Prepare intermediate stop IDs and names
      final validStops = _intermediateStops.where((loc) => loc != null).toList();
      final intermediateStopsIds = validStops.map((loc) => loc!.id).toList();
      // Server's ScheduleRideRequestDto.IntermediateStops expects stop names (not IDs)
      final intermediateStopNames = validStops.map((loc) => loc!.name).toList();

      // Format travelDate (date only in ISO 8601)
      final travelDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      ).toIso8601String();

      // Format departureTime (HH:mm)
      final departureTimeStr = '${_departureTime.hour.toString().padLeft(2, '0')}:${_departureTime.minute.toString().padLeft(2, '0')}';

      String? returnDepartureTime;
      if (_scheduleReturnTrip && _returnDate != null && _returnTime != null) {
        final returnDateTime = DateTime(
          _returnDate!.year,
          _returnDate!.month,
          _returnDate!.day,
          _returnTime!.hour,
          _returnTime!.minute,
        );
        returnDepartureTime = returnDateTime.toIso8601String();
      }
      
      final request = ScheduleRideRequest(
        pickupLocationId: _selectedPickup!.id,
        dropoffLocationId: _selectedDropoff!.id,
        pickupLocation: LocationDto(
          cityId: _selectedPickup!.id,
          address: _selectedPickup!.fullAddress,
          latitude: _selectedPickup!.latitude ?? 0.0,
          longitude: _selectedPickup!.longitude ?? 0.0,
        ),
        dropoffLocation: LocationDto(
          cityId: _selectedDropoff!.id,
          address: _selectedDropoff!.fullAddress,
          latitude: _selectedDropoff!.latitude ?? 0.0,
          longitude: _selectedDropoff!.longitude ?? 0.0,
        ),
        intermediateStops: intermediateStopNames.isNotEmpty ? intermediateStopNames : null,
        intermediateStopsIds: intermediateStopsIds.isNotEmpty ? intermediateStopsIds : null,
        travelDate: travelDate,
        departureTime: departureTimeStr,
        totalSeats: int.parse(_totalSeatsController.text),
        pricePerSeat: double.parse(_pricePerSeatController.text),
        vehicleModelId: null, // Backend uses registered vehicle
        scheduleReturnTrip: _scheduleReturnTrip,
        returnDepartureTime: returnDepartureTime,
        segmentPrices: _segmentPrices.isNotEmpty ? _segmentPrices : null,
      );
      
      // Debug logging
      print('📤 Schedule Ride Request:');
      print('Pickup: ${_selectedPickup!.fullAddress}');
      print('Dropoff: ${_selectedDropoff!.fullAddress}');
      print('Intermediate Stops IDs: $intermediateStopsIds');
      print('Travel Date: $travelDate');
      print('Departure Time: $departureTimeStr');
      print('Total Seats: ${_totalSeatsController.text}');
      print('Price Per Seat: ${_pricePerSeatController.text}');
      print('Vehicle Model ID: null (using registered vehicle)');
      print('Schedule Return Trip: $_scheduleReturnTrip');
      print('Return Departure Time: $returnDepartureTime');
      print('Segment Prices Count: ${_segmentPrices.length}');
      print('JSON: ${request.toJson()}');
      
      try {
        final success = await ref.read(driverRideNotifierProvider.notifier)
            .scheduleRide(request);
        
        if (mounted) {
          if (success) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(
                  _scheduleReturnTrip 
                    ? 'Outbound and return rides scheduled successfully!'
                    : 'Ride scheduled successfully!',
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            navigator.pop();
          } else {
            final rideState = ref.read(driverRideNotifierProvider);
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(rideState.errorMessage ?? 'Failed to schedule ride'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        print('Schedule ride error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('Schedule Ride', style: TextStyles.headingMedium),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Popular Routes Quick Selection
              _buildPopularRoutes(isDark),
              
              const SizedBox(height: AppSpacing.xl),

              // Route Section
              _buildSectionHeader('Route Details', isDark),
              const SizedBox(height: AppSpacing.md),
              _buildRouteSection(isDark),

              const SizedBox(height: AppSpacing.xl),

              // Departure Section
              _buildSectionHeader('Departure Schedule', isDark),
              const SizedBox(height: AppSpacing.md),
              _buildDepartureSection(isDark),

              const SizedBox(height: AppSpacing.xl),

              // Pricing
              _buildSectionHeader('Pricing', isDark),
              const SizedBox(height: AppSpacing.md),
              _buildPricingSection(isDark),

              const SizedBox(height: AppSpacing.xl),

              // Return Trip Section
              _buildReturnTripSection(isDark),

              const SizedBox(height: AppSpacing.xl),

              // Route Preview
              if (_pickupController.text.isNotEmpty && _dropoffController.text.isNotEmpty)
                _buildRoutePreview(isDark),

              const SizedBox(height: AppSpacing.xl),

              // Schedule Button
              PrimaryButton(
                text: _scheduleReturnTrip ? 'Schedule Both Rides' : 'Schedule Ride',
                onPressed: _scheduleRide,
                isLoading: ref.watch(driverRideNotifierProvider).isLoading,
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularRoutes(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Routes',
          style: TextStyles.headingSmall.copyWith(
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _popularRoutes.map((route) {
            final isSelected = _selectedRoute == route;
            return ChoiceChip(
              label: Text(route),
              selected: isSelected,
              onSelected: (selected) async {
                if (selected) {
                  setState(() {
                    _selectedRoute = route;
                  });
                  
                  final parts = route.split(' - ');
                  final pickupName = parts[0];
                  final dropoffName = parts[1];
                  
                  // Fetch locations from server using location service
                  final locationService = ref.read(locationServiceProvider);
                  
                  try {
                    // Search for pickup location
                    final pickupResults = await locationService.searchLocations(pickupName);
                    if (pickupResults.isNotEmpty) {
                      final pickup = pickupResults.firstWhere(
                        (loc) => loc.name.toLowerCase() == pickupName.toLowerCase(),
                        orElse: () => pickupResults.first,
                      );
                      // Trigger the callback to properly set the selection
                      setState(() {
                        _selectedPickup = pickup;
                        _pickupController.text = pickup.name;
                      });
                    }
                    
                    // Search for dropoff location
                    final dropoffResults = await locationService.searchLocations(dropoffName);
                    if (dropoffResults.isNotEmpty) {
                      final dropoff = dropoffResults.firstWhere(
                        (loc) => loc.name.toLowerCase() == dropoffName.toLowerCase(),
                        orElse: () => dropoffResults.first,
                      );
                      // Trigger the callback to properly set the selection
                      setState(() {
                        _selectedDropoff = dropoff;
                        _dropoffController.text = dropoff.name;
                      });
                    }
                    
                    // Calculate segment prices if needed
                    _calculateSegmentPrices();
                    
                    // Unfocus to close any open dropdowns
                    FocusScope.of(context).unfocus();
                  } catch (e) {
                    print('Error loading popular route locations: $e');
                    // Fallback to just setting text
                    setState(() {
                      _pickupController.text = pickupName;
                      _dropoffController.text = dropoffName;
                    });
                  }
                }
              },
              selectedColor: AppColors.primaryYellow,
              backgroundColor: isDark ? AppColors.darkCardBg : Colors.grey[200],
              labelStyle: TextStyles.bodySmall.copyWith(
                color: isSelected 
                    ? Colors.white 
                    : (isDark ? Colors.white : AppColors.lightTextPrimary),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primaryYellow,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: TextStyles.headingSmall.copyWith(
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRouteSection(bool isDark) {
    return Container(
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
          // Pickup
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.trip_origin,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push<LocationSuggestion>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationSearchScreen(
                          title: 'Pickup Location',
                          initialValue: _pickupController.text,
                          isPickup: true,
                        ),
                      ),
                    );
                    
                    if (result != null) {
                      setState(() {
                        _selectedPickup = result;
                        _pickupController.text = result.name;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.trip_origin,
                          color: isDark 
                              ? AppColors.darkTextSecondary 
                              : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            _pickupController.text.isEmpty 
                                ? 'Pickup location' 
                                : _pickupController.text,
                            style: TextStyles.bodyMedium.copyWith(
                              color: _pickupController.text.isEmpty
                                  ? (isDark 
                                      ? AppColors.darkTextTertiary 
                                      : AppColors.lightTextTertiary)
                                  : (isDark 
                                      ? AppColors.darkTextPrimary 
                                      : AppColors.lightTextPrimary),
                              fontWeight: _pickupController.text.isEmpty 
                                  ? FontWeight.normal 
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Intermediate stops
          if (_intermediateStopControllers.isNotEmpty) ...[
            for (int i = 0; i < _intermediateStopControllers.length; i++) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.primaryYellow,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push<LocationSuggestion>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LocationSearchScreen(
                              title: 'Stop ${i + 1}',
                              initialValue: _intermediateStopControllers[i].text,
                              isPickup: false,
                            ),
                          ),
                        );
                        
                        if (result != null) {
                          setState(() {
                            _intermediateStops[i] = result;
                            _intermediateStopControllers[i].text = result.name;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: isDark 
                                  ? AppColors.darkTextSecondary 
                                  : AppColors.lightTextSecondary,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                _intermediateStopControllers[i].text.isEmpty 
                                    ? 'Stop ${i + 1}' 
                                    : _intermediateStopControllers[i].text,
                                style: TextStyles.bodyMedium.copyWith(
                                  color: _intermediateStopControllers[i].text.isEmpty
                                      ? (isDark 
                                          ? AppColors.darkTextTertiary 
                                          : AppColors.lightTextTertiary)
                                      : (isDark 
                                          ? AppColors.darkTextPrimary 
                                          : AppColors.lightTextPrimary),
                                  fontWeight: _intermediateStopControllers[i].text.isEmpty 
                                      ? FontWeight.normal 
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeIntermediateStop(i),
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                  ),
                ],
              ),
            ],
          ],

          const SizedBox(height: AppSpacing.md),

          // Add stop button
          TextButton.icon(
            onPressed: _addIntermediateStop,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Intermediate Stop'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryYellow,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Dropoff
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push<LocationSuggestion>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationSearchScreen(
                          title: 'Drop-off Location',
                          initialValue: _dropoffController.text,
                          isPickup: false,
                        ),
                      ),
                    );
                    
                    if (result != null) {
                      setState(() {
                        _selectedDropoff = result;
                        _dropoffController.text = result.name;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: isDark 
                              ? AppColors.darkTextSecondary 
                              : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            _dropoffController.text.isEmpty 
                                ? 'Drop-off location' 
                                : _dropoffController.text,
                            style: TextStyles.bodyMedium.copyWith(
                              color: _dropoffController.text.isEmpty
                                  ? (isDark 
                                      ? AppColors.darkTextTertiary 
                                      : AppColors.lightTextTertiary)
                                  : (isDark 
                                      ? AppColors.darkTextPrimary 
                                      : AppColors.lightTextPrimary),
                              fontWeight: _dropoffController.text.isEmpty 
                                  ? FontWeight.normal 
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildDepartureSection(bool isDark) {
    return Container(
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
          Expanded(
            child: InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppColors.primaryYellow,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Date',
                          style: TextStyles.caption.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: InkWell(
              onTap: _selectTime,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.primaryYellow,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Time',
                          style: TextStyles.caption.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _departureTime.format(context),
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2, end: 0);
  }

  Widget _buildPricingSection(bool isDark) {
    final totalSeats = int.tryParse(_totalSeatsController.text) ?? 0;
    final pricePerSeat = double.tryParse(_pricePerSeatController.text) ?? 0.0;
    final totalEarnings = totalSeats * pricePerSeat;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.2) 
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Total Seats
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? AppColors.darkBackground.withOpacity(0.5)
                        : AppColors.lightBackground.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark 
                          ? AppColors.darkBorder.withOpacity(0.5)
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.airline_seat_recline_normal,
                            size: 18,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Total Seats',
                            style: TextStyles.caption.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Decrement Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                final currentValue = int.tryParse(_totalSeatsController.text) ?? 0;
                                if (currentValue > 1) {
                                  _totalSeatsController.text = (currentValue - 1).toString();
                                  setState(() {});
                                }
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isDark 
                                        ? AppColors.darkBorder 
                                        : AppColors.lightBorder,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.remove,
                                  size: 16,
                                  color: isDark 
                                      ? AppColors.darkTextSecondary 
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Input Field
                          Flexible(
                            child: SizedBox(
                              width: 50,
                              child: TextFormField(
                                controller: _totalSeatsController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: TextStyles.headingMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark 
                                      ? AppColors.darkTextPrimary 
                                      : AppColors.lightTextPrimary,
                                  height: 1.2,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                  isDense: true,
                                  hintText: '0',
                                  hintStyle: TextStyles.headingMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: (isDark 
                                        ? AppColors.darkTextSecondary 
                                        : AppColors.lightTextSecondary).withOpacity(0.3),
                                  ),
                                ),
                                onChanged: (value) => setState(() {}),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  final seats = int.tryParse(value);
                                  if (seats == null || seats <= 0) {
                                    return 'Invalid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Increment Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                final currentValue = int.tryParse(_totalSeatsController.text) ?? 0;
                                final maxSeats = 50; // Max seats limit (vehicle model from registration)
                                if (currentValue < maxSeats) {
                                  _totalSeatsController.text = (currentValue + 1).toString();
                                  setState(() {});
                                }
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isDark 
                                        ? AppColors.darkBorder 
                                        : AppColors.lightBorder,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 16,
                                  color: isDark 
                                      ? AppColors.darkTextSecondary 
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Price per Seat
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? AppColors.darkBackground.withOpacity(0.5)
                        : AppColors.lightBackground.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark 
                          ? AppColors.darkBorder.withOpacity(0.5)
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.currency_rupee,
                            size: 18,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Price per Seat',
                            style: TextStyles.caption.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pricePerSeatController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyles.headingMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                          height: 1.2,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          isDense: true,
                          hintText: '0',
                          hintStyle: TextStyles.headingMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success.withOpacity(0.3),
                          ),
                          prefix: Padding(
                            padding: const EdgeInsets.only(left: 8, right: 4),
                            child: Text(
                              '₹',
                              style: TextStyles.headingMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _calculateSegmentPrices();
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'Invalid price';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Total Earnings Summary
          if (totalSeats > 0 && pricePerSeat > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryYellow.withOpacity(0.1),
                    AppColors.success.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: AppColors.success,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Potential Earnings',
                            style: TextStyles.caption.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$totalSeats seats × ₹${pricePerSeat.toStringAsFixed(0)}',
                            style: TextStyles.caption.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary.withOpacity(0.7)
                                  : AppColors.lightTextSecondary.withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '₹${totalEarnings.toStringAsFixed(0)}',
                    style: TextStyles.headingMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Segment Pricing Section
          if (_intermediateStopControllers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _buildSegmentPricingSection(isDark),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildSegmentPricingSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _showSegmentPricing
              ? AppColors.primaryYellow.withOpacity(0.5)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        borderRadius: BorderRadius.circular(12),
        color: isDark ? AppColors.darkCardBg : Colors.white,
      ),
      child: Column(
        children: [
          // Header - Expandable
          InkWell(
            onTap: () {
              setState(() {
                _showSegmentPricing = !_showSegmentPricing;
                if (_showSegmentPricing) {
                  _calculateSegmentPrices();
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.route,
                      size: 18,
                      color: AppColors.primaryYellow,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Segment Pricing',
                          style: TextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Set different prices for route segments',
                          style: TextStyles.caption.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showSegmentPricing
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable Content
          if (_showSegmentPricing) ...[
            Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Banner
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primaryYellow.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.primaryYellow,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Suggested prices are auto-calculated. You can override them.',
                            style: TextStyles.caption.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Segment List
                  if (_segmentPrices.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          'Enter base price to see suggested segment prices',
                          style: TextStyles.caption.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    ...List.generate(_segmentPrices.length, (index) {
                      final segment = _segmentPrices[index];
                      return _buildSegmentPriceCard(
                        segment,
                        index,
                        isDark,
                      );
                    }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSegmentPriceCard(SegmentPrice segment, int index, bool isDark) {
    // Get or create controller for this segment
    if (!_segmentPriceControllers.containsKey(index)) {
      _segmentPriceControllers[index] = TextEditingController(
        text: segment.price.toStringAsFixed(0),
      );
    } else {
      // Update text if price changed (but not during user input)
      final currentText = _segmentPriceControllers[index]!.text;
      final expectedText = segment.price.toStringAsFixed(0);
      if (currentText != expectedText && !_segmentPriceControllers[index]!.selection.isValid) {
        _segmentPriceControllers[index]!.text = expectedText;
      }
    }
    
    final controller = _segmentPriceControllers[index]!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBackground.withOpacity(0.3)
            : AppColors.lightBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: segment.isOverridden
              ? AppColors.success.withOpacity(0.5)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Segment ${index + 1}',
                  style: TextStyles.caption.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryYellow,
                  ),
                ),
              ),
              if (segment.isOverridden) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.edit,
                  size: 14,
                  color: AppColors.success,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: AppColors.success,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  segment.fromLocation,
                  style: TextStyles.caption.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Icon(
              Icons.arrow_downward,
              size: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: AppColors.error,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  segment.toLocation,
                  style: TextStyles.caption.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suggested: ₹${segment.suggestedPrice.toStringAsFixed(0)}',
                      style: TextStyles.caption.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Price: ',
                          style: TextStyles.caption.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            style: TextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                            decoration: InputDecoration(
                              prefix: Text(
                                '₹ ',
                                style: TextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: AppColors.success,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              isDense: true,
                            ),
                            onChanged: (value) {
                              final price = double.tryParse(value);
                              if (price != null && price > 0) {
                                _updateSegmentPrice(index, price);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (segment.isOverridden)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _segmentPrices[index] = segment.copyWith(
                        price: segment.suggestedPrice,
                        isOverridden: false,
                      );
                    });
                  },
                  icon: Icon(
                    Icons.refresh,
                    size: 20,
                    color: AppColors.primaryYellow,
                  ),
                  tooltip: 'Reset to suggested',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReturnTripSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _scheduleReturnTrip
              ? AppColors.primaryYellow
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.swap_horiz,
                          color: AppColors.primaryYellow,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Schedule Return Trip',
                          style: TextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Automatically create return journey',
                      style: TextStyles.caption.copyWith(
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _scheduleReturnTrip,
                onChanged: (value) {
                  setState(() {
                    _scheduleReturnTrip = value;
                    if (value && _returnDate == null) {
                      _returnDate = _selectedDate.add(const Duration(days: 1));
                      _returnTime = const TimeOfDay(hour: 18, minute: 0);
                    }
                  });
                },
                activeColor: AppColors.primaryYellow,
              ),
            ],
          ),
          
          if (_scheduleReturnTrip) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.primaryYellow,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Return Journey',
                        style: TextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryYellow,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${_dropoffController.text} → ${_pickupController.text}',
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selectReturnDate,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCardBg : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Return Date',
                                  style: TextStyles.caption.copyWith(
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _returnDate != null
                                      ? '${_returnDate!.day}/${_returnDate!.month}/${_returnDate!.year}'
                                      : 'Select',
                                  style: TextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: InkWell(
                          onTap: _selectReturnTime,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCardBg : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Return Time',
                                  style: TextStyles.caption.copyWith(
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _returnTime != null
                                      ? _returnTime!.format(context)
                                      : 'Select',
                                  style: TextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildRoutePreview(bool isDark) {
    final stops = <String>[
      _pickupController.text,
      ..._intermediateStopControllers
          .where((c) => c.text.trim().isNotEmpty)
          .map((c) => c.text),
      _dropoffController.text,
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryYellow.withOpacity(0.1),
            AppColors.primaryOrange.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryYellow.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.route,
                color: AppColors.primaryYellow,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Route Preview',
                style: TextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryYellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...stops.asMap().entries.map((entry) {
            final index = entry.key;
            final stop = entry.value;
            final isFirst = index == 0;
            final isLast = index == stops.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isFirst
                            ? AppColors.success
                            : isLast
                                ? AppColors.error
                                : AppColors.primaryYellow,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 30,
                        color: AppColors.primaryYellow.withOpacity(0.3),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      stop,
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: isFirst || isLast ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
          
          if (_scheduleReturnTrip) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(color: AppColors.primaryYellow.withOpacity(0.3)),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  Icons.keyboard_return,
                  color: AppColors.primaryYellow,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Return: ${_dropoffController.text} → ${_pickupController.text}',
                    style: TextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 700.ms).scale(begin: const Offset(0.95, 0.95));
  }
}
