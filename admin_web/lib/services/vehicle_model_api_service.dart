import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vehicle_model_model.dart';
import '../core/services/admin_auth_service.dart';
import '../core/constants/app_constants.dart';

class VehicleModelApiService {
  static String get baseUrl => '${AppConstants.baseUrl}/vehicles/models';
  final AdminAuthService _authService = AdminAuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Get all vehicle models with optional filters
  Future<VehicleModelsResponse> getVehicleModels({
    bool? isActive,
    String? type,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (isActive != null) queryParams['active'] = isActive.toString();
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return VehicleModelsResponse.fromJson(jsonData['data']);
        }
      }

      throw Exception('Failed to load vehicle models');
    } catch (e) {
      throw Exception('Error fetching vehicle models: $e');
    }
  }

  /// Get a specific vehicle model by ID
  Future<VehicleModel> getVehicleModel(String id) async {
    try {
      final uri = Uri.parse('$baseUrl/$id');
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return VehicleModel.fromJson(jsonData['data']);
        }
      }

      throw Exception('Failed to load vehicle model');
    } catch (e) {
      throw Exception('Error fetching vehicle model: $e');
    }
  }

  /// Create a new vehicle model
  Future<VehicleModel> createVehicleModel(CreateVehicleModelDto vehicleModelDto) async {
    try {
      final uri = Uri.parse(baseUrl);
      final response = await http.post(
        uri,
        headers: await _getHeaders(),
        body: json.encode(vehicleModelDto.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return VehicleModel.fromJson(jsonData['data']);
        }
      }

      // Try to get error message from response
      final jsonData = json.decode(response.body);
      final errorMessage = jsonData['message'] ?? 'Failed to create vehicle model';
      throw Exception(errorMessage);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error creating vehicle model: $e');
    }
  }

  /// Update an existing vehicle model
  Future<VehicleModel> updateVehicleModel(String id, UpdateVehicleModelDto vehicleModelDto) async {
    try {
      final uri = Uri.parse('$baseUrl/$id');
      final response = await http.put(
        uri,
        headers: await _getHeaders(),
        body: json.encode(vehicleModelDto.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return VehicleModel.fromJson(jsonData['data']);
        }
      }

      // Try to get error message from response
      final jsonData = json.decode(response.body);
      final errorMessage = jsonData['message'] ?? 'Failed to update vehicle model';
      throw Exception(errorMessage);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error updating vehicle model: $e');
    }
  }

  /// Delete a vehicle model
  Future<void> deleteVehicleModel(String id) async {
    try {
      final uri = Uri.parse('$baseUrl/$id');
      final response = await http.delete(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        return;
      }

      // Try to get error message from response
      final jsonData = json.decode(response.body);
      final errorMessage = jsonData['message'] ?? 'Failed to delete vehicle model';
      throw Exception(errorMessage);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error deleting vehicle model: $e');
    }
  }
}
