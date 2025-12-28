import 'package:flutter/material.dart';
import '../../../../core/data/local/ride_cache.dart';

/// Train-style intermediate stops list showing pickups, drops, and distances
class IntermediateStopsList extends StatelessWidget {
  final List<IntermediateStopData> stops;
  final dynamic currentLocation;
  final Function(IntermediateStopData) onStopTap;

  const IntermediateStopsList({
    super.key,
    required this.stops,
    this.currentLocation,
    required this.onStopTap,
  });

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No intermediate stops for this trip',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Route Timeline',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...stops.asMap().entries.map((entry) {
          final index = entry.key;
          final stop = entry.value;
          final isLast = index == stops.length - 1;
          
          return _buildStopItem(context, stop, isLast);
        }).toList(),
      ],
    );
  }

  Widget _buildStopItem(BuildContext context, IntermediateStopData stop, bool isLast) {
    final isPassed = stop.isPassed;
    final statusColor = isPassed ? Colors.green : Colors.orange;
    
    return InkWell(
      onTap: () => onStopTap(stop),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator (like train tracking)
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  // Station circle
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPassed ? Colors.green : Colors.white,
                      border: Border.all(
                        color: statusColor,
                        width: 3,
                      ),
                    ),
                    child: isPassed
                        ? const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  // Connecting line
                  if (!isLast)
                    Container(
                      width: 3,
                      height: 60,
                      color: isPassed ? Colors.green.withOpacity(0.3) : Colors.grey[300],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Stop details
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPassed 
                      ? Colors.green.withOpacity(0.05)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPassed ? Colors.green.withOpacity(0.2) : Colors.grey[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            stop.locationName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isPassed ? Colors.grey[600] : Colors.black,
                              decoration: isPassed ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${stop.distanceFromOrigin.toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Pickup/Drop indicators
                    Row(
                      children: [
                        if (stop.pickupCount > 0) ...[
                          Icon(
                            Icons.upload,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${stop.pickupCount} pickup${stop.pickupCount > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (stop.dropoffCount > 0) ...[
                          Icon(
                            Icons.download,
                            size: 16,
                            color: Colors.red[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${stop.dropoffCount} drop${stop.dropoffCount > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Passenger names
                    if (stop.pickupPassengerNames.isNotEmpty ||
                        stop.dropoffPassengerNames.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      if (stop.pickupPassengerNames.isNotEmpty)
                        _buildPassengerChips(
                          stop.pickupPassengerNames,
                          Colors.blue,
                          'Pick up',
                        ),
                      if (stop.dropoffPassengerNames.isNotEmpty)
                        _buildPassengerChips(
                          stop.dropoffPassengerNames,
                          Colors.red,
                          'Drop',
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerChips(List<String> names, Color color, String action) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: names.map((name) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              name,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.9),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
