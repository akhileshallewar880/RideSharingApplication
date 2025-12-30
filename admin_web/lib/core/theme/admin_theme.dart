import 'package:flutter/material.dart';

class AdminTheme {
  // Primary Colors - Forest Green (Shiprocket-inspired)
  static const Color primaryColor = Color(0xFF1B5E20); // Forest Green
  static const Color primaryLight = Color(0xFF4CAF50); // Light Green
  static const Color primaryDark = Color(0xFF0D3D12); // Dark Green
  
  // Accent Colors - Yellow/Amber
  static const Color accentColor = Color(0xFFFFB300); // Vibrant Yellow
  static const Color accentLight = Color(0xFFFFD54F); // Light Yellow
  static const Color accentDark = Color(0xFFF57F17); // Dark Yellow
  
  // Status Colors
  static const Color successColor = Color(0xFF4caf50);
  static const Color warningColor = Color(0xFFff9800);
  static const Color errorColor = Color(0xFFf44336);
  static const Color infoColor = Color(0xFF2196f3);
  
  // Neutral Colors
  static const Color backgroundColor = Color(0xFFf5f5f5);
  static const Color surfaceColor = Color(0xFFffffff);
  static const Color cardColor = Color(0xFFffffff);
  static const Color dividerColor = Color(0xFFe0e0e0);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFbdbdbd);
  static const Color textWhite = Color(0xFFffffff);
  
  // Sidebar Colors
  static const Color sidebarBackground = Color(0xFF1B5E20); // Forest Green
  static const Color sidebarHover = Color(0xFF2E7D32); // Hover Green
  static const Color sidebarActive = Color(0xFF388E3C); // Active Green
  
  // Shiprocket-inspired UI Colors
  static const Color highlightYellow = Color(0xFFFFF8E1); // Light yellow background
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color hoverGray = Color(0xFFF5F5F5);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: textWhite,
        onSecondary: textWhite,
        onSurface: textPrimary,
        onError: textWhite,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: textWhite,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textWhite,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: MaterialStateProperty.all(primaryLight.withOpacity(0.1)),
        dataRowColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryLight.withOpacity(0.08);
          }
          return null;
        }),
        headingTextStyle: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        dataTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textWhite,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: errorColor),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryLight.withOpacity(0.1),
        labelStyle: TextStyle(color: primaryColor),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
    );
  }
  
  // Helper method for status chip colors
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return warningColor;
      case 'approved':
      case 'active':
      case 'completed':
        return successColor;
      case 'rejected':
      case 'cancelled':
      case 'inactive':
        return errorColor;
      case 'in_progress':
      case 'ongoing':
        return infoColor;
      default:
        return textSecondary;
    }
  }
  
  // Helper method for status chip background colors
  static Color getStatusBackgroundColor(String status) {
    return getStatusColor(status).withOpacity(0.1);
  }
}
