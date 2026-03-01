import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/driver_models.dart';
import '../../../../app/themes/app_colors.dart';
import '../../../../app/themes/app_spacing.dart';
import '../../../../app/themes/text_styles.dart';

/// Bottom sheet showing passengers at a specific stop for boarding and cash collection
class StopPassengersBottomSheet extends ConsumerStatefulWidget {
  final String stopLocation;
  final String rideId;
  final List<PassengerInfo> pickupPassengers;
  final List<PassengerInfo> dropoffPassengers;

  const StopPassengersBottomSheet({
    super.key,
    required this.stopLocation,
    required this.rideId,
    required this.pickupPassengers,
    required this.dropoffPassengers,
  });

  @override
  ConsumerState<StopPassengersBottomSheet> createState() => _StopPassengersBottomSheetState();
}

class _StopPassengersBottomSheetState extends ConsumerState<StopPassengersBottomSheet> {
  final Map<String, bool> _cashCollected = {};
  final Map<String, String> _passengerStatuses = {}; // Track local boarding statuses
  bool _hasMarkedPassenger = false; // Track if any passenger was marked as boarded

  @override
  void initState() {
    super.initState();
    for (var passenger in widget.pickupPassengers) {
      _passengerStatuses[passenger.bookingId] = passenger.boardingStatus;
    }
    for (var passenger in widget.dropoffPassengers) {
      _cashCollected[passenger.bookingId] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPickups = widget.pickupPassengers.isNotEmpty;
    final hasDropoffs = widget.dropoffPassengers.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLG)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(Icons.location_on, color: AppColors.primaryYellow),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.stopLocation,
                    style: TextStyles.headingMedium.copyWith(
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context, _hasMarkedPassenger),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pickup passengers
                  if (hasPickups) ...[
                    _buildSectionHeader('Boarding Passengers', Icons.arrow_circle_up, AppColors.success, isDark),
                    const SizedBox(height: AppSpacing.md),
                    ...widget.pickupPassengers.map((passenger) =>
                      _buildPickupPassengerCard(passenger, isDark)
                    ),
                    if (hasDropoffs) const SizedBox(height: AppSpacing.xl),
                  ],

                  // Dropoff passengers
                  if (hasDropoffs) ...[
                    _buildSectionHeader('Alighting Passengers', Icons.arrow_circle_down, AppColors.error, isDark),
                    const SizedBox(height: AppSpacing.md),
                    ...widget.dropoffPassengers.map((passenger) =>
                      _buildDropoffPassengerCard(passenger, isDark)
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: TextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPickupPassengerCard(PassengerInfo passenger, bool isDark) {
    final isBoarded = _passengerStatuses[passenger.bookingId] == 'boarded';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isBoarded
            ? AppColors.success.withValues(alpha: 0.1)
            : (isDark ? AppColors.darkBackground : AppColors.lightBackground),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        border: Border.all(
          color: isBoarded ? AppColors.success : Colors.grey[300]!,
          width: isBoarded ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isBoarded ? AppColors.success : AppColors.primaryYellow,
                child: Icon(
                  isBoarded ? Icons.check : Icons.person,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passenger.passengerName,
                      style: TextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      passenger.phoneNumber,
                      style: TextStyles.bodySmall.copyWith(
                        color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isBoarded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                  ),
                  child: Text(
                    'BOARDED',
                    style: TextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Trip details
          Row(
            children: [
              Icon(Icons.people, size: 16, color: Colors.grey[600]),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${passenger.passengerCount} ${passenger.passengerCount == 1 ? 'seat' : 'seats'}',
                style: TextStyles.bodyMedium.copyWith(
                  color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'To: ${passenger.dropoffLocation}',
                  style: TextStyles.bodyMedium.copyWith(
                    color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          if (!isBoarded) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _markAsBoarded(passenger),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark as Boarded'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropoffPassengerCard(PassengerInfo passenger, bool isDark) {
    final cashCollected = _cashCollected[passenger.bookingId] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cashCollected
            ? AppColors.success.withValues(alpha: 0.1)
            : (isDark ? AppColors.darkBackground : AppColors.lightBackground),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        border: Border.all(
          color: cashCollected ? AppColors.success : Colors.grey[300]!,
          width: cashCollected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: cashCollected ? AppColors.success : AppColors.error,
                child: Icon(
                  cashCollected ? Icons.check : Icons.person,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passenger.passengerName,
                      style: TextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      passenger.phoneNumber,
                      style: TextStyles.bodySmall.copyWith(
                        color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (cashCollected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                  ),
                  child: Text(
                    'PAID',
                    style: TextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Trip details
          Row(
            children: [
              Icon(Icons.people, size: 16, color: Colors.grey[600]),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${passenger.passengerCount} ${passenger.passengerCount == 1 ? 'seat' : 'seats'}',
                style: TextStyles.bodyMedium.copyWith(
                  color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'From: ${passenger.pickupLocation}',
                  style: TextStyles.bodyMedium.copyWith(
                    color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Payment info
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fare Amount',
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  '₹ ${_calculateFare(passenger)}',
                  style: TextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Cash collection button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: cashCollected ? null : () => _markCashCollected(passenger.bookingId),
              icon: Icon(cashCollected ? Icons.check_circle : Icons.payments),
              label: Text(cashCollected ? 'Cash Collected' : 'Collect Cash'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cashCollected ? Colors.grey : AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateFare(PassengerInfo passenger) {
    return '250';
  }

  void _markAsBoarded(PassengerInfo passenger) {
    setState(() {
      _passengerStatuses[passenger.bookingId] = 'boarded';
      _hasMarkedPassenger = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text('${passenger.passengerName} marked as boarded!'),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _markCashCollected(String bookingId) {
    setState(() {
      _cashCollected[bookingId] = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cash collection marked ✓'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
