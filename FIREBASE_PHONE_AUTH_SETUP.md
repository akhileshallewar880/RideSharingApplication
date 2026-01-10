# Firebase Phone Authentication Setup Guide

## Overview
This guide covers the Firebase phone authentication implementation with SMS auto-fetch for OTP verification in the VanYatra mobile app.

## ✅ What's Been Implemented

### 1. Dependencies Added
- **firebase_auth: ^4.16.0** - Firebase Authentication SDK
- **sms_autofill: ^2.3.0** - Automatic SMS OTP detection for Android

### 2. Firebase Auth Service
Created `lib/core/services/firebase_auth_service.dart` with:
- `sendOtp()` - Sends OTP via Firebase with callbacks for:
  - `onCodeSent` - Called when SMS is sent successfully
  - `onVerificationFailed` - Error handling
  - `onAutoVerify` - Auto verification on Android (instant verification)
- `verifyOtp()` - Verifies the OTP code and returns UserCredential
- Comprehensive error handling for all Firebase auth exceptions

### 3. Updated Login Flow
**File:** `lib/features/auth/presentation/screens/login_screen.dart`
- Integrated FirebaseAuthService
- Sends OTP using Firebase instead of backend
- Captures verificationId from Firebase
- Passes both phoneNumber and verificationId to OTP screen
- Added loading states and error handling

### 4. Updated OTP Screen
**File:** `lib/features/auth/presentation/screens/otp_verification_screen.dart`
- Added `CodeAutoFill` mixin for SMS listening
- Accepts `verificationId` parameter from login screen
- Setup auto OTP fetch with `_setupAutoOtpFetch()`
- Implemented `codeUpdated()` callback for auto-filled OTP
- Auto-verifies OTP after SMS is received (Android)
- Properly disposes SMS listener

### 5. Route Configuration
**File:** `lib/main.dart`
- Updated '/otp' route to accept Map<String, dynamic> arguments
- Supports both:
  - New format: `{'phoneNumber': String, 'verificationId': String}`
  - Old format: String phoneNumber (backward compatibility)

### 6. Android Permissions
**File:** `android/app/src/main/AndroidManifest.xml`
Added SMS permissions:
```xml
<uses-permission android:name="android.permission.RECEIVE_SMS" />
<uses-permission android:name="android.permission.READ_SMS" />
<uses-permission android:name="com.google.android.gms.permission.USER_CONSENT" />
```

## 🔧 Firebase Console Setup Required

### Step 1: Enable Phone Authentication
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **VanYatra** (or create one if needed)
3. Navigate to **Authentication** → **Sign-in method**
4. Enable **Phone** authentication provider
5. Click **Save**

### Step 2: Add Android App Configuration
1. In Firebase Console, go to **Project Settings** → **Your apps**
2. Select your Android app or add one if not present:
   - Package name: `com.allapalli.allapalli_ride`
3. Add your debug SHA-1 fingerprint:
   ```
   C8:58:76:47:2C:D9:8D:46:C8:A5:FD:75:96:20:02:B0:D8:33:F8:72
   ```
4. For release builds, add your release SHA-1 fingerprint (get from Play Console or keystore)
5. Click **Save**
6. Download updated `google-services.json` and replace the file in `android/app/`

### Step 3: Get SHA-1 Fingerprints
For debug builds:
```bash
cd android
./gradlew signingReport
```

For release builds:
```bash
keytool -list -v -keystore /path/to/your/release.keystore -alias your-alias
```

### Step 4: Configure Phone Authentication Settings
1. In Firebase Console → Authentication → Settings → Phone numbers for testing
2. (Optional) Add test phone numbers if needed for development
3. Configure reCAPTCHA for web (if using web platform)

## 📱 How It Works

### Authentication Flow:
1. **User enters phone number** → Login screen validates format (+91XXXXXXXXXX)
2. **Firebase sends OTP** → Firebase Auth triggers SMS delivery
3. **App listens for SMS** → sms_autofill listens in background (Android only)
4. **Auto-fill OTP** → When SMS received, auto-populates 4-digit code
5. **Verify OTP** → App verifies code with Firebase
6. **Authentication success** → User proceeds to app

### SMS Format Expected:
```
Your VanYatra OTP is: 123456
<#> Your VanYatra OTP is: 123456
FA+9qCX9VSu (App signature)
```

Note: Firebase sends 6-digit OTP, but app extracts first 4 digits as per backend API spec.

## 🔥 Key Features

### Auto OTP Fetch (Android Only)
- Uses Android SMS Retriever API
- No manual OTP entry needed
- Works without SMS READ permission on Android 8+
- Automatically fills OTP field when SMS arrives
- Auto-verifies after 500ms delay

### iOS Behavior
- iOS doesn't support automatic SMS reading
- User needs to manually copy OTP from SMS
- Or use iOS 12+ Password AutoFill (requires proper SMS format)

### Error Handling
Comprehensive error messages for:
- Invalid phone number format
- SMS quota exceeded
- Network errors
- Invalid verification code
- Timeout errors (default: 30 seconds)

## 🧪 Testing

### Test on Android Device/Emulator:
```bash
cd mobile
flutter run
```

### Test Auto OTP Fetch:
1. Enter a real phone number
2. Tap "Send OTP"
3. Wait for SMS to arrive
4. OTP should auto-fill and verify automatically

### Debug SMS Listening:
Check console logs for:
```
📱 SMS Auto-fetch initialized
   App Signature: FA+9qCX9VSu
✅ Auto-fetched OTP: 123456
```

## ⚠️ Important Notes

### Production Checklist:
- [ ] Add release SHA-1 fingerprint to Firebase Console
- [ ] Download and replace `google-services.json` with production config
- [ ] Test with real phone numbers (not test numbers)
- [ ] Configure proper Firebase App Check for security
- [ ] Set up Firebase Analytics for monitoring
- [ ] Enable Firebase Crashlytics for error tracking

### Security Considerations:
- Never commit `google-services.json` to public repositories
- Use Firebase App Check to prevent abuse
- Implement rate limiting for OTP requests
- Monitor Firebase usage quotas
- Consider implementing reCAPTCHA for web

### Known Limitations:
- SMS auto-fetch only works on Android
- Requires Google Play Services on device
- May not work on custom Android ROMs without Play Services
- SMS format must match specific pattern for auto-fetch
- Firebase has SMS quota limits (10,000/day for free tier)

## 📝 File Changes Summary

### New Files:
- `lib/core/services/firebase_auth_service.dart` - Firebase auth wrapper

### Modified Files:
- `mobile/pubspec.yaml` - Added dependencies
- `lib/features/auth/presentation/screens/login_screen.dart` - Firebase integration
- `lib/features/auth/presentation/screens/otp_verification_screen.dart` - Auto OTP fetch
- `lib/main.dart` - Route configuration
- `android/app/src/main/AndroidManifest.xml` - SMS permissions

## 🚀 Next Steps

1. **Complete Firebase Setup** (see Firebase Console Setup section above)
2. **Test on Real Device** with actual phone number
3. **Verify Auto OTP Fetch** works on Android
4. **Test Error Scenarios** (invalid OTP, timeout, etc.)
5. **Monitor Firebase Console** for usage and errors
6. **Consider Backend Integration** - You may want to sync Firebase auth with your backend

## 💡 Tips

### Getting App Signature:
The app signature is automatically generated. To get it:
```dart
final signature = await SmsAutoFill().getAppSignature;
print('App Signature: $signature');
```

### SMS Format for Auto-Fetch:
Include app signature in your SMS for auto-fetch to work:
```
<#> Your OTP is: 1234
FA+9qCX9VSu
```

### Debugging Issues:
- Check Firebase Console → Authentication → Sign-in methods → Phone (Enabled?)
- Verify SHA-1 fingerprint is correct
- Ensure `google-services.json` is updated
- Check Android permissions are granted
- Look for errors in Firebase Console logs

## 📞 Support

If you encounter issues:
1. Check Firebase Console logs
2. Review console output for error messages
3. Verify phone number format (+91XXXXXXXXXX)
4. Ensure Firebase Phone Auth is enabled
5. Confirm SHA-1 fingerprint is added
6. Check Android Play Services are installed

## 🔄 Rollback Instructions

If you need to revert to the old OTP system:
1. Restore previous login_screen.dart (uses authNotifierProvider)
2. Restore previous otp_verification_screen.dart (without Firebase)
3. Restore previous main.dart route configuration
4. Remove firebase_auth and sms_autofill from pubspec.yaml
5. Run `flutter pub get`
6. Remove SMS permissions from AndroidManifest.xml

---

**Last Updated:** $(date)
**Implementation Status:** ✅ Complete - Requires Firebase Console Configuration
