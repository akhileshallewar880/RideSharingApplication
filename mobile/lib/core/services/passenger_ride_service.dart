import 'package:dio/dio.dart';
import 'package:allapalli_ride/core/models/api_response.dart';
import 'package:allapalli_ride/core/models/passenger_ride_models.dart';
import 'package:allapalli_ride/core/network/dio_client.dart';

/// Passenger ride service for searching, booking, and managing rides
class PassengerRideService {
  final Dio _dio = DioClient.instance;

  /// Search for available rides
  Future<ApiResponse<List<AvailableRide>>> searchRides(
    SearchRidesRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/rides/search',
        data: request.toJson(),
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) {
          final availableRides = json['availableRides'] as List?;
          return availableRides
                  ?.map((ride) => AvailableRide.fromJson(ride))
                  .toList() ??
              [];
        },
      );

      return apiResponse;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Book a ride
  Future<ApiResponse<BookingResponse>> bookRide(
    BookRideRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/rides/book',
        data: request.toJson(),
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => BookingResponse.fromJson(json),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Get booking details
  Future<ApiResponse<BookingDetails>> getBookingDetails(
    String bookingId,
  ) async {
    try {
      final response = await _dio.get('/rides/bookings/$bookingId');

      return ApiResponse.fromJson(
        response.data,
        (json) => BookingDetails.fromJson(json),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Cancel booking
  Future<ApiResponse<CancelBookingResponse>> cancelBooking(
    String bookingId,
    CancelBookingRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/rides/bookings/$bookingId/cancel',
        data: request.toJson(),
      );

      // Handle case where data is just a string ("success")
      final responseData = response.data;
      if (responseData['data'] is String) {
        // Create a minimal CancelBookingResponse when data is just "success"
        return ApiResponse(
          success: responseData['success'] ?? true,
          message: responseData['message'] ?? 'Booking cancelled successfully',
          data: CancelBookingResponse(
            bookingId: bookingId,
            status: 'cancelled',
            refundAmount: 0.0,
            cancellationCharge: 0.0,
            cancelledAt: DateTime.now().toIso8601String(),
          ),
        );
      }

      return ApiResponse.fromJson(
        response.data,
        (json) => CancelBookingResponse.fromJson(json),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Get ride history
  Future<ApiResponse<PaginatedResponse<RideHistoryItem>>> getRideHistory({
    String? status,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get(
        '/rides/history',
        queryParameters: queryParams,
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => PaginatedResponse<RideHistoryItem>.fromJson(
          {
            'items': json['rides'],
            'pagination': json['pagination'],
          },
          (item) => RideHistoryItem.fromJson(item),
        ),
      );

      return apiResponse;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Rate a ride
  Future<ApiResponse<String>> rateRide(
    String bookingId,
    RateRideRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/rides/bookings/$bookingId/rate',
        data: request.toJson(),
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => json.toString(), // Backend returns string "success"
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Handle Dio errors
  ApiResponse<T> _handleError<T>(DioException error) {
    String message = 'An error occurred';
    List<String>? errors;

    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map<String, dynamic>) {
        message = data['message'] ?? message;
        if (data['errors'] != null) {
          errors = List<String>.from(data['errors']);
        }
      }
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout. Please check your internet connection.';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'No internet connection.';
    } else {
      message = error.message ?? message;
    }

    return ApiResponse<T>(
      success: false,
      message: message,
      errors: errors,
    );
  }
}
