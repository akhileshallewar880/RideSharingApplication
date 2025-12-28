import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/core/providers/driver_dashboard_provider.dart';

/// Driver earnings screen
class DriverEarningsScreen extends ConsumerStatefulWidget {
  const DriverEarningsScreen({super.key});
  
  @override
  ConsumerState<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends ConsumerState<DriverEarningsScreen> {
  
  @override
  void initState() {
    super.initState();
    // Load earnings for current month
    Future.microtask(() {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1).toIso8601String();
      final endDate = DateTime(now.year, now.month + 1, 0).toIso8601String();
      ref.read(driverDashboardNotifierProvider.notifier)
          .loadEarnings(startDate: startDate, endDate: endDate);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(driverDashboardNotifierProvider);
    final earningsData = dashboardState.earningsData;
    
    return RefreshIndicator(
      onRefresh: () async {
        final now = DateTime.now();
        final startDate = DateTime(now.year, now.month, 1).toIso8601String();
        final endDate = DateTime(now.year, now.month + 1, 0).toIso8601String();
        await ref.read(driverDashboardNotifierProvider.notifier)
            .loadEarnings(startDate: startDate, endDate: endDate);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Total earnings card
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppSpacing.borderRadiusLG,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Earnings',
                  style: TextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '₹${(earningsData?.summary.totalEarnings ?? 0.0).toStringAsFixed(0)}',
                  style: TextStyles.displayLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(color: Colors.white.withOpacity(0.3)),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _EarningsStat(
                      label: 'Total Rides',
                      value: '${earningsData?.summary.totalRides ?? 0}',
                    ),
                    _EarningsStat(
                      label: 'Avg/Ride',
                      value: '₹${(earningsData?.summary.averageEarningsPerRide ?? 0.0).toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ],
            ),
          ).animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.2, end: 0),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Earnings Breakdown
          Text(
            'Earnings Breakdown',
            style: TextStyles.headingMedium,
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.payments,
                  label: 'Cash',
                  value: '₹${(earningsData?.breakdown.cashCollected ?? 0.0).toStringAsFixed(0)}',
                  color: AppColors.success,
                ).animate()
                    .fadeIn(delay: 100.ms)
                    .slideY(begin: 0.2, end: 0, delay: 100.ms),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  icon: Icons.credit_card,
                  label: 'Online',
                  value: '₹${(earningsData?.breakdown.onlinePayments ?? 0.0).toStringAsFixed(0)}',
                  color: AppColors.info,
                ).animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: 0.2, end: 0, delay: 200.ms),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.remove_circle_outline,
                  label: 'Commission',
                  value: '₹${(earningsData?.breakdown.commission ?? 0.0).toStringAsFixed(0)}',
                  color: AppColors.error,
                ).animate()
                    .fadeIn(delay: 300.ms)
                    .slideY(begin: 0.2, end: 0, delay: 300.ms),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  icon: Icons.account_balance_wallet,
                  label: 'Net Earnings',
                  value: '₹${(earningsData?.breakdown.netEarnings ?? 0.0).toStringAsFixed(0)}',
                  color: AppColors.primaryYellow,
                ).animate()
                    .fadeIn(delay: 400.ms)
                    .slideY(begin: 0.2, end: 0, delay: 400.ms),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Recent payouts
          Text(
            'Recent Payouts',
            style: TextStyles.headingMedium,
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          if (dashboardState.payoutHistory.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No payout history yet',
                      style: TextStyles.bodyLarge.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...dashboardState.payoutHistory.map((payout) => _PayoutTile(
              amount: '₹${payout.amount.toStringAsFixed(0)}',
              date: payout.completedAt ?? payout.requestedAt,
              status: payout.status,
            )),
        ],
      ),
    );
  }
}

class _EarningsStat extends StatelessWidget {
  final String label;
  final String value;
  
  const _EarningsStat({
    required this.label,
    required this.value,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.caption.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: TextStyles.headingLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: AppSpacing.borderRadiusLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: AppSpacing.iconLG,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            label,
            style: TextStyles.caption.copyWith(
              color: isDark 
                  ? AppColors.darkTextSecondary 
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: TextStyles.headingLarge,
          ),
        ],
      ),
    );
  }
}

class _PayoutTile extends StatelessWidget {
  final String amount;
  final String date;
  final String status;
  
  const _PayoutTile({
    required this.amount,
    required this.date,
    required this.status,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: AppSpacing.borderRadiusMD,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: AppSpacing.borderRadiusSM,
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  amount,
                  style: TextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  date,
                  style: TextStyles.caption.copyWith(
                    color: isDark 
                        ? AppColors.darkTextSecondary 
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: AppSpacing.borderRadiusSM,
            ),
            child: Text(
              status,
              style: TextStyles.caption.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
