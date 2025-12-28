import 'package:flutter/material.dart';

/// Consistent spacing system across the app
class AppSpacing {
  // Base spacing unit (4dp)
  static const double base = 4.0;
  
  // Spacing Scale
  static const double xs = base * 1; // 4dp
  static const double sm = base * 2; // 8dp
  static const double md = base * 3; // 12dp
  static const double lg = base * 4; // 16dp
  static const double xl = base * 5; // 20dp
  static const double xxl = base * 6; // 24dp
  static const double xxxl = base * 8; // 32dp
  static const double huge = base * 10; // 40dp
  static const double massive = base * 12; // 48dp
  
  // Padding Helpers
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);
  static const EdgeInsets paddingXXL = EdgeInsets.all(xxl);
  
  // Horizontal Padding
  static const EdgeInsets horizontalXS = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSM = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMD = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLG = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXL = EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets horizontalXXL = EdgeInsets.symmetric(horizontal: xxl);
  
  // Vertical Padding
  static const EdgeInsets verticalXS = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSM = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMD = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLG = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXL = EdgeInsets.symmetric(vertical: xl);
  static const EdgeInsets verticalXXL = EdgeInsets.symmetric(vertical: xxl);
  
  // Page Padding (Horizontal only)
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets pagePaddingLarge = EdgeInsets.symmetric(horizontal: xl);
  
  // Card Padding
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(xl);
  
  // Border Radius
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusFull = 999.0;
  
  // Border Radius Objects
  static const BorderRadius borderRadiusXS = BorderRadius.all(Radius.circular(radiusXS));
  static const BorderRadius borderRadiusSM = BorderRadius.all(Radius.circular(radiusSM));
  static const BorderRadius borderRadiusMD = BorderRadius.all(Radius.circular(radiusMD));
  static const BorderRadius borderRadiusLG = BorderRadius.all(Radius.circular(radiusLG));
  static const BorderRadius borderRadiusXL = BorderRadius.all(Radius.circular(radiusXL));
  static const BorderRadius borderRadiusXXL = BorderRadius.all(Radius.circular(radiusXXL));
  static const BorderRadius borderRadiusFull = BorderRadius.all(Radius.circular(radiusFull));
  
  // Top-only Border Radius
  static const BorderRadius borderRadiusTopMD = BorderRadius.vertical(top: Radius.circular(radiusMD));
  static const BorderRadius borderRadiusTopLG = BorderRadius.vertical(top: Radius.circular(radiusLG));
  static const BorderRadius borderRadiusTopXL = BorderRadius.vertical(top: Radius.circular(radiusXL));
  
  // Icon Sizes
  static const double iconXS = 16.0;
  static const double iconSM = 20.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;
  static const double iconXL = 40.0;
  static const double iconXXL = 48.0;
  static const double iconHuge = 64.0;
  
  // Button Heights
  static const double buttonHeightSM = 36.0;
  static const double buttonHeightMD = 44.0;
  static const double buttonHeightLG = 52.0;
  static const double buttonHeightXL = 60.0;
  
  // Input Field Heights
  static const double inputHeightMD = 48.0;
  static const double inputHeightLG = 56.0;
  
  // Avatar Sizes
  static const double avatarSM = 32.0;
  static const double avatarMD = 40.0;
  static const double avatarLG = 56.0;
  static const double avatarXL = 80.0;
  static const double avatarXXL = 120.0;
  
  // Elevation (Shadow)
  static const double elevationSM = 2.0;
  static const double elevationMD = 4.0;
  static const double elevationLG = 8.0;
  static const double elevationXL = 12.0;
  
  // Gap (for Flex widgets)
  static SizedBox gapXS = const SizedBox(height: xs, width: xs);
  static SizedBox gapSM = const SizedBox(height: sm, width: sm);
  static SizedBox gapMD = const SizedBox(height: md, width: md);
  static SizedBox gapLG = const SizedBox(height: lg, width: lg);
  static SizedBox gapXL = const SizedBox(height: xl, width: xl);
  static SizedBox gapXXL = const SizedBox(height: xxl, width: xxl);
}
