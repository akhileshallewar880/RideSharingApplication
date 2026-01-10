import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/passenger_ride_models.dart';
import '../services/passenger_ride_service.dart';

// Passenger ride service provider
final passengerRideServiceProvider =
    Provider<PassengerRideService>((ref) => PassengerRideService());

// Passenger ride state
class PassengerRideState {
  final List<AvailableRide> availableRides;
  final BookingDetails? currentBooking;
  final List<RideHistoryItem> rideHistory;
  final bool isLoading;
  final String? errorMessage;

  PassengerRideState({
    this.availableRides = const [],
    this.currentBooking,
    this.rideHistory = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  PassengerRideState copyWith({
    List<AvailableRide>? availableRides,
    BookingDetails? currentBooking,
    List<RideHistoryItem>? rideHistory,
    bool? isLoading,
    String? errorMessage,
    bool clearCurrentBooking = false,
  }) {
    return PassengerRideState(
      availableRides: availableRides ?? this.availableRides,
      currentBooking:
          clearCurrentBooking ? null : (currentBooking ?? this.currentBooking),
      rideHistory: rideHistory ?? this.rideHistory,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Passenger ride notifier
class PassengerRideNotifier extends StateNotifier<PassengerRideState> {
  final PassengerRideService _service;

  PassengerRideNotifier(this._service) : super(PassengerRideState());

  Future<void> searchRides(SearchRidesRequest request) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _service.searchRides(request);
      if (response.success && response.data != null) {
        print('🔍 Search Results: Found ${response.data!.length} rides');
        for (var ride in response.data!) {
          print('   Ride ${ride.rideId}:');
          print('     Route: ${ride.pickupLocation} → ${ride.dropoffLocation}');
          print('     Intermediate Stops: ${ride.intermediateStops}');
          print('     Stops Count: ${ride.intermediateStops?.length ?? 0}');
        }
        state = state.copyWith(
          availableRides: response.data!,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> bookRide(BookRideRequest request) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _service.bookRide(request);
      if (response.success && response.data != null) {
        print('🎫 [PROVIDER] BookingResponse received:');
        print('   Booking Number: ${response.data!.bookingNumber}');
        print('   Selected Seats from API: ${response.data!.selectedSeats}');
        
        // Convert BookingResponse to BookingDetails
        final bookingDetails = BookingDetails(
          bookingNumber: response.data!.bookingNumber,
          status: response.data!.status,
          otp: response.data!.otp,
          rideId: response.data!.rideId,
          pickupLocation: response.data!.pickupLocation,
          dropoffLocation: response.data!.dropoffLocation,
          departureTime: response.data!.departureTime,
          passengerCount: response.data!.passengerCount,
          totalFare: response.data!.totalFare,
          paymentStatus: response.data!.paymentStatus,
          driverDetails: response.data!.driverDetails,
          selectedSeats: response.data!.selectedSeats,
        );
        
        print('🎫 [PROVIDER] BookingDetails created:');
        print('   Selected Seats in BookingDetails: ${bookingDetails.selectedSeats}');
        
        state = state.copyWith(
          currentBooking: bookingDetails,
          isLoading: false,
        );
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

  Future<void> loadBookingDetails(String bookingId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _service.getBookingDetails(bookingId);
      if (response.success && response.data != null) {
        state = state.copyWith(
          currentBooking: response.data,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<BookingDetails?> getBookingDetails(String bookingId) async {
    try {
      final response = await _service.getBookingDetails(bookingId);
      if (response.success && response.data != null) {
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> cancelBooking(String bookingId, String reason) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final request = CancelBookingRequest(
        reason: reason,
        cancellationType: 'passenger',
      );
      final response = await _service.cancelBooking(bookingId, request);
      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          clearCurrentBooking: true,
        );
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

  Future<void> loadRideHistory({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _service.getRideHistory(
        status: status,
        page: page,
        pageSize: pageSize,
      );
      if (response.success && response.data != null) {
        final items = response.data!.items;
        final newHistory = page == 1
            ? items
            : [...state.rideHistory, ...items];
        state = state.copyWith(
          rideHistory: newHistory,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> rateRide(String bookingId, RateRideRequest request) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _service.rateRide(bookingId, request);
      if (response.success) {
        // Refresh ride history
        await loadRideHistory();
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

  void clearAvailableRides() {
    state = state.copyWith(availableRides: []);
  }

  void clearCurrentBooking() {
    state = state.copyWith(clearCurrentBooking: true);
  }
}

// Passenger ride notifier provider
final passengerRideNotifierProvider =
    StateNotifierProvider<PassengerRideNotifier, PassengerRideState>((ref) {
  final service = ref.watch(passengerRideServiceProvider);
  return PassengerRideNotifier(service);
});
