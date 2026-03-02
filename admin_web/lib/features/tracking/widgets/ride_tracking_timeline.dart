import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../../core/providers/live_tracking_provider.dart';

// ─────────────────────────────────────────────────────────────
//  Stop type enum
// ─────────────────────────────────────────────────────────────
enum StopType { start, intermediate, end }

// ─────────────────────────────────────────────────────────────
//  TrainStop data model (mirrors driver screen's TrainStop)
// ─────────────────────────────────────────────────────────────
class TrainStop {
  final String name;
  final DateTime time; // Scheduled ETA
  final StopType type;
  final int pickupCount;
  final int dropoffCount;
  final double? segmentDistance; // Incoming distance: prev stop → this stop
  final double distance; // Cumulative distance from origin
  final double? latitude;
  final double? longitude;

  TrainStop({
    required this.name,
    required this.time,
    required this.type,
    required this.pickupCount,
    required this.dropoffCount,
    this.segmentDistance,
    required this.distance,
    this.latitude,
    this.longitude,
  });
}

// ─────────────────────────────────────────────────────────────
//  RideTrackingTimeline widget
// ─────────────────────────────────────────────────────────────
class RideTrackingTimeline extends ConsumerStatefulWidget {
  final dynamic ride;
  final bool isDark;

  const RideTrackingTimeline({
    Key? key,
    required this.ride,
    this.isDark = false,
  }) : super(key: key);

  @override
  ConsumerState<RideTrackingTimeline> createState() =>
      _RideTrackingTimelineState();
}

class _RideTrackingTimelineState extends ConsumerState<RideTrackingTimeline> {
  // ── Mirrors _currentStopIndex in DriverTrackingScreen ──
  int _currentStopIndex = 0;

  // Actual arrival times keyed by stop index
  final Map<int, DateTime> _arrivalTimes = {};

  // Cached stop list (route doesn't change during a ride)
  List<TrainStop>? _cachedStops;

  // Guard to avoid re-scheduling update callbacks for the same location
  String? _lastLocationKey;

  @override
  void initState() {
    super.initState();
    final rideId = widget.ride['rideId']?.toString();
    if (rideId != null && rideId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(liveTrackingProvider.notifier).trackRide(rideId);
        }
      });
    }
  }

  @override
  void dispose() {
    final rideId = widget.ride['rideId']?.toString();
    if (rideId != null && rideId.isNotEmpty) {
      try {
        ref.read(liveTrackingProvider.notifier).stopTrackingRide(rideId);
      } catch (_) {}
    }
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  //  Stop list builder (pure data, no GPS logic)
  // ─────────────────────────────────────────────────────────────
  List<TrainStop> _getStops() {
    _cachedStops ??= _buildStopsList();
    return _cachedStops!;
  }

  List<TrainStop> _buildStopsList() {
    try {
      final pickup = widget.ride['pickupLocation']?.toString() ?? '';
      final dropoff = widget.ride['dropoffLocation']?.toString() ?? '';
      if (pickup.isEmpty || dropoff.isEmpty) return [];

      final intermediateRaw = widget.ride['intermediateStops'];
      final List<String> intermediates = intermediateRaw is List
          ? intermediateRaw.map((s) => s.toString()).toList()
          : [];

      final orderedRoute = <String>[pickup, ...intermediates, dropoff];
      final n = orderedRoute.length;

      final totalDistance = _parseDouble(widget.ride['distance']);
      final totalDuration = (widget.ride['duration'] as int?) ?? 0;
      final numSegments = math.max(1, n - 1);
      final perSegDist = totalDistance > 0 ? totalDistance / numSegments : null;
      final perSegDur =
          totalDuration > 0 ? (totalDuration / numSegments).round() : 0;

      // Pickup / dropoff coordinates (only these two are available from API)
      final pickupLat = (widget.ride['pickupLatitude'] as num?)?.toDouble();
      final pickupLng = (widget.ride['pickupLongitude'] as num?)?.toDouble();
      final dropoffLat = (widget.ride['dropoffLatitude'] as num?)?.toDouble();
      final dropoffLng = (widget.ride['dropoffLongitude'] as num?)?.toDouble();

      // Parse departure time (HH:mm) on the scheduled date
      final scheduledTime =
          widget.ride['scheduledTime'] != null
              ? DateTime.tryParse(widget.ride['scheduledTime'].toString()) ??
                  DateTime.now()
              : DateTime.now();

      DateTime startTime = scheduledTime;
      if (widget.ride['departureTime'] != null) {
        try {
          final parts = widget.ride['departureTime'].toString().split(':');
          if (parts.length >= 2) {
            startTime = DateTime(
              scheduledTime.year,
              scheduledTime.month,
              scheduledTime.day,
              int.parse(parts[0]),
              int.parse(parts[1]),
            );
          }
        } catch (_) {}
      }

      final stops = <TrainStop>[];
      double cumulativeDist = 0.0;
      int cumulativeMin = 0;

      for (int i = 0; i < n; i++) {
        final isFirst = i == 0;
        final isLast = i == n - 1;

        // Accumulate segment before this stop
        if (!isFirst) {
          cumulativeDist += perSegDist ?? 0.0;
          cumulativeMin += perSegDur;
        }

        stops.add(TrainStop(
          name: orderedRoute[i],
          time: startTime.add(Duration(minutes: cumulativeMin)),
          type: isFirst
              ? StopType.start
              : isLast
                  ? StopType.end
                  : StopType.intermediate,
          pickupCount: 0,
          dropoffCount: 0,
          // Incoming segment distance (null for origin → no label shown)
          segmentDistance: isFirst ? null : perSegDist,
          distance: cumulativeDist,
          // Coordinates only for pickup and dropoff
          latitude: isFirst ? pickupLat : (isLast ? dropoffLat : null),
          longitude: isFirst ? pickupLng : (isLast ? dropoffLng : null),
        ));
      }

      return stops;
    } catch (e) {
      print('Error building stops: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  GPS: update _currentStopIndex (mirrors _updateCurrentStop)
  // ─────────────────────────────────────────────────────────────
  void _updateCurrentStopImpl(
      RideLocation driverLocation, List<TrainStop> stops) {
    if (stops.isEmpty) return;
    final n = stops.length;

    // 1. Haversine check against stops with known coordinates (4 km radius)
    double minDist = double.infinity;
    int closestIdx = _currentStopIndex;
    for (int i = 0; i < n; i++) {
      if (stops[i].latitude != null && stops[i].longitude != null) {
        final d = _haversine(
          driverLocation.latitude,
          driverLocation.longitude,
          stops[i].latitude!,
          stops[i].longitude!,
        );
        if (d < minDist) {
          minDist = d;
          closestIdx = i;
        }
      }
    }

    final isDestination = closestIdx == n - 1;
    if (minDist < 4.0 &&
        (closestIdx > _currentStopIndex ||
            (isDestination && closestIdx >= _currentStopIndex))) {
      setState(() {
        for (int i = _currentStopIndex; i <= closestIdx; i++) {
          _arrivalTimes[i] ??= DateTime.now();
        }
        _currentStopIndex = closestIdx;
      });
      return;
    }

    if (minDist < 4.0 && closestIdx == _currentStopIndex) {
      setState(() {
        _arrivalTimes[closestIdx] ??= DateTime.now();
      });
      return;
    }

    // 2. Fallback: GPS progress ratio for intermediate stops without coords
    final pickupLat = stops.first.latitude;
    final pickupLng = stops.first.longitude;
    final dropoffLat = stops.last.latitude;
    final dropoffLng = stops.last.longitude;
    if (pickupLat == null ||
        pickupLng == null ||
        dropoffLat == null ||
        dropoffLng == null) return;

    final progress = _computeDriverProgress(
      driverLocation.latitude,
      driverLocation.longitude,
      pickupLat,
      pickupLng,
      dropoffLat,
      dropoffLng,
    );

    // Equal-interval thresholds for stops
    int newIdx = _currentStopIndex;
    for (int i = _currentStopIndex + 1; i < n; i++) {
      final threshold = n == 1 ? 1.0 : i / (n - 1).toDouble();
      if (progress >= threshold - 0.03) newIdx = i;
    }

    if (newIdx > _currentStopIndex) {
      setState(() {
        for (int i = _currentStopIndex; i <= newIdx; i++) {
          _arrivalTimes[i] ??= DateTime.now();
        }
        _currentStopIndex = newIdx;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Vehicle position (mirrors _calculateVehiclePosition)
  // ─────────────────────────────────────────────────────────────
  Map<String, dynamic> _calculateVehiclePosition(
      RideLocation driverLocation, List<TrainStop> stops) {
    if (stops.length < 2) return {'atNodeIndex': _currentStopIndex};

    // Check if vehicle is within 4 km of any node with coordinates
    double minNodeDist = 4.0;
    int? closestNode;
    for (int i = 0; i < stops.length; i++) {
      if (stops[i].latitude != null && stops[i].longitude != null) {
        final d = _haversine(
          driverLocation.latitude,
          driverLocation.longitude,
          stops[i].latitude!,
          stops[i].longitude!,
        );
        if (d < minNodeDist) {
          minNodeDist = d;
          closestNode = i;
        }
      }
    }
    if (closestNode != null) return {'atNodeIndex': closestNode};

    // Find the closest segment
    double minDev = double.infinity;
    int segIdx = _currentStopIndex < stops.length - 1
        ? _currentStopIndex
        : stops.length - 2;
    double progress = 0.0;

    for (int i = 0; i < stops.length - 1; i++) {
      if (stops[i].latitude != null &&
          stops[i].longitude != null &&
          stops[i + 1].latitude != null &&
          stops[i + 1].longitude != null) {
        final dFrom = _haversine(
          driverLocation.latitude,
          driverLocation.longitude,
          stops[i].latitude!,
          stops[i].longitude!,
        );
        final dTo = _haversine(
          driverLocation.latitude,
          driverLocation.longitude,
          stops[i + 1].latitude!,
          stops[i + 1].longitude!,
        );
        final segLen = _haversine(
          stops[i].latitude!,
          stops[i].longitude!,
          stops[i + 1].latitude!,
          stops[i + 1].longitude!,
        );
        final dev = ((dFrom + dTo) - segLen).abs();
        if (dev < minDev) {
          minDev = dev;
          segIdx = i;
          progress = segLen > 0 ? (dFrom / segLen).clamp(0.0, 1.0) : 0.0;
        }
      }
    }

    // If no segment had both endpoints with coordinates, we can't determine
    // where between stops the vehicle is — pin it to the current stop node.
    if (minDev == double.infinity) {
      return {'atNodeIndex': _currentStopIndex};
    }

    if (segIdx < _currentStopIndex) {
      segIdx = _currentStopIndex;
      progress = 0.0;
    }

    return {'segmentIndex': segIdx, 'progress': progress, 'atNodeIndex': null};
  }

  // ─────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(liveTrackingProvider);
    final rideId = widget.ride['rideId']?.toString();
    final driverLocation =
        rideId != null ? trackingState.rideLocations[rideId] : null;

    final stops = _getStops();

    // Schedule stop-index update only when driver location changes
    if (driverLocation != null && stops.isNotEmpty) {
      final key =
          '${driverLocation.latitude},${driverLocation.longitude}';
      if (key != _lastLocationKey) {
        _lastLocationKey = key;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _updateCurrentStopImpl(driverLocation, stops);
        });
      }
    }

    // If ride completed, pin to last stop
    final status = widget.ride['status']?.toString().toLowerCase() ?? '';
    if (status == 'completed' && _currentStopIndex < stops.length - 1) {
      _currentStopIndex = stops.length - 1;
      for (int i = 0; i < stops.length; i++) {
        _arrivalTimes[i] ??= stops[i].time;
      }
    }

    if (stops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No route information available',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    // Vehicle position (synchronous, no async needed)
    Map<String, dynamic>? vehiclePosition;
    if (driverLocation != null) {
      vehiclePosition = _calculateVehiclePosition(driverLocation, stops);
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          _buildHeader(driverLocation, trackingState.isConnected),
          const Divider(height: 1),

          // ── Timeline ──
          Expanded(
            child: ListView.builder(
              itemCount: stops.length,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemBuilder: (context, index) {
                final stop = stops[index];
                final isCurrentStop = index == _currentStopIndex;
                // Strictly before current → green and checked
                final isPassed = index < _currentStopIndex;
                final isNext = index == _currentStopIndex + 1;
                final isLast = index == stops.length - 1;

                // Vehicle is travelling between this stop and the next
                final showVehicleBetween = vehiclePosition != null &&
                    vehiclePosition['atNodeIndex'] == null &&
                    vehiclePosition['segmentIndex'] == index &&
                    (vehiclePosition['progress'] as double) < 1.0;

                // Vehicle is parked at this stop's node
                final showVehicleHere = vehiclePosition != null &&
                    vehiclePosition['atNodeIndex'] == index;

                // Vehicle is departing (between stops, and this is current)
                final isVehicleDeparting =
                    showVehicleBetween && index == _currentStopIndex;

                return Column(
                  children: [
                    _buildStopItem(
                      stop,
                      isCurrentStop,
                      isPassed,
                      isNext,
                      widget.isDark,
                      isLast,
                      showVehicleHere,
                      isVehicleDeparting,
                      _arrivalTimes[index],
                    ),
                    // Animated vehicle between two stops
                    if (showVehicleBetween && !isLast)
                      _buildVehicleBetweenStops(
                        vehiclePosition['progress'] as double,
                        widget.isDark,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Header: driver location / waiting indicator / status chip
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeader(RideLocation? driverLocation, bool isConnected) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route, size: 20, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                'Route Timeline',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              _buildStatusChip(),
            ],
          ),
          const SizedBox(height: 12),
          if (driverLocation != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver Location',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lat: ${driverLocation.latitude.toStringAsFixed(6)}, '
                          'Lng: ${driverLocation.longitude.toStringAsFixed(6)}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                        Text(
                          'Last update: ${_formatTimestamp(driverLocation.lastUpdate)}',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.circle, size: 8, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isConnected) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Waiting for driver location...',
                    style:
                        TextStyle(fontSize: 11, color: Colors.orange.shade700),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Status chip
  // ─────────────────────────────────────────────────────────────
  Widget _buildStatusChip() {
    final status = widget.ride['status'] ?? 'unknown';
    Color statusColor;
    IconData statusIcon;
    switch (status.toString().toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'in_progress':
      case 'inprogress':
        statusColor = Colors.orange;
        statusIcon = Icons.directions_car;
        break;
      case 'scheduled':
        statusColor = Colors.blue;
        statusIcon = Icons.schedule;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 14, color: statusColor),
          const SizedBox(width: 6),
          Text(
            status.toString().toUpperCase().replaceAll('_', ' '),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusColor),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Vehicle between stops (mirrors driver screen's widget)
  // ─────────────────────────────────────────────────────────────
  Widget _buildVehicleBetweenStops(double progress, bool isDark) {
    final vehicleY = (progress * 48).clamp(0.0, 48.0);
    final vehicleCenterY = vehicleY + 13; // half of 26px icon

    return SizedBox(
      height: 60,
      child: Row(
        children: [
          const SizedBox(width: 60), // matches distance column
          SizedBox(
            width: 40,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Green top half of line
                Positioned(
                  left: 18,
                  top: 0,
                  height: vehicleCenterY,
                  child: Container(width: 3, color: Colors.green),
                ),
                // Grey bottom half
                Positioned(
                  left: 18,
                  top: vehicleCenterY,
                  bottom: 0,
                  child: Container(width: 3, color: Colors.grey.shade300),
                ),
                // Vehicle icon at progress position
                Positioned(
                  left: 7,
                  top: vehicleY,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.orange.shade700, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.directions_car,
                        size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Stop item (mirrors driver screen's _buildStopItem)
  // ─────────────────────────────────────────────────────────────
  Widget _buildStopItem(
    TrainStop stop,
    bool isCurrent,
    bool isPassed,
    bool isNext,
    bool isDark,
    bool isLast,
    bool showVehicleHere,
    bool isVehicleDeparting,
    DateTime? actualArrival,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Distance column ──
          Container(
            width: 60,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 16),
            child: stop.segmentDistance != null
                ? Text(
                    '${stop.segmentDistance!.toStringAsFixed(0)}km',
                    style: TextStyle(
                      color: isDark
                          ? Colors.amber.shade400
                          : Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  )
                : const SizedBox.shrink(), // no label for origin
          ),

          // ── Timeline column ──
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Top line (green if this stop has been reached)
                if (stop.type != StopType.start)
                  Container(
                    width: 3,
                    height: 20,
                    color: isPassed || isCurrent
                        ? Colors.green
                        : Colors.grey.shade300,
                  ),

                // Stop node
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isPassed || isCurrent
                        ? Colors.green
                        : Colors.grey.shade300,
                    shape: stop.type == StopType.intermediate
                        ? BoxShape.circle
                        : BoxShape.rectangle,
                    borderRadius: stop.type != StopType.intermediate
                        ? BorderRadius.circular(4)
                        : null,
                    border: Border.all(
                      color: isPassed || isCurrent
                          ? Colors.green.shade700
                          : Colors.grey.shade400,
                      width: showVehicleHere ? 3 : 2,
                    ),
                  ),
                  child: showVehicleHere
                      ? const Icon(Icons.directions_car,
                          size: 14, color: Colors.white)
                      : (isPassed || isCurrent)
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                ),

                // Bottom line
                // Green only when vehicle has left this stop:
                //   isPassed (strictly before current) → always green
                //   isCurrent + departing              → green
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 3,
                      color: isPassed || isVehicleDeparting
                          ? Colors.green
                          : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),

          // ── Stop info column ──
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isCurrent
                    ? Colors.orange.withOpacity(0.08)
                    : isNext
                        ? Colors.blue.withOpacity(0.04)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stop.name,
                              style: TextStyle(
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white
                                    : Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatTime(stop.time),
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey.shade500,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'CURRENT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Pickup / dropoff counts (shown when > 0)
                  if (stop.pickupCount > 0 || stop.dropoffCount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (stop.pickupCount > 0) ...[
                          Icon(Icons.arrow_circle_up,
                              size: 14, color: Colors.green.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${stop.pickupCount} pickup',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (stop.pickupCount > 0 && stop.dropoffCount > 0)
                          const SizedBox(width: 12),
                        if (stop.dropoffCount > 0) ...[
                          Icon(Icons.arrow_circle_down,
                              size: 14, color: Colors.red.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${stop.dropoffCount} drop',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Actual arrival time column ──
          Container(
            width: 60,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 16),
            child: _buildActualArrivalTime(
                stop, isPassed, isCurrent, isDark, actualArrival),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Arrival time (mirrors driver screen's _buildActualArrivalTime)
  // ─────────────────────────────────────────────────────────────
  Widget _buildActualArrivalTime(
    TrainStop stop,
    bool isPassed,
    bool isCurrent,
    bool isDark,
    DateTime? actualArrival,
  ) {
    if (!isPassed && !isCurrent) {
      return Text(
        '-',
        style: TextStyle(
          color: isDark ? Colors.white38 : Colors.grey.shade400,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      );
    }

    final actualTime = actualArrival ?? (isCurrent ? DateTime.now() : null);
    if (actualTime == null) {
      return Text(
        '-',
        style: TextStyle(
          color: isDark ? Colors.white38 : Colors.grey.shade400,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      );
    }

    final delayMinutes = actualTime.difference(stop.time).inMinutes;
    final textColor = delayMinutes <= 0
        ? Colors.green
        : delayMinutes <= 5
            ? Colors.orange
            : Colors.red;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(actualTime),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        if (delayMinutes > 0)
          Text(
            '+${delayMinutes}m',
            style: TextStyle(color: textColor, fontSize: 9),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────────────────────
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimestamp(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 10) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Distance ratio driver progress — handles non-straight routes correctly.
  double _computeDriverProgress(
    double driverLat,
    double driverLng,
    double pickupLat,
    double pickupLng,
    double dropoffLat,
    double dropoffLng,
  ) {
    final dFromPickup =
        _haversine(driverLat, driverLng, pickupLat, pickupLng);
    final dFromDropoff =
        _haversine(driverLat, driverLng, dropoffLat, dropoffLng);
    final total = dFromPickup + dFromDropoff;
    if (total == 0) return 0.0;
    return (dFromPickup / total).clamp(0.0, 1.0);
  }

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _toRad(double deg) => deg * math.pi / 180;
}
