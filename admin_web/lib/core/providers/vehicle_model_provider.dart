import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/vehicle_model_model.dart';
import '../../services/vehicle_model_api_service.dart';

final vehicleModelApiServiceProvider = Provider<VehicleModelApiService>((ref) {
  return VehicleModelApiService();
});

final vehicleModelNotifierProvider = StateNotifierProvider<VehicleModelNotifier, VehicleModelState>((ref) {
  final apiService = ref.watch(vehicleModelApiServiceProvider);
  return VehicleModelNotifier(apiService);
});

class VehicleModelState {
  final List<VehicleModel> vehicleModels;
  final bool isLoading;
  final String? error;

  VehicleModelState({
    this.vehicleModels = const [],
    this.isLoading = false,
    this.error,
  });

  VehicleModelState copyWith({
    List<VehicleModel>? vehicleModels,
    bool? isLoading,
    String? error,
  }) {
    return VehicleModelState(
      vehicleModels: vehicleModels ?? this.vehicleModels,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class VehicleModelNotifier extends StateNotifier<VehicleModelState> {
  final VehicleModelApiService _apiService;

  VehicleModelNotifier(this._apiService) : super(VehicleModelState());

  Future<void> loadVehicleModels({
    bool? isActive,
    String? type,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.getVehicleModels(
        isActive: isActive,
        type: type,
      );
      
      state = state.copyWith(
        vehicleModels: response.vehicles,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<VehicleModel?> createVehicleModel(CreateVehicleModelDto dto) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final vehicleModel = await _apiService.createVehicleModel(dto);
      
      // Add to list
      state = state.copyWith(
        vehicleModels: [...state.vehicleModels, vehicleModel],
        isLoading: false,
        error: null,
      );
      
      return vehicleModel;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  Future<VehicleModel?> updateVehicleModel(String id, UpdateVehicleModelDto dto) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedModel = await _apiService.updateVehicleModel(id, dto);
      
      // Update in list
      final updatedList = state.vehicleModels.map((model) {
        return model.id == id ? updatedModel : model;
      }).toList();
      
      state = state.copyWith(
        vehicleModels: updatedList,
        isLoading: false,
        error: null,
      );
      
      return updatedModel;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  Future<bool> deleteVehicleModel(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.deleteVehicleModel(id);
      
      // Remove from list
      final updatedList = state.vehicleModels.where((model) => model.id != id).toList();
      
      state = state.copyWith(
        vehicleModels: updatedList,
        isLoading: false,
        error: null,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}
