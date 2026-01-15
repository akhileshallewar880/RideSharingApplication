import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vehicle_type_model.dart';
import '../core/services/admin_auth_service.dart';
import '../core/constants/app_constants.dart';

class VehicleTypeApiService {
  static String get baseUrl => '${AppConstants.baseUrl}/admin/vehicle-types';
  final AdminAuthService _authService = AdminAuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Get all vehicle types with optional filters
  Future<VehicleTypesResponse> getVehicleTypes({
    bool? isActive,
    String? category,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (isActive != null) queryParams['active'] = isActive.toString();
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return VehicleTypesResponse.fromJson(jsonData['data']);
        }
      }

      throw Exception('Failed to load vehicle types');
    } catch (e) {
      throw Exception('Error fetching vehicle types: $e');
    }
  }

  /// Get a specific vehicle type by ID
  Future<VehicleType> getVehicleType(String id) async {
    try {
      final uri = Uri.parse('$baseUrl/$id');
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return VehicleType.fromJson(jsonData['data']);
        }
      }

      throw Exception('Failed to load vehicle type');
    } catch (e) {
      throw Exception('Error fetching vehicle type: $e');
    }
  }

  /// Create a new vehicle type
  Future<VehicleType> createVehicleType(CreateVehicleTypeDto vehicleTypeDto) async {
    try {
      final uri = Uri.parse(baseUrl);
      final response = await http.post(
        uri,
        headers: await _getHeaders(),
        body: json.encode(vehicleTypeDto.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return VehicleType.fromJson(jsonData['data']);
        }
      }

      // Try to get error message from response
      final jsonData = json.decode(response.body);
      final errorMessage = jsonData['message'] ?? 'Failed to create vehicle type';
      throw Exception(errorMessage);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error creating vehicle type: $e');
    }
  }

  /// Update an existing vehicle type
  Future<VehicleType> updateVehicleType(String id, UpdateVehicleTypeDto vehicleTypeDto) async {
    try {
      final uri = Uri.parse('$baseUrl/$id');
      final response = await http.put(
        uri,
        headers: await _getHeaders(),
        body: json.encode(vehicleTypeDto.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return VehicleType.fromJson(jsonData['data']);
        }
      }

      // Try to get error message from response
      final jsonData = json.decode(response.body);
      final errorMessage = jsonData['message'] ?? 'Failed to update vehicle type';
      throw Exception(errorMessage);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error updating vehicle type: $e');
    }
  }

  /// Delete a vehicle type
  Future<void> deleteVehicleType(String id) async {
    try {
      final uri = Uri.parse('$baseUrl/$id');
      final response = await http.delete(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        return;
      }

      // Try to get error message from response
      final jsonData = json.decode(response.body);
      final errorMessage = jsonData['message'] ?? 'Failed to delete vehicle type';
      throw Exception(errorMessage);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error deleting vehicle type: $e');
    }
  }
}
