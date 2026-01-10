import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/admin_ride_models.dart';
import '../../core/models/location_suggestion.dart';
import '../../core/providers/admin_ride_provider.dart';
import '../../core/theme/admin_theme.dart';
import '../../shared/widgets/location_search_field.dart';
import '../../core/services/google_maps_service.dart';

class AdminScheduleRideDialog extends ConsumerStatefulWidget {
  const AdminScheduleRideDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminScheduleRideDialog> createState() => _AdminScheduleRideDialogState();
}

class _AdminScheduleRideDialogState extends ConsumerState<AdminScheduleRideDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _totalSeatsController = TextEditingController(text: '7');
  final _pricePerSeatController = TextEditingController(text: '850');
  final _adminNotesController = TextEditingController();
  final GoogleMapsService _googleMapsService = GoogleMapsService();

  // Location data
  LocationSuggestion? _pickupLocation;
  LocationSuggestion? _dropoffLocation;
  
  // Distance and Duration
  String? _estimatedDistance;
  String? _estimatedDuration;
  bool _isCalculatingRoute = false;
  
  // Intermediate stops
  final List<TextEditingController> _intermediateStopControllers = [];
  final List<LocationSuggestion?> _intermediateStops = [];
  
  AdminDriverInfo? _selectedDriver;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _departureTime = const TimeOfDay(hour: 6, minute: 0);
  bool _scheduleReturnTrip = false;
  DateTime? _returnDate;
  TimeOfDay? _returnTime;
  bool _isSubmitting = false;

  // Segment Pricing
  bool _showSegmentPricing = false;
  List<SegmentPrice> _segmentPrices = [];
  final Map<int, TextEditingController> _segmentPriceControllers = {};

  final List<String> _popularRoutes = [
    'Allapalli → Chandrapur',
    'Allapalli → Nagpur',
    'Chandrapur → Allapalli',
    'Nagpur → Allapalli',
  ];

  @override
  void initState() {
    super.initState();
    // Load drivers with error handling
    Future.microtask(() async {
      try {
        await ref.read(adminDriversProvider.notifier).loadDrivers();
      } catch (e) {
        // Error will be shown in UI
      }
    });
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _totalSeatsController.dispose();
    _pricePerSeatController.dispose();
    _adminNotesController.dispose();
    for (var controller in _intermediateStopControllers) {
      controller.dispose();
    }
    for (var controller in _segmentPriceControllers.values) {
      controller.dispose();
    }
    super.dispose();
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

  void _addIntermediateStop() {
    setState(() {
      _intermediateStopControllers.add(TextEditingController());
      _intermediateStops.add(null);
    });
    // Recalculate when stops change
    _calculateDistanceAndDuration();
  }

  void _removeIntermediateStop(int index) {
    setState(() {
      _intermediateStopControllers[index].dispose();
      _intermediateStopControllers.removeAt(index);
      _intermediateStops.removeAt(index);
    });
    // Recalculate when stops change
    _calculateDistanceAndDuration();
  }

  void _setPopularRoute(String route) {
    final parts = route.split(' → ');
    setState(() {
      _pickupController.text = parts[0];
      _dropoffController.text = parts[1];
      // Note: User still needs to select from autocomplete to get coordinates
      _pickupLocation = null;
      _dropoffLocation = null;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AdminTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _departureTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AdminTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _departureTime = picked);
    }
  }

  Future<void> _selectReturnDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _returnDate ?? _selectedDate.add(const Duration(days: 1)),
      firstDate: _selectedDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AdminTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _returnDate = picked);
    }
  }

  Future<void> _selectReturnTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _returnTime ?? const TimeOfDay(hour: 16, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AdminTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _returnTime = picked);
    }
  }

  /// Calculate distance and duration using Google Maps API via backend
  Future<void> _calculateDistanceAndDuration() async {
    if (_pickupLocation == null || _dropoffLocation == null) {
      setState(() {
        _estimatedDistance = null;
        _estimatedDuration = null;
      });
      return;
    }

    // Check if coordinates are available
    if (_pickupLocation!.latitude == null || _pickupLocation!.longitude == null ||
        _dropoffLocation!.latitude == null || _dropoffLocation!.longitude == null) {
      setState(() {
        _estimatedDistance = 'Coordinates missing';
        _estimatedDuration = 'Coordinates missing';
        _isCalculatingRoute = false;
      });
      return;
    }

    setState(() => _isCalculatingRoute = true);

    try {
      // Build list of intermediate stops (only non-null ones with coordinates)
      final List<LocationSuggestion>? intermediateStopLocations = _intermediateStops
          .where((stop) => stop != null && stop.latitude != null && stop.longitude != null)
          .cast<LocationSuggestion>()
          .toList();

      final result = await _googleMapsService.getDistanceAndDuration(
        pickupLocation: _pickupLocation!,
        dropoffLocation: _dropoffLocation!,
        intermediateStops: intermediateStopLocations != null && intermediateStopLocations.isNotEmpty 
            ? intermediateStopLocations 
            : null,
      );

      if (result != null && mounted) {
        setState(() {
          _estimatedDistance = result['distanceText'];
          _estimatedDuration = result['durationText'];
          _isCalculatingRoute = false;
        });
      } else if (mounted) {
        setState(() {
          _estimatedDistance = 'Unable to calculate';
          _estimatedDuration = 'Unable to calculate';
          _isCalculatingRoute = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _estimatedDistance = 'Error calculating';
          _estimatedDuration = 'Error calculating';
          _isCalculatingRoute = false;
        });
      }
    }
  }

  Future<void> _scheduleRide() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDriver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a driver')),
      );
      return;
    }

    if (_pickupLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pickup location')),
      );
      return;
    }

    if (_dropoffLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a dropoff location')),
      );
      return;
    }

    // Validate return trip timing
    if (_scheduleReturnTrip) {
      if (_returnDate == null || _returnTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select return date and time')),
        );
        return;
      }
      
      final outboundDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _departureTime.hour,
        _departureTime.minute,
      );
      
      final returnDateTime = DateTime(
        _returnDate!.year,
        _returnDate!.month,
        _returnDate!.day,
        _returnTime!.hour,
        _returnTime!.minute,
      );
      
      if (returnDateTime.isBefore(outboundDateTime) || returnDateTime.isAtSameMomentAs(outboundDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Return trip must be scheduled after outbound trip')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
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

      final request = AdminScheduleRideRequest(
        driverId: _selectedDriver!.driverId,
        pickupLocation: LocationDto(
          address: _pickupLocation!.fullAddress,
          latitude: _pickupLocation!.latitude ?? 0.0,
          longitude: _pickupLocation!.longitude ?? 0.0,
        ),
        dropoffLocation: LocationDto(
          address: _dropoffLocation!.fullAddress,
          latitude: _dropoffLocation!.latitude ?? 0.0,
          longitude: _dropoffLocation!.longitude ?? 0.0,
        ),
        intermediateStops: _intermediateStops.isNotEmpty 
            ? _intermediateStops
                .where((stop) => stop != null)
                .map((stop) => stop!.fullAddress)
                .toList()
            : null,
        intermediateStopLocations: _intermediateStops.isNotEmpty
            ? _intermediateStops
                .where((stop) => stop != null && stop!.latitude != null && stop!.longitude != null)
                .map((stop) => {
                      'address': stop!.fullAddress,
                      'latitude': stop!.latitude,
                      'longitude': stop!.longitude,
                    })
                .toList()
            : null,
        travelDate: _selectedDate,
        departureTime: departureTimeStr,
        totalSeats: int.parse(_totalSeatsController.text),
        pricePerSeat: double.parse(_pricePerSeatController.text),
        scheduleReturnTrip: _scheduleReturnTrip,
        returnDepartureTime: returnDepartureTime,
        segmentPrices: _showSegmentPricing && _segmentPrices.isNotEmpty ? _segmentPrices : null,
        adminNotes: _adminNotesController.text.isNotEmpty ? _adminNotesController.text : null,
      );

      final response = await ref.read(adminRideNotifierProvider.notifier).scheduleRide(request);

      if (mounted) {
        setState(() => _isSubmitting = false);

        if (response != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ride ${response.rideNumber} scheduled successfully'
                    '${response.returnRideNumber != null ? " with return ride ${response.returnRideNumber}" : ""}',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to schedule ride'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final driversState = ref.watch(adminDriversProvider);

    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(
          maxHeight: 900,
          minHeight: 400,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                color: AdminTheme.primaryColor,
                child: Row(
                  children: [
                    const Icon(Icons.add_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Schedule New Ride',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Popular Routes
                      const Text(
                        'Popular Routes',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _popularRoutes.map((route) {
                          return ActionChip(
                            label: Text(route),
                            onPressed: () => _setPopularRoute(route),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Driver Selection
                      const Text(
                        'Select Driver *',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      driversState.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : driversState.errorMessage != null
                              ? Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    border: Border.all(color: Colors.red),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error, color: Colors.red),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Failed to load drivers',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              driversState.errorMessage!,
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          ref.read(adminDriversProvider.notifier).loadDrivers();
                                        },
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                )
                              : driversState.drivers.isEmpty
                                  ? Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[50],
                                        border: Border.all(color: Colors.orange),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.warning, color: Colors.orange),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text('No drivers available'),
                                          ),
                                        ],
                                      ),
                                    )
                                  : DropdownButtonFormField<AdminDriverInfo>(
                                      value: _selectedDriver,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: 'Choose a driver',
                                      ),
                                      items: driversState.drivers.map((driver) {
                                        return DropdownMenuItem(
                                          value: driver,
                                          child: Text(
                                            '${driver.name} - ${driver.vehicleModel ?? ''} (${driver.vehicleSeats} seats)',
                                            style: const TextStyle(fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (driver) {
                                        setState(() {
                                          _selectedDriver = driver;
                                          if (driver != null) {
                                            _totalSeatsController.text = driver.vehicleSeats.toString();
                                          }
                                });
                              },
                              validator: (value) =>
                                  value == null ? 'Please select a driver' : null,
                            ),

                      const SizedBox(height: 24),

                      // Route Details
                      const Text(
                        'Route Details',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      LocationSearchField(
                        controller: _pickupController,
                        label: 'Pickup Location *',
                        hint: 'Search for pickup location',
                        prefixIcon: Icons.trip_origin,
                        onLocationSelected: (location) {
                          setState(() {
                            _pickupLocation = location;
                          });
                          _calculateDistanceAndDuration();
                        },
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required';
                          if (_pickupLocation == null) return 'Please select a location from suggestions';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Intermediate Stops
                      if (_intermediateStops.isNotEmpty) ...[
                        for (int i = 0; i < _intermediateStops.length; i++) ...[
                          Row(
                            children: [
                              Expanded(
                                child: LocationSearchField(
                                  controller: _intermediateStopControllers[i],
                                  label: 'Intermediate Stop ${i + 1}',
                                  hint: 'Search for stop location',
                                  prefixIcon: Icons.location_on_outlined,
                                  onLocationSelected: (location) {
                                    setState(() {
                                      _intermediateStops[i] = location;
                                    });
                                    // Recalculate when intermediate location is selected
                                    _calculateDistanceAndDuration();
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () => _removeIntermediateStop(i),
                                tooltip: 'Remove stop',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],

                      // Add Intermediate Stop Button
                      OutlinedButton.icon(
                        onPressed: _addIntermediateStop,
                        icon: const Icon(Icons.add_location_alt),
                        label: Text(_intermediateStops.isEmpty
                            ? 'Add Intermediate Stops'
                            : 'Add Another Stop'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AdminTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),

                      LocationSearchField(
                        controller: _dropoffController,
                        label: 'Dropoff Location *',
                        hint: 'Search for dropoff location',
                        prefixIcon: Icons.location_on,
                        onLocationSelected: (location) {
                          setState(() {
                            _dropoffLocation = location;
                          });
                          _calculateDistanceAndDuration();
                        },
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required';
                          if (_dropoffLocation == null) return 'Please select a location from suggestions';
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Distance and Duration Info
                      if (_pickupLocation != null && _dropoffLocation != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              if (_isCalculatingRoute)
                                const Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Calculating route...'),
                                  ],
                                )
                              else if (_estimatedDistance != null && _estimatedDuration != null)
                                Expanded(
                                  child: Text(
                                    'Distance: $_estimatedDistance • Duration: $_estimatedDuration',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )
                              else
                                const Text(
                                  'Unable to calculate distance',
                                  style: TextStyle(color: Colors.orange),
                                ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Schedule Details
                      const Text(
                        'Schedule Details',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Travel Date',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: _selectTime,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Departure Time',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.access_time),
                                ),
                                child: Text(_departureTime.format(context)),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Pricing
                      const Text(
                        'Pricing & Capacity',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _totalSeatsController,
                              decoration: const InputDecoration(
                                labelText: 'Total Seats *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.airline_seat_recline_normal),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Required';
                                final seats = int.tryParse(value!);
                                if (seats == null || seats <= 0) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _pricePerSeatController,
                              decoration: const InputDecoration(
                                labelText: 'Price per Seat *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.attach_money),
                                prefixText: '₹ ',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Required';
                                final price = double.tryParse(value!);
                                if (price == null || price <= 0) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Segment Pricing Section
                      _buildSegmentPricingSection(),

                      const SizedBox(height: 24),

                      // Return Trip
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Schedule Return Trip'),
                        value: _scheduleReturnTrip,
                        onChanged: (value) {
                          setState(() {
                            _scheduleReturnTrip = value ?? false;
                            if (_scheduleReturnTrip) {
                              // Set default return date/time to be after outbound trip
                              final outboundDateTime = DateTime(
                                _selectedDate.year,
                                _selectedDate.month,
                                _selectedDate.day,
                                _departureTime.hour,
                                _departureTime.minute,
                              );
                              // Default return trip to 2 hours after outbound
                              final defaultReturn = outboundDateTime.add(const Duration(hours: 2));
                              _returnDate = defaultReturn;
                              _returnTime = TimeOfDay(hour: defaultReturn.hour, minute: defaultReturn.minute);
                            }
                          });
                        },
                      ),

                      if (_scheduleReturnTrip) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _selectReturnDate,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Return Date',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.calendar_today),
                                  ),
                                  child: Text(
                                    _returnDate != null
                                        ? DateFormat('dd MMM yyyy').format(_returnDate!)
                                        : 'Select date',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: _selectReturnTime,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Return Time',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.access_time),
                                  ),
                                  child: Text(
                                    _returnTime != null
                                        ? _returnTime!.format(context)
                                        : 'Select time',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Admin Notes
                      const Text(
                        'Admin Notes (Optional)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _adminNotesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Add any special instructions or notes...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _scheduleRide,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(_isSubmitting ? 'Scheduling...' : 'Schedule Ride'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
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
    );
  }

  Widget _buildSegmentPricingSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _showSegmentPricing
              ? AdminTheme.primaryColor.withOpacity(0.5)
              : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header - Expandable
          InkWell(
            onTap: () {
              if (!_showSegmentPricing) {
                // Calculate prices before showing
                _calculateSegmentPrices();
              }
              setState(() {
                _showSegmentPricing = !_showSegmentPricing;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(
                    Icons.route,
                    size: 16,
                    color: AdminTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Segment Pricing (Optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(
                    _showSegmentPricing
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable Content
          if (_showSegmentPricing) ...[
            Divider(height: 1, color: Colors.grey[300]),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Info Banner
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AdminTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: AdminTheme.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Auto-calculated prices based on route segments',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // Segment List
                    if (_segmentPrices.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Enter base price to see segment pricing',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      )
                    else
                      ...List.generate(_segmentPrices.length, (index) {
                        return _buildSegmentPriceCard(
                          _segmentPrices[index],
                          index,
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSegmentPriceCard(SegmentPrice segment, int index) {
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: segment.isOverridden
              ? Colors.green.withOpacity(0.5)
              : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AdminTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Segment ${index + 1}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AdminTheme.primaryColor,
                  ),
                ),
              ),
              if (segment.isOverridden) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.edit,
                  size: 14,
                  color: Colors.green,
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
                color: Colors.green,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  segment.fromLocation,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
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
              color: Colors.grey[600],
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: Colors.red,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  segment.toLocation,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
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
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Price: ',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              prefix: Text(
                                '₹ ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
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
            ],
          ),
        ],
      ),
    );
  }}