import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/admin_ride_models.dart';
import '../../core/providers/admin_ride_provider.dart';
import '../../core/theme/admin_theme.dart';
import 'admin_schedule_ride_dialog.dart';
import 'admin_reschedule_ride_dialog.dart';
import 'admin_ride_details_dialog.dart';

class AdminRideManagementScreen extends ConsumerStatefulWidget {
  const AdminRideManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminRideManagementScreen> createState() => _AdminRideManagementScreenState();
}

class _AdminRideManagementScreenState extends ConsumerState<AdminRideManagementScreen> {
  String _selectedStatus = 'all';
  String? _selectedDriverId;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    // Defer provider update until after build to avoid lifecycle violation
    Future.microtask(() => _loadRides());
  }

  void _loadRides() {
    ref.read(adminRideNotifierProvider.notifier).loadRides(
          status: _selectedStatus == 'all' ? null : _selectedStatus,
          driverId: _selectedDriverId,
          fromDate: _fromDate,
          toDate: _toDate,
        );
  }

  Future<void> _showScheduleRideDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AdminScheduleRideDialog(),
    );

    if (result == true) {
      _loadRides();
    }
  }

  Future<void> _showRescheduleDialog(AdminRideInfo ride) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AdminRescheduleRideDialog(ride: ride),
    );

    if (result == true) {
      _loadRides();
    }
  }

  Future<void> _showCancelDialog(AdminRideInfo ride) async {
    final reasonController = TextEditingController();
    bool notifyPassengers = true;

    await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Cancel Ride'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to cancel ride ${ride.rideNumber}?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                '${ride.pickupLocation} → ${ride.dropoffLocation}',
                style: const TextStyle(color: Colors.grey),
              ),
              Text(
                'Date: ${DateFormat('dd MMM yyyy').format(ride.travelDate)} ${ride.departureTime}',
                style: const TextStyle(color: Colors.grey),
              ),
              Text(
                'Booked: ${ride.bookedSeats}/${ride.totalSeats} seats',
                style: TextStyle(
                  color: ride.bookedSeats > 0 ? Colors.orange : Colors.grey,
                  fontWeight: ride.bookedSeats > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Cancellation Reason',
                  hintText: 'Enter reason for cancellation',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Notify Passengers'),
                subtitle: Text(
                  ride.bookedSeats > 0
                      ? 'Send notification to ${ride.bookedSeats} passenger(s)'
                      : 'No passengers to notify',
                ),
                value: notifyPassengers,
                onChanged: ride.bookedSeats > 0
                    ? (value) {
                        setState(() {
                          notifyPassengers = value ?? true;
                        });
                      }
                    : null,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please provide a cancellation reason')),
                  );
                  return;
                }

                Navigator.pop(context, true);
                
                final success = await ref.read(adminRideNotifierProvider.notifier).cancelRide(
                      ride.rideId,
                      reason: reason,
                      notifyPassengers: notifyPassengers,
                    );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Ride cancelled successfully'
                          : 'Failed to cancel ride'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.errorColor,
              ),
              child: const Text('Cancel Ride'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminRideNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Management'),
        backgroundColor: AdminTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRides,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filters
          _buildFilters(),
          
          // Rides List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.errorMessage != null
                    ? _buildError(state.errorMessage!)
                    : state.rides.isEmpty
                        ? _buildEmptyState()
                        : _buildRidesList(state.rides),
          ),

          // Pagination
          if (state.totalPages > 1) _buildPagination(state),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showScheduleRideDialog,
        backgroundColor: AdminTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Schedule Ride'),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          // Status Filter - Enhanced
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButton<String>(
              value: _selectedStatus,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: AdminTheme.primaryColor),
              items: [
                DropdownMenuItem(
                  value: 'all',
                  child: Row(
                    children: [
                      Icon(Icons.list, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      const Text('All Status'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'scheduled',
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text('Scheduled'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'active',
                  child: Row(
                    children: [
                      Icon(Icons.directions_car, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text('Active'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'completed',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      const Text('Completed'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'cancelled',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text('Cancelled'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value ?? 'all';
                });
                _loadRides();
              },
            ),
          ),

          // Date Range
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range),
            label: Text(_fromDate != null && _toDate != null
                ? '${DateFormat('MMM dd').format(_fromDate!)} - ${DateFormat('MMM dd').format(_toDate!)}'
                : 'Select Date Range'),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDateRange: _fromDate != null && _toDate != null
                    ? DateTimeRange(start: _fromDate!, end: _toDate!)
                    : null,
              );

              if (picked != null) {
                setState(() {
                  _fromDate = picked.start;
                  _toDate = picked.end;
                });
                _loadRides();
              }
            },
          ),

          if (_fromDate != null || _toDate != null)
            OutlinedButton.icon(
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
              onPressed: () {
                setState(() {
                  _fromDate = null;
                  _toDate = null;
                });
                _loadRides();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRidesList(List<AdminRideInfo> rides) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rides.length,
      itemBuilder: (context, index) {
        final ride = rides[index];
        return _buildRideCard(ride);
      },
    );
  }

  Widget _buildRideCard(AdminRideInfo ride) {
    final statusColor = _getStatusColor(ride.status);
    final canModify = ride.status.toLowerCase() != 'completed' &&
        ride.status.toLowerCase() != 'cancelled';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showRideDetails(ride),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            ride.rideNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ride.status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Driver: ${ride.driverName}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (canModify)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'reschedule') {
                        _showRescheduleDialog(ride);
                      } else if (value == 'cancel') {
                        _showCancelDialog(ride);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'reschedule',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Reschedule'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Row(
                          children: [
                            Icon(Icons.cancel, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Cancel', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const Divider(height: 24),

            // Route
            Row(
              children: [
                const Icon(Icons.trip_origin, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ride.pickupLocation,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ride.dropoffLocation,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Details
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildDetailChip(
                  Icons.calendar_today,
                  DateFormat('dd MMM yyyy').format(ride.travelDate),
                ),
                _buildDetailChip(Icons.access_time, ride.departureTime),
                _buildDetailChip(
                  Icons.airline_seat_recline_normal,
                  '${ride.bookedSeats}/${ride.totalSeats} seats',
                  color: ride.bookedSeats == ride.totalSeats ? Colors.red : null,
                ),
                _buildDetailChip(
                  Icons.attach_money,
                  '₹${ride.pricePerSeat.toStringAsFixed(0)}/seat',
                  color: Colors.green,
                ),
              ],
            ),

            if (ride.vehicleNumber != null || ride.vehicleModel != null) ...[
              const SizedBox(height: 8),
              Text(
                '${ride.vehicleModel ?? ''} ${ride.vehicleNumber ?? ''}'.trim(),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],

            if (ride.adminNotes != null && ride.adminNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ride.adminNotes!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }

  void _showRideDetails(AdminRideInfo ride) {
    showDialog(
      context: context,
      builder: (context) => AdminRideDetailsDialog(ride: ride),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'active':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No rides found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to schedule a new ride',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadRides,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(AdminRideState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: state.currentPage > 1
                ? () => ref.read(adminRideNotifierProvider.notifier).loadPreviousPage()
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
          ),
          Text(
            'Page ${state.currentPage} of ${state.totalPages}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ElevatedButton.icon(
            onPressed: state.currentPage < state.totalPages
                ? () => ref.read(adminRideNotifierProvider.notifier).loadNextPage()
                : null,
            label: const Text('Next'),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
