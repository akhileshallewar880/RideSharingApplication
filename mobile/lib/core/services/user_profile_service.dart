import 'dart:io';
import 'package:dio/dio.dart';
import 'package:allapalli_ride/core/models/api_response.dart';
import 'package:allapalli_ride/core/models/user_profile_models.dart';
import 'package:allapalli_ride/core/network/dio_client.dart';

/// User profile service
class UserProfileService {
  final Dio _dio = DioClient.instance;

  /// Get user profile
  Future<ApiResponse<UserProfile>> getProfile() async {
    try {
      final response = await _dio.get('/users/profile');

      return ApiResponse.fromJson(
        response.data,
        (json) => UserProfile.fromJson(json),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Update user profile
  Future<ApiResponse<UserProfile>> updateProfile(
    UpdateProfileRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '/users/profile',
        data: request.toJson(),
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => UserProfile.fromJson(json),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Upload profile picture
  Future<ApiResponse<UploadProfilePictureResponse>> uploadProfilePicture(
    File imageFile,
  ) async {
    try {
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '/users/profile/picture',
        data: formData,
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => UploadProfilePictureResponse.fromJson(json),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Delete profile picture
  Future<ApiResponse<void>> deleteProfilePicture() async {
    try {
      final response = await _dio.delete('/users/profile/picture');

      return ApiResponse.fromJson(response.data, null);
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
