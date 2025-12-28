import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/admin_ride_models.dart';
import '../../core/providers/admin_ride_provider.dart';
import '../../core/theme/admin_theme.dart';

class AdminRescheduleRideDialog extends ConsumerStatefulWidget {
  final AdminRideInfo ride;

  const AdminRescheduleRideDialog({Key? key, required this.ride}) : super(key: key);

  @override
  ConsumerState<AdminRescheduleRideDialog> createState() => _AdminRescheduleRideDialogState();
}

class _AdminRescheduleRideDialogState extends ConsumerState<AdminRescheduleRideDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _totalSeatsController = TextEditingController();
  final _pricePerSeatController = TextEditingController();
  final _adminNotesController = TextEditingController();
  
  late DateTime _selectedDate;
  late TimeOfDay _departureTime;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing ride data
    _pickupController.text = widget.ride.pickupLocation;
    _dropoffController.text = widget.ride.dropoffLocation;
    _totalSeatsController.text = widget.ride.totalSeats.toString();
    _pricePerSeatController.text = widget.ride.pricePerSeat.toStringAsFixed(0);
    _selectedDate = widget.ride.travelDate;
    
    // Parse departure time
    final timeParts = widget.ride.departureTime.split(':');
    _departureTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );
    
    if (widget.ride.adminNotes != null) {
      _adminNotesController.text = widget.ride.adminNotes!;
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _totalSeatsController.dispose();
    _pricePerSeatController.dispose();
    _adminNotesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _departureTime,
    );
    if (picked != null) {
      setState(() => _departureTime = picked);
    }
  }

  Future<void> _updateRide() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final departureTimeStr = '${_departureTime.hour.toString().padLeft(2, '0')}:${_departureTime.minute.toString().padLeft(2, '0')}';

      final request = AdminUpdateRideRequest(
        pickupLocation: _pickupController.text != widget.ride.pickupLocation
            ? LocationDto(
                address: _pickupController.text,
                latitude: 21.0, // TODO: Implement location search
                longitude: 79.0,
              )
            : null,
        dropoffLocation: _dropoffController.text != widget.ride.dropoffLocation
            ? LocationDto(
                address: _dropoffController.text,
                latitude: 20.5,
                longitude: 78.5,
              )
            : null,
        travelDate: _selectedDate != widget.ride.travelDate ? _selectedDate : null,
        departureTime: departureTimeStr != widget.ride.departureTime ? departureTimeStr : null,
        totalSeats: int.parse(_totalSeatsController.text) != widget.ride.totalSeats
            ? int.parse(_totalSeatsController.text)
            : null,
        pricePerSeat: double.parse(_pricePerSeatController.text) != widget.ride.pricePerSeat
            ? double.parse(_pricePerSeatController.text)
            : null,
        adminNotes: _adminNotesController.text.isNotEmpty ? _adminNotesController.text : null,
      );

      final success = await ref.read(adminRideNotifierProvider.notifier).updateRide(
            widget.ride.rideId,
            request,
          );

      if (mounted) {
        setState(() => _isSubmitting = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ride ${widget.ride.rideNumber} updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update ride'),
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
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                color: AdminTheme.primaryColor,
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reschedule Ride',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.ride.rideNumber,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Warning for booked seats
              if (widget.ride.bookedSeats > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.orange[50],
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${widget.ride.bookedSeats} passenger(s) have booked this ride. Changes may affect their bookings.',
                          style: const TextStyle(fontSize: 12),
                        ),
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
                      // Driver Info (readonly)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Driver',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    widget.ride.driverName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Route Details
                      const Text(
                        'Route Details',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pickupController,
                        decoration: const InputDecoration(
                          labelText: 'Pickup Location *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.trip_origin, color: Colors.green),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _dropoffController,
                        decoration: const InputDecoration(
                          labelText: 'Dropoff Location *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on, color: Colors.red),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
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

                      // Pricing & Capacity
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
                              decoration: InputDecoration(
                                labelText: 'Total Seats *',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.airline_seat_recline_normal),
                                helperText: widget.ride.bookedSeats > 0
                                    ? 'Min: ${widget.ride.bookedSeats} (booked)'
                                    : null,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Required';
                                final seats = int.tryParse(value!);
                                if (seats == null || seats <= 0) return 'Invalid';
                                if (seats < widget.ride.bookedSeats) {
                                  return 'Cannot be less than ${widget.ride.bookedSeats}';
                                }
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
                      onPressed: _isSubmitting ? null : _updateRide,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(_isSubmitting ? 'Updating...' : 'Update Ride'),
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
}
