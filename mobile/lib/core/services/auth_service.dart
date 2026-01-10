import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:allapalli_ride/app/constants/app_constants.dart';
import 'package:allapalli_ride/core/models/api_response.dart';
import 'package:allapalli_ride/core/models/auth_models.dart';
import 'package:allapalli_ride/core/network/dio_client.dart';
import 'package:allapalli_ride/core/services/notification_service.dart';

/// Authentication service for handling login, registration, and token management
class AuthService {
  final Dio _dio = DioClient.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Store Google Sign-In user data temporarily for phone verification flow
  String? _pendingGoogleEmail;
  String? _pendingGoogleName;
  String? _pendingGooglePhotoUrl;
  String? _pendingGoogleIdToken;
  
  // Google Sign-In with Web Client ID for getting ID Token
  // This Web Client ID is from Firebase Console (OAuth 2.0 Web Client)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/user.phonenumbers.read', // Phone number scope
    ],
    // CRITICAL: serverClientId is required to get the ID token
    // This is the Web OAuth client ID from google-services.json (client_type: 3)
    serverClientId: '657234227532-huehlrive2scm4b4nu623j9edllnc23m.apps.googleusercontent.com',
  );

  /// Get pending Google user data (for phone entry screen)
  Map<String, String?> getPendingGoogleUserData() {
    return {
      'email': _pendingGoogleEmail,
      'name': _pendingGoogleName,
      'photoUrl': _pendingGooglePhotoUrl,
      'googleIdToken': _pendingGoogleIdToken,
    };
  }

  /// Clear pending Google user data
  void clearPendingGoogleUserData() {
    _pendingGoogleEmail = null;
    _pendingGoogleName = null;
    _pendingGooglePhotoUrl = null;
    _pendingGoogleIdToken = null;
  }

  /// Send OTP to phone number
  Future<ApiResponse<SendOtpResponse>> sendOtp(String phoneNumber) async {
    try {
      print('🔵 Sending OTP request...');
      print('🔵 Base URL: ${AppConstants.apiBaseUrl}');
      print('🔵 Phone: $phoneNumber');
      
      final response = await _dio.post(
        '/auth/send-otp',
        data: SendOtpRequest(
          phoneNumber: phoneNumber,
        ).toJson(),
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => SendOtpResponse.fromJson(json),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Verify OTP
  Future<ApiResponse<VerifyOtpResponse>> verifyOtp(
    String phoneNumber,
    String otp,
    String otpId,
  ) async {
    try {
      print('🔵 Verifying OTP...');
      print('🔵 Phone: $phoneNumber');
      print('🔵 OTP: $otp');
      print('🔵 OTP ID: $otpId');
      
      final response = await _dio.post(
        '/auth/verify-otp',
        data: VerifyOtpRequest(
          phoneNumber: phoneNumber,
          otp: otp,
          otpId: otpId,
        ).toJson(),
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => VerifyOtpResponse.fromJson(json),
      );

      // Store tokens if user is not new
      if (apiResponse.isSuccess && apiResponse.data != null) {
        final data = apiResponse.data!;
        
        print('📦 OTP Verification Response:');
        print('   Is New User: ${data.isNewUser}');
        print('   Has Access Token: ${data.accessToken != null}');
        print('   Has Refresh Token: ${data.refreshToken != null}');
        print('   Has User Data: ${data.user != null}');
        
        if (!data.isNewUser && data.accessToken != null) {
          print('✅ Existing user - storing tokens');
          await _storeAuthData(
            accessToken: data.accessToken!,
            refreshToken: data.refreshToken!,
            userId: data.user!.userId,
            userType: data.user!.userType,
          );
          
          // Sync FCM token with backend after successful login
          try {
            final notificationService = NotificationService();
            await notificationService.syncTokenWithBackend();
          } catch (e) {
            print('⚠️ Failed to sync FCM token after login: $e');
          }
        } else if (data.isNewUser && data.tempToken != null) {
          print('⚠️ New user - storing temp token only');
          // Store temp token for registration
          await _storage.write(
            key: AppConstants.keyAccessToken,
            value: data.tempToken,
          );
        } else {
          print('⚠️ Unexpected response state');
        }
      }

      return apiResponse;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Verify Firebase phone authentication with backend
  /// Called after Firebase OTP verification is successful
  Future<ApiResponse<VerifyOtpResponse>> verifyFirebasePhoneAuth(
    String firebaseIdToken,
    String phoneNumber,
  ) async {
    try {
      print('🔐 Verifying Firebase phone auth with backend...');
      print('   Phone: $phoneNumber');
      
      final response = await _dio.post(
        '/auth/verify-firebase-phone',
        data: {
          'firebaseIdToken': firebaseIdToken,
          'phoneNumber': phoneNumber,
        },
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => VerifyOtpResponse.fromJson(json),
      );

      // Store tokens if user is not new
      if (apiResponse.isSuccess && apiResponse.data != null) {
        final data = apiResponse.data!;
        
        print('📦 Firebase Phone Auth Response:');
        print('   Is New User: \${data.isNewUser}');
        print('   Has Access Token: \${data.accessToken != null}');
        print('   Has User Data: \${data.user != null}');
        
        if (!data.isNewUser && data.accessToken != null) {
          print('✅ Existing user - storing tokens');
          await _storeAuthData(
            accessToken: data.accessToken!,
            refreshToken: data.refreshToken!,
            userId: data.user!.userId,
            userType: data.user!.userType,
          );
          
          // Sync FCM token with backend
          try {
            final notificationService = NotificationService();
            await notificationService.syncTokenWithBackend();
          } catch (e) {
            print('⚠️ Failed to sync FCM token: \$e');
          }
        } else if (data.isNewUser && data.tempToken != null) {
          print('⚠️ New user - storing temp token only');
          await _storage.write(
            key: AppConstants.keyAccessToken,
            value: data.tempToken,
          );
        }
      }

      return apiResponse;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Complete registration for new users
  Future<ApiResponse<AuthResponse>> completeRegistration(
    CompleteRegistrationRequest request,
    String phoneNumber,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/complete-registration',
        data: request.toJson(),
        options: Options(
          headers: {
            'X-Phone-Number': phoneNumber,
          },
        ),
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => AuthResponse.fromJson(json),
      );

      // Store tokens after successful registration
      if (apiResponse.isSuccess && apiResponse.data != null) {
        final data = apiResponse.data!;
        print('✅ Registration completed successfully');
        await _storeAuthData(
          accessToken: data.accessToken,
          refreshToken: data.refreshToken,
          userId: data.user.userId,
          userType: data.user.userType,
        );
        
        // Sync FCM token with backend after successful registration
        try {
          final notificationService = NotificationService();
          await notificationService.syncTokenWithBackend();
        } catch (e) {
          print('⚠️ Failed to sync FCM token after registration: $e');
        }
      }

      return apiResponse;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Complete driver registration with vehicle details
  Future<ApiResponse<AuthResponse>> completeDriverRegistration(
    DriverRegistrationRequest request,
    String phoneNumber,
  ) async {
    try {
      print('🚗 Starting driver registration...');
      print('🔵 Phone: $phoneNumber');
      print('🔵 Name: ${request.name}');
      print('🔵 Vehicle Model ID: ${request.vehicleModelId}');
      print('🔵 Vehicle Number: ${request.vehicleNumber}');
      
      final response = await _dio.post(
        '/auth/complete-registration',
        data: request.toJson(),
        options: Options(
          headers: {
            'X-Phone-Number': phoneNumber,
          },
        ),
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => AuthResponse.fromJson(json),
      );

      // Store tokens after successful registration
      if (apiResponse.isSuccess && apiResponse.data != null) {
        final data = apiResponse.data!;
        print('✅ Driver registration completed successfully');
        await _storeAuthData(
          accessToken: data.accessToken,
          refreshToken: data.refreshToken,
          userId: data.user.userId,
          userType: data.user.userType,
        );
        
        // Sync FCM token with backend after successful driver registration
        try {
          final notificationService = NotificationService();
          await notificationService.syncTokenWithBackend();
        } catch (e) {
          print('⚠️ Failed to sync FCM token after driver registration: $e');
        }
      }

      return apiResponse;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Upload driver document (license or RC)
  Future<ApiResponse<DriverDocumentUploadResponse>> uploadDriverDocument(
    File file,
    String documentType,
  ) async {
    try {
      print('📤 Uploading driver document: $documentType');
      
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        'documentType': documentType,
      });

      final response = await _dio.post(
        '/driver/vehicles/documents',
        data: formData,
      );

      print('✅ Document uploaded successfully: $documentType');
      
      return ApiResponse.fromJson(
        response.data,
        (json) => DriverDocumentUploadResponse.fromJson(json),
      );
    } on DioException catch (e) {
      print('🔴 Document upload failed: $documentType - ${e.message}');
      return _handleError(e);
    }
  }

  /// Queue document upload for background processing
  Future<void> queueDocumentUpload(String filePath, String documentType) async {
    print('📋 Queuing document upload: $documentType');
    final key = 'pending_${documentType}_upload';
    await _storage.write(key: key, value: filePath);
    await _storage.write(key: '${key}_attempts', value: '0');
  }

  /// Process pending document uploads
  Future<void> processPendingDocumentUploads() async {
    print('🔄 Processing pending document uploads...');
    
    final licenseUpload = await _storage.read(key: 'pending_license_upload');
    final rcUpload = await _storage.read(key: 'pending_rc_upload');
    
    if (licenseUpload != null) {
      await _attemptDocumentUpload(licenseUpload, 'license');
    }
    
    if (rcUpload != null) {
      await _attemptDocumentUpload(rcUpload, 'rc');
    }
  }

  /// Attempt to upload a queued document
  Future<void> _attemptDocumentUpload(String filePath, String documentType) async {
    final key = 'pending_${documentType}_upload';
    final attemptsKey = '${key}_attempts';
    
    final attemptsStr = await _storage.read(key: attemptsKey);
    final attempts = int.tryParse(attemptsStr ?? '0') ?? 0;
    
    if (attempts >= 5) {
      print('⚠️ Max retry attempts reached for $documentType. Giving up.');
      await _storage.delete(key: key);
      await _storage.delete(key: attemptsKey);
      return;
    }
    
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('⚠️ File not found: $filePath. Removing from queue.');
        await _storage.delete(key: key);
        await _storage.delete(key: attemptsKey);
        return;
      }
      
      final response = await uploadDriverDocument(file, documentType);
      
      if (response.isSuccess) {
        print('✅ Successfully uploaded queued document: $documentType');
        await _storage.delete(key: key);
        await _storage.delete(key: attemptsKey);
      } else {
        print('⚠️ Upload failed for $documentType. Will retry later.');
        await _storage.write(key: attemptsKey, value: '${attempts + 1}');
      }
    } catch (e) {
      print('🔴 Error uploading queued document: $e');
      await _storage.write(key: attemptsKey, value: '${attempts + 1}');
    }
  }

  /// Check if there are pending document uploads
  Future<bool> hasPendingDocumentUploads() async {
    final licenseUpload = await _storage.read(key: 'pending_license_upload');
    final rcUpload = await _storage.read(key: 'pending_rc_upload');
    return licenseUpload != null || rcUpload != null;
  }

  /// Refresh access token
  Future<ApiResponse<RefreshTokenResponse>> refreshToken() async {
    try {
      final refreshToken = await _storage.read(
        key: AppConstants.keyRefreshToken,
      );

      if (refreshToken == null) {
        return ApiResponse(
          success: false,
          message: 'No refresh token found',
        );
      }

      final response = await _dio.post(
        '/auth/refresh-token',
        data: RefreshTokenRequest(refreshToken: refreshToken).toJson(),
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => RefreshTokenResponse.fromJson(json),
      );

      // Update stored tokens
      if (apiResponse.isSuccess && apiResponse.data != null) {
        final data = apiResponse.data!;
        await _storage.write(
          key: AppConstants.keyAccessToken,
          value: data.accessToken,
        );
        await _storage.write(
          key: AppConstants.keyRefreshToken,
          value: data.refreshToken,
        );
      }

      return apiResponse;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Logout
  Future<ApiResponse<void>> logout() async {
    try {
      final refreshToken = await _storage.read(
        key: AppConstants.keyRefreshToken,
      );

      if (refreshToken != null) {
        await _dio.post(
          '/auth/logout',
          data: LogoutRequest(refreshToken: refreshToken).toJson(),
        );
      }

      // Clear all stored data
      await clearAuthData();

      return ApiResponse(
        success: true,
        message: 'Logged out successfully',
      );
    } on DioException catch (e) {
      print('Logout API error: ${e.message}');
      // Even if API call fails, clear local data
      await clearAuthData();
      return ApiResponse(
        success: true,
        message: 'Logged out successfully',
      );
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final accessToken = await _storage.read(key: AppConstants.keyAccessToken);
    final hasToken = accessToken != null;
    print('🔍 Auth Check - Has Token: $hasToken');
    if (hasToken) {
      print('   Token: ${accessToken.substring(0, 20)}...');
    }
    return hasToken;
  }

  /// Get stored user type
  Future<String?> getUserType() async {
    final userType = await _storage.read(key: AppConstants.keyUserType);
    print('🔍 Get User Type: $userType');
    return userType;
  }

  /// Get stored user ID
  Future<String?> getUserId() async {
    final userId = await _storage.read(key: AppConstants.keyUserId);
    print('🔍 Get User ID: $userId');
    return userId;
  }

  /// Store authentication data
  Future<void> _storeAuthData({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String userType,
  }) async {
    print('💾 Storing auth data:');
    print('   User ID: $userId');
    print('   User Type: $userType');
    print('   Access Token: ${accessToken.substring(0, 20)}...');
    
    await _storage.write(key: AppConstants.keyAccessToken, value: accessToken);
    await _storage.write(key: AppConstants.keyRefreshToken, value: refreshToken);
    await _storage.write(key: AppConstants.keyUserId, value: userId);
    await _storage.write(key: AppConstants.keyUserType, value: userType);
    
    print('✅ Auth data stored successfully');
  }

  /// Clear all authentication data
  Future<void> clearAuthData() async {
    print('🗑️ Clearing all auth data...');
    await _storage.delete(key: AppConstants.keyAccessToken);
    await _storage.delete(key: AppConstants.keyRefreshToken);
    await _storage.delete(key: AppConstants.keyUserId);
    await _storage.delete(key: AppConstants.keyUserType);
    print('✅ All auth data cleared');
  }

  /// Handle Dio errors
  ApiResponse<T> _handleError<T>(DioException error) {
    String message = 'An error occurred';
    List<String>? errors;

    // Debug logging
    print('🔴 API Error Type: ${error.type}');
    print('🔴 Error Message: ${error.message}');
    print('🔴 Request URL: ${error.requestOptions.uri}');

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
      message = 'Connection timeout. Please check your backend server is running.';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'Cannot connect to server. Check if backend is running at ${error.requestOptions.uri.host}:${error.requestOptions.uri.port}';
    } else {
      message = error.message ?? message;
    }

    return ApiResponse<T>(
      success: false,
      message: message,
      errors: errors,
    );
  }

  /// Fetch available cities for driver registration
  Future<ApiResponse<List<dynamic>>> getCities() async {
    try {
      final response = await _dio.get('/auth/cities');
      
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => json as List<dynamic>,
      );

      return apiResponse;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Sign in with Google (returns user data if phone number is needed)
  Future<ApiResponse<AuthResponse>> signInWithGoogle({String? phoneNumber}) async {
    try {
      print('🔵 Starting Google Sign-In...');
      
      // Check if Google Sign-In is properly configured
      print('⚠️ Google Sign-In requires proper Firebase configuration');
      print('⚠️ Please configure OAuth 2.0 credentials in Google Cloud Console');
      print('⚠️ Add SHA-1 fingerprint: C8:58:76:47:2C:D9:8D:46:C8:A5:FD:75:96:20:02:B0:D8:33:F8:72');
      
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        print('⚠️ Google Sign-In cancelled by user');
        return ApiResponse<AuthResponse>(
          success: false,
          message: 'Sign-in cancelled',
        );
      }
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      print('✅ Google Sign-In successful');
      print('   Email: ${googleUser.email}');
      print('   Name: ${googleUser.displayName}');
      print('   ID Token: ${googleAuth.idToken?.substring(0, 20)}...');
      
      // Store pending Google user data for phone verification flow
      _pendingGoogleEmail = googleUser.email;
      _pendingGoogleName = googleUser.displayName;
      _pendingGooglePhotoUrl = googleUser.photoUrl;
      _pendingGoogleIdToken = googleAuth.idToken;
      
      // Try to fetch phone number from Google People API
      String? googlePhoneNumber;
      if (phoneNumber == null) {
        googlePhoneNumber = await _fetchPhoneNumberFromGoogle(googleAuth.accessToken);
        if (googlePhoneNumber != null) {
          print('✅ Fetched phone number from Google: $googlePhoneNumber');
        } else {
          print('⚠️ No phone number found in Google account');
        }
      }
      
      // Send the ID token to your backend
      final response = await _dio.post(
        '/auth/google-signin',
        data: {
          'idToken': googleAuth.idToken,
          'email': googleUser.email,
          'name': googleUser.displayName,
          'photoUrl': googleUser.photoUrl,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
          if (googlePhoneNumber != null) 'phoneNumber': googlePhoneNumber,
        },
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => AuthResponse.fromJson(json),
      );
        // Clear pending data after successful authentication
        clearPendingGoogleUserData();
        
        

      // Store tokens after successful Google sign-in
      if (apiResponse.isSuccess && apiResponse.data != null) {
        final data = apiResponse.data!;
        print('✅ Google authentication completed successfully');
        await _storeAuthData(
          accessToken: data.accessToken,
          refreshToken: data.refreshToken,
          userId: data.user.userId,
          userType: data.user.userType,
        );
        
        // Sync FCM token with backend after successful Google sign-in
        try {
          final notificationService = NotificationService();
          await notificationService.syncTokenWithBackend();
        } catch (e) {
          print('⚠️ Failed to sync FCM token after Google sign-in: $e');
        }
      }

      return apiResponse;
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      print('🔴 Google Sign-In error: $e');
      print('🔴 Error details: ${e.runtimeType}');
      print('🔴 This usually means Google Sign-In is not configured in Firebase Console');
      print('🔴 Error code 10 = DEVELOPER_ERROR (OAuth client not configured)');
      return ApiResponse<AuthResponse>(
        success: false,
        message: 'Google Sign-In is not configured. Please use phone number login.',
      );
    }
  }

  /// Fetch phone number from Google People API
  Future<String?> _fetchPhoneNumberFromGoogle(String? accessToken) async {
    if (accessToken == null) {
      print('⚠️ No access token available for Google People API');
      return null;
    }

    try {
      print('📱 Fetching phone number from Google People API...');
      
      final response = await Dio().get(
        'https://people.googleapis.com/v1/people/me',
        queryParameters: {
          'personFields': 'phoneNumbers',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final phoneNumbers = data['phoneNumbers'] as List<dynamic>?;
        
        if (phoneNumbers != null && phoneNumbers.isNotEmpty) {
          // Get the first phone number
          final phoneData = phoneNumbers[0] as Map<String, dynamic>;
          String phoneNumber = phoneData['value'] as String? ?? '';
          
          // Clean up phone number (remove spaces, dashes, etc.)
          phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
          
          // Ensure it starts with country code
          if (phoneNumber.startsWith('0')) {
            phoneNumber = '+91${phoneNumber.substring(1)}'; // Assume Indian number
          } else if (!phoneNumber.startsWith('+')) {
            phoneNumber = '+91$phoneNumber'; // Add Indian country code
          }
          
          print('✅ Found phone number: $phoneNumber');
          return phoneNumber;
        } else {
          print('⚠️ No phone numbers found in Google account');
        }
      }
    } catch (e) {
      print('⚠️ Error fetching phone number from Google: $e');
    }
    
    return null;
  }

  /// Sign out from Google
  Future<void> signOutFromGoogle() async {
    try {
      await _googleSignIn.signOut();
      print('✅ Signed out from Google');
    } catch (e) {
      print('⚠️ Error signing out from Google: $e');
    }
  }
}
