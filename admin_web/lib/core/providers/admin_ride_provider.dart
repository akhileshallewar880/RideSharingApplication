import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_ride_models.dart';
import '../services/admin_ride_service.dart';
import '../services/admin_auth_service.dart';

// Provider instances
final adminRideServiceProvider = Provider<AdminRideService>((ref) {
  final authService = AdminAuthService();
  return AdminRideService(authService);
});

final adminRideNotifierProvider = StateNotifierProvider<AdminRideNotifier, AdminRideState>((ref) {
  return AdminRideNotifier(ref.read(adminRideServiceProvider));
});

final adminDriversProvider = StateNotifierProvider<AdminDriversNotifier, AdminDriversState>((ref) {
  return AdminDriversNotifier(ref.read(adminRideServiceProvider));
});

// State classes
class AdminRideState {
  final List<AdminRideInfo> rides;
  final bool isLoading;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  final int totalCount;

  AdminRideState({
    this.rides = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
  });

  AdminRideState copyWith({
    List<AdminRideInfo>? rides,
    bool? isLoading,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    int? totalCount,
  }) {
    return AdminRideState(
      rides: rides ?? this.rides,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class AdminDriversState {
  final List<AdminDriverInfo> drivers;
  final bool isLoading;
  final String? errorMessage;

  AdminDriversState({
    this.drivers = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  AdminDriversState copyWith({
    List<AdminDriverInfo>? drivers,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AdminDriversState(
      drivers: drivers ?? this.drivers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Notifiers
class AdminRideNotifier extends StateNotifier<AdminRideState> {
  final AdminRideService _service;

  AdminRideNotifier(this._service) : super(AdminRideState());

  /// Schedule a new ride
  Future<AdminScheduleRideResponse?> scheduleRide(AdminScheduleRideRequest request) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _service.scheduleRide(request);
      // Reload rides after scheduling
      await loadRides();
      return response;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Update/Reschedule a ride
  Future<bool> updateRide(String rideId, AdminUpdateRideRequest request) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.updateRide(rideId, request);
      // Reload rides after update
      await loadRides();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Cancel a ride
  Future<bool> cancelRide(String rideId, {String? reason, bool notifyPassengers = true}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.cancelRide(
        rideId,
        reason: reason,
        notifyPassengers: notifyPassengers,
      );
      // Reload rides after cancellation
      await loadRides();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Load rides with filters
  Future<void> loadRides({
    String? status,
    String? driverId,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int pageSize = 20,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await _service.getAllRides(
        status: status,
        driverId: driverId,
        fromDate: fromDate,
        toDate: toDate,
        page: page,
        pageSize: pageSize,
      );

      final rides = (data['rides'] as List)
          .map((item) => AdminRideInfo.fromJson(item as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        rides: rides,
        isLoading: false,
        currentPage: data['pageNumber'] ?? page,
        totalPages: ((data['totalCount'] ?? 0) / pageSize).ceil(),
        totalCount: data['totalCount'] ?? 0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Load next page
  Future<void> loadNextPage() async {
    if (state.currentPage < state.totalPages) {
      await loadRides(page: state.currentPage + 1);
    }
  }

  /// Load previous page
  Future<void> loadPreviousPage() async {
    if (state.currentPage > 1) {
      await loadRides(page: state.currentPage - 1);
    }
  }
}

class AdminDriversNotifier extends StateNotifier<AdminDriversState> {
  final AdminRideService _service;

  AdminDriversNotifier(this._service) : super(AdminDriversState());

  /// Load available drivers
  Future<void> loadDrivers({DateTime? date}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final drivers = await _service.getAvailableDrivers(date: date);
      state = state.copyWith(
        drivers: drivers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}
