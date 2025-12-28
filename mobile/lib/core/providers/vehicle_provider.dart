import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle_models.dart';
import '../services/vehicle_service.dart';

// Vehicle service provider
final vehicleServiceProvider = Provider<VehicleService>((ref) => VehicleService());

// Vehicle state
class VehicleState {
  final VehicleDetails? vehicle;
  final bool isLoading;
  final String? errorMessage;

  VehicleState({
    this.vehicle,
    this.isLoading = false,
    this.errorMessage,
  });

  VehicleState copyWith({
    VehicleDetails? vehicle,
    bool? isLoading,
    String? errorMessage,
  }) {
    return VehicleState(
      vehicle: vehicle ?? this.vehicle,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Vehicle notifier
class VehicleNotifier extends StateNotifier<VehicleState> {
  final VehicleService _service;

  VehicleNotifier(this._service) : super(VehicleState());

  Future<void> loadVehicle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _service.getVehicle();
      if (response.success && response.data != null) {
        state = state.copyWith(
          vehicle: response.data,
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

  Future<bool> updateVehicle(UpdateVehicleRequest request) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _service.updateVehicle(request);
      if (response.success && response.data != null) {
        state = state.copyWith(
          vehicle: response.data,
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

  Future<bool> uploadDocument(dynamic file, String documentType) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _service.uploadDocument(file, documentType);
      if (response.success) {
        // Reload vehicle to get updated document URL
        await loadVehicle();
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

  Future<bool> deleteDocument(String documentType) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _service.deleteDocument(documentType);
      if (response.success) {
        // Reload vehicle to reflect deletion
        await loadVehicle();
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

  void clearVehicle() {
    state = VehicleState();
  }
}

// Vehicle notifier provider
final vehicleNotifierProvider =
    StateNotifierProvider<VehicleNotifier, VehicleState>((ref) {
  final service = ref.watch(vehicleServiceProvider);
  return VehicleNotifier(service);
});
