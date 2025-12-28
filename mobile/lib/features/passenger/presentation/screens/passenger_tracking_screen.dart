import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/models/passenger_ride_models.dart';
import '../../../../core/providers/location_tracking_provider.dart';
import '../../../../app/themes/app_colors.dart';
import '../../../../core/widgets/mock_location_debug_panel.dart';
import '../widgets/trip_progress_timeline.dart';

/// Passenger tracking screen - shows live driver location and trip progress
class PassengerTrackingScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final BookingResponse bookingDetails;

  const PassengerTrackingScreen({
    super.key,
    required this.bookingId,
    required this.bookingDetails,
  });

  @override
  ConsumerState<PassengerTrackingScreen> createState() => _PassengerTrackingScreenState();
}

class _PassengerTrackingScreenState extends ConsumerState<PassengerTrackingScreen> {
  GoogleMapController? _mapController;
  bool _followDriver = true;

  @override
  void initState() {
    super.initState();
    // Join ride room for real-time updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationTrackingProvider.notifier).joinRideAsPassenger(
        widget.bookingDetails.rideId,
      );
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(locationTrackingProvider);
    final driverLocation = trackingState.driverLocation;
    
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Google Map
            _buildMap(driverLocation, trackingState),
            
            // Top header
            _buildTopHeader(context, trackingState),
            
            // Bottom sheet with trip progress
            _buildBottomSheet(context, trackingState),
            
            // Center on driver FAB
            if (driverLocation != null)
              _buildCenterButton(),
            
            // Mock Location Debug Panel (only visible in debug mode)
            MockLocationDebugPanel(
              onMockModeChanged: () {
                // Rejoin ride room to restart tracking
                ref.read(locationTrackingProvider.notifier).joinRideAsPassenger(
                  widget.bookingDetails.rideId,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(dynamic driverLocation, LocationTrackingState trackingState) {
    // Default to pickup location if driver location not available
    final initialPosition = driverLocation != null
        ? LatLng(driverLocation.latitude, driverLocation.longitude)
        : const LatLng(20.1809, 80.0016);
    
    final markers = _buildMarkers(driverLocation);
    
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: 14,
      ),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      compassEnabled: true,
      mapToolbarEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
        if (driverLocation != null && _followDriver) {
          _animateToDriver(driverLocation);
        }
      },
      onCameraMove: (_) {
        // User manually moved map
        if (_followDriver) {
          setState(() => _followDriver = false);
        }
      },
    );
  }

  Set<Marker> _buildMarkers(dynamic driverLocation) {
    final markers = <Marker>{};
    
    // Driver location marker with car icon
    if (driverLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(driverLocation.latitude, driverLocation.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: widget.bookingDetails.driverDetails.name,
            snippet: widget.bookingDetails.driverDetails.vehicleNumber,
          ),
          rotation: driverLocation.heading,
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }
    
    // TODO: Add pickup and dropoff markers
    
    return markers;
  }

  void _animateToDriver(dynamic location) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(location.latitude, location.longitude),
        16,
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, LocationTrackingState trackingState) {
    final eta = trackingState.estimatedArrival;
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Trip',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        widget.bookingDetails.driverDetails.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Driver avatar and rating
                Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryYellow,
                      child: Text(
                        widget.bookingDetails.driverDetails.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          widget.bookingDetails.driverDetails.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Vehicle and ETA info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Number plate widget
                  _buildNumberPlate(widget.bookingDetails.driverDetails.vehicleNumber),
                  const SizedBox(width: 8),
                  // Vehicle model
                  Expanded(
                    child: Text(
                      widget.bookingDetails.driverDetails.vehicleModel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryYellow,
                      ),
                    ),
                  ),
                  if (eta != null) ...[
                    Icon(Icons.access_time, size: 16, color: AppColors.primaryYellow),
                    const SizedBox(width: 4),
                    Text(
                      '$eta min',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryYellow,
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

  Widget _buildBottomSheet(BuildContext context, LocationTrackingState trackingState) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.25,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Trip status
              _buildTripStatus(trackingState),
              const SizedBox(height: 24),
              // Route info
              _buildRouteInfo(),
              const SizedBox(height: 24),
              // Trip progress timeline
              TripProgressTimeline(
                pickupLocation: widget.bookingDetails.pickupLocation,
                dropoffLocation: widget.bookingDetails.dropoffLocation,
                currentStatus: _determineCurrentStatus(trackingState),
                intermediateStops: trackingState.intermediateStops,
              ),
              const SizedBox(height: 24),
              // Contact driver button
              _buildContactButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTripStatus(LocationTrackingState trackingState) {
    final distance = trackingState.remainingDistance;
    final eta = trackingState.estimatedArrival;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            icon: Icons.navigation,
            label: 'Distance',
            value: distance != null ? '${distance.toStringAsFixed(1)} km' : '--',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            icon: Icons.schedule,
            label: 'ETA',
            value: eta != null ? '$eta min' : '--',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            icon: Icons.people,
            label: 'Passengers',
            value: '${widget.bookingDetails.passengerCount}',
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Journey',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildRoutePoint(
            icon: Icons.trip_origin,
            location: widget.bookingDetails.pickupLocation,
            label: 'Pickup',
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          _buildRoutePoint(
            icon: Icons.location_on,
            location: widget.bookingDetails.dropoffLocation,
            label: 'Drop-off',
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildRoutePoint({
    required IconData icon,
    required String location,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactButton() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Call driver
            },
            icon: const Icon(Icons.phone),
            label: const Text('Call Driver'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: AppColors.primaryYellow),
              foregroundColor: AppColors.primaryYellow,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Message driver
            },
            icon: const Icon(Icons.message),
            label: const Text('Message'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: AppColors.primaryYellow),
              foregroundColor: AppColors.primaryYellow,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCenterButton() {
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).size.height * 0.35,
      child: FloatingActionButton.small(
        onPressed: () {
          setState(() => _followDriver = true);
          final driverLocation = ref.read(locationTrackingProvider).driverLocation;
          if (driverLocation != null) {
            _animateToDriver(driverLocation);
          }
        },
        backgroundColor: _followDriver ? AppColors.primaryYellow : Colors.white,
        child: Icon(
          Icons.my_location,
          color: _followDriver ? Colors.white : AppColors.primaryYellow,
        ),
      ),
    );
  }

  String _determineCurrentStatus(LocationTrackingState trackingState) {
    // Logic to determine current trip status
    // For now, return a default status
    return 'en_route';
  }

  Widget _buildNumberPlate(String vehicleNumber) {
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
}
