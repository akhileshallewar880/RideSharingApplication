# Token-Based Authentication Implementation

## Overview
The app now implements persistent login using token-based authentication. Users only need to log in once per device, and their session will be automatically restored on app restart.

## Features Implemented

### 1. **Automatic Token Storage** ✅
When a user successfully logs in, the following data is securely stored:
- **Access Token**: Used for API authentication
- **Refresh Token**: Used to get new access tokens when they expire
- **User ID**: Unique identifier for the user
- **User Type**: Either 'passenger' or 'driver'

**Storage Location**: `flutter_secure_storage` (encrypted storage)

### 2. **Auto-Login on App Startup** ✅
- **File**: `lib/features/auth/presentation/screens/splash_screen.dart`
- **Implementation**:
  - On app startup, the splash screen checks if valid tokens exist
  - If tokens are found, user is automatically redirected to their home screen
  - Passengers → `/passenger/home`
  - Drivers → `/driver/dashboard`
  - No tokens → `/onboarding` (login flow)

### 3. **Automatic Token Refresh** ✅
- **File**: `lib/core/network/auth_interceptor.dart`
- **Implementation**:
  - All API requests automatically include the access token
  - If a request fails with 401 (token expired), the app automatically:
    1. Uses refresh token to get a new access token
    2. Retries the failed request with the new token
    3. User never sees an error or needs to re-login
  - If refresh token is also expired, user is redirected to login

### 4. **Logout Functionality** ✅
- **File**: `lib/features/passenger/presentation/screens/profile_screen.dart`
- **Implementation**:
  - Red "Logout" button added at the bottom of profile screen
  - Shows confirmation dialog before logging out
  - On logout:
    1. Calls backend logout API (invalidates refresh token)
    2. Clears all stored tokens from device
    3. Redirects to login screen
    4. Shows success message

## How It Works

### Login Flow
```
1. User enters phone number → OTP sent
2. User enters OTP → Backend validates
3. If new user → Complete registration
4. Backend returns tokens
5. Tokens saved securely → User authenticated
6. Redirect to home screen
```

### Auto-Login Flow
```
1. App starts → Splash screen loads
2. Check secure storage for tokens
3. If tokens exist:
   - Load user type
   - Redirect to appropriate home screen
4. If no tokens:
   - Redirect to onboarding/login
```

### Logout Flow
```
1. User taps "Logout" in profile
2. Confirmation dialog appears
3. User confirms
4. Call backend logout API
5. Clear all local tokens
6. Redirect to login screen
7. Show success message
```

## Security Features

### Secure Token Storage
- Uses `flutter_secure_storage` package
- Tokens encrypted at rest on device
- Keys used:
  - `access_token`
  - `refresh_token`
  - `user_id`
  - `user_type`

### Token Lifecycle Management
- **Access Token**: Short-lived (~1 hour)
- **Refresh Token**: Long-lived (~30 days)
- Automatic refresh before expiry
- Both tokens invalidated on logout

### API Security
- All protected endpoints require `Authorization: Bearer <token>`
- Tokens added automatically by `AuthInterceptor`
- Failed auth attempts logged and handled gracefully

## Files Modified

### Core Services
1. **auth_service.dart** - Already had token management methods:
   - `isAuthenticated()` - Check if user has valid token
   - `getUserType()` - Get stored user type
   - `getUserId()` - Get stored user ID
   - `logout()` - Clear tokens and logout
   - `_storeAuthData()` - Save tokens securely
   - `clearAuthData()` - Remove all tokens

### Network Layer
2. **auth_interceptor.dart** - Already had automatic token refresh:
   - Adds token to all API requests
   - Intercepts 401 errors
   - Automatically refreshes expired tokens
   - Retries failed requests

### UI Screens
3. **splash_screen.dart** - Auto-login check added:
   - Changed from `StatefulWidget` to `ConsumerStatefulWidget`
   - Added `_checkAuthAndNavigate()` method
   - Checks auth state on startup
   - Routes to correct screen based on user type

4. **profile_screen.dart** - Logout button added:
   - Red "Logout" button with icon
   - Confirmation dialog
   - Loading indicator during logout
   - Success/error messages
   - Automatic navigation to login

### State Management
5. **auth_provider.dart** - Already had logout method:
   - `logout()` - Calls auth service and resets state
   - Updates authentication state
   - Notifies UI of changes

## Testing Checklist

### Test Auto-Login
- [ ] Login with valid credentials
- [ ] Close app completely
- [ ] Reopen app
- [ ] Should go directly to home screen (no login required)

### Test Token Refresh
- [ ] Login and use app normally
- [ ] Wait for access token to expire (~1 hour)
- [ ] Make API calls (book ride, update profile)
- [ ] Should work seamlessly without re-login

### Test Logout
- [ ] Go to Profile screen
- [ ] Tap "Logout" button
- [ ] Confirm in dialog
- [ ] Should redirect to login screen
- [ ] Reopen app
- [ ] Should show onboarding/login (not auto-login)

### Test Session Expiry
- [ ] Login normally
- [ ] Wait for refresh token to expire (~30 days) OR manually delete tokens
- [ ] Try to make API call
- [ ] Should redirect to login screen

## User Experience

### Before (Without Persistent Login)
❌ User logs in
❌ Closes app
❌ Opens app again
❌ Must log in again (frustrating!)

### After (With Persistent Login)
✅ User logs in once
✅ Closes app
✅ Opens app again
✅ Automatically logged in (seamless!)
✅ Only needs to log in again after 30 days or manual logout

## Backend Requirements

The backend must support:
1. **POST /auth/verify-otp** - Returns access token + refresh token
2. **POST /auth/refresh-token** - Accepts refresh token, returns new access + refresh tokens
3. **POST /auth/logout** - Invalidates refresh token
4. **401 Response** - When access token expires (triggers auto-refresh)

## Configuration

Token storage keys are defined in:
```dart
// lib/app/constants/app_constants.dart
static const String keyAccessToken = 'access_token';
static const String keyRefreshToken = 'refresh_token';
static const String keyUserId = 'user_id';
static const String keyUserType = 'user_type';
```

## Troubleshooting

### User not auto-logging in?
1. Check if tokens exist in secure storage
2. Verify `isAuthenticated()` returns true
3. Check console logs during splash screen
4. Ensure `_checkAuthStatus()` is called in `AuthNotifier`

### Token refresh not working?
1. Check if backend returns proper refresh token response
2. Verify `AuthInterceptor` is added to Dio instance
3. Check network logs for 401 responses
4. Ensure refresh token hasn't expired

### Logout not clearing session?
1. Verify `clearAuthData()` is called
2. Check secure storage is actually cleared
3. Ensure navigation removes all previous routes
4. Verify `AuthState` is reset

## Next Steps

### Enhancements (Optional)
1. **Biometric Login**: Add fingerprint/face unlock
2. **Multiple Devices**: Track and manage user sessions
3. **Session History**: Show login history in profile
4. **Force Logout**: Allow users to logout from all devices
5. **Token Expiry Warning**: Show notification before session expires

---

## Summary

✅ **Token storage** - Secure, encrypted
✅ **Auto-login** - Seamless experience
✅ **Token refresh** - Automatic, transparent
✅ **Logout** - Clean, with confirmation
✅ **Security** - Industry-standard practices

Users can now enjoy persistent login without compromising security!
