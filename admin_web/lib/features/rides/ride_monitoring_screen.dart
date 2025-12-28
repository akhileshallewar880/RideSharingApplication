import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/admin_models.dart';
import '../../core/providers/ride_provider.dart';
import '../../core/theme/admin_theme.dart';

class RideMonitoringScreen extends ConsumerStatefulWidget {
  const RideMonitoringScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RideMonitoringScreen> createState() => _RideMonitoringScreenState();
}

class _RideMonitoringScreenState extends ConsumerState<RideMonitoringScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadRides();
    
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(AppConstants.refreshInterval, (_) {
      _loadRides();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadRides() {
    ref.read(activeRidesProvider.notifier).loadActiveRides();
  }

  Future<void> _cancelRide(RideInfo ride) async {
    final reason = await _showCancelDialog();
    
    if (reason != null && reason.isNotEmpty) {
      await ref.read(activeRidesProvider.notifier).cancelRide(ride.id, reason);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ride cancelled successfully'),
            backgroundColor: AdminTheme.warningColor,
          ),
        );
      }
    }
  }

  Future<String?> _showCancelDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Ride'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please provide a reason for cancellation:'),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g., Emergency, safety concern...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.errorColor,
            ),
            child: Text('Cancel Ride'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ridesState = ref.watch(activeRidesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Active Rides Monitoring'),
        actions: [
          // Last Updated
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                'Updated: ${DateFormat('hh:mm:ss a').format(ridesState.lastUpdated)}',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadRides,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Summary
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Active Rides',
                    ridesState.rides.length.toString(),
                    Icons.local_taxi,
                    AdminTheme.infoColor,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Requested',
                    ridesState.rides
                        .where((r) => r.status == AppConstants.rideRequested)
                        .length
                        .toString(),
                    Icons.pending,
                    AdminTheme.warningColor,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'In Progress',
                    ridesState.rides
                        .where((r) => r.status == AppConstants.rideInProgress)
                        .length
                        .toString(),
                    Icons.directions_car,
                    AdminTheme.successColor,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),

          // Rides List
          Expanded(
            child: ridesState.isLoading && ridesState.rides.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ridesState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: AdminTheme.errorColor),
                            SizedBox(height: 16),
                            Text(
                              ridesState.error!,
                              style: TextStyle(color: AdminTheme.errorColor),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadRides,
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : ridesState.rides.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline,
                                    size: 64, color: AdminTheme.successColor),
                                SizedBox(height: 16),
                                Text(
                                  'No active rides',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: AdminTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth > 800) {
                                return _buildDataTable(ridesState.rides);
                              } else {
                                return _buildListView(ridesState.rides);
                              }
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: AdminTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(List<RideInfo> rides) {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 32,
          ),
          child: DataTable(
            columns: [
              DataColumn(label: Text('Ride #')),
              DataColumn(label: Text('Passenger')),
              DataColumn(label: Text('Driver')),
              DataColumn(label: Text('Pickup')),
              DataColumn(label: Text('Dropoff')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Fare')),
              DataColumn(label: Text('Time')),
              DataColumn(label: Text('Actions')),
            ],
            rows: rides.map((ride) {
              return DataRow(
                cells: [
                  DataCell(Text(
                    ride.rideNumber,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  )),
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(ride.passenger.name),
                        Text(
                          ride.passenger.phone,
                          style: TextStyle(
                            fontSize: 12,
                            color: AdminTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    ride.driver != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(ride.driver!.name),
                              Text(
                                ride.driver!.vehicleNumber,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AdminTheme.textSecondary,
                                ),
                              ),
                            ],
                          )
                        : Text('Not assigned'),
                  ),
                  DataCell(
                    SizedBox(
                      width: 150,
                      child: Text(
                        ride.pickup.address,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 150,
                      child: Text(
                        ride.dropoff.address,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(_buildStatusChip(ride.status)),
                  DataCell(Text('₹${ride.estimatedFare.toStringAsFixed(0)}')),
                  DataCell(Text(
                    DateFormat('hh:mm a').format(ride.requestedAt),
                  )),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.visibility, size: 20),
                          onPressed: () {
                            _showRideDetails(ride);
                          },
                          tooltip: 'View Details',
                        ),
                        IconButton(
                          icon: Icon(Icons.cancel, size: 20),
                          onPressed: () => _cancelRide(ride),
                          color: AdminTheme.errorColor,
                          tooltip: 'Cancel Ride',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<RideInfo> rides) {
    return ListView.builder(
      itemCount: rides.length,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final ride = rides[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _showRideDetails(ride),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ride.rideNumber,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _buildStatusChip(ride.status),
                    ],
                  ),
                  SizedBox(height: 12),
                  Divider(),
                  SizedBox(height: 12),
                  _buildInfoRow(Icons.person, 'Passenger', ride.passenger.name),
                  SizedBox(height: 8),
                  if (ride.driver != null)
                    _buildInfoRow(Icons.drive_eta, 'Driver',
                        '${ride.driver!.name} - ${ride.driver!.vehicleNumber}'),
                  SizedBox(height: 8),
                  _buildInfoRow(Icons.location_on, 'Pickup', ride.pickup.address),
                  SizedBox(height: 8),
                  _buildInfoRow(Icons.flag, 'Dropoff', ride.dropoff.address),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${ride.estimatedFare.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AdminTheme.primaryColor,
                        ),
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.cancel, size: 18),
                        label: Text('Cancel'),
                        onPressed: () => _cancelRide(ride),
                        style: TextButton.styleFrom(
                          foregroundColor: AdminTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AdminTheme.getStatusBackgroundColor(status),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: AdminTheme.getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AdminTheme.textSecondary),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: AdminTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showRideDetails(RideInfo ride) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ride Details - ${ride.rideNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Status', ride.status.toUpperCase()),
              Divider(),
              _buildDetailRow('Passenger', ride.passenger.name),
              _buildDetailRow('Phone', ride.passenger.phone),
              if (ride.driver != null) ...[
                Divider(),
                _buildDetailRow('Driver', ride.driver!.name),
                _buildDetailRow('Vehicle', ride.driver!.vehicleNumber),
                _buildDetailRow('Vehicle Type', ride.driver!.vehicleType),
              ],
              Divider(),
              _buildDetailRow('Pickup', ride.pickup.address),
              _buildDetailRow('Dropoff', ride.dropoff.address),
              Divider(),
              _buildDetailRow(
                'Requested At',
                DateFormat('dd MMM yyyy, hh:mm a').format(ride.requestedAt),
              ),
              if (ride.acceptedAt != null)
                _buildDetailRow(
                  'Accepted At',
                  DateFormat('dd MMM yyyy, hh:mm a').format(ride.acceptedAt!),
                ),
              if (ride.startedAt != null)
                _buildDetailRow(
                  'Started At',
                  DateFormat('dd MMM yyyy, hh:mm a').format(ride.startedAt!),
                ),
              Divider(),
              _buildDetailRow('Estimated Fare', '₹${ride.estimatedFare.toStringAsFixed(2)}'),
              if (ride.distance != null)
                _buildDetailRow('Distance', '${ride.distance!.toStringAsFixed(2)} km'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelRide(ride);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.errorColor,
            ),
            child: Text('Cancel Ride'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AdminTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
