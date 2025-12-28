# 🐛 Debug: Notifications Not Received Issue

## Current Status

✅ **Backend Fixed:**
- Firebase Admin SDK initialized successfully
- FCM service registered and working
- serviceAccountKey.json is present and valid
- Backend logs: `✅ Firebase Admin SDK initialized successfully`

⚠️ **Issue:**
- Notifications are saved to database ✅
- But NOT received on mobile device ❌

## Root Cause Analysis

Since notifications are being **saved to the database**, this means:
1. ✅ Mobile app receives SOMETHING
2. ✅ Mobile app saves it via `POST /api/v1/notifications`
3. ❌ But push notification not appearing on device

This indicates **backend may not be sending FCM notifications at all**, or the FCM token is invalid/empty.

## Debugging Steps

### Step 1: Check Backend Logs When Booking is Created

Create a booking and watch for these logs:

**Expected Success Logs:**
```
[INFO] 📱 Sending booking confirmation to FCM token: ABC123...
[INFO] 🔔 SendBookingConfirmationAsync called - IsInitialized: True, MessagingNull: False
[INFO] 📤 Preparing to send notification to token: ABC123...
[INFO] 📨 Sending FCM message...
[INFO] ✅ Booking confirmation sent successfully! MessageId: projects/...
```

**Warning if No FCM Token:**
```
[WARN] ⚠️ No FCM token found for user {guid}. Notification not sent.
```

**Error if Firebase Issue:**
```
[ERROR] ❌ Failed to send booking confirmation notification
```

### Step 2: Check FCM Token in Database

The most likely issue is the **FCM token is missing or invalid**.

**Check via API:**
Create an endpoint or query to check your FCM token:

```sql
-- Connect to database and run:
SELECT Id, PhoneNumber, FCMToken, CreatedAt 
FROM Users 
WHERE PhoneNumber = 'YOUR_PHONE_NUMBER';
```

**Expected:**
- FCMToken should be a long string (~150+ characters)
- Should NOT be NULL or empty

**If FCMToken is NULL/empty:**
- Mobile app hasn't registered FCM token with backend
- Check mobile app FCM registration code

### Step 3: Verify Mobile App Sends FCM Token to Backend

Check mobile app code - it should:
1. Get FCM token from Firebase
2. Send it to backend via API (usually `POST /api/v1/users/fcm-token` or similar)
3. Backend saves it in Users.FCMToken column

**Mobile app should have code like:**
```dart
// Get FCM token
String? fcmToken = await FirebaseMessaging.instance.getToken();

// Send to backend
await dio.post('/api/v1/users/update-fcm-token', data: {
  'fcmToken': fcmToken
});
```

### Step 4: Check if Backend is Actually Calling FCM Service

Add a breakpoint or check logs at:
- `RidesController.cs` line ~383: Where it calls `SendBookingConfirmationAsync`
- Look for log: `📱 Sending booking confirmation to FCM token...`

If you DON'T see this log, the code isn't being executed (maybe different booking endpoint?)

### Step 5: Test FCM Token Manually

You can test if the FCM token works by using Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Cloud Messaging → New campaign → Notification message
3. Enter title and body
4. Click "Send test message"
5. Paste FCM token
6. Send

**If notification appears:** Token is valid, backend should work
**If notification doesn't appear:** Token is invalid (expired, wrong device, etc.)

## Quick Fix Actions

### Action 1: Add FCM Token Update Endpoint

Check if backend has an endpoint to update FCM token:

```csharp
[HttpPost("update-fcm-token")]
public async Task<IActionResult> UpdateFCMToken([FromBody] UpdateFCMTokenRequest request)
{
    var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    var user = await _context.Users.FindAsync(Guid.Parse(userId));
    
    if (user != null)
    {
        user.FCMToken = request.FCMToken;
        await _context.SaveChangesAsync();
        _logger.LogInformation($"✅ FCM token updated for user {userId}");
        return Ok(new { message = "FCM token updated successfully" });
    }
    
    return NotFound();
}
```

### Action 2: Check Mobile App FCM Registration

Mobile app should register token on:
- App startup
- After login
- When token refreshes

```dart
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
  // Send new token to backend
  updateFCMToken(newToken);
});
```

### Action 3: Verify Notification Saved to DB Flow

The fact that notifications are saved to DB means:
1. Mobile app receives a notification (maybe via HTTP polling or local notification)
2. Mobile app calls `POST /api/v1/notifications` to save it

**Check:** Is mobile app creating local notifications and saving them, rather than receiving FCM push notifications?

## Testing Checklist

- [ ] Backend shows: `✅ Firebase Admin SDK initialized successfully`
- [ ] Create a booking via mobile app
- [ ] Check backend logs for: `📱 Sending booking confirmation to FCM token`
- [ ] Check backend logs for: `✅ Booking confirmation sent successfully`
- [ ] If "No FCM token found" warning appears → FCM token not in database
- [ ] Check Users table for FCMToken value
- [ ] If FCMToken is NULL → Mobile app not sending token to backend
- [ ] If FCMToken exists → Check if it's a valid 150+ character string
- [ ] Test FCM token manually in Firebase Console
- [ ] Check mobile device notification permissions are enabled
- [ ] Check mobile app is not in "Do Not Disturb" mode

## Common Issues

### Issue 1: FCM Token is NULL
**Cause:** Mobile app hasn't sent FCM token to backend
**Fix:** Ensure mobile app calls update-fcm-token API after login

### Issue 2: FCM Token is Invalid/Expired
**Cause:** Token expired, user uninstalled/reinstalled app
**Fix:** Mobile app should refresh token and update backend

### Issue 3: Backend Not Calling FCM Service
**Cause:** Wrong booking endpoint being called
**Fix:** Check which endpoint mobile app uses for booking

### Issue 4: Firebase Project Mismatch
**Cause:** serviceAccountKey.json is from different Firebase project than mobile app
**Fix:** Ensure same Firebase project for both backend and mobile app

### Issue 5: Notification Permissions Disabled
**Cause:** User denied notification permissions
**Fix:** Check device settings and request permissions in app

## Next Steps

1. **First:** Check backend logs when creating a booking
2. **Second:** Check if FCM token exists in database for your user
3. **Third:** If token missing, check mobile app FCM registration code
4. **Fourth:** Test FCM token manually in Firebase Console

Once you know where the issue is, let me know and I'll help fix it!

## Expected vs Actual Flow

### Expected Flow (Should Happen):
```
User Books Ride
  ↓
Backend Creates Booking
  ↓
Backend Fetches User.FCMToken
  ↓
Backend Calls Firebase API with Token
  ↓
Firebase Sends Push Notification to Device
  ↓
Mobile Device Shows Notification
  ↓
Mobile App Receives FCM Notification
  ↓
Mobile App Saves to Database
```

### Actual Flow (What's Happening):
```
User Books Ride
  ↓
Backend Creates Booking
  ↓
❓ Backend Tries to Send FCM?
  ↓
❌ Push Notification NOT Received on Device
  ↓
✅ But Notification IS Saved to Database
```

This suggests notifications are being created locally by the app, not received via FCM.
