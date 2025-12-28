import 'package:flutter/material.dart';
import '../../../../core/data/local/ride_cache.dart';

/// Timeline widget showing trip progress through stops (train-style)
class TripProgressTimeline extends StatelessWidget {
  final String pickupLocation;
  final String dropoffLocation;
  final String currentStatus;
  final List<IntermediateStopData> intermediateStops;

  const TripProgressTimeline({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.currentStatus,
    this.intermediateStops = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trip Progress',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Origin
        _buildTimelineItem(
          context,
          icon: Icons.trip_origin,
          location: pickupLocation,
          status: 'Pickup Point',
          isCompleted: true,
          isFirst: true,
        ),
        // Intermediate stops
        ...intermediateStops.map((stop) {
          return _buildTimelineItem(
            context,
            icon: Icons.location_on_outlined,
            location: stop.locationName,
            status: stop.isPassed ? 'Passed' : 'Upcoming',
            isCompleted: stop.isPassed,
            distance: '${stop.distanceFromOrigin.toStringAsFixed(1)} km',
          );
        }).toList(),
        // Destination
        _buildTimelineItem(
          context,
          icon: Icons.location_on,
          location: dropoffLocation,
          status: 'Drop-off Point',
          isCompleted: false,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required IconData icon,
    required String location,
    required String status,
    required bool isCompleted,
    bool isFirst = false,
    bool isLast = false,
    String? distance,
  }) {
    final color = isCompleted ? Colors.green : Colors.grey;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator column
        Column(
          children: [
            // Top connecting line
            if (!isFirst)
              Container(
                width: 2,
                height: 24,
                color: isCompleted ? Colors.green : Colors.grey[300],
              ),
            // Dot indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? Colors.green : Colors.white,
                border: Border.all(
                  color: color,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
        const SizedBox(width: 12),
        // Location info (expanded to take remaining space)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                location,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? Colors.grey[600] : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (distance != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        distance,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              // Bottom spacing with connecting line
              if (!isLast)
                Stack(
                  children: [
                    // Connecting line positioned at the left edge
                    Positioned(
                      left: -12 - 11, // -12 for SizedBox width, -11 to center on dot (24/2 - 2/2)
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: isCompleted ? Colors.green : Colors.grey[300],
                      ),
                    ),
                    // Spacer for minimum height
                    const SizedBox(height: 24),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
