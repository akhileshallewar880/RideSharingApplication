import 'package:flutter/material.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:intl/intl.dart';

/// Skeleton loading screen shown while searching for rides
class RideSearchLoadingScreen extends StatefulWidget {
  final String pickupLocation;
  final String dropoffLocation;
  final DateTime travelDate;
  
  const RideSearchLoadingScreen({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.travelDate,
  });
  
  @override
  State<RideSearchLoadingScreen> createState() => _RideSearchLoadingScreenState();
}

class _RideSearchLoadingScreenState extends State<RideSearchLoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  
  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _shimmerAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );
  }
  
  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(isDark),
            
            // Loading content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    // Filter chips skeleton
                    _buildFilterChipsSkeleton(isDark),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Ride card skeletons
                    _buildRideCardSkeleton(isDark, const Color(0xFFFFE5E5)),
                    const SizedBox(height: AppSpacing.md),
                    _buildRideCardSkeleton(isDark, const Color(0xFFE5E5FF)),
                    const SizedBox(height: AppSpacing.md),
                    _buildRideCardSkeleton(isDark, const Color(0xFFE5FFE5)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.pickupLocation,
                        style: TextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: isDark 
                            ? AppColors.darkTextSecondary 
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        widget.dropoffLocation,
                        style: TextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '0 Buses',
                  style: TextStyles.bodySmall.copyWith(
                    color: isDark 
                        ? AppColors.darkTextSecondary 
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Date badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('dd MMM').format(widget.travelDate),
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('E').format(widget.travelDate),
                  style: TextStyles.caption.copyWith(
                    color: isDark 
                        ? AppColors.darkTextSecondary 
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChipsSkeleton(bool isDark) {
    final chipColor = isDark ? AppColors.darkCardBg : Colors.grey[200]!;
    return Row(
      children: [
        Expanded(child: _buildShimmerBox(double.infinity, 36, isDark, chipColor)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _buildShimmerBox(double.infinity, 36, isDark, chipColor)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _buildShimmerBox(double.infinity, 36, isDark, chipColor)),
      ],
    );
  }
  
  Widget _buildRideCardSkeleton(bool isDark, Color accentColor) {
    final greyColor = isDark ? AppColors.darkBorder : Colors.grey[300]!;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top section with icon and text
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(60, 60, isDark, greyColor),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerBox(double.infinity, 16, isDark, greyColor),
                      const SizedBox(height: AppSpacing.sm),
                      _buildShimmerBox(120, 12, isDark, greyColor),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Middle section
            Row(
              children: [
                Expanded(
                  child: _buildShimmerBox(double.infinity, 24, isDark, greyColor),
                ),
                const SizedBox(width: AppSpacing.md),
                _buildShimmerBox(80, 40, isDark, greyColor),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Bottom buttons
            Row(
              children: [
                Expanded(child: _buildShimmerBox(double.infinity, 32, isDark, greyColor)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _buildShimmerBox(double.infinity, 32, isDark, greyColor)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _buildShimmerBox(double.infinity, 32, isDark, greyColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBox(double width, double height, bool isDark, Color baseColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use actual layout width when double.infinity is passed
        final resolvedWidth = width == double.infinity ? constraints.maxWidth : width;
        return AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (context, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: resolvedWidth,
                height: height,
                color: baseColor.withValues(alpha: isDark ? 0.2 : 0.5),
                child: Transform.translate(
                  offset: Offset(_shimmerAnimation.value * resolvedWidth, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: isDark ? 0.1 : 0.3),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
