import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_models.dart';
import '../services/admin_auth_service.dart';

final adminAuthServiceProvider = Provider<AdminAuthService>((ref) {
  return AdminAuthService();
});

final adminAuthProvider = StateNotifierProvider<AdminAuthNotifier, AdminAuthState>((ref) {
  final authService = ref.watch(adminAuthServiceProvider);
  return AdminAuthNotifier(authService);
});

class AdminAuthState {
  final AdminUser? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AdminAuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AdminAuthState copyWith({
    AdminUser? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AdminAuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AdminAuthNotifier extends StateNotifier<AdminAuthState> {
  final AdminAuthService _authService;

  AdminAuthNotifier(this._authService) : super(AdminAuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        // Restore user data from storage
        final user = await _authService.getStoredUser();
        if (user != null) {
          state = state.copyWith(
            isAuthenticated: true,
            user: user,
          );
          print('✅ Session restored for user: ${user.email}');
        } else {
          // Token exists but no user data, force re-login
          await _authService.logout();
          state = state.copyWith(isAuthenticated: false);
        }
      } else {
        state = state.copyWith(isAuthenticated: false);
      }
    } catch (e) {
      print('❌ Error checking auth status: $e');
      state = state.copyWith(isAuthenticated: false);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = await _authService.login(email, password);
      
      // Ensure user object is complete before updating state
      if (user.id.isEmpty || user.email.isEmpty || user.name.isEmpty) {
        throw Exception('Incomplete user data received from server');
      }
      
      // Add small delay to ensure all data is processed
      await Future.delayed(Duration(milliseconds: 50));
      
      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
        error: null,
      );
      
      print('✅ Auth state updated - User: ${user.name}, Email: ${user.email}');
    } catch (e) {
      print('❌ Login error in provider: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
        isAuthenticated: false,
        user: null,
      );
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AdminAuthState();
  }
}
