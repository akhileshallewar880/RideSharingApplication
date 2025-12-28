# 🔥 Firebase Setup Guide for Push Notifications

## Current Status
✅ Code is ready - FCM token storage and sync implemented  
❌ Firebase config files missing - Need to add for push notifications to work

## Error You're Seeing
```
⚠️ Firebase not initialized. Skipping FCM setup.
```

This means the app can't initialize Firebase Cloud Messaging because the configuration files are missing.

---

## 📱 Setup Steps

### 1. Create/Access Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing project
3. Add your app to the project

### 2. For Android (google-services.json)

1. In Firebase Console, click **"Add app"** → Select **Android**
2. Register your app:
   - **Package name**: `com.example.allapalli_ride` (or your actual package name from `android/app/build.gradle`)
   - **App nickname**: Allapalli Ride (optional)
   - **Debug signing certificate**: (optional for development)
3. Download `google-services.json`
4. Place it here: `mobile/android/app/google-services.json`

**File location:**
```
mobile/
  android/
    app/
      google-services.json  ← Place here
      build.gradle
```

### 3. For iOS (GoogleService-Info.plist)

1. In Firebase Console, click **"Add app"** → Select **iOS**
2. Register your app:
   - **Bundle ID**: Get from `ios/Runner.xcodeproj/project.pbxproj` (search for PRODUCT_BUNDLE_IDENTIFIER)
   - **App nickname**: Allapalli Ride (optional)
3. Download `GoogleService-Info.plist`
4. Open `ios/Runner.xcworkspace` in Xcode
5. Drag `GoogleService-Info.plist` into the `Runner` folder in Xcode
6. Make sure "Copy items if needed" is checked

**File location:**
```
mobile/
  ios/
    Runner/
      GoogleService-Info.plist  ← Place here
      Info.plist
```

### 4. Enable Cloud Messaging in Firebase

1. Go to Firebase Console → Your Project
2. Navigate to: **Project Settings** → **Cloud Messaging** tab
3. If you see "Enable Cloud Messaging API", click it
4. Note your **Server Key** (needed for backend if using legacy FCM)

---

## 🧪 Testing After Setup

1. **Clean and rebuild:**
   ```bash
   cd mobile
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Check logs for success:**
   ```
   ✅ Firebase initialized
   🔔 Initializing Notification Service...
   📱 FCM Token: <long_token_string>
   💾 FCM Token saved locally
   ✅ Notification Service initialized
   ```

3. **After login, check for:**
   ```
   🔄 Syncing FCM token with backend...
   ✅ FCM Token sent to backend successfully
   ```

4. **Verify in database:**
   ```sql
   SELECT Id, PhoneNumber, FCMToken 
   FROM Users 
   WHERE FCMToken IS NOT NULL;
   ```

---

## 🔐 Backend Firebase Setup (For Sending Notifications)

If you want to send push notifications from your backend, you also need:

### Option 1: Firebase Admin SDK (Recommended)

1. Go to Firebase Console → Project Settings → Service Accounts
2. Click **"Generate new private key"**
3. Save the JSON file securely
4. Place it in: `server/ride_sharing_application/firebase-adminsdk.json`
5. Add to `.gitignore` (DO NOT commit this file!)

### Option 2: Legacy Server Key

1. Go to Firebase Console → Project Settings → Cloud Messaging
2. Copy the **Server Key**
3. Store in environment variable or secure configuration

---

## 📋 Checklist

- [ ] Added `google-services.json` to `android/app/`
- [ ] Added `GoogleService-Info.plist` to `ios/Runner/`
- [ ] Ran `flutter clean && flutter pub get`
- [ ] Tested app - Firebase initializes successfully
- [ ] Logged in - FCM token sent to backend
- [ ] Verified token stored in database
- [ ] (Optional) Set up backend Firebase Admin SDK

---

## 🐛 Troubleshooting

### Still getting "Firebase not initialized" error?
- Check file names are exact: `google-services.json` and `GoogleService-Info.plist`
- Check file locations are correct
- Clean and rebuild: `flutter clean && flutter run`

### Token not being sent to backend?
- Make sure you're logged in (token sync happens after login)
- Check backend logs for authentication issues
- Verify backend is running and accessible

### Backend not saving token?
- Check backend logs for errors
- Verify `FCMToken` column exists in Users table
- Test the endpoint directly with Postman

---

## 📞 Need Help?

If you continue to have issues:
1. Check Flutter logs: Look for FCM-related errors
2. Check backend logs: Look for token update requests
3. Verify Firebase project settings match your app configuration
