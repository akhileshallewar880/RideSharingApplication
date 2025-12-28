import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';

/// Animated loader widget
class AnimatedLoader extends StatelessWidget {
  final double size;
  final Color? color;
  
  const AnimatedLoader({
    super.key,
    this.size = AppSpacing.iconLG,
    this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return SpinKitFadingCircle(
      color: color ?? AppColors.primaryYellow,
      size: size,
    );
  }
}

/// Full screen loading overlay
class LoadingOverlay extends StatelessWidget {
  final String? message;
  
  const LoadingOverlay({
    super.key,
    this.message,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      color: (isDark ? AppColors.darkBackground : AppColors.lightBackground)
          .withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AnimatedLoader(),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder
class ShimmerLoader extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  
  const ShimmerLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightBorder,
        borderRadius: borderRadius ?? AppSpacing.borderRadiusMD,
      ),
    );
  }
}
