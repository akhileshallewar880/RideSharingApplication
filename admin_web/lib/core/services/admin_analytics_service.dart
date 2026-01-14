import 'package:dio/dio.dart';
import 'admin_auth_service.dart';

class AdminAnalyticsService {
  final AdminAuthService _authService;
  late final Dio _dio;

  AdminAnalyticsService(this._authService) {
    _dio = _authService.dio;
  }

  /// Get comprehensive dashboard analytics including drivers, passengers, rides, revenue
  /// [startDate] - Start date for analytics (optional, defaults to 30 days ago)
  /// [endDate] - End date for analytics (optional, defaults to today)
  Future<Map<String, dynamic>> getDashboardAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await _dio.get(
        '/admin/analytics/dashboard',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to fetch dashboard analytics');
      }
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Get revenue analytics grouped by day, week, or month
  /// [grouping] - Grouping type: 'day', 'week', or 'month' (default: 'day')
  Future<Map<String, dynamic>> getRevenueAnalytics({
    String grouping = 'day',
  }) async {
    try {
      final response = await _dio.get(
        '/admin/analytics/revenue',
        queryParameters: {'grouping': grouping},
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to fetch revenue analytics');
      }
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Get driver statistics and analytics
  Future<Map<String, dynamic>> getDriverAnalytics() async {
    try {
      final response = await _dio.get(
        '/admin/analytics/drivers',
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to fetch driver analytics');
      }
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Get ride statistics and analytics
  Future<Map<String, dynamic>> getRideAnalytics() async {
    try {
      final response = await _dio.get(
        '/admin/analytics/rides',
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to fetch ride analytics');
      }
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Handle Dio errors and return consistent error response
  Map<String, dynamic> _handleError(DioException e) {
    String errorMessage;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      errorMessage = 'Connection timeout. Please check your internet connection.';
    } else if (e.type == DioExceptionType.connectionError) {
      errorMessage = 'Network error. Please check your internet connection.';
    } else if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final responseData = e.response!.data;

      switch (statusCode) {
        case 400:
          errorMessage = responseData['message'] ?? 'Bad request';
          break;
        case 401:
          errorMessage = 'Unauthorized. Please login again.';
          break;
        case 403:
          errorMessage = 'Forbidden. You do not have permission to access this resource.';
          break;
        case 404:
          errorMessage = 'Resource not found';
          break;
        case 500:
          errorMessage = responseData['message'] ?? 'Server error. Please try again later.';
          break;
        default:
          errorMessage = responseData['message'] ?? 'An error occurred';
      }
    } else {
      errorMessage = 'An unexpected error occurred';
    }

    return {
      'success': false,
      'message': errorMessage,
      'data': null,
    };
  }
}
