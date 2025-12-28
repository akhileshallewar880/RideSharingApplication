# 🚀 Quick Start - Push Notifications

## Testing All Notifications

### 1. Passenger Notifications

#### Test Booking Confirmed
```bash
# 1. Open mobile app as passenger
# 2. Search and book a ride
# 3. ✅ You should see: "Booking Confirmed! 🎉"
```

#### Test Ride Started
```bash
# 1. Book a ride (note the OTP)
# 2. Driver opens app and verifies your OTP
# 3. ✅ You should see: "Your ride has started! 🚗"
```

#### Test Ride Completed
```bash
# 1. Complete full ride flow (book → OTP → ride)
# 2. Driver completes trip
# 3. ✅ You should see: "Ride Completed! ✅"
```

#### Test Booking Cancelled
```bash
# 1. Book a ride
# 2. Cancel it from your bookings
# 3. ✅ You should see: "Booking Cancelled ❌"
```

### 2. Driver Notifications

#### Test New Booking
```bash
# 1. Open mobile app as driver
# 2. Schedule a new ride
# 3. Have another user book your ride
# 4. ✅ You should see: "New Booking Received! 🎉"
```

#### Test Booking Cancelled
```bash
# 1. Have a passenger book your ride
# 2. Passenger cancels the booking
# 3. ✅ You should see: "Booking Cancelled ❌"
```

## Debug Commands

### Check Backend Logs
```bash
cd server/ride_sharing_application
dotnet watch run --project RideSharing.API
```

Look for:
- ✅ Firebase Admin SDK initialized successfully
- 📤 Preparing to send notification
- ✅ Booking confirmation sent successfully!

### Check Mobile Logs
```bash
cd mobile
flutter run
```

Look for:
- 🔔 Initializing Notification Service...
- ✅ FCM Token: ...
- 📨 Foreground message received
- ✅ Local notification shown successfully!

## Quick Troubleshooting

### Notifications Not Appearing?

1. **Check Firebase initialization**
   ```bash
   # Backend logs should show:
   ✅ Firebase Admin SDK initialized successfully
   ```

2. **Check FCM token**
   ```bash
   # Mobile logs should show:
   ✅ FCM Token: [long token string]
   ```

3. **Check permissions**
   ```bash
   # For Android 13+, check Settings > Apps > YourApp > Notifications
   # Should be enabled
   ```

4. **Check notification icon**
   ```dart
   // Should be using:
   icon: '@mipmap/ic_launcher'
   ```

### Backend Not Sending?

1. **Check serviceAccountKey.json exists**
   ```bash
   ls server/ride_sharing_application/RideSharing.API/serviceAccountKey.json
   ```

2. **Check FCM service is injected**
   ```csharp
   // In controller constructor:
   private readonly FCMNotificationService _fcmService;
   ```

3. **Check user has FCM token in database**
   ```sql
   SELECT FCMToken FROM Users WHERE Id = 'user-guid';
   ```

### Mobile Not Receiving?

1. **Hot restart the app**
   ```bash
   # In Flutter terminal, press 'R'
   # Or run: flutter run
   ```

2. **Check notification channel exists**
   ```dart
   // Should see in logs:
   ✅ Android notification channel created
   ```

3. **Test with debug notification**
   ```dart
   // Call from UI:
   NotificationService().showTestNotification()
   ```

## API Endpoints

### Save FCM Token
```http
POST /api/v1/notifications/fcm-token
Authorization: Bearer {token}
Content-Type: application/json

{
  "token": "fcm-device-token-here"
}
```

### Get Notifications
```http
GET /api/v1/notifications
Authorization: Bearer {token}
```

### Mark as Read
```http
PUT /api/v1/notifications/{id}/read
Authorization: Bearer {token}
```

## Files Reference

### Backend
- Service: `server/ride_sharing_application/RideSharing.API/Services/Notification/FCMNotificationService.cs`
- Config: `server/ride_sharing_application/RideSharing.API/serviceAccountKey.json`
- Integration: 
  - `RidesController.cs` (BookRide, CancelBooking)
  - `DriverRidesController.cs` (VerifyOtp, CompleteTrip)

### Mobile
- Service: `mobile/lib/core/services/notification_service.dart`
- Config: 
  - `mobile/android/app/google-services.json`
  - `mobile/android/app/src/main/AndroidManifest.xml`

## Next Steps

After testing all notifications:

1. **Implement navigation** in `notification_service.dart`:
   ```dart
   void _navigateToBookingDetails(String? bookingId) {
     context.go('/bookings/$bookingId');
   }
   ```

2. **Add custom notification sounds**
   ```dart
   sound: RawResourceAndroidNotificationSound('notification_sound')
   ```

3. **Implement notification badges**
   ```dart
   badge: unreadCount
   ```

4. **Add notification preferences**
   - Let users mute certain notification types
   - Allow custom notification sounds
   - Schedule quiet hours

## Support

For detailed implementation guide, see:
- [NOTIFICATION_SYSTEM_COMPLETE.md](./NOTIFICATION_SYSTEM_COMPLETE.md)
- [PUSH_NOTIFICATIONS_FIX_COMPLETE.md](./PUSH_NOTIFICATIONS_FIX_COMPLETE.md)
