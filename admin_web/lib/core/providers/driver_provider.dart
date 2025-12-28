import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_models.dart';
import '../services/driver_service.dart';
import 'admin_auth_provider.dart';

final driverServiceProvider = Provider<DriverService>((ref) {
  final authService = ref.watch(adminAuthServiceProvider);
  return DriverService(authService);
});

final pendingDriversProvider = StateNotifierProvider<PendingDriversNotifier, PendingDriversState>((ref) {
  final driverService = ref.watch(driverServiceProvider);
  return PendingDriversNotifier(driverService);
});

class PendingDriversState {
  final List<PendingDriver> drivers;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;

  PendingDriversState({
    this.drivers = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
  });

  PendingDriversState copyWith({
    List<PendingDriver>? drivers,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
  }) {
    return PendingDriversState(
      drivers: drivers ?? this.drivers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class PendingDriversNotifier extends StateNotifier<PendingDriversState> {
  final DriverService _driverService;

  PendingDriversNotifier(this._driverService) : super(PendingDriversState());

  Future<void> loadDrivers({String? status, String? searchQuery}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final drivers = await _driverService.getPendingDrivers(
        page: 1,
        pageSize: 20,
        status: status,
        searchQuery: searchQuery,
      );
      
      state = state.copyWith(
        drivers: drivers,
        isLoading: false,
        currentPage: 1,
        hasMore: drivers.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadMore({String? status, String? searchQuery}) async {
    if (state.isLoading || !state.hasMore) return;
    
    state = state.copyWith(isLoading: true);
    
    try {
      final nextPage = state.currentPage + 1;
      final newDrivers = await _driverService.getPendingDrivers(
        page: nextPage,
        pageSize: 20,
        status: status,
        searchQuery: searchQuery,
      );
      
      state = state.copyWith(
        drivers: [...state.drivers, ...newDrivers],
        isLoading: false,
        currentPage: nextPage,
        hasMore: newDrivers.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> approveDriver(String driverId, {String? notes}) async {
    try {
      await _driverService.approveDriver(driverId, notes: notes);
      // Remove from list
      state = state.copyWith(
        drivers: state.drivers.where((d) => d.id != driverId).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> rejectDriver(String driverId, String reason) async {
    try {
      await _driverService.rejectDriver(driverId, reason);
      // Remove from list
      state = state.copyWith(
        drivers: state.drivers.where((d) => d.id != driverId).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}
