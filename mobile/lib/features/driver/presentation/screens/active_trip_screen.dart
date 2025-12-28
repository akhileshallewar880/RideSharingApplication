import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/shared/widgets/buttons.dart';
import 'package:allapalli_ride/core/models/driver_models.dart';
import 'package:allapalli_ride/core/providers/driver_ride_provider.dart';
import 'package:allapalli_ride/features/driver/presentation/screens/driver_tracking_screen.dart';


/// Active trip screen - now shows live tracking with train-style UI
class ActiveTripScreen extends ConsumerStatefulWidget {
  final DriverRide ride;
  final DateTime scheduledDepartureTime;

  const ActiveTripScreen({
    super.key,
    required this.ride,
    required this.scheduledDepartureTime,
  });

  @override
  ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen> {
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    // Defer state modifications until after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndRedirect();
    });
  }
  
  Future<void> _loadAndRedirect() async {
    try {
      print('� Starting trip...');
      
      // First, start the trip via API
      final success = await ref.read(driverRideNotifierProvider.notifier).startTrip(widget.ride.rideId);
      
      if (!success) {
        print('❌ Failed to start trip');
        if (mounted) {
          setState(() => _isLoading = false);
          final errorMsg = ref.read(driverRideNotifierProvider).errorMessage ?? 'Failed to start trip';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      
      print('✅ Trip started successfully');
      print('�📡 Loading ride details for tracking redirect...');
      await ref.read(driverRideNotifierProvider.notifier).loadRideDetails(widget.ride.rideId);
      
      if (!mounted) return;
      
      final rideDetails = ref.read(driverRideNotifierProvider).currentRideDetails;
      
      if (rideDetails != null && mounted) {
        print('✅ Ride details loaded, navigating to tracking screen');
        // Import DriverTrackingScreen and navigate directly
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DriverTrackingScreen(
              rideId: widget.ride.rideId,
              rideDetails: rideDetails,
            ),
          ),
        );
      } else {
        print('❌ Ride details is null');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load ride details. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error loading ride details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Not needed - redirecting in initState
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? AppColors.darkBackground 
            : AppColors.lightBackground,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // If loading failed, show error
    return Scaffold(
      appBar: AppBar(title: Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: AppColors.error),
            SizedBox(height: AppSpacing.md),
            Text('Failed to load ride details'),
            SizedBox(height: AppSpacing.md),
            PrimaryButton(
              text: 'Retry',
              onPressed: () {
                setState(() => _isLoading = true);
                _loadAndRedirect();
              },
            ),
          ],
        ),
      ),
    );
  }
}
