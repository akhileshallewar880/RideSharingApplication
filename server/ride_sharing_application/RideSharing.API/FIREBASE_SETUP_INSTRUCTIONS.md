# Firebase Cloud Messaging (FCM) Setup Instructions

## Overview
The backend is now configured to send push notifications via Firebase Cloud Messaging. To enable this functionality, you need to add your Firebase service account key.

## Setup Steps

### 1. Get Service Account Key from Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create one if you haven't)
3. Click the gear icon ⚙️ → **Project Settings**
4. Navigate to **Service Accounts** tab
5. Click **Generate New Private Key**
6. Save the downloaded JSON file

### 2. Add Service Account Key to Project

Place the downloaded JSON file at:
```
/Users/akhileshallewar/project_dev/taxi-booking-app/server/ride_sharing_application/RideSharing.API/serviceAccountKey.json
```

**IMPORTANT:** Add this to `.gitignore` to keep it secure:
```bash
echo "serviceAccountKey.json" >> .gitignore
```

### 3. Verify Setup

When you run the API, you should see this log message:
```
✅ Firebase Admin SDK initialized successfully
```

If the file is missing, you'll see:
```
⚠️ Firebase service account key not found at: [path]
Firebase notifications will NOT be sent. Please add serviceAccountKey.json to enable push notifications.
```

## How It Works

### Backend Flow
1. When a booking is created in `RidesController`, the backend:
   - Fetches the user's FCM token from the database
   - Calls `FCMNotificationService.SendBookingConfirmationAsync()`
   - Sends the notification to Firebase
   - Firebase delivers it to the mobile device

### Mobile Flow
1. Mobile app receives the FCM notification
2. Mobile app saves it to local database via `POST /api/v1/notifications`
3. User sees the notification in their notification list

## Notification Types

The FCM service supports:
- ✅ `SendBookingConfirmationAsync()` - When booking is confirmed
- `SendRideStartedAsync()` - When ride starts
- `SendRideCompletedAsync()` - When ride ends
- `SendBookingCancelledAsync()` - When booking is cancelled
- `SendDriverAssignedAsync()` - When driver is assigned
- `SendPaymentReminderAsync()` - Payment reminders

## Testing

1. Create a booking via the mobile app or API
2. Check backend logs for:
   ```
   📱 Sending booking confirmation to FCM token...
   ✅ Booking confirmation sent successfully. MessageId: [id]
   ```
3. Verify notification appears on mobile device
4. Check that notification is saved to database

## Troubleshooting

### No FCM Token
```
⚠️ No FCM token found for user [guid]
```
**Solution:** Make sure the mobile app registers the FCM token and sends it to the backend.

### Firebase Not Initialized
```
⚠️ Firebase service account key not found
```
**Solution:** Add the `serviceAccountKey.json` file as described above.

### Notification Send Failed
```
❌ Failed to send booking confirmation notification
```
**Solution:** Check the exception details in the logs. Common issues:
- Invalid FCM token
- Token expired (user uninstalled/reinstalled app)
- Firebase quota exceeded
- Network issues

## Code Changes Made

### Files Modified:
1. ✅ `RideSharing.API/Services/Notification/FCMNotificationService.cs` - FCM integration
2. ✅ `RideSharing.API/Program.cs` - Service registration
3. ✅ `RideSharing.API/Controllers/RidesController.cs` - Notification sending after booking
4. ✅ `RideSharing.API/RideSharing.API.csproj` - FirebaseAdmin package added

### NuGet Packages Added:
- FirebaseAdmin v3.4.0
- Google.Apis.Auth v1.68.0
- Google.Api.Gax v4.8.0

## Security Notes

⚠️ **NEVER commit `serviceAccountKey.json` to version control**
- Add it to `.gitignore`
- Store it securely in production (Azure Key Vault, AWS Secrets Manager, etc.)
- Rotate keys periodically
- Use environment-specific keys (dev, staging, prod)
