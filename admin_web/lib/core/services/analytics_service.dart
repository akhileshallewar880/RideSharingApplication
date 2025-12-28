import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../models/admin_models.dart';
import 'admin_auth_service.dart';

class AnalyticsService {
  final AdminAuthService _authService;
  late final Dio _dio;

  AnalyticsService(this._authService) {
    _dio = _authService.dio;
  }

  Future<DashboardStats> getDashboardStats({
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
        '/AdminAnalytics/dashboard',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final overview = data['overview'];
        final dailyStatsList = (data['dailyStats'] as List?) ?? const [];

        // Convert dailyStats from API to DailyStats model
        final dailyStats = dailyStatsList
            .whereType<Map>()
            .map((stat) {
              final rawDate = stat['date'] ?? stat['Date'];
              if (rawDate == null) return null;

              final parsedDate = DateTime.tryParse(rawDate.toString());
              if (parsedDate == null) return null;

              final ridesValue = stat['rides'] ?? stat['Rides'] ?? 0;
              final revenueValue = stat['revenue'] ?? stat['Revenue'] ?? 0;

              return DailyStats(
                date: parsedDate,
                rides: (ridesValue is num) ? ridesValue.toInt() : 0,
                revenue: (revenueValue is num) ? revenueValue.toDouble() : 0.0,
                newDrivers: 0, // Not provided by API, default to 0
                newPassengers: 0, // Not provided by API, default to 0
              );
            })
            .whereType<DailyStats>()
            .toList();

        return DashboardStats(
          totalDrivers: overview['totalDrivers'] ?? 0,
          activeDrivers: overview['activeDrivers'] ?? 0,
          totalPassengers: overview['totalPassengers'] ?? 0,
          totalRides: overview['totalRides'] ?? 0,
          completedRides: overview['completedRides'] ?? 0,
          activeRides: overview['activeRides'] ?? 0,
          totalRevenue: (overview['totalRevenue'] ?? 0).toDouble(),
          todayRevenue: dailyStats.isNotEmpty ? dailyStats.last.revenue : 0.0,
          pendingVerifications: overview['pendingVerifications'] ?? 0,
          rejectedDrivers: 0, // Not provided by API, default to 0
          dailyStats: dailyStats,
        );
      } else {
        throw Exception('Failed to fetch dashboard analytics');
      }
    } on DioException catch (e) {
      // Fallback to dummy data on error for now (for development)
      print('Error fetching analytics: ${e.message}');
      return _getDummyDashboardStats();
    } catch (e) {
      print('Error parsing analytics: $e');
      return _getDummyDashboardStats();
    }
  }

  DashboardStats _getDummyDashboardStats() {
    final now = DateTime.now();
    final dailyStats = List.generate(30, (index) {
      final date = now.subtract(Duration(days: 29 - index));
      return DailyStats(
        date: date,
        rides: 20 + (index % 15),
        revenue: 5000 + (index * 200.0) + (index % 5 * 1000),
        newDrivers: index % 3,
        newPassengers: 5 + (index % 10),
      );
    });

    return DashboardStats(
      totalDrivers: 45,
      activeDrivers: 38,
      pendingVerifications: 4,
      rejectedDrivers: 3,
      totalRides: 850,
      activeRides: 3,
      completedRides: 820,
      totalPassengers: 320,
      totalRevenue: 245000,
      todayRevenue: 12500,
      dailyStats: dailyStats,
    );
  }

  Future<Map<String, dynamic>> getRevenueAnalytics({
    required DateTime startDate,
    required DateTime endDate,
    String groupBy = 'day', // day, week, month
  }) async {
    try {
      final response = await _dio.get(
        '${AppConstants.analyticsEndpoint}/revenue',
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'groupBy': groupBy,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to load revenue analytics');
    } catch (e) {
      throw Exception('Error fetching revenue analytics: $e');
    }
  }

  Future<Map<String, dynamic>> getDriverAnalytics() async {
    try {
      final response = await _dio.get('${AppConstants.analyticsEndpoint}/drivers');

      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to load driver analytics');
    } catch (e) {
      throw Exception('Error fetching driver analytics: $e');
    }
  }

  Future<Map<String, dynamic>> getRideAnalytics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dio.get(
        '${AppConstants.analyticsEndpoint}/rides',
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to load ride analytics');
    } catch (e) {
      throw Exception('Error fetching ride analytics: $e');
    }
  }
}
