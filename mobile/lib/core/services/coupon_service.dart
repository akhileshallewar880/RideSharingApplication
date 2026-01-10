import 'package:dio/dio.dart';

class CouponValidationRequest {
  final String couponCode;
  final String userId;
  final double orderAmount;

  CouponValidationRequest({
    required this.couponCode,
    required this.userId,
    required this.orderAmount,
  });

  Map<String, dynamic> toJson() => {
    'couponCode': couponCode,
    'userId': userId,
    'orderAmount': orderAmount,
  };
}

class CouponValidationResponse {
  final bool isValid;
  final String? message;
  final CouponDetails? coupon;
  final double discountAmount;
  final double finalAmount;

  CouponValidationResponse({
    required this.isValid,
    this.message,
    this.coupon,
    required this.discountAmount,
    required this.finalAmount,
  });

  factory CouponValidationResponse.fromJson(Map<String, dynamic> json) {
    return CouponValidationResponse(
      isValid: json['isValid'] as bool,
      message: json['message'] as String?,
      coupon: json['coupon'] != null 
          ? CouponDetails.fromJson(json['coupon'] as Map<String, dynamic>)
          : null,
      discountAmount: (json['discountAmount'] as num).toDouble(),
      finalAmount: (json['finalAmount'] as num).toDouble(),
    );
  }
}

class CouponDetails {
  final String id;
  final String code;
  final String? description;
  final String discountType;
  final double discountValue;
  final double? maxDiscountAmount;
  final double minOrderAmount;
  final DateTime validFrom;
  final DateTime validUntil;
  final bool isFirstTimeUserOnly;

  CouponDetails({
    required this.id,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.maxDiscountAmount,
    required this.minOrderAmount,
    required this.validFrom,
    required this.validUntil,
    required this.isFirstTimeUserOnly,
  });

  factory CouponDetails.fromJson(Map<String, dynamic> json) {
    return CouponDetails(
      id: json['id'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      discountType: json['discountType'] as String,
      discountValue: (json['discountValue'] as num).toDouble(),
      maxDiscountAmount: json['maxDiscountAmount'] != null 
          ? (json['maxDiscountAmount'] as num).toDouble()
          : null,
      minOrderAmount: (json['minOrderAmount'] as num).toDouble(),
      validFrom: DateTime.parse(json['validFrom'] as String),
      validUntil: DateTime.parse(json['validUntil'] as String),
      isFirstTimeUserOnly: json['isFirstTimeUserOnly'] as bool,
    );
  }
}

class ApplyCouponRequest {
  final String couponId;
  final String userId;
  final String bookingId;
  final double discountApplied;

  ApplyCouponRequest({
    required this.couponId,
    required this.userId,
    required this.bookingId,
    required this.discountApplied,
  });

  Map<String, dynamic> toJson() => {
    'couponId': couponId,
    'userId': userId,
    'bookingId': bookingId,
    'discountApplied': discountApplied,
  };
}

class CouponService {
  final Dio _dio;
  final String baseUrl;

  CouponService({
    required Dio dio,
    required this.baseUrl,
  }) : _dio = dio;

  /// Validate a coupon code
  Future<CouponValidationResponse> validateCoupon({
    required String couponCode,
    required String userId,
    required double orderAmount,
  }) async {
    try {
      final request = CouponValidationRequest(
        couponCode: couponCode,
        userId: userId,
        orderAmount: orderAmount,
      );

      print('🎟️ Validating coupon: $couponCode');
      print('🎟️ API URL: $baseUrl/api/Coupons/validate');
      print('🎟️ Request data: ${request.toJson()}');

      final response = await _dio.post(
        '$baseUrl/api/Coupons/validate',
        data: request.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500, // Accept all responses < 500
        ),
      );

      print('🎟️ Response status: ${response.statusCode}');
      print('🎟️ Response data: ${response.data}');

      // The response data is the ValidateCouponResponseDto directly
      return CouponValidationResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      print('❌ Coupon validation DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      print('❌ Status code: ${e.response?.statusCode}');
      
      // Handle network errors
      if (e.response != null && e.response?.data != null) {
        try {
          // Try to parse error response
          final errorData = e.response!.data;
          if (errorData is Map<String, dynamic>) {
            return CouponValidationResponse(
              isValid: false,
              message: errorData['message'] as String? ?? 'Failed to validate coupon',
              discountAmount: 0,
              finalAmount: orderAmount,
            );
          }
        } catch (parseError) {
          print('❌ Error parsing error response: $parseError');
        }
      }
      
      return CouponValidationResponse(
        isValid: false,
        message: 'Network error: ${e.message}',
        discountAmount: 0,
        finalAmount: orderAmount,
      );
    } catch (e) {
      print('❌ Coupon validation error: $e');
      return CouponValidationResponse(
        isValid: false,
        message: 'An error occurred: $e',
        discountAmount: 0,
        finalAmount: orderAmount,
      );
    }
  }

  /// Apply a coupon to a booking
  Future<bool> applyCoupon({
    required String couponId,
    required String userId,
    required String bookingId,
    required double discountApplied,
  }) async {
    try {
      final request = ApplyCouponRequest(
        couponId: couponId,
        userId: userId,
        bookingId: bookingId,
        discountApplied: discountApplied,
      );

      print('🎟️ Applying coupon: $couponId to booking: $bookingId');
      
      await _dio.post(
        '$baseUrl/api/Coupons/apply',
        data: request.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print('✅ Coupon applied successfully');
      return true;
    } catch (e) {
      print('❌ Error applying coupon: $e');
      return false;
    }
  }

  /// Get the currently active coupon
  Future<CouponDetails?> getActiveCoupon() async {
    try {
      print('🎟️ Fetching active coupon...');
      
      final response = await _dio.get(
        '$baseUrl/api/Coupons/active',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print('🎟️ Active coupon response: ${response.data}');

      final data = response.data as Map<String, dynamic>;
      if (data['hasActiveCoupon'] == true && data['coupon'] != null) {
        return CouponDetails.fromJson(data['coupon'] as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      print('❌ Error fetching active coupon: $e');
      return null;
    }
  }
}
