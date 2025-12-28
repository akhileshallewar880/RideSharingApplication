import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Breakpoints (Shiprocket-inspired)
  static const double mobileMaxWidth = 768;
  static const double tabletMaxWidth = 1024;
  static const double desktopMaxWidth = 1440;
  static const double largeDesktopMinWidth = 1441;
  
  // Screen size checks
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileMaxWidth;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileMaxWidth && width < tabletMaxWidth;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletMaxWidth;
  }
  
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeDesktopMinWidth;
  }
  
  // Responsive value picker
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
    T? largeDesktop,
  }) {
    if (isLargeDesktop(context) && largeDesktop != null) {
      return largeDesktop;
    } else if (isDesktop(context)) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }
  
  // Grid column count
  static int getGridColumns(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 2;
    } else if (isLargeDesktop(context)) {
      return 4;
    } else {
      return 3;
    }
  }
  
  // Sidebar width
  static double getSidebarWidth(BuildContext context) {
    if (isMobile(context)) {
      return 0; // Hidden on mobile (drawer)
    } else if (isTablet(context)) {
      return 70; // Collapsed
    } else {
      return 250; // Full width
    }
  }
  
  // Content padding
  static EdgeInsets getContentPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(12);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(16);
    } else {
      return const EdgeInsets.all(24);
    }
  }
  
  // Card elevation
  static double getCardElevation(BuildContext context) {
    return isMobile(context) ? 1 : 2;
  }
  
  // Font sizes
  static double getTitleFontSize(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 20,
      desktop: 24,
    );
  }
  
  static double getHeadingFontSize(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 16,
      desktop: 18,
    );
  }
  
  static double getBodyFontSize(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 14,
      desktop: 14,
    );
  }
}

// Responsive widget builder
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints) builder;
  
  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => builder(context, constraints),
    );
  }
}
