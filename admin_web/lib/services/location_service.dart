import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/admin_location_models.dart';
import '../core/services/admin_auth_service.dart';
import '../core/config/environment_config.dart';

class LocationService {
  static String get baseUrl => AdminEnvironmentConfig.locationsUrl;
  final AdminAuthService _authService = AdminAuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<LocationsResponse> getAllLocations({
    String? search,
    bool? isActive,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (isActive != null) {
        queryParams['isActive'] = isActive.toString();
      }

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return LocationsResponse.fromJson(jsonResponse['data']);
      } else {
        throw Exception('Failed to load locations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching locations: $e');
    }
  }

  Future<AdminLocation> getLocationById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return AdminLocation.fromJson(jsonResponse['data']);
      } else if (response.statusCode == 404) {
        throw Exception('Location not found');
      } else {
        throw Exception('Failed to load location: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching location: $e');
    }
  }

  Future<AdminLocation> createLocation(CreateLocationRequest request) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: await _getHeaders(),
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return AdminLocation.fromJson(jsonResponse['data']);
      } else {
        final errorMessage = json.decode(response.body)['message'] ?? 'Failed to create location';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error creating location: $e');
    }
  }

  Future<AdminLocation> updateLocation(String id, UpdateLocationRequest request) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: await _getHeaders(),
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return AdminLocation.fromJson(jsonResponse['data']);
      } else {
        final errorMessage = json.decode(response.body)['message'] ?? 'Failed to update location';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error updating location: $e');
    }
  }

  Future<void> deleteLocation(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) {
        final errorMessage = json.decode(response.body)['message'] ?? 'Failed to delete location';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error deleting location: $e');
    }
  }

  Future<LocationStatistics> getStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/statistics'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return LocationStatistics.fromJson(jsonResponse['data']);
      } else {
        throw Exception('Failed to load statistics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching statistics: $e');
    }
  }
}
