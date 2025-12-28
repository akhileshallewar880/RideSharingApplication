import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../models/auth_models.dart';
import '../services/auth_service.dart';

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Auth state provider
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? userType;
  final String? userId;
  final String? errorMessage;
  final String? otpId; // Store otpId from send-otp response
  final bool? isExistingUser; // Store if user exists from send-otp response

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.userType,
    this.userId,
    this.errorMessage,
    this.otpId,
    this.isExistingUser,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? userType,
    String? userId,
    String? errorMessage,
    String? otpId,
    bool? isExistingUser,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      userType: userType ?? this.userType,
      userId: userId ?? this.userId,
      errorMessage: errorMessage,
      otpId: otpId ?? this.otpId,
      isExistingUser: isExistingUser ?? this.isExistingUser,
    );
  }
}

// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isAuth = await _authService.isAuthenticated();
    if (isAuth) {
      final userType = await _authService.getUserType();
      final userId = await _authService.getUserId();
      state = state.copyWith(
        isAuthenticated: true,
        userType: userType,
        userId: userId,
      );
    }
  }

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _authService.sendOtp(phoneNumber);
      if (response.success && response.data != null) {
        // Store otpId and isExistingUser from response
        state = state.copyWith(
          isLoading: false,
          otpId: response.data!.otpId,
          isExistingUser: response.data!.isExistingUser,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<VerifyOtpResponse?> verifyOtp(String phoneNumber, String otp) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // Get otpId from state
      final otpId = state.otpId;
      if (otpId == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'OTP session expired. Please request a new OTP.',
        );
        return null;
      }
      
      final response = await _authService.verifyOtp(phoneNumber, otp, otpId);
      if (response.success && response.data != null) {
        final userType = await _authService.getUserType();
        final userId = await _authService.getUserId();
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: !response.data!.isNewUser,
          userType: userType,
          userId: userId,
        );
        return response.data;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  Future<void> completeRegistration(
      CompleteRegistrationRequest request, String phoneNumber) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _authService.completeRegistration(request, phoneNumber);
      if (response.success) {
        // Use userType from API response, not from storage
        final userType = response.data?.user.userType ?? await _authService.getUserType();
        final userId = response.data?.user.userId ?? await _authService.getUserId();
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          userType: userType,
          userId: userId,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> completeDriverRegistration(
    DriverRegistrationRequest request,
    String phoneNumber,
    File licenseFile,
    File rcFile,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // Complete driver registration first
      final response = await _authService.completeDriverRegistration(request, phoneNumber);
      if (response.success) {
        final userType = await _authService.getUserType();
        final userId = await _authService.getUserId();
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          userType: userType,
          userId: userId,
        );

        // Queue documents for async upload
        await _authService.queueDocumentUpload(licenseFile.path, 'license');
        await _authService.queueDocumentUpload(rcFile.path, 'rc');

        // Attempt immediate upload in background
        _authService.processPendingDocumentUploads().catchError((e) {
          print('⚠️ Background document upload failed: $e');
          // Documents will be retried later
        });
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> retryDocumentUploads() async {
    try {
      await _authService.processPendingDocumentUploads();
    } catch (e) {
      print('⚠️ Document upload retry failed: $e');
    }
  }

  Future<bool> hasPendingDocumentUploads() async {
    return await _authService.hasPendingDocumentUploads();
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authService.logout();
      // Reset to initial unauthenticated state
      state = AuthState(
        isAuthenticated: false,
        isLoading: false,
        userType: null,
        userId: null,
        errorMessage: null,
        otpId: null,
        isExistingUser: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      // Even if there's an error, reset the state
      state = AuthState(
        isAuthenticated: false,
        isLoading: false,
        userType: null,
        userId: null,
        errorMessage: null,
        otpId: null,
        isExistingUser: null,
      );
    }
  }
}

// Auth state notifier provider
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
