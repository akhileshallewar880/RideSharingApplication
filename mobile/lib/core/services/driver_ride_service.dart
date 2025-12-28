import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../models/api_response.dart';
import '../models/driver_models.dart';
import '../../app/constants/app_constants.dart';

/// Service for driver ride operations
class DriverRideService {
  final Dio _dio = DioClient.instance;
  final String _baseUrl = '${AppConstants.apiBaseUrl}/driver/rides';

  /// Schedule a new ride
  Future<ApiResponse<ScheduleRideResponse>> scheduleRide(
    ScheduleRideRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/schedule',
        data: request.toJson(),
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => ScheduleRideResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get all active rides for the driver
  Future<ApiResponse<List<DriverRide>>> getActiveRides() async {
    try {
      print('🔍 Fetching active rides from: $_baseUrl/active');
      final response = await _dio.get('$_baseUrl/active');
      
      print('✅ Received response: ${response.data}');
      
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) {
          final rides = (json as List)
              .map((item) => DriverRide.fromJson(item as Map<String, dynamic>))
              .toList();
          print('📋 Parsed ${rides.length} rides');
          for (var ride in rides) {
            print('  - Ride ${ride.rideNumber}: ${ride.pickupLocation} → ${ride.dropoffLocation}, Status: ${ride.status}');
          }
          return rides;
        },
      );
      
      return apiResponse;
    } catch (e) {
      print('❌ Error fetching active rides: $e');
      rethrow;
    }
  }

  /// Get ride details with passenger information
  Future<ApiResponse<RideDetailsWithPassengers>> getRideDetails(
    String rideId,
  ) async {
    try {
      print('🔍 Service: Fetching ride details from: $_baseUrl/$rideId');
      print('🔍 Service: Making HTTP GET request...');
      final response = await _dio.get('$_baseUrl/$rideId');
      print('✅ Service: Received response with status: ${response.statusCode}');
      print('✅ Service: Response data: ${response.data}');

      return ApiResponse.fromJson(
        response.data,
        (json) =>
            RideDetailsWithPassengers.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      print('❌ Error fetching ride details: $e');
      rethrow;
    }
  }

  /// Start a trip
  Future<ApiResponse<StartTripResponse>> startTrip(String rideId) async {
    try {
      final response = await _dio.post('$_baseUrl/$rideId/start');

      return ApiResponse.fromJson(
        response.data,
        (json) => StartTripResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Verify passenger OTP and mark them as boarded
  Future<ApiResponse<VerifyPassengerResponse>> verifyPassengerOtp(
    String rideId,
    String bookingId,
    VerifyOtpRequest request,
  ) async {
    try {
      print('🔍 Verifying OTP at: $_baseUrl/$rideId/verify-otp');
      print('📤 Request data: ${request.toJson()}');
      
      final response = await _dio.post(
        '$_baseUrl/$rideId/verify-otp',
        data: request.toJson(),
      );
      
      print('✅ Verify OTP response: ${response.data}');

      // Check if response.data is already ApiResponse or raw data
      if (response.data is Map<String, dynamic>) {
        final Map<String, dynamic> responseMap = response.data;
        
        // If data field is a string (simple success message), create a mock response
        if (responseMap['data'] is String) {
          return ApiResponse(
            success: responseMap['success'] ?? true,
            message: responseMap['message'] ?? 'Verified successfully',
            data: VerifyPassengerResponse(
              bookingId: bookingId,
              passengerName: '',
              boardingStatus: 'boarded',
              verifiedAt: DateTime.now().toIso8601String(),
            ),
          );
        }
        
        return ApiResponse.fromJson(
          response.data,
          (json) => VerifyPassengerResponse.fromJson(json as Map<String, dynamic>),
        );
      }
      
      throw Exception('Unexpected response format');
    } catch (e) {
      print('❌ Error verifying OTP: $e');
      rethrow;
    }
  }

  /// Complete a trip
  Future<ApiResponse<CompleteTripResponse?>> completeTrip(
    String rideId,
    CompleteTripRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/$rideId/complete',
        data: request.toJson(),
      );

      return ApiResponse.fromJson(
        response.data,
        (json) {
          // Handle case where data is just a string "success" or null
          if (json is String || json == null) {
            return null;
          }
          return CompleteTripResponse.fromJson(json as Map<String, dynamic>);
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel a ride
  Future<ApiResponse<CancelRideResponse>> cancelRide(
    String rideId,
    CancelRideRequest request,
  ) async {
    try {
      print('🚫 Service: Cancelling ride $rideId');
      print('🚫 Request URL: $_baseUrl/$rideId/cancel');
      print('🚫 Request body: ${request.toJson()}');
      
      final response = await _dio.post(
        '$_baseUrl/$rideId/cancel',
        data: request.toJson(),
      );

      print('🚫 Response status: ${response.statusCode}');
      print('🚫 Response data: ${response.data}');

      return ApiResponse.fromJson(
        response.data,
        (json) => CancelRideResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      print('❌ Service error: $e');
      rethrow;
    }
  }

  /// Update price per seat for a ride
  Future<ApiResponse<UpdateRidePriceResponse>> updateRidePrice(
    String rideId,
    UpdateRidePriceRequest request,
  ) async {
    try {
      print('💰 Updating price for ride: $rideId');
      final response = await _dio.put(
        '$_baseUrl/$rideId/price',
        data: request.toJson(),
      );

      print('✅ Price update response: ${response.data}');
      return ApiResponse.fromJson(
        response.data,
        (json) => UpdateRidePriceResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      print('❌ Error updating price: $e');
      rethrow;
    }
  }

  /// Update segment prices for a ride
  Future<ApiResponse<UpdateSegmentPricesResponse>> updateSegmentPrices(
    String rideId,
    UpdateSegmentPricesRequest request,
  ) async {
    try {
      print('💰 Updating segment prices for ride: $rideId');
      final response = await _dio.put(
        '$_baseUrl/$rideId/segment-prices',
        data: request.toJson(),
      );

      print('✅ Segment prices update response: ${response.data}');
      return ApiResponse.fromJson(
        response.data,
        (json) => UpdateSegmentPricesResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      print('❌ Error updating segment prices: $e');
      rethrow;
    }
  }

  /// Update schedule for a ride
  Future<ApiResponse<UpdateRideScheduleResponse>> updateRideSchedule(
    String rideId,
    UpdateRideScheduleRequest request,
  ) async {
    try {
      print('📅 Updating schedule for ride: $rideId');
      final response = await _dio.put(
        '$_baseUrl/$rideId/schedule',
        data: request.toJson(),
      );

      print('✅ Schedule update response: ${response.data}');
      return ApiResponse.fromJson(
        response.data,
        (json) => UpdateRideScheduleResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      print('❌ Error updating schedule: $e');
      rethrow;
    }
  }
}
