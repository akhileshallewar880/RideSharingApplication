import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/vehicle_type_model.dart';
import '../../services/vehicle_type_api_service.dart';

// Service provider
final vehicleTypeServiceProvider = Provider<VehicleTypeApiService>((ref) {
  return VehicleTypeApiService();
});

// State notifier provider
final vehicleTypeNotifierProvider = StateNotifierProvider<VehicleTypeNotifier, VehicleTypeState>((ref) {
  return VehicleTypeNotifier(ref.read(vehicleTypeServiceProvider));
});

// Vehicle Type State
class VehicleTypeState {
  final List<VehicleType> vehicleTypes;
  final bool isLoading;
  final String? error;
  final VehicleType? selectedVehicleType;
  final int total;

  VehicleTypeState({
    this.vehicleTypes = const [],
    this.isLoading = false,
    this.error,
    this.selectedVehicleType,
    this.total = 0,
  });

  VehicleTypeState copyWith({
    List<VehicleType>? vehicleTypes,
    bool? isLoading,
    String? error,
    VehicleType? selectedVehicleType,
    bool clearSelectedVehicleType = false,
    int? total,
  }) {
    return VehicleTypeState(
      vehicleTypes: vehicleTypes ?? this.vehicleTypes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedVehicleType: clearSelectedVehicleType ? null : (selectedVehicleType ?? this.selectedVehicleType),
      total: total ?? this.total,
    );
  }
}

// State Notifier
class VehicleTypeNotifier extends StateNotifier<VehicleTypeState> {
  final VehicleTypeApiService _service;

  VehicleTypeNotifier(this._service) : super(VehicleTypeState());

  /// Load all vehicle types with optional filters
  Future<void> loadVehicleTypes({bool? isActive, String? category}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _service.getVehicleTypes(
        isActive: isActive,
        category: category,
      );

      state = state.copyWith(
        vehicleTypes: response.vehicleTypes,
        total: response.total,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load a specific vehicle type by ID
  Future<void> loadVehicleType(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final vehicleType = await _service.getVehicleType(id);
      state = state.copyWith(
        selectedVehicleType: vehicleType,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Create a new vehicle type
  Future<bool> createVehicleType(CreateVehicleTypeDto vehicleTypeDto) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final newVehicleType = await _service.createVehicleType(vehicleTypeDto);
      
      // Add to the list
      state = state.copyWith(
        vehicleTypes: [...state.vehicleTypes, newVehicleType],
        total: state.total + 1,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Update an existing vehicle type
  Future<bool> updateVehicleType(String id, UpdateVehicleTypeDto vehicleTypeDto) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedVehicleType = await _service.updateVehicleType(id, vehicleTypeDto);
      
      // Update in the list
      final updatedList = state.vehicleTypes.map((vt) {
        return vt.id == id ? updatedVehicleType : vt;
      }).toList();

      state = state.copyWith(
        vehicleTypes: updatedList,
        selectedVehicleType: updatedVehicleType,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Delete a vehicle type
  Future<bool> deleteVehicleType(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.deleteVehicleType(id);
      
      // Remove from the list
      final updatedList = state.vehicleTypes.where((vt) => vt.id != id).toList();

      state = state.copyWith(
        vehicleTypes: updatedList,
        total: state.total - 1,
        isLoading: false,
        clearSelectedVehicleType: true,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Clear selected vehicle type
  void clearSelectedVehicleType() {
    state = state.copyWith(clearSelectedVehicleType: true);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
