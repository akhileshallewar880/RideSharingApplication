import 'package:flutter/material.dart';

/// App-wide color palette supporting light and dark themes
/// "Fresh Canopy" Palette - Modern & Clean for VanYatra
class AppColors {
  // Brand Colors - Fresh Canopy Palette
  static const Color primaryGreen = Color(0xFF2E7D32); // Forest Green (Primary Brand)
  static const Color primaryLight = Color(0xFF4CAF50); // Medium Green
  static const Color primaryDark = Color(0xFF1B5E20); // Deep Forest Green
  static const Color secondaryGreen = Color(0xFFE8F5E9); // Very Pale Green (Selected items)
  static const Color accentLime = Color(0xFFCDDC39); // Lime Green (Icons/Badges)
  static const Color accentAmber = Color(0xFFFFC107); // Amber (Alternative accent)
  static const Color accentTeal = Color(0xFF26A69A); // Complementary teal
  
  // Legacy support (for gradual migration)
  static const Color primaryYellow = Color(0xFFFFC107); // Now maps to Amber accent
  static const Color primaryOrange = Color(0xFFCDDC39); // Now maps to Lime
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentRed = Color(0xFFE53935);
  static const Color accentGold = Color(0xFFFFC107); // Amber
  static const Color accentBeige = Color(0xFFE8F5E9); // Pale green
  static const Color accentCream = Color(0xFFF1F8E9); // Light lime
  static const Color accentBrown = Color(0xFF795548); // Brown for contrast
  
  // Light Theme Colors - Fresh & Modern
  static const Color lightBackground = Color(0xFFFAFAFA); // Very light grey
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure white
  static const Color lightCardBg = Color(0xFFFFFFFF); // White cards
  static const Color lightTextPrimary = Color(0xFF263238); // Blue Grey (softer than black)
  static const Color lightTextSecondary = Color(0xFF546E7A); // Medium Blue Grey
  static const Color lightTextTertiary = Color(0xFF90A4AE); // Light Blue Grey
  static const Color lightBorder = Color(0xFFE0E0E0); // Light grey border
  static const Color lightDivider = Color(0xFFEEEEEE); // Very light divider
  static const Color lightShadow = Color(0x1A000000); // Subtle shadow
  
  // Dark Theme Colors - Dark Canopy
  static const Color darkBackground = Color(0xFF121212); // Almost black
  static const Color darkSurface = Color(0xFF1E1E1E); // Dark grey
  static const Color darkCardBg = Color(0xFF2C2C2C); // Dark card
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // White
  static const Color darkTextSecondary = Color(0xFFB0BEC5); // Light Blue Grey
  static const Color darkTextTertiary = Color(0xFF78909C); // Medium Blue Grey
  static const Color darkBorder = Color(0xFF37474F); // Dark border
  static const Color darkDivider = Color(0xFF263238); // Dark divider
  static const Color darkShadow = Color(0x33000000); // Dark shadow
  
  // Semantic Colors - Fresh & Clear
  static const Color success = Color(0xFF4CAF50); // Green success
  static const Color warning = Color(0xFFFFC107); // Amber warning
  static const Color error = Color(0xFFE53935); // Red error
  static const Color info = Color(0xFF26A69A); // Teal for info
  
  // Status Colors - Vibrant & Clear
  static const Color rideActive = Color(0xFF4CAF50); // Medium green
  static const Color rideScheduled = Color(0xFFCDDC39); // Lime green
  static const Color rideCancelled = Color(0xFFE53935); // Red
  static const Color rideCompleted = Color(0xFF26A69A); // Teal
  
  // Map Colors
  static const Color pickupMarker = Color(0xFF4CAF50); // Medium green
  static const Color dropoffMarker = Color(0xFFE53935); // Red
  static const Color routePath = Color(0xFF2E7D32); // Brand forest green
  static const Color driverMarker = Color(0xFFFFC107); // Amber
  
  // Gradient Colors - Modern & Clean
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF5F5F5)], // White to light grey
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)], // Dark to medium green
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF26A69A)], // Green to teal
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFFC107), Color(0xFFFFB300)], // Amber gradient
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFAFAFA)], // White to very light grey
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1B5E20), Color(0xFF121212)], // Deep green to black
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF2C2C2C), Color(0xFF1E1E1E)], // Dark card gradient
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Button Gradients - Clean & Modern
  static const LinearGradient primaryButtonGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF388E3C)], // Forest green gradient
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryButtonGradient = LinearGradient(
    colors: [Color(0xFF26A69A), Color(0xFF4CAF50)], // Teal to green
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentButtonGradient = LinearGradient(
    colors: [Color(0xFFCDDC39), Color(0xFFD4E157)], // Lime gradient
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Opacity Helpers
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
  
  // Shimmer colors for loading states
  static const Color shimmerBase = Color(0xFFE0E0E0); // Light grey
  static const Color shimmerHighlight = Color(0xFFF5F5F5); // Very light grey
}
