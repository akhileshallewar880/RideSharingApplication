import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../../core/providers/live_tracking_provider.dart';

/// Stop types for the timeline
enum StopType { start, intermediate, end }

/// Train-style stop data model
class TrainStop {
  final String name;
  final DateTime time;
  final StopType type;
  final int pickupCount;
  final int dropoffCount;
  final double? segmentDistance;
  final double distance;
  final DateTime? actualArrivalTime;
  final bool isPassed;

  TrainStop({
    required this.name,
    required this.time,
    required this.type,
    required this.pickupCount,
    required this.dropoffCount,
    this.segmentDistance,
    required this.distance,
    this.actualArrivalTime,
    this.isPassed = false,
  });
}

/// Widget to display a train-style tracking timeline for a ride
class RideTrackingTimeline extends ConsumerStatefulWidget {
  final dynamic ride;
  final bool isDark;

  const RideTrackingTimeline({
    Key? key,
    required this.ride,
    this.isDark = false,
  }) : super(key: key);

  @override
  ConsumerState<RideTrackingTimeline> createState() => _RideTrackingTimelineState();
}

class _RideTrackingTimelineState extends ConsumerState<RideTrackingTimeline> {
  @override
  void initState() {
    super.initState();
    // Start tracking this ride
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
    // Stop tracking when dialog closes
    final rideId = widget.ride['rideId']?.toString();
    if (rideId != null && rideId.isNotEmpty && mounted) {
      try {
        ref.read(liveTrackingProvider.notifier).stopTrackingRide(rideId);
      } catch (e) {
        // Ignore errors during disposal
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(liveTrackingProvider);
    final rideId = widget.ride['rideId']?.toString();
    final driverLocation = rideId != null ? trackingState.rideLocations[rideId] : null;
    final stops = _buildStopsList();

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
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
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
                // Driver location indicator
                if (driverLocation != null) ...[
                  const SizedBox(height: 12),
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
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 16,
                          ),
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
                                'Lat: ${driverLocation.latitude.toStringAsFixed(6)}, Lng: ${driverLocation.longitude.toStringAsFixed(6)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                'Last update: ${_formatTimestamp(driverLocation.lastUpdate)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: Colors.white,
                              ),
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
                ] else if (trackingState.isConnected) ...[
                  const SizedBox(height: 12),
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Waiting for driver location...',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // Timeline
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: stops.length,
              itemBuilder: (context, index) {
                final stop = stops[index];
                final isLast = index == stops.length - 1;
                final isCurrent = _isCurrentStop(stop, stops, index);

                return _buildStopItem(
                  stop,
                  isCurrent,
                  stop.isPassed,
                  isLast,
                  widget.isDark,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

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
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  bool _isCurrentStop(TrainStop stop, List<TrainStop> stops, int index) {
    // If ride is completed, no current stop
    final status = widget.ride['status']?.toString().toLowerCase() ?? '';
    if (status == 'completed') return false;

    // Find first non-passed stop
    for (int i = 0; i < stops.length; i++) {
      if (!stops[i].isPassed) {
        return i == index;
      }
    }
    return false;
  }

  Widget _buildStopItem(
    TrainStop stop,
    bool isCurrent,
    bool isPassed,
    bool isLast,
    bool isDark,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Distance column
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
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
                  : Text(
                      '${stop.distance.toStringAsFixed(0)}km',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white60
                            : Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
            ),
          ),

          // Timeline column
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Top line
                if (stop.type != StopType.start)
                  Container(
                    width: 3,
                    height: 20,
                    color: isPassed ? Colors.green : Colors.grey.shade300,
                  ),

                // Stop indicator
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? Colors.orange
                        : isPassed
                            ? Colors.green
                            : Colors.grey.shade300,
                    shape: stop.type == StopType.intermediate
                        ? BoxShape.circle
                        : BoxShape.rectangle,
                    borderRadius: stop.type != StopType.intermediate
                        ? BorderRadius.circular(4)
                        : null,
                    border: Border.all(
                      color: isCurrent
                          ? Colors.orange.shade700
                          : isPassed
                              ? Colors.green.shade700
                              : Colors.grey.shade400,
                      width: isCurrent ? 3 : 2,
                    ),
                  ),
                  child: isCurrent
                      ? const Icon(Icons.directions_car,
                          size: 14, color: Colors.white)
                      : isPassed
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                ),

                // Bottom line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 3,
                      color: isPassed ? Colors.green : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),

          // Stop info column
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12, right: 8),
              decoration: BoxDecoration(
                color: isCurrent
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isCurrent
                    ? Border.all(color: Colors.orange.shade200, width: 1)
                    : null,
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
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(stop.time),
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey.shade500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
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

                  // Pickup/Dropoff counts
                  if (stop.pickupCount > 0 || stop.dropoffCount > 0) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (stop.pickupCount > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_circle_up,
                                  size: 14, color: Colors.green.shade600),
                              const SizedBox(width: 4),
                              Text(
                                '${stop.pickupCount} pickup${stop.pickupCount > 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: Colors.green.shade600,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        if (stop.dropoffCount > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_circle_down,
                                  size: 14, color: Colors.red.shade600),
                              const SizedBox(width: 4),
                              Text(
                                '${stop.dropoffCount} drop${stop.dropoffCount > 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],

                  // Actual arrival time if available
                  if (stop.actualArrivalTime != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 12, color: Colors.green.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Arrived: ${_formatTime(stop.actualArrivalTime!)}',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
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

          // Time column (actual arrival)
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: stop.actualArrivalTime != null
                  ? Text(
                      _formatTime(stop.actualArrivalTime!),
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.right,
                    )
                  : isPassed
                      ? Icon(Icons.check_circle,
                          size: 16, color: Colors.green.shade600)
                      : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 10) {
      return 'Just now';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }

  List<TrainStop> _buildStopsList() {
    try {
      final List<TrainStop> stops = [];
      
      // Get passengers data
      final passengers = widget.ride['passengers'] as List<dynamic>? ?? [];
      
      // Parse segment prices if available for distances
      final segmentPricesRaw = widget.ride['segmentPrices'];
      List<dynamic> segmentPrices = [];
      
      if (segmentPricesRaw != null) {
        if (segmentPricesRaw is String) {
          try {
            segmentPrices = jsonDecode(segmentPricesRaw) as List<dynamic>;
          } catch (e) {
            print('Error parsing segment prices: $e');
          }
        } else if (segmentPricesRaw is List) {
          segmentPrices = segmentPricesRaw;
        }
      }

      // Build unique locations map with counts
      final Map<String, Map<String, dynamic>> locationMap = {};

      // If we have passengers, count them at each location
      for (var passenger in passengers) {
        final pickup = _normalizeLocation(passenger['pickupLocation'] ?? '');
        final dropoff = _normalizeLocation(passenger['dropoffLocation'] ?? '');

        // Count pickups
        if (pickup.isNotEmpty) {
          locationMap[pickup] = locationMap[pickup] ?? {
            'pickupCount': 0,
            'dropoffCount': 0,
            'fullName': passenger['pickupLocation'] ?? pickup,
          };
          locationMap[pickup]!['pickupCount'] = 
              (locationMap[pickup]!['pickupCount'] as int) + 1;
        }

        // Count dropoffs
        if (dropoff.isNotEmpty) {
          locationMap[dropoff] = locationMap[dropoff] ?? {
            'pickupCount': 0,
            'dropoffCount': 0,
            'fullName': passenger['dropoffLocation'] ?? dropoff,
          };
          locationMap[dropoff]!['dropoffCount'] = 
              (locationMap[dropoff]!['dropoffCount'] as int) + 1;
        }
      }

      // If no passengers but we have segment prices, build from segments
      if (locationMap.isEmpty && segmentPrices.isNotEmpty) {
        for (var segment in segmentPrices) {
          final fromLocation = segment['fromLocation']?.toString() ?? 
                              segment['FromLocation']?.toString() ?? '';
          final toLocation = segment['toLocation']?.toString() ?? 
                            segment['ToLocation']?.toString() ?? '';
          
          if (fromLocation.isNotEmpty) {
            final normalized = _normalizeLocation(fromLocation);
            locationMap[normalized] = locationMap[normalized] ?? {
              'pickupCount': 0,
              'dropoffCount': 0,
              'fullName': fromLocation,
            };
          }
          
          if (toLocation.isNotEmpty) {
            final normalized = _normalizeLocation(toLocation);
            locationMap[normalized] = locationMap[normalized] ?? {
              'pickupCount': 0,
              'dropoffCount': 0,
              'fullName': toLocation,
            };
          }
        }
      }

      // If still empty, use pickup and dropoff from ride
      if (locationMap.isEmpty) {
        final pickup = widget.ride['pickupLocation']?.toString() ?? '';
        final dropoff = widget.ride['dropoffLocation']?.toString() ?? '';
        
        if (pickup.isNotEmpty) {
          locationMap[_normalizeLocation(pickup)] = {
            'pickupCount': 0,
            'dropoffCount': 0,
            'fullName': pickup,
          };
        }
        
        if (dropoff.isNotEmpty) {
          locationMap[_normalizeLocation(dropoff)] = {
            'pickupCount': 0,
            'dropoffCount': 0,
            'fullName': dropoff,
          };
        }
      }

      if (locationMap.isEmpty) {
        return stops;
      }

      // Get pickup and dropoff locations from ride
      final pickupLocation = _normalizeLocation(widget.ride['pickupLocation'] ?? '');
      final dropoffLocation = _normalizeLocation(widget.ride['dropoffLocation'] ?? '');
      
      // Get intermediate stops from ride data
      final intermediateStopsRaw = widget.ride['intermediateStops'];
      List<String> intermediateStops = [];
      if (intermediateStopsRaw != null) {
        if (intermediateStopsRaw is List) {
          intermediateStops = intermediateStopsRaw.map((s) => s.toString()).toList();
        }
      }

      // Build ordered route
      final List<String> orderedLocations = [];
      final Set<String> addedLocations = {};

      // Add start location
      if (pickupLocation.isNotEmpty && locationMap.containsKey(pickupLocation)) {
        orderedLocations.add(pickupLocation);
        addedLocations.add(pickupLocation);
      }

      // Add intermediate stops in order
      for (var stop in intermediateStops) {
        final normalized = _normalizeLocation(stop);
        if (normalized.isNotEmpty && !addedLocations.contains(normalized)) {
          // Ensure this location exists in our location map
          if (!locationMap.containsKey(normalized)) {
            locationMap[normalized] = {
              'pickupCount': 0,
              'dropoffCount': 0,
              'fullName': stop,
            };
          }
          orderedLocations.add(normalized);
          addedLocations.add(normalized);
        }
      }

      // Add any remaining stops from segment prices that aren't already added
      for (var segment in segmentPrices) {
        final from = _normalizeLocation(segment['from'] ?? segment['fromLocation'] ?? segment['FromLocation'] ?? '');
        final to = _normalizeLocation(segment['to'] ?? segment['toLocation'] ?? segment['ToLocation'] ?? '');

        if (from.isNotEmpty && !addedLocations.contains(from) && locationMap.containsKey(from)) {
          orderedLocations.add(from);
          addedLocations.add(from);
        }
        if (to.isNotEmpty && !addedLocations.contains(to) && locationMap.containsKey(to)) {
          orderedLocations.add(to);
          addedLocations.add(to);
        }
      }

      // Add dropoff location if not already added
      if (dropoffLocation.isNotEmpty && 
          !addedLocations.contains(dropoffLocation) && 
          locationMap.containsKey(dropoffLocation)) {
        orderedLocations.add(dropoffLocation);
        addedLocations.add(dropoffLocation);
      }

      // Create TrainStop objects
      double cumulativeDistance = 0.0;
      int cumulativeMinutes = 0;
      final scheduledTime = widget.ride['scheduledTime'] != null
          ? DateTime.parse(widget.ride['scheduledTime'].toString())
          : DateTime.now();
      
      // Parse departure time (HH:mm format) and set it on scheduled date
      DateTime startTime = scheduledTime;
      if (widget.ride['departureTime'] != null) {
        try {
          final timeParts = widget.ride['departureTime'].toString().split(':');
          if (timeParts.length >= 2) {
            final hour = int.parse(timeParts[0]);
            final minute = int.parse(timeParts[1]);
            startTime = DateTime(
              scheduledTime.year,
              scheduledTime.month,
              scheduledTime.day,
              hour,
              minute,
            );
          }
        } catch (e) {
          print('Error parsing departure time: $e');
        }
      }
      
      // Get total distance and duration for calculating segment times
      final totalDistance = _parseDouble(widget.ride['distance']);
      final totalDuration = widget.ride['duration'] as int? ?? 0;

      for (int i = 0; i < orderedLocations.length; i++) {
        final location = orderedLocations[i];
        final locationData = locationMap[location]!;
        
        // Find segment distance and duration
        double? segmentDistance;
        int? segmentDuration;
        if (i < orderedLocations.length - 1) {
          final nextLocation = orderedLocations[i + 1];
          
          // Find matching segment
          for (var segment in segmentPrices) {
            final from = _normalizeLocation(
              segment['from'] ?? 
              segment['fromLocation'] ?? 
              segment['FromLocation'] ?? ''
            );
            final to = _normalizeLocation(
              segment['to'] ?? 
              segment['toLocation'] ?? 
              segment['ToLocation'] ?? ''
            );
            
            if (from == location && to == nextLocation) {
              segmentDistance = _parseDouble(
                segment['distance'] ?? 
                segment['Distance'] ?? 
                segment['distanceKm'] ?? 0
              );
              segmentDuration = segment['duration'] as int? ?? 
                               segment['Duration'] as int? ?? 
                               segment['durationMinutes'] as int?;
              break;
            }
          }
          
          // If no segment data found, estimate based on proportion of total
          if (segmentDistance == null && totalDistance > 0) {
            // Estimate this segment as equal portion of remaining distance
            final remainingStops = orderedLocations.length - i - 1;
            segmentDistance = (totalDistance - cumulativeDistance) / remainingStops;
          }
          
          if (segmentDuration == null && totalDuration > 0 && segmentDistance != null) {
            // Estimate duration proportionally to distance
            segmentDuration = ((segmentDistance / totalDistance) * totalDuration).round();
          }
        }

        if (segmentDistance != null) {
          cumulativeDistance += segmentDistance;
        }
        
        if (segmentDuration != null) {
          cumulativeMinutes += segmentDuration;
        }

        // Determine stop type
        StopType stopType;
        if (i == 0) {
          stopType = StopType.start;
        } else if (i == orderedLocations.length - 1) {
          stopType = StopType.end;
        } else {
          stopType = StopType.intermediate;
        }

        // Calculate estimated arrival time
        final estimatedTime = startTime.add(Duration(minutes: cumulativeMinutes));

        // Check if stop has been passed (for in-progress rides)
        final status = widget.ride['status']?.toString().toLowerCase() ?? '';
        final isPassed = status == 'completed' || 
                        (status == 'in_progress' && i < orderedLocations.length - 1);

        stops.add(TrainStop(
          name: locationData['fullName'] as String,
          time: estimatedTime,
          type: stopType,
          pickupCount: locationData['pickupCount'] as int,
          dropoffCount: locationData['dropoffCount'] as int,
          segmentDistance: segmentDistance,
          distance: cumulativeDistance,
          actualArrivalTime: isPassed ? estimatedTime : null,
          isPassed: isPassed,
        ));
      }

      return stops;
    } catch (e) {
      print('Error building stops list: $e');
      return [];
    }
  }

  String _normalizeLocation(String location) {
    return location.split(',').first.trim().toLowerCase();
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
