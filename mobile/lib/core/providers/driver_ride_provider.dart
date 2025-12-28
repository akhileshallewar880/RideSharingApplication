import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/driver_models.dart';
import '../services/driver_ride_service.dart';

// Driver ride service provider
final driverRideServiceProvider =
    Provider<DriverRideService>((ref) => DriverRideService());

// Driver ride state
class DriverRideState {
  final List<DriverRide> activeRides;
  final RideDetailsWithPassengers? currentRideDetails;
  final bool isLoading;
  final String? errorMessage;

  DriverRideState({
    this.activeRides = const [],
    this.currentRideDetails,
    this.isLoading = false,
    this.errorMessage,
  });

  DriverRideState copyWith({
    List<DriverRide>? activeRides,
    RideDetailsWithPassengers? currentRideDetails,
    bool? isLoading,
    String? errorMessage,
    bool clearCurrentRide = false,
  }) {
    return DriverRideState(
      activeRides: activeRides ?? this.activeRides,
      currentRideDetails: clearCurrentRide
          ? null
          : (currentRideDetails ?? this.currentRideDetails),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Driver ride notifier
class DriverRideNotifier extends StateNotifier<DriverRideState> {
  final DriverRideService _service;

  DriverRideNotifier(this._service) : super(DriverRideState());

  Future<bool> scheduleRide(ScheduleRideRequest request) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _service.scheduleRide(request);
      if (response.success) {
        // Reload active rides
        await loadActiveRides();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> loadActiveRides() async {
    print('🚗 Loading active rides...');
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _service.getActiveRides();
      print('📦 Service response - Success: ${response.success}, Data count: ${response.data?.length ?? 0}');
      if (response.success && response.data != null) {
        print('✅ Setting ${response.data!.length} rides in state');
        state = state.copyWith(
          activeRides: response.data!,
          isLoading: false,
        );
      } else {
        print('⚠️ Response not successful: ${response.message}');
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
      }
    } catch (e) {
      print('❌ Error loading rides: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadRideDetails(String rideId) async {
    print('🚗 Provider: Loading ride details for: $rideId');
    print('🚗 Provider: Current state before load - isLoading: ${state.isLoading}');
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      print('📡 Provider: Calling service.getRideDetails...');
      final response = await _service.getRideDetails(rideId);
      print('📦 Service response - Success: ${response.success}');
      if (response.success && response.data != null) {
        print('✅ Setting ride details with ${response.data!.passengers.length} passengers');
        state = state.copyWith(
          currentRideDetails: response.data,
          isLoading: false,
        );
        print('✅ State updated - currentRideDetails is now: ${state.currentRideDetails != null}');
        print('✅ State - isLoading: ${state.isLoading}');
      } else {
        print('⚠️ Response not successful: ${response.message}');
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
      }
    } catch (e) {
      print('❌ Error loading ride details: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> startTrip(String rideId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _service.startTrip(rideId);
      if (response.success) {
        // Reload ride details to get updated status
        await loadRideDetails(rideId);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> verifyPassengerOtp(
    String rideId,
    String bookingId,
    String otp,
  ) async {
    print('🔐 Provider: Verifying OTP for booking $bookingId');
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final request = VerifyOtpRequest(otp: otp);
      final response =
          await _service.verifyPassengerOtp(rideId, bookingId, request);
      print('📦 Verify response - Success: ${response.success}, Message: ${response.message}');
      
      if (response.success) {
        // Reload ride details to update passenger status
        await loadRideDetails(rideId);
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
        return false;
      }
    } catch (e) {
      print('❌ Provider error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> completeTrip(String rideId, CompleteTripRequest request) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _service.completeTrip(rideId, request);
      if (response.success) {
        // Clear current ride and reload active rides
        state = state.copyWith(clearCurrentRide: true);
        await loadActiveRides();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> cancelRide(String rideId, String reason) async {
    print('🚫 cancelRide called - rideId: $rideId, reason: "$reason"');
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final request = CancelRideRequest(reason: reason);
      print('🚫 Calling service.cancelRide...');
      final response = await _service.cancelRide(rideId, request);
      print('🚫 Service response - success: ${response.success}, message: ${response.message}');
      
      if (response.success) {
        print('✅ Cancel successful, reloading rides...');
        // Reload active rides
        await loadActiveRides();
        state = state.copyWith(clearCurrentRide: true);
        return true;
      } else {
        print('❌ Cancel failed: ${response.message}');
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
        return false;
      }
    } catch (e) {
      print('❌ Cancel error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void clearCurrentRide() {
    state = state.copyWith(clearCurrentRide: true);
  }

  /// Update ride price
  Future<bool> updateRidePrice(String rideId, double newPrice) async {
    print('💰 Updating price for ride: $rideId to ₹$newPrice');
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final request = UpdateRidePriceRequest(pricePerSeat: newPrice);
      final response = await _service.updateRidePrice(rideId, request);
      
      if (response.success) {
        print('✅ Price updated successfully');
        // Reload active rides to get updated data
        await loadActiveRides();
        
        // Update current ride details if it's the same ride
        if (state.currentRideDetails?.rideId == rideId) {
          await loadRideDetails(rideId);
        }
        
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
        return false;
      }
    } catch (e) {
      print('❌ Error updating price: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Update segment prices
  Future<bool> updateSegmentPrices(
    String rideId,
    List<SegmentPrice> segmentPrices,
  ) async {
    print('💰 Updating segment prices for ride: $rideId');
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final request = UpdateSegmentPricesRequest(segmentPrices: segmentPrices);
      final response = await _service.updateSegmentPrices(rideId, request);
      
      if (response.success) {
        print('✅ Segment prices updated successfully');
        // Reload active rides to get updated data
        await loadActiveRides();
        
        // Update current ride details if it's the same ride
        if (state.currentRideDetails?.rideId == rideId) {
          await loadRideDetails(rideId);
        }
        
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
        return false;
      }
    } catch (e) {
      print('❌ Error updating segment prices: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Update ride schedule
  Future<bool> updateRideSchedule(
    String rideId,
    String date,
    String departureTime,
  ) async {
    print('📅 Updating schedule for ride: $rideId to $date at $departureTime');
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final request = UpdateRideScheduleRequest(
        date: date,
        departureTime: departureTime,
      );
      final response = await _service.updateRideSchedule(rideId, request);
      
      if (response.success) {
        print('✅ Schedule updated successfully');
        // Reload active rides to get updated data
        await loadActiveRides();
        
        // Update current ride details if it's the same ride
        if (state.currentRideDetails?.rideId == rideId) {
          await loadRideDetails(rideId);
        }
        
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
        return false;
      }
    } catch (e) {
      print('❌ Error updating schedule: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

// Driver ride notifier provider
final driverRideNotifierProvider =
    StateNotifierProvider<DriverRideNotifier, DriverRideState>((ref) {
  final service = ref.watch(driverRideServiceProvider);
  return DriverRideNotifier(service);
});
