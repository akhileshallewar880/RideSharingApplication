import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_models.dart';
import '../services/ride_service.dart';
import 'admin_auth_provider.dart';

final rideServiceProvider = Provider<RideService>((ref) {
  final authService = ref.watch(adminAuthServiceProvider);
  return RideService(authService);
});

final activeRidesProvider = StateNotifierProvider<ActiveRidesNotifier, ActiveRidesState>((ref) {
  final rideService = ref.watch(rideServiceProvider);
  return ActiveRidesNotifier(rideService);
});

class ActiveRidesState {
  final List<RideInfo> rides;
  final bool isLoading;
  final String? error;
  final DateTime lastUpdated;

  ActiveRidesState({
    this.rides = const [],
    this.isLoading = false,
    this.error,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  ActiveRidesState copyWith({
    List<RideInfo>? rides,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return ActiveRidesState(
      rides: rides ?? this.rides,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class ActiveRidesNotifier extends StateNotifier<ActiveRidesState> {
  final RideService _rideService;

  ActiveRidesNotifier(this._rideService) : super(ActiveRidesState());

  Future<void> loadActiveRides() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final rides = await _rideService.getActiveRides();
      state = state.copyWith(
        rides: rides,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> cancelRide(String rideId, String reason) async {
    try {
      await _rideService.cancelRide(rideId, reason);
      // Remove from list
      state = state.copyWith(
        rides: state.rides.where((r) => r.id != rideId).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}
