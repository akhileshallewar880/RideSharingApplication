import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../models/admin_models.dart';
import 'admin_auth_service.dart';

class DriverService {
  final Dio _dio;
  final AdminAuthService _authService;

  DriverService(this._authService)
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

  Future<List<PendingDriver>> getPendingDrivers({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? searchQuery,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'pageSize': pageSize,
        if (status != null) 'status': status,
        if (searchQuery != null) 'search': searchQuery,
      };

      final response = await _dio.get(
        '${AppConstants.baseUrl}/admin/drivers/pending',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List<dynamic> driversList = data['drivers'] ?? [];
        return driversList.map((json) => PendingDriver.fromJson(json)).toList();
      }
      throw Exception('Failed to load pending drivers');
    } catch (e) {
      print('Error fetching pending drivers: $e');
      throw Exception('Error fetching pending drivers: $e');
    }
  }

  Future<PendingDriver> getDriverDetails(String driverId) async {
    try {
      final response = await _dio.get('${AppConstants.baseUrl}/admin/drivers/$driverId');

      if (response.statusCode == 200) {
        return PendingDriver.fromJson(response.data['data']);
      }
      throw Exception('Failed to load driver details');
    } catch (e) {
      throw Exception('Error fetching driver details: $e');
    }
  }

  Future<void> approveDriver(String driverId, {String? notes}) async {
    try {
      final response = await _dio.post(
        '${AppConstants.baseUrl}/admin/drivers/$driverId/approve',
        data: {'notes': notes},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to approve driver');
      }
    } catch (e) {
      throw Exception('Error approving driver: $e');
    }
  }

  Future<void> rejectDriver(String driverId, String reason) async {
    try {
      final response = await _dio.post(
        '${AppConstants.baseUrl}/admin/drivers/$driverId/reject',
        data: {'reason': reason},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to reject driver');
      }
    } catch (e) {
      throw Exception('Error rejecting driver: $e');
    }
  }

  Future<String> getDocumentUrl(String documentId) async {
    try {
      final response = await _dio.get('${AppConstants.driversEndpoint}/documents/$documentId');

      if (response.statusCode == 200) {
        return response.data['url'];
      }
      throw Exception('Failed to get document URL');
    } catch (e) {
      throw Exception('Error fetching document URL: $e');
    }
  }

  Future<List<DriverInfo>> getAllDrivers({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? searchQuery,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'pageSize': pageSize,
        if (status != null) 'status': status,
        if (searchQuery != null) 'search': searchQuery,
      };

      final response = await _dio.get(
        '${AppConstants.baseUrl}/admin/drivers',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List<dynamic> driversList = data['drivers'] ?? [];
        return driversList.map((json) => DriverInfo.fromJson(json)).toList();
      }
      throw Exception('Failed to load drivers');
    } catch (e) {
      throw Exception('Error fetching drivers: $e');
    }
  }

  Future<void> deactivateDriver(String driverId, String reason) async {
    try {
      final response = await _dio.post(
        '${AppConstants.baseUrl}/admin/drivers/$driverId/deactivate',
        data: {'reason': reason},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to deactivate driver');
      }
    } catch (e) {
      throw Exception('Error deactivating driver: $e');
    }
  }

  Future<void> activateDriver(String driverId) async {
    try {
      final response = await _dio.post('${AppConstants.baseUrl}/admin/drivers/$driverId/activate');

      if (response.statusCode != 200) {
        throw Exception('Failed to activate driver');
      }
    } catch (e) {
      throw Exception('Error activating driver: $e');
    }
  }
}
