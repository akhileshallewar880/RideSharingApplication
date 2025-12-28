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
    final isLoggedIn = await _authService.isLoggedIn();
    state = state.copyWith(isAuthenticated: isLoggedIn);
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = await _authService.login(email, password);
      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
        isAuthenticated: false,
      );
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AdminAuthState();
  }
}
