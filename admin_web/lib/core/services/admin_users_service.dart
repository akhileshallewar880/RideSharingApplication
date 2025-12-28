import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'admin_auth_service.dart';

class AdminUsersService {
  final Dio _dio;
  final AdminAuthService _authService;

  AdminUsersService(this._authService)
      : _dio = Dio(BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: AppConstants.apiTimeout,
          receiveTimeout: AppConstants.apiTimeout,
        )) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  /// Get paginated list of users with filters
  /// GET /api/v1/AdminUsers
  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 20,
    String? search,
    String? userType,
    String? status,
  }) async {
    try {
      final response = await _dio.get(
        '/AdminUsers',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (userType != null && userType != 'all') 'userType': userType,
          if (status != null && status != 'all') 'status': status,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user by ID
  /// GET /api/v1/AdminUsers/{userId}
  Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      final response = await _dio.get('/AdminUsers/$userId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create admin user (Super Admin only)
  /// POST /api/v1/AdminUsers/create-admin
  Future<Map<String, dynamic>> createAdminUser({
    String? name,
    required String email,
    required String password,
    String? phone,
    String? role,
    bool? phoneVerified,
  }) async {
    try {
      final response = await _dio.post(
        '/AdminUsers/create-admin',
        data: {
          if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
          'email': email,
          'password': password,
          if (phone != null) 'phone': phone,
          if (role != null) 'role': role,
          if (phoneVerified != null) 'phoneVerified': phoneVerified,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Send OTP to phone number
  /// POST /api/v1/auth/send-otp
  Future<Map<String, dynamic>> sendOtp({
    required String phoneNumber,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/send-otp',
        data: {
          'phoneNumber': phoneNumber,
        },
      );
      final body = response.data;
      if (body is Map && body['success'] == true) {
        return (body['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      }
      if (body is Map && body.containsKey('message')) {
        throw body['message'];
      }
      throw 'Failed to send OTP';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Verify OTP
  /// POST /api/v1/auth/verify-otp
  Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String otp,
    required String otpId,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/verify-otp',
        data: {
          'phoneNumber': phoneNumber,
          'otp': otp,
          'otpId': otpId,
        },
      );
      final body = response.data;
      if (body is Map && body['success'] == true) {
        return (body['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      }
      if (body is Map && body.containsKey('message')) {
        throw body['message'];
      }
      throw 'OTP verification failed';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Block or unblock a user
  /// PUT /api/v1/AdminUsers/{userId}/block
  Future<Map<String, dynamic>> blockUser({
    required String userId,
    required bool block,
    String? reason,
  }) async {
    try {
      final response = await _dio.put(
        '/AdminUsers/$userId/block',
        data: {
          'block': block,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete user (soft delete)
  /// DELETE /api/v1/AdminUsers/{userId}
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      final response = await _dio.delete('/AdminUsers/$userId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

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
        '/AdminDriver/register',
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
        '/AdminDriver/$driverId/block',
        data: {
          'block': block,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
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
      return 'Connection timeout. Please check your internet connection.';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Server response timeout. Please try again.';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'Unable to connect to server. Please ensure the backend is running.';
    } else {
      return 'Network error: ${e.message}';
    }
  }
}
