import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

class AdminDriverService {
  final Dio _dio;
  final String baseUrl;

  AdminDriverService({
    required Dio dio,
    String? baseUrl,
  })  : _dio = dio,
        baseUrl = baseUrl ?? AppConstants.baseUrl;

  /// Register a new driver
  /// POST /api/v1/AdminDriver/register
  Future<Map<String, dynamic>> registerDriver({
    required String name,
    String? email,
    required String phoneNumber,
    required String password,
    required String licenseNumber,
    String? vehicleNumber,
    String? address,
    String? emergencyContact,
    String countryCode = '+91',
    DateTime? licenseExpiryDate,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'name': name,
        'phoneNumber': phoneNumber,
        'password': password,
        'licenseNumber': licenseNumber,
        'countryCode': countryCode,
      };

      // Add optional fields only if provided
      if (email != null && email.isNotEmpty) requestData['email'] = email;
      if (vehicleNumber != null && vehicleNumber.isNotEmpty) requestData['vehicleNumber'] = vehicleNumber;
      if (address != null && address.isNotEmpty) requestData['address'] = address;
      if (emergencyContact != null && emergencyContact.isNotEmpty) requestData['emergencyContact'] = emergencyContact;
      if (licenseExpiryDate != null) requestData['licenseExpiryDate'] = licenseExpiryDate.toIso8601String();

      final response = await _dio.post(
        '$baseUrl/AdminDriver/register',
        data: requestData,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Block or unblock a driver
  /// PUT /api/v1/AdminDriver/{driverId}/block
  Future<Map<String, dynamic>> blockDriver({
    required String driverId,
    required bool block,
    String? reason,
  }) async {
    try {
      final response = await _dio.put(
        '$baseUrl/AdminDriver/$driverId/block',
        data: {
          'block': block,
          'reason': reason,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Verify or reject a driver
  /// PUT /api/v1/AdminDriver/{driverId}/verify
  Future<Map<String, dynamic>> verifyDriver({
    required String driverId,
    required bool approve,
    String? notes,
  }) async {
    try {
      final response = await _dio.put(
        '$baseUrl/AdminDriver/$driverId/verify',
        data: {
          'approve': approve,
          'notes': notes,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all drivers with filters
  /// GET /api/v1/AdminDriver
  Future<Map<String, dynamic>> getDrivers({
    String status = 'all',
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/AdminDriver',
        queryParameters: {
          'status': status,
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get driver details
  /// GET /api/v1/AdminDriver/{driverId}
  Future<Map<String, dynamic>> getDriverById(String driverId) async {
    try {
      final response = await _dio.get('$baseUrl/AdminDriver/$driverId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
      return 'Server error: ${e.response!.statusCode}';
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Server response timeout';
    } else {
      return 'Network error: ${e.message}';
    }
  }
}
