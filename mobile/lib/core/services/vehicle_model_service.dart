import 'package:dio/dio.dart';
import 'package:allapalli_ride/core/models/api_response.dart';
import 'package:allapalli_ride/core/models/vehicle_models.dart';
import 'package:allapalli_ride/core/network/dio_client.dart';

/// Service for vehicle model catalog operations
class VehicleModelService {
  final Dio _dio = DioClient.instance;

  /// Get all available vehicle models
  Future<ApiResponse<VehicleModelsResponse>> getVehicleModels({
    String? type,
    bool activeOnly = true,
  }) async {
    try {
      print('🚗 Fetching vehicle models...');
      if (type != null) print('   Type filter: $type');
      
      final queryParams = <String, dynamic>{};
      if (type != null) queryParams['type'] = type;
      if (activeOnly) queryParams['active'] = true;

      final response = await _dio.get(
        '/vehicles/models',
        queryParameters: queryParams,
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => VehicleModelsResponse.fromJson(json),
      );

      print('✅ Fetched ${apiResponse.data?.vehicles.length ?? 0} vehicle models');
      
      return apiResponse;
    } on DioException catch (e) {
      print('❌ Error fetching vehicle models: ${e.message}');
      
      // Return popular models as fallback
      print('⚠️ Using fallback vehicle models');
      final fallbackVehicles = type != null
          ? PopularVehicleModels.getByType(type)
          : PopularVehicleModels.all;
      
      return ApiResponse(
        success: true,
        message: 'Using default vehicle models',
        data: VehicleModelsResponse(
          vehicles: fallbackVehicles,
          total: fallbackVehicles.length,
        ),
      );
    }
  }

  /// Get vehicle models by type (cars, suvs, vans, buses)
  Future<ApiResponse<VehicleModelsResponse>> getVehicleModelsByType(
    String type,
  ) async {
    return getVehicleModels(type: type);
  }

  /// Get specific vehicle model by ID
  Future<ApiResponse<VehicleModel>> getVehicleModelById(String modelId) async {
    try {
      print('🚗 Fetching vehicle model: $modelId');
      
      final response = await _dio.get('/vehicles/models/$modelId');

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => VehicleModel.fromJson(json),
      );

      print('✅ Vehicle model fetched: ${apiResponse.data?.displayName}');
      
      return apiResponse;
    } on DioException catch (e) {
      print('❌ Error fetching vehicle model: ${e.message}');
      
      // Try to find in fallback list
      try {
        final fallbackModel = PopularVehicleModels.all
            .firstWhere((model) => model.id == modelId);
        
        return ApiResponse(
          success: true,
          message: 'Using default vehicle model',
          data: fallbackModel,
        );
      } catch (_) {
        return _handleError(e);
      }
    }
  }

  /// Search vehicle models by name or brand
  Future<ApiResponse<VehicleModelsResponse>> searchVehicleModels(
    String query,
  ) async {
    try {
      print('🔍 Searching vehicle models: $query');
      
      final response = await _dio.get(
        '/vehicles/models/search',
        queryParameters: {'q': query},
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => VehicleModelsResponse.fromJson(json),
      );

      print('✅ Found ${apiResponse.data?.vehicles.length ?? 0} matching models');
      
      return apiResponse;
    } on DioException catch (e) {
      print('❌ Error searching vehicle models: ${e.message}');
      
      // Search in fallback list
      final searchQuery = query.toLowerCase();
      final matchingModels = PopularVehicleModels.all.where((model) {
        return model.name.toLowerCase().contains(searchQuery) ||
            model.brand.toLowerCase().contains(searchQuery) ||
            model.displayName.toLowerCase().contains(searchQuery);
      }).toList();
      
      return ApiResponse(
        success: true,
        message: 'Search results from default models',
        data: VehicleModelsResponse(
          vehicles: matchingModels,
          total: matchingModels.length,
        ),
      );
    }
  }

  /// Get vehicle categories
  List<String> getVehicleCategories() {
    return ['All', 'Car', 'SUV', 'Van', 'Bus'];
  }

  /// Get fallback/popular vehicle models (offline support)
  VehicleModelsResponse getPopularVehicleModels({String? type}) {
    final vehicles = type != null
        ? PopularVehicleModels.getByType(type)
        : PopularVehicleModels.all;
    
    return VehicleModelsResponse(
      vehicles: vehicles,
      total: vehicles.length,
    );
  }

  /// Handle Dio errors
  ApiResponse<T> _handleError<T>(DioException error) {
    String message = 'An error occurred';

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout. Please check your internet connection.';
    } else if (error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 404) {
        message = 'Vehicle models not found';
      } else if (statusCode == 500) {
        message = 'Server error. Please try again later.';
      } else {
        message = error.response?.data['message'] ?? 'Request failed';
      }
    } else if (error.type == DioExceptionType.cancel) {
      message = 'Request cancelled';
    } else {
      message = 'Network error. Please check your connection.';
    }

    return ApiResponse(
      success: false,
      message: message,
    );
  }
}
