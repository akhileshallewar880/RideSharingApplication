import 'package:dio/dio.dart';
import '../models/admin_ride_models.dart';
import '../constants/app_constants.dart';
import 'admin_auth_service.dart';

/// Service for admin ride management operations
class AdminRideService {
  final AdminAuthService _authService;
  late final Dio _dio;

  AdminRideService(this._authService) {
    _dio = _authService.dio;
  }

  final String _baseUrl = '${AppConstants.baseUrl}/admin/rides';

  /// Schedule a new ride for a driver
  Future<AdminScheduleRideResponse> scheduleRide(
    AdminScheduleRideRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/schedule',
        data: request.toJson(),
      );

      final data = response.data['data'];
      return AdminScheduleRideResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Update/Reschedule an existing ride
  Future<AdminScheduleRideResponse> updateRide(
    String rideId,
    AdminUpdateRideRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '$_baseUrl/$rideId',
        data: request.toJson(),
      );

      final data = response.data['data'];
      return AdminScheduleRideResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel a ride
  Future<Map<String, dynamic>> cancelRide(
    String rideId, {
    String? reason,
    bool notifyPassengers = true,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/$rideId/cancel',
        data: {
          'reason': reason,
          'notifyPassengers': notifyPassengers,
        },
      );

      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all available drivers for scheduling
  Future<List<AdminDriverInfo>> getAvailableDrivers({
    DateTime? date,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) {
        queryParams['date'] = date.toIso8601String();
      }

      print('🔍 Fetching drivers from: $_baseUrl/drivers');
      final response = await _dio.get(
        '$_baseUrl/drivers',
        queryParameters: queryParams,
      );

      print('✅ Response status: ${response.statusCode}');
      print('📦 Response data: ${response.data}');

      final data = response.data['data'] as List;
      print('👥 Found ${data.length} drivers');
      return data.map((item) => AdminDriverInfo.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      print('❌ Status code: ${e.response?.statusCode}');
      print('❌ Response: ${e.response?.data}');
      // Safely extract error message from various response structures
      String errorMsg = 'Unknown error';
      if (e.response?.data != null) {
        if (e.response!.data is Map) {
          errorMsg = e.response!.data['message']?.toString() ?? 
                     e.response!.data['error']?.toString() ?? 
                     e.message ?? 'Request failed';
        } else if (e.response!.data is String) {
          errorMsg = e.response!.data;
        }
      } else {
        errorMsg = e.message ?? 'Request failed';
      }
      throw Exception('Failed to load drivers: $errorMsg');
    } catch (e) {
      print('❌ Exception: $e');
      rethrow;
    }
  }

  /// Get all rides with filters
  Future<Map<String, dynamic>> getAllRides({
    String? status,
    String? driverId,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };

      if (status != null) queryParams['status'] = status;
      if (driverId != null) queryParams['driverId'] = driverId;
      if (fromDate != null) queryParams['fromDate'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['toDate'] = toDate.toIso8601String();

      final response = await _dio.get(
        _baseUrl,
        queryParameters: queryParams,
      );

      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Get ride details
  Future<AdminRideInfo> getRideDetails(String rideId) async {
    try {
      final response = await _dio.get('$_baseUrl/$rideId');

      final data = response.data['data'];
      return AdminRideInfo.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }
}
