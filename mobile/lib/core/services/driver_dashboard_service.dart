import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../models/api_response.dart';
import '../models/driver_models.dart';
import '../../app/constants/app_constants.dart';

/// Service for driver dashboard operations
class DriverDashboardService {
  final Dio _dio = DioClient.instance;
  final String _baseUrl = '${AppConstants.apiBaseUrl}/driver/dashboard';

  /// Get driver dashboard data
  Future<ApiResponse<DashboardData>> getDashboard() async {
    try {
      final response = await _dio.get(_baseUrl);

      return ApiResponse.fromJson(
        response.data,
        (json) => DashboardData.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update online/offline status
  Future<ApiResponse<String>> updateOnlineStatus(
    UpdateOnlineStatusRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '$_baseUrl/status',
        data: request.toJson(),
      );

      // Backend returns a string "success" as data
      return ApiResponse.fromJson(
        response.data,
        (json) => json.toString(), // Just return the string
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get earnings report
  Future<ApiResponse<EarningsData>> getEarnings({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/earnings',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => EarningsData.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get payout history
  Future<ApiResponse<List<PayoutItem>>> getPayoutHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/payouts',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => (json as List)
            .map((item) => PayoutItem.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Request payout
  Future<ApiResponse<RequestPayoutResponse>> requestPayout(
    RequestPayoutRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/payouts/request',
        data: request.toJson(),
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => RequestPayoutResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }
}
