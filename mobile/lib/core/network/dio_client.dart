import 'package:dio/dio.dart';
import 'package:allapalli_ride/app/constants/app_constants.dart';
import 'package:allapalli_ride/core/network/auth_interceptor.dart';
import 'package:allapalli_ride/core/network/logging_interceptor.dart';

/// Dio HTTP client singleton
class DioClient {
  static Dio? _dio;

  static Dio get instance {
    if (_dio == null) {
      _dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.apiBaseUrl,
          connectTimeout: Duration(seconds: AppConstants.connectionTimeout),
          receiveTimeout: Duration(seconds: AppConstants.receiveTimeout),
          sendTimeout: Duration(seconds: AppConstants.connectionTimeout),
          validateStatus: (status) {
            return status != null && status < 500;
          },
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          contentType: 'application/json',
        ),
      );

      // Add interceptors
      _dio!.interceptors.add(LoggingInterceptor());
      _dio!.interceptors.add(AuthInterceptor());
    }
    return _dio!;
  }

  /// Reset the instance (useful for testing or logout)
  static void reset() {
    _dio?.close();
    _dio = null;
  }

  /// Create multipart request for file uploads
  static Future<FormData> createFormData(
    Map<String, dynamic> fields, {
    List<MapEntry<String, MultipartFile>>? files,
  }) async {
    final formData = FormData.fromMap(fields);
    
    if (files != null) {
      for (var file in files) {
        formData.files.add(file);
      }
    }
    
    return formData;
  }
}
