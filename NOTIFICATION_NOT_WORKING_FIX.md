# 🔔 Notification Not Working - Fix Guide

## Issue
Notifications were working before but stopped after changing the notification icon.

## Root Cause
When you change `AndroidManifest.xml` (like we did for the notification icon), the app needs a **full rebuild**, not just hot reload or hot restart.

## Solution Steps

### 1. **Stop All Running Instances**
```bash
# Stop the Flutter app
# In the terminal where flutter run is running, press 'q'

# Or force kill
pkill -f "flutter run"
```

### 2. **Clean Build**
```bash
cd /Users/akhileshallewar/project_dev/RideBuisnessCodePrivate/vanyatra_rural_ride_booking/mobile

# Clean all build artifacts
flutter clean

# Get dependencies
flutter pub get
```

### 3. **Full Rebuild**
```bash
# Build and install the app fresh
flutter run
```

### 4. **Check Notification Permissions**
After the app launches:
1. Go to **Android Settings**
2. **Apps** → **VanYatra** (or your app name)
3. **Notifications**
4. Verify notifications are **enabled**
5. If disabled, **enable** them

### 5. **Test Notification**
Book a ride and check if you receive the notification.

## Additional Checks

### Check Backend Logs
```bash
cd /Users/akhileshallewar/project_dev/RideBuisnessCodePrivate/vanyatra_rural_ride_booking/server/ride_sharing_application
dotnet run --project RideSharing.API
```

Look for:
- ✅ `Firebase Admin SDK initialized successfully`
- ✅ `Sending booking confirmation to passenger`
- ✅ `Booking confirmation sent successfully`

### Check Mobile Logs
In Flutter console, look for:
- ✅ `Firebase initialized successfully`
- ✅ `Notification Service initialized`
- ✅ `FCM Token: [token]`
- ✅ `Android notification channel created`
- ✅ `Foreground message received`

## Verification

After rebuilding, you should see:
1. **Notification icon** - VanYatra van icon in status bar
2. **Color tint** - Yellow/orange color (#FFD700)
3. **Large icon** - VanYatra app logo
4. **Title** - "Booking Confirmed! 🎉"
5. **Body** - "Your booking is confirmed. OTP: XXXX"

## Troubleshooting

### Still Not Working?

#### 1. Check FCM Token
```dart
// In your app, print the token
final notificationService = NotificationService();
print('FCM Token: ${notificationService.fcmToken}');
```

#### 2. Test with Firebase Console
1. Go to Firebase Console → Cloud Messaging
2. Send test message with your FCM token
3. If this works, backend is the issue
4. If this doesn't work, mobile setup is the issue

#### 3. Check Backend Database
```sql
-- Check if user has FCM token stored
SELECT Id, PhoneNumber, FCMToken 
FROM Users 
WHERE PhoneNumber = 'YOUR_PHONE_NUMBER';
```

#### 4. Manual Notification Test
```dart
// In your app, test local notification
final notificationService = NotificationService();
await notificationService.showTestNotification();
```

If test notification works but booking notification doesn't:
- ❌ Backend not sending
- ❌ User's FCM token not in database
- ❌ Backend Firebase not initialized

If test notification doesn't work:
- ❌ Notification permissions denied
- ❌ Notification service not initialized
- ❌ App needs full rebuild

## Files Changed

1. **AndroidManifest.xml** - Changed notification icon to `ic_stat_vanyatra`
2. **notification_service.dart** - Updated icon references (3 locations)
3. **FCMNotificationService.cs** - Updated backend icon reference (2 files)

## Important Notes

- **AndroidManifest.xml changes require full rebuild**
- Hot reload/restart is NOT enough
- Must run `flutter clean` before rebuilding
- Check notification permissions in device settings
- Backend must have `serviceAccountKey.json`
- User must have FCM token in database

## Status
After following these steps, notifications should work again with the new VanYatra icon! 🚐
