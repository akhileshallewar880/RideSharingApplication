import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:allapalli_ride/app/constants/app_constants.dart';

/// Interceptor to add authentication token to requests and handle token refresh
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip token for auth endpoints
    if (_isAuthEndpoint(options.path)) {
      return handler.next(options);
    }

    // Add access token to headers
    final accessToken = await _storage.read(key: AppConstants.keyAccessToken);
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized - Token expired
    if (err.response?.statusCode == 401) {
      final refreshed = await _refreshToken();
      
      if (refreshed) {
        // Retry the request with new token
        final accessToken = await _storage.read(key: AppConstants.keyAccessToken);
        err.requestOptions.headers['Authorization'] = 'Bearer $accessToken';
        
        try {
          final response = await Dio().fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(err);
        }
      } else {
        // Refresh failed, clear tokens and redirect to login
        await _clearTokens();
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/send-otp') ||
        path.contains('/auth/verify-otp') ||
        path.contains('/auth/refresh-token') ||
        path.contains('/auth/complete-registration');
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.keyRefreshToken);
      
      if (refreshToken == null) {
        return false;
      }

      final response = await Dio().post(
        '${AppConstants.apiBaseUrl}/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        await _storage.write(
          key: AppConstants.keyAccessToken,
          value: data['accessToken'],
        );
        await _storage.write(
          key: AppConstants.keyRefreshToken,
          value: data['refreshToken'],
        );
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: AppConstants.keyAccessToken);
    await _storage.delete(key: AppConstants.keyRefreshToken);
    await _storage.delete(key: AppConstants.keyUserId);
    await _storage.delete(key: AppConstants.keyUserType);
  }
}
