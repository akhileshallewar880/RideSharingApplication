import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';

/// Ride card component for displaying ride information
class RideCard extends StatelessWidget {
  final String pickupLocation;
  final String dropoffLocation;
  final String? driverName;
  final String? vehicleNumber;
  final String? fare;
  final String? status;
  final String? time;
  final VoidCallback? onTap;
  
  const RideCard({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.driverName,
    this.vehicleNumber,
    this.fare,
    this.status,
    this.time,
    this.onTap,
  });
  
  Color _getStatusColor() {
    switch (status?.toLowerCase()) {
      case 'completed':
        return AppColors.rideCompleted;
      case 'ongoing':
      case 'active':
        return AppColors.rideActive;
      case 'scheduled':
        return AppColors.rideScheduled;
      case 'cancelled':
        return AppColors.rideCancelled;
      default:
        return AppColors.lightTextSecondary;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusLG,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (status != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: AppSpacing.borderRadiusSM,
                      ),
                      child: Text(
                        status!.toUpperCase(),
                        style: TextStyles.labelSmall.copyWith(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (time != null)
                    Text(
                      time!,
                      style: TextStyles.bodySmall.copyWith(
                        color: isDark 
                            ? AppColors.darkTextSecondary 
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Route information
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route indicator
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppColors.pickupMarker,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 30,
                        color: isDark 
                            ? AppColors.darkBorder 
                            : AppColors.lightBorder,
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppColors.dropoffMarker,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: AppSpacing.md),
                  
                  // Locations
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pickupLocation,
                          style: TextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 26),
                        Text(
                          dropoffLocation,
                          style: TextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Driver and fare information
              if (driverName != null || vehicleNumber != null || fare != null) ...[
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (driverName != null || vehicleNumber != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (driverName != null)
                            Text(
                              driverName!,
                              style: TextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (vehicleNumber != null)
                            Text(
                              vehicleNumber!,
                              style: TextStyles.caption.copyWith(
                                color: isDark 
                                    ? AppColors.darkTextSecondary 
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                        ],
                      ),
                    if (fare != null)
                      Text(
                        fare!,
                        style: TextStyles.headingMedium.copyWith(
                          color: AppColors.primaryYellow,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(
      begin: -0.1,
      end: 0,
      duration: 300.ms,
    );
  }
}

/// Driver info card
class DriverInfoCard extends StatelessWidget {
  final String name;
  final String vehicleNumber;
  final String vehicleModel;
  final String? photoUrl;
  final double? rating;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;
  
  const DriverInfoCard({
    super.key,
    required this.name,
    required this.vehicleNumber,
    required this.vehicleModel,
    this.photoUrl,
    this.rating,
    this.onCall,
    this.onMessage,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            // Driver photo
            CircleAvatar(
              radius: AppSpacing.avatarMD / 2,
              backgroundColor: AppColors.primaryYellow,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
              child: photoUrl == null
                  ? Text(
                      name[0].toUpperCase(),
                      style: TextStyles.headingMedium.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    )
                  : null,
            ),
            
            const SizedBox(width: AppSpacing.md),
            
            // Driver info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: TextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (rating != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.star,
                          size: AppSpacing.iconSM,
                          color: AppColors.primaryYellow,
                        ),
                        Text(
                          rating!.toStringAsFixed(1),
                          style: TextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$vehicleModel • $vehicleNumber',
                    style: TextStyles.bodySmall.copyWith(
                      color: isDark 
                          ? AppColors.darkTextSecondary 
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Action buttons
            Row(
              children: [
                if (onCall != null)
                  IconButton(
                    onPressed: onCall,
                    icon: const Icon(Icons.phone),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.success.withOpacity(0.1),
                      foregroundColor: AppColors.success,
                    ),
                  ),
                if (onMessage != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    onPressed: onMessage,
                    icon: const Icon(Icons.message),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.info.withOpacity(0.1),
                      foregroundColor: AppColors.info,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
