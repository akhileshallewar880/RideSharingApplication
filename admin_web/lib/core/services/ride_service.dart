import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../models/admin_models.dart';
import 'admin_auth_service.dart';

class RideService {
  final Dio _dio;
  final AdminAuthService _authService;

  RideService(this._authService)
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

  Future<List<RideInfo>> getActiveRides() async {
    // BYPASS MODE: Return dummy data (always true for testing)
    await Future.delayed(Duration(milliseconds: 500));
    return _getDummyActiveRides();
  }

  List<RideInfo> _getDummyActiveRides() {
    return [
      RideInfo(
        id: 'ride_001',
        rideNumber: 'RID-2025-001',
        status: 'in_progress',
        passenger: PassengerInfo(
          id: 'pass_001',
          name: 'Anjali Desai',
          phone: '+91-9876543250',
          rating: 4.5,
        ),
        driver: DriverInfo(
          id: 'drv_005',
          name: 'Rajesh Kumar',
          phone: '+91-9876543210',
          vehicleNumber: 'MH 12 AB 1234',
          vehicleType: 'car',
          rating: 4.8,
          totalRides: 150,
        ),
        pickup: LocationInfo(
          address: 'Mumbai Central Station, Mumbai',
          latitude: 18.9688,
          longitude: 72.8205,
          landmark: 'Near Platform 1',
        ),
        dropoff: LocationInfo(
          address: 'Gateway of India, Mumbai',
          latitude: 18.9220,
          longitude: 72.8347,
        ),
        requestedAt: DateTime.now().subtract(Duration(minutes: 15)),
        acceptedAt: DateTime.now().subtract(Duration(minutes: 12)),
        startedAt: DateTime.now().subtract(Duration(minutes: 8)),
        estimatedFare: 250.0,
        distance: 8.5,
      ),
      RideInfo(
        id: 'ride_002',
        rideNumber: 'RID-2025-002',
        status: 'requested',
        passenger: PassengerInfo(
          id: 'pass_002',
          name: 'Rohit Mehta',
          phone: '+91-9876543260',
          rating: 4.2,
        ),
        pickup: LocationInfo(
          address: 'Andheri Station, Mumbai',
          latitude: 19.1197,
          longitude: 72.8464,
        ),
        dropoff: LocationInfo(
          address: 'BKC, Mumbai',
          latitude: 19.0659,
          longitude: 72.8688,
        ),
        requestedAt: DateTime.now().subtract(Duration(minutes: 2)),
        estimatedFare: 180.0,
        distance: 6.2,
      ),
      RideInfo(
        id: 'ride_003',
        rideNumber: 'RID-2025-003',
        status: 'in_progress',
        passenger: PassengerInfo(
          id: 'pass_003',
          name: 'Sneha Reddy',
          phone: '+91-9876543270',
          rating: 4.7,
        ),
        driver: DriverInfo(
          id: 'drv_006',
          name: 'Amit Sharma',
          phone: '+91-9876543220',
          vehicleNumber: 'DL 5C XY 5678',
          vehicleType: 'suv',
          rating: 4.6,
          totalRides: 98,
        ),
        pickup: LocationInfo(
          address: 'Phoenix Mall, Mumbai',
          latitude: 19.0876,
          longitude: 72.8813,
        ),
        dropoff: LocationInfo(
          address: 'Chhatrapati Shivaji Airport, Mumbai',
          latitude: 19.0896,
          longitude: 72.8656,
        ),
        requestedAt: DateTime.now().subtract(Duration(minutes: 20)),
        acceptedAt: DateTime.now().subtract(Duration(minutes: 18)),
        startedAt: DateTime.now().subtract(Duration(minutes: 15)),
        estimatedFare: 320.0,
        distance: 12.3,
      ),
    ];
  }

  Future<List<RideInfo>> getRides({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // BYPASS MODE: Return dummy data (always true for testing)
    await Future.delayed(Duration(milliseconds: 500));
    return _getDummyActiveRides();
  }

  Future<RideInfo> getRideDetails(String rideId) async {
    // BYPASS MODE: Return dummy data (always true for testing)
    await Future.delayed(Duration(milliseconds: 300));
    return _getDummyActiveRides().first;
  }

  Future<void> cancelRide(String rideId, String reason) async {
    // BYPASS MODE: Just delay (always true for testing)
    await Future.delayed(Duration(milliseconds: 500));
    return;
  }
}
