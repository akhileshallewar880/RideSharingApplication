import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/admin_ride_models.dart';
import '../../core/theme/admin_theme.dart';
import '../tracking/widgets/ride_tracking_timeline.dart';

class AdminRideDetailsDialog extends StatefulWidget {
  final AdminRideInfo ride;

  const AdminRideDetailsDialog({Key? key, required this.ride}) : super(key: key);

  @override
  State<AdminRideDetailsDialog> createState() => _AdminRideDetailsDialogState();
}

class _AdminRideDetailsDialogState extends State<AdminRideDetailsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'active':
      case 'in_progress':
      case 'inprogress':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.ride.status);

    return Dialog(
      child: Container(
        width: 900,
        constraints: const BoxConstraints(maxHeight: 850),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: AdminTheme.primaryColor,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ride Details - ${widget.ride.rideNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.ride.status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
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

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AdminTheme.primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AdminTheme.primaryColor,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.info_outline),
                    text: 'Ride Information',
                  ),
                  Tab(
                    icon: Icon(Icons.route),
                    text: 'Live Tracking',
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Ride Information
                  _buildRideInformationTab(),

                  // Tab 2: Live Tracking
                  _buildTrackingTab(),
                ],
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
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.primaryColor,
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideInformationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Driver Information
          _buildSection(
            'Driver Information',
            Icons.person,
            [
              _buildInfoRow('Driver Name', widget.ride.driverName),
              if (widget.ride.vehicleModel != null)
                _buildInfoRow('Vehicle Model', widget.ride.vehicleModel!),
              if (widget.ride.vehicleNumber != null)
                _buildInfoRow('Vehicle Number', widget.ride.vehicleNumber!),
            ],
          ),

          const SizedBox(height: 24),

          // Route Information
          _buildSection(
            'Route Information',
            Icons.route,
            [
              _buildRouteInfo(
                'Pickup',
                widget.ride.pickupLocation,
                Icons.trip_origin,
                Colors.green,
              ),
              const SizedBox(height: 8),
              _buildRouteInfo(
                'Dropoff',
                widget.ride.dropoffLocation,
                Icons.location_on,
                Colors.red,
              ),
              if (widget.ride.distance != null || widget.ride.duration != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      if (widget.ride.distance != null) ...[
                        Icon(Icons.straighten, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.ride.distance!.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      if (widget.ride.distance != null && widget.ride.duration != null)
                        const SizedBox(width: 16),
                      if (widget.ride.duration != null) ...[
                        Icon(Icons.access_time, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(widget.ride.duration!),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 24),

          // Schedule Information
          _buildSection(
            'Schedule Information',
            Icons.schedule,
            [
              _buildInfoRow(
                'Travel Date',
                DateFormat('dd MMM yyyy').format(widget.ride.travelDate),
              ),
              _buildInfoRow('Departure Time', widget.ride.departureTime),
              _buildInfoRow(
                'Scheduled On',
                DateFormat('dd MMM yyyy, hh:mm a').format(widget.ride.createdAt),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Pricing & Capacity
          _buildSection(
            'Pricing & Capacity',
            Icons.attach_money,
            [
              _buildInfoRow('Total Seats', widget.ride.totalSeats.toString()),
              _buildInfoRow('Booked Seats', widget.ride.bookedSeats.toString()),
              _buildInfoRow(
                'Available Seats',
                (widget.ride.totalSeats - widget.ride.bookedSeats).toString(),
              ),
              _buildInfoRow(
                'Price per Seat',
                '₹${widget.ride.pricePerSeat.toStringAsFixed(0)}',
              ),
              _buildInfoRow(
                'Total Revenue',
                '₹${(widget.ride.pricePerSeat * widget.ride.bookedSeats).toStringAsFixed(0)}',
              ),
            ],
          ),

          // Segment Pricing
          if (widget.ride.segmentPrices != null && widget.ride.segmentPrices!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSegmentPricing(widget.ride.segmentPrices!),
          ],

          // Passenger OTP
          if (widget.ride.passengerOtp != null) ...[
            const SizedBox(height: 24),
            _buildSection(
              'Passenger OTP',
              Icons.pin,
              [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      widget.ride.passengerOtp!,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Admin Notes
          if (widget.ride.adminNotes != null && widget.ride.adminNotes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSection(
              'Admin Notes',
              Icons.note,
              [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.ride.adminNotes!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackingTab() {
    // Convert AdminRideInfo to a map that the timeline widget expects
    final rideMap = {
      'rideId': widget.ride.rideId,
      'rideNumber': widget.ride.rideNumber,
      'pickupLocation': widget.ride.pickupLocation,
      'dropoffLocation': widget.ride.dropoffLocation,
      'scheduledTime': widget.ride.travelDate.toIso8601String(),
      'status': widget.ride.status,
      'segmentPrices': widget.ride.segmentPrices,
      'intermediateStops': widget.ride.intermediateStops,
      'distance': widget.ride.distance,
      'duration': widget.ride.duration,
      'departureTime': widget.ride.departureTime,
      'pickupLatitude': widget.ride.pickupLatitude,
      'pickupLongitude': widget.ride.pickupLongitude,
      'dropoffLatitude': widget.ride.dropoffLatitude,
      'dropoffLongitude': widget.ride.dropoffLongitude,
      'passengers': [], // TODO: Fetch passengers from API when available
    };

    return RideTrackingTimeline(
      ride: rideMap,
      isDark: false,
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AdminTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(String label, String address, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentPricing(List<dynamic> segmentPrices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.route, color: AdminTheme.primaryColor),
            const SizedBox(width: 8),
            const Text(
              'Segment Pricing',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(segmentPrices.length, (index) {
          final segment = segmentPrices[index] is Map<String, dynamic> 
              ? segmentPrices[index] as Map<String, dynamic>
              : segmentPrices[index];
          
          final fromLocation = segment['fromLocation']?.toString() ?? segment['FromLocation']?.toString() ?? 'Unknown';
          final toLocation = segment['toLocation']?.toString() ?? segment['ToLocation']?.toString() ?? 'Unknown';
          final price = (segment['price'] ?? segment['Price'] ?? 0).toDouble();
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AdminTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Segment ${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AdminTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              fromLocation,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.only(left: 18),
                        child: Icon(Icons.arrow_downward, size: 10, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.red),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              toLocation,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '₹${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '$hours hr';
    }
    return '$hours hr $mins min';
  }
}
