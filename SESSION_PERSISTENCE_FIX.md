# Admin Web App - Session Persistence Fix

## Problem
When the admin web app was refreshed, users were logged out and redirected to the login page, even though their authentication token was still valid in localStorage.

## Root Cause
1. **SplashScreen always redirected to login**: The splash screen was hardcoded to always navigate to `/login` regardless of authentication status
2. **User data not persisted**: Only the token was stored in localStorage, but user data (name, email, role, permissions) was not stored
3. **Auth state not restored**: The auth provider only checked if a token existed but didn't restore the complete user data

## Solution Implemented

### 1. Store User Data in localStorage
**File**: `admin_web/lib/core/services/admin_auth_service.dart`

Added user data storage after successful login:
```dart
// Store user data as JSON string for session persistence
try {
  final userJsonStr = jsonEncode(userJson);
  await _storage.write(
    key: AppConstants.userDataKey,
    value: userJsonStr,
  );
  print('✅ User data stored in localStorage');
} catch (storageError) {
  print('⚠️ Error storing user data: $storageError');
}
```

### 2. Retrieve Stored User Data
**File**: `admin_web/lib/core/services/admin_auth_service.dart`

Added new method to retrieve stored user data:
```dart
Future<AdminUser?> getStoredUser() async {
  try {
    final userDataStr = await _storage.read(key: AppConstants.userDataKey);
    if (userDataStr != null && userDataStr.isNotEmpty) {
      print('🔍 Retrieving stored user data from localStorage...');
      final userJson = jsonDecode(userDataStr) as Map<String, dynamic>;
      final user = AdminUser.fromJson(userJson);
      print('✅ User data restored: ${user.email}');
      return user;
    }
  } catch (e) {
    print('❌ Error retrieving stored user: $e');
  }
  return null;
}
```

### 3. Restore Auth State on App Initialization
**File**: `admin_web/lib/core/providers/admin_auth_provider.dart`

Updated `_checkAuthStatus()` to restore user data:
```dart
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
```

### 4. Update Splash Screen to Check Auth
**File**: `admin_web/lib/main.dart`

Updated splash screen to check auth state and navigate accordingly:
```dart
Future<void> _checkAuth() async {
  // Wait a bit for the provider to initialize
  await Future.delayed(Duration(milliseconds: 1500));
  
  if (mounted) {
    // Check if user is authenticated
    final authState = ref.read(adminAuthProvider);
    
    if (authState.isAuthenticated && authState.user != null) {
      print('✅ User authenticated, navigating to dashboard...');
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      print('ℹ️ User not authenticated, navigating to login...');
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}
```

## How It Works

1. **Login Flow**:
   - User logs in with email/password
   - Backend returns token, refreshToken, and user data
   - Auth service stores all three in localStorage (token, refreshToken, userData)
   - Auth provider updates state with user data

2. **Page Refresh Flow**:
   - App loads, splash screen shows
   - Auth provider's `_checkAuthStatus()` runs automatically
   - Checks if token exists in localStorage
   - If token exists, retrieves and parses stored user data
   - Restores auth state with user data
   - Splash screen checks auth state and navigates to dashboard

3. **Logout Flow**:
   - User clicks logout
   - Auth service calls logout API
   - Clears token, refreshToken, and userData from localStorage
   - Auth provider resets state
   - User navigated to login screen

## Benefits

✅ **Persistent Sessions**: Users stay logged in across page refreshes  
✅ **Automatic Session Restoration**: User data automatically restored on app load  
✅ **Secure**: Token validation still happens via API interceptors  
✅ **Graceful Degradation**: If user data is corrupted/missing but token exists, forces re-login  
✅ **Clean Logout**: All session data properly cleared on logout

## Testing

1. **Test Session Persistence**:
   - Login to admin web app
   - Refresh the page (F5 or Cmd+R)
   - Should stay on dashboard, not redirect to login

2. **Test Logout**:
   - Click logout button
   - Should clear session and redirect to login
   - Refreshing after logout should keep you on login page

3. **Test Token Expiration**:
   - Wait for token to expire (or manually delete token from localStorage)
   - Next API call should fail with 401
   - Should be redirected to login

## Files Modified

1. `admin_web/lib/core/services/admin_auth_service.dart` - Added user data storage/retrieval
2. `admin_web/lib/core/providers/admin_auth_provider.dart` - Added session restoration logic
3. `admin_web/lib/main.dart` - Updated splash screen to check auth state

## Storage Keys Used

- `admin_auth_token` - JWT access token
- `admin_refresh_token` - Refresh token for renewing expired tokens
- `admin_user_data` - JSON serialized user data (id, email, name, role, permissions, createdAt)
