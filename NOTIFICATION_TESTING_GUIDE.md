# Quick Testing Guide - Push Notifications

## Prerequisites
- [ ] Firebase service account key downloaded and placed at `RideSharing.API/serviceAccountKey.json`
- [ ] Backend building successfully
- [ ] Mobile app has FCM token registered
- [ ] User has an FCM token in the database

## Step-by-Step Testing

### 1. Start the Backend

```bash
cd /Users/akhileshallewar/project_dev/taxi-booking-app/server/ride_sharing_application
dotnet run --project RideSharing.API
```

**Look for:**
```
✅ Firebase Admin SDK initialized successfully
```

If you see this instead, notifications won't be sent:
```
⚠️ Firebase service account key not found - notifications disabled
```

### 2. Check User Has FCM Token

```sql
SELECT Id, PhoneNumber, FCMToken 
FROM Users 
WHERE PhoneNumber = 'YOUR_TEST_USER_PHONE';
```

**Expected:** FCMToken should NOT be null or empty.

If it's null, the mobile app hasn't registered the token yet. Open the app and it should register automatically.

### 3. Create a Test Booking

**Option A: Via Mobile App**
1. Open the mobile app
2. Search for a ride
3. Select a ride
4. Book it

**Option B: Via API (Postman/curl)**
```bash
curl -X POST http://localhost:5000/api/v1/rides/book \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "rideId": "RIDE_GUID",
    "passengerCount": 1,
    "pickupLocation": {
      "address": "Location A",
      "latitude": 20.0,
      "longitude": 79.0
    },
    "dropoffLocation": {
      "address": "Location B",
      "latitude": 20.1,
      "longitude": 79.1
    }
  }'
```

### 4. Check Backend Logs

**Success Logs:**
```
📱 Sending booking confirmation to FCM token: ABC123...
✅ Booking confirmation sent successfully. MessageId: projects/...
```

**Warning Logs:**
```
⚠️ No FCM token found for user {guid}
```
→ User doesn't have FCM token registered. Make sure mobile app is running and has registered the token.

**Error Logs:**
```
❌ Failed to send booking confirmation notification
```
→ Check the exception details. Common causes:
- Invalid FCM token
- Firebase quota exceeded
- Network issues
- Invalid serviceAccountKey.json

### 5. Verify Mobile App Receives Notification

1. Check mobile device notification tray
2. You should see: **"Booking Confirmed! 🎉"**
3. Body: **"Your booking is confirmed. OTP: XXXX"**

### 6. Verify Notification Saved to Database

```sql
SELECT * FROM Notifications 
WHERE UserId = 'YOUR_USER_GUID'
ORDER BY CreatedAt DESC;
```

**Expected:** New notification record with:
- Title: "Booking Confirmed! 🎉"
- Type: "booking_confirmed"
- Data: Contains booking details
- IsRead: false
- CreatedAt: Recent timestamp

### 7. Check Mobile App Notification List

1. Open mobile app
2. Go to notifications screen
3. Verify the booking confirmation appears in the list

## Troubleshooting

### Problem: No notification received on mobile

**Check:**
1. Is FCM token in database?
   ```sql
   SELECT FCMToken FROM Users WHERE Id = 'USER_GUID';
   ```
2. Does backend log show "Sending booking confirmation"?
3. Does backend log show success or error?
4. Is mobile app in foreground or background?
5. Are notifications enabled in mobile device settings?

### Problem: Backend log shows "serviceAccountKey not found"

**Solution:**
1. Download key from Firebase Console
2. Place at: `RideSharing.API/serviceAccountKey.json`
3. Restart backend

### Problem: Backend log shows "No FCM token found"

**Solution:**
1. Open mobile app
2. Check mobile app logs for FCM token registration
3. Verify token is sent to backend
4. Query database to confirm token is saved

### Problem: "Invalid FCM token" error

**Solution:**
1. User may have uninstalled/reinstalled app
2. Delete old token from database
3. Mobile app should register new token on next launch
4. Try booking again

## Expected Flow Diagram

```
┌─────────────┐
│ Mobile App  │
│ Books Ride  │
└──────┬──────┘
       │
       ▼
┌─────────────────┐
│ Backend         │
│ Creates Booking │
└──────┬──────────┘
       │
       ▼
┌────────────────────┐
│ Backend Fetches    │
│ User's FCM Token   │
└──────┬─────────────┘
       │
       ▼
┌─────────────────────────┐
│ Backend Sends to        │
│ Firebase Cloud Messaging│
└──────┬──────────────────┘
       │
       ▼
┌──────────────────┐
│ Firebase         │
│ Delivers to      │
│ Mobile Device    │
└──────┬───────────┘
       │
       ▼
┌─────────────────┐
│ Mobile App      │
│ Receives        │
│ Notification    │
└──────┬──────────┘
       │
       ▼
┌─────────────────┐
│ Mobile App      │
│ Saves to DB     │
│ via POST        │
└─────────────────┘
```

## Quick Verification Commands

```bash
# 1. Check if backend builds
cd /Users/akhileshallewar/project_dev/taxi-booking-app/server/ride_sharing_application
dotnet build

# 2. Check if serviceAccountKey.json exists
ls -la RideSharing.API/serviceAccountKey.json

# 3. Start backend
dotnet run --project RideSharing.API

# 4. Check logs for Firebase initialization
# Look for: "✅ Firebase Admin SDK initialized successfully"
```

## Success Criteria

✅ Backend builds without errors
✅ serviceAccountKey.json present
✅ Backend logs show Firebase initialized
✅ User has FCM token in database
✅ Booking creation succeeds
✅ Backend logs show notification sent
✅ Mobile device receives push notification
✅ Notification appears in device notification tray
✅ Notification saved to database
✅ Notification appears in mobile app list

## Next Steps After Success

Once notifications are working:

1. **Add More Notification Types**
   - Ride started
   - Ride completed
   - Booking cancelled
   - Driver assigned

2. **Add Notification Settings**
   - Let users enable/disable notification types
   - Quiet hours
   - Do not disturb

3. **Add Analytics**
   - Track notification delivery rate
   - Track notification open rate
   - Track user engagement

4. **Production Setup**
   - Use Azure Key Vault for serviceAccountKey.json
   - Set up monitoring/alerts
   - Configure rate limiting
   - Set up Firebase quota alerts
