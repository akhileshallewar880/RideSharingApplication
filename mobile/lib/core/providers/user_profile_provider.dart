import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile_models.dart';
import '../services/user_profile_service.dart';

// User profile service provider
final userProfileServiceProvider =
    Provider<UserProfileService>((ref) => UserProfileService());

// User profile state
class UserProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final String? errorMessage;

  UserProfileState({
    this.profile,
    this.isLoading = false,
    this.errorMessage,
  });

  UserProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? errorMessage,
  }) {
    return UserProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// User profile notifier
class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final UserProfileService _service;

  UserProfileNotifier(this._service) : super(UserProfileState());

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _service.getProfile();
      if (response.success && response.data != null) {
        state = state.copyWith(
          profile: response.data,
          isLoading: false,
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

  Future<bool> updateProfile(UpdateProfileRequest request) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _service.updateProfile(request);
      if (response.success && response.data != null) {
        state = state.copyWith(
          profile: response.data,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> uploadProfilePicture(dynamic file) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _service.uploadProfilePicture(file);
      if (response.success) {
        // Reload profile to get updated picture URL
        await loadProfile();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> deleteProfilePicture() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _service.deleteProfilePicture();
      if (response.success) {
        // Reload profile to reflect the deletion
        await loadProfile();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void clearProfile() {
    state = UserProfileState();
  }
}

// User profile notifier provider
final userProfileNotifierProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
  final service = ref.watch(userProfileServiceProvider);
  return UserProfileNotifier(service);
});
