import 'package:flutter/material.dart';

/// Indian number plate widget that displays vehicle registration number
/// in the authentic Indian number plate format with IND marker and tri-color stripe
class IndianNumberPlate extends StatelessWidget {
  final String vehicleNumber;
  final double scale;
  final bool showShadow;
  final Color backgroundColor;

  const IndianNumberPlate({
    super.key,
    required this.vehicleNumber,
    this.scale = 1.0,
    this.showShadow = true,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    // Parse the vehicle number to format properly
    // Expected format: MH40BP4231 or MH 40 BP 4231
    String formattedNumber = _formatVehicleNumber(vehicleNumber);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * scale,
        vertical: 6 * scale,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4 * scale),
        border: Border.all(
          color: Colors.black,
          width: 2 * scale,
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4 * scale,
                  offset: Offset(0, 2 * scale),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Left tri-color stripe (Saffron, White, Green)
          Container(
            width: 4 * scale,
            height: 24 * scale,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFF9933), // Saffron
                  Color(0xFFFFFFFF), // White
                  Color(0xFF138808), // Green
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(2 * scale),
            ),
          ),
          SizedBox(width: 6 * scale),
          
          // IND text
          Text(
            'IND',
            style: TextStyle(
              fontSize: 10 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 0.5,
              height: 1.2,
            ),
          ),
          SizedBox(width: 6 * scale),
          
          // Separator line
          Container(
            width: 1.5 * scale,
            height: 20 * scale,
            color: Colors.black,
          ),
          SizedBox(width: 6 * scale),
          
          // Vehicle number
          Text(
            formattedNumber,
            style: TextStyle(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: 1.5 * scale,
              fontFamily: 'monospace',
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Format vehicle number to proper display format
  /// Handles various input formats and standardizes them
  String _formatVehicleNumber(String number) {
    if (number.isEmpty) {
      return 'MH 40BP 4231'; // Default placeholder
    }

    // Remove all spaces and convert to uppercase
    String cleaned = number.replaceAll(' ', '').toUpperCase();

    // Try to parse Indian number plate format: AA00AA0000
    // Example: MH40BP4231 -> MH 40BP 4231
    RegExp pattern = RegExp(r'^([A-Z]{2})(\d{1,2})([A-Z]{1,2})(\d{1,4})$');
    Match? match = pattern.firstMatch(cleaned);

    if (match != null) {
      // Format as: MH 40BP 4231
      return '${match.group(1)} ${match.group(2)}${match.group(3)} ${match.group(4)}';
    }

    // If pattern doesn't match, return as-is with spaces added for readability
    // Try to intelligently add spaces
    if (cleaned.length >= 6) {
      // Add space after first 2 chars and before last 4 chars
      String part1 = cleaned.substring(0, 2);
      String middle = cleaned.substring(2, cleaned.length - 4);
      String part2 = cleaned.substring(cleaned.length - 4);
      return '$part1 $middle $part2';
    }

    return cleaned;
  }
}

/// Compact version for smaller displays
class CompactIndianNumberPlate extends StatelessWidget {
  final String vehicleNumber;
  final bool showShadow;
  final Color backgroundColor;

  const CompactIndianNumberPlate({
    super.key,
    required this.vehicleNumber,
    this.showShadow = false,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return IndianNumberPlate(
      vehicleNumber: vehicleNumber,
      scale: 0.7,
      showShadow: showShadow,
      backgroundColor: backgroundColor,
    );
  }
}
