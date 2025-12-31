/// Utility class for parsing DateTime strings from .NET APIs
/// Handles .NET datetime format with more than 6 decimal places in fractional seconds
class DateTimeParser {
  /// Parse DateTime string safely, handling .NET's 7+ decimal place format
  /// 
  /// Dart's DateTime.parse() only supports up to 6 decimal places in fractional seconds,
  /// but .NET can return timestamps with 7 decimal places (e.g., "2025-12-30T17:46:43.2333333")
  /// 
  /// This method truncates fractional seconds to 6 decimal places before parsing.
  static DateTime parse(String dateTimeStr) {
    try {
      // Handle .NET datetime format with more than 6 decimal places
      if (dateTimeStr.contains('.')) {
        final parts = dateTimeStr.split('.');
        if (parts.length == 2) {
          // Extract the fractional seconds part
          final fractionalPart = parts[1];
          // Check if it has more than 6 digits before 'Z' or end
          final match = RegExp(r'^(\d{7,})(.*)$').firstMatch(fractionalPart);
          if (match != null) {
            // Truncate to 6 decimal places
            final group1 = match.group(1);
            if (group1 != null && group1.length >= 6) {
              final truncated = group1.substring(0, 6);
              final suffix = match.group(2) ?? '';
              dateTimeStr = '${parts[0]}.$truncated$suffix';
            }
          }
        }
      }
      return DateTime.parse(dateTimeStr);
    } catch (e) {
      print('⚠️ Error parsing datetime "$dateTimeStr": $e');
      return DateTime.now();
    }
  }

  /// Parse DateTime string safely with a fallback value
  static DateTime parseOrDefault(String? dateTimeStr, DateTime defaultValue) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) {
      return defaultValue;
    }
    return parse(dateTimeStr);
  }

  /// Parse DateTime string safely with null return on error
  static DateTime? parseOrNull(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) {
      return null;
    }
    try {
      return parse(dateTimeStr);
    } catch (e) {
      return null;
    }
  }
}
