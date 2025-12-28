import 'package:flutter/material.dart';
import '../../../../app/themes/app_colors.dart';
import '../../../../app/themes/app_spacing.dart';
import '../../../../app/themes/text_styles.dart';

/// Bottom sheet for rating a completed ride (Passenger version)
class RateRideBottomSheet extends StatefulWidget {
  final String rideId;
  final String bookingNumber;
  final String? driverName;
  final double? driverRating;
  final String? vehicleModel;
  final String? vehicleNumber;
  final Function(int rating, String feedback) onSubmit;

  const RateRideBottomSheet({
    super.key,
    required this.rideId,
    required this.bookingNumber,
    this.driverName,
    this.driverRating,
    this.vehicleModel,
    this.vehicleNumber,
    required this.onSubmit,
  });

  @override
  State<RateRideBottomSheet> createState() => _RateRideBottomSheetState();
}

class _RateRideBottomSheetState extends State<RateRideBottomSheet> {
  int _selectedRating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_selectedRating == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = true);

    try {
      // Call the onSubmit callback - parent will handle closing and API call
      await widget.onSubmit(_selectedRating, _feedbackController.text.trim());
      // Don't close here - parent handles it to avoid "ref after dispose" error
    } catch (e) {
      print('❌ Rating submission error: $e');
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      // Close on error only
      Navigator.pop(context, false);
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text('Failed to submit rating. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title
              Text(
                'Rate Your Trip',
                style: TextStyles.headingMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.bookingNumber,
                style: TextStyles.bodyMedium.copyWith(
                  color: isDark ? Colors.white60 : AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              // Driver Details Card
              if (widget.driverName != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : AppColors.primaryYellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                    border: Border.all(
                      color: isDark ? Colors.white12 : AppColors.primaryYellow.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Driver Icon
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primaryYellow.withOpacity(0.2),
                        child: Icon(
                          Icons.person,
                          size: 32,
                          color: AppColors.primaryYellow,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Driver Name
                      Text(
                        widget.driverName!,
                        style: TextStyles.bodyLarge.copyWith(
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Driver Rating
                      if (widget.driverRating != null && widget.driverRating! > 0) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              widget.driverRating!.toStringAsFixed(1),
                              style: TextStyles.bodyMedium.copyWith(
                                color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                      // Vehicle Details
                      if (widget.vehicleModel != null || widget.vehicleNumber != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Divider(
                          color: isDark ? Colors.white12 : Colors.grey[300],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions_car,
                              size: 18,
                              color: isDark ? Colors.white60 : AppColors.lightTextSecondary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '${widget.vehicleModel ?? ''} ${widget.vehicleNumber ?? ''}',
                              style: TextStyles.bodyMedium.copyWith(
                                color: isDark ? Colors.white60 : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: AppSpacing.xl),

              // Star rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedRating = starValue);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        starValue <= _selectedRating
                            ? Icons.star
                            : Icons.star_border,
                        size: 44,
                        color: starValue <= _selectedRating
                            ? AppColors.primaryYellow
                            : (isDark ? Colors.white38 : Colors.grey[400]),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Rating text
              if (_selectedRating > 0)
                Text(
                  _getRatingText(_selectedRating),
                  style: TextStyles.bodyLarge.copyWith(
                    color: AppColors.primaryYellow,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: AppSpacing.xl),

              // Feedback field
              Text(
                'Additional Feedback (Optional)',
                style: TextStyles.bodyMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _feedbackController,
                maxLines: 4,
                maxLength: 500,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Share your experience about this trip...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white12 : Colors.grey[300]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                    borderSide: BorderSide(
                      color: AppColors.primaryYellow,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                  ),
                  disabledBackgroundColor: Colors.grey[400],
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Submit Rating',
                        style: TextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}
