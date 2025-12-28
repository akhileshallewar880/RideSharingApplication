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
            color: Colors.black.withOpacity(0.05),
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
              color: AppColors.primaryYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
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
    return Row(
      children: [
        _buildShimmerBox(120, 36, isDark, const Color(0xFFFFE5E5)),
        const SizedBox(width: AppSpacing.sm),
        _buildShimmerBox(100, 36, isDark, const Color(0xFFE5E5FF)),
        const SizedBox(width: AppSpacing.sm),
        _buildShimmerBox(100, 36, isDark, const Color(0xFFE5FFE5)),
      ],
    );
  }
  
  Widget _buildRideCardSkeleton(bool isDark, Color accentColor) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBg : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top section with icon and text
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShimmerBox(60, 60, isDark, accentColor),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildShimmerBox(200, 16, isDark, Colors.grey[300]!),
                              const SizedBox(height: AppSpacing.sm),
                              _buildShimmerBox(120, 12, isDark, Colors.grey[300]!),
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
                          child: _buildShimmerBox(double.infinity, 24, isDark, Colors.grey[300]!),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _buildShimmerBox(80, 40, isDark, accentColor),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.md),
                    
                    // Bottom buttons
                    Row(
                      children: [
                        _buildShimmerBox(100, 32, isDark, Colors.grey[300]!),
                        const SizedBox(width: AppSpacing.sm),
                        _buildShimmerBox(100, 32, isDark, Colors.grey[300]!),
                        const SizedBox(width: AppSpacing.sm),
                        _buildShimmerBox(100, 32, isDark, Colors.grey[300]!),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildShimmerBox(double width, double height, bool isDark, Color baseColor) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: baseColor.withOpacity(isDark ? 0.2 : 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(_shimmerAnimation.value * width, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(isDark ? 0.1 : 0.3),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
