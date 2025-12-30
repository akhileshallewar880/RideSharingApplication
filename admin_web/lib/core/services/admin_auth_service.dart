import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../models/admin_models.dart';

class AdminAuthService {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  // Expose dio instance for use by other services
  Dio get dio => _dio;

  AdminAuthService()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: Duration(seconds: 60), // Increased timeout
          receiveTimeout: Duration(seconds: 60),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )),
        _storage = const FlutterSecureStorage() {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired, try to refresh
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the request
            return handler.resolve(await _retry(error.requestOptions));
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await _dio.post('/auth/refresh-token', data: {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        await _storage.write(key: AppConstants.tokenKey, value: data['accessToken']);
        await _storage.write(key: AppConstants.refreshTokenKey, value: data['refreshToken']);
        return true;
      }
    } catch (e) {
      print('Error refreshing token: $e');
    }
    return false;
  }

  Future<AdminUser> login(String email, String password) async {
    try {
      print('🔐 Admin Login - Starting login request...');
      print('📍 URL: ${AppConstants.baseUrl}/admin/auth/login');
      print('📧 Email: $email');
      
      final response = await _dio.post('/admin/auth/login', data: {
        'email': email,
        'password': password,
      });

      print('✅ Login Response Status: ${response.statusCode}');
      print('📦 Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData == null || responseData['data'] == null) {
          throw Exception('Invalid response format: missing data field');
        }
        
        final data = responseData['data'];
        
        // Validate required fields
        if (data['token'] == null || data['refreshToken'] == null || data['user'] == null) {
          throw Exception('Invalid response format: missing required fields');
        }
        
        // Store tokens
        await _storage.write(key: AppConstants.tokenKey, value: data['token']);
        await _storage.write(key: AppConstants.refreshTokenKey, value: data['refreshToken']);
        
        // Parse user data
        final user = AdminUser.fromJson(data['user']);
        
        print('✅ Login successful for user: ${user.email}');
        return user;
      } else {
        print('❌ Login failed with status: ${response.statusCode}');
        throw Exception('Login failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ DioException during login:');
      print('   Type: ${e.type}');
      print('   Message: ${e.message}');
      print('   Response: ${e.response?.data}');
      print('   Status Code: ${e.response?.statusCode}');
      
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid email or password');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Access denied. Admin privileges required.');
      }
      throw Exception('Login failed: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error during login: $e');
      throw Exception('Login error: $e');
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken != null) {
        await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      }
    } catch (e) {
      print('Error during logout: $e');
    } finally {
      await _storage.delete(key: AppConstants.tokenKey);
      await _storage.delete(key: AppConstants.refreshTokenKey);
      await _storage.delete(key: AppConstants.userDataKey);
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    return token != null;
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }
}
