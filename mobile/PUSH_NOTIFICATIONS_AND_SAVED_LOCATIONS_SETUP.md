# Push Notifications and Saved Locations - Setup Guide

## ✅ Features Implemented

### 1. **Push Notifications (Firebase Cloud Messaging)**
- FCM token management
- Foreground, background, and terminated state notifications
- Local notifications with custom actions
- Notification permissions handling (iOS & Android 13+)
- Topic subscriptions for broadcast messages
- Deep linking based on notification type

### 2. **Saved Locations**
- Save Home, Work, and Favorite locations
- Quick access from location search screen
- Edit and delete saved locations
- Recently used tracking
- Local storage using Hive
- Export to LocationSuggestion format for backward compatibility

---

## 🔧 Setup Instructions

### Step 1: Install Dependencies

Run the following command in the `mobile/` directory:

```bash
flutter pub get
```

This will install:
- `firebase_core: ^2.27.0`
- `firebase_messaging: ^14.7.19`
- `flutter_local_notifications: ^17.0.0`
- `uuid: ^4.3.3`

### Step 2: Generate Hive Adapters

The `SavedLocation` model uses Hive for local storage. Generate the adapter:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will create `saved_location.g.dart` with the Hive type adapter.

### Step 3: Firebase Setup

#### **For Android:**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing one
3. Add Android app:
   - Package name: `com.example.allapalli_ride` (or your actual package name)
   - Download `google-services.json`
   - Place it in `android/app/google-services.json`

4. Update `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

5. Update `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'

dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

6. Update `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    
    <application>
        <!-- Default notification channel for FCM -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="allapalli_ride_channel" />
        
        <!-- Default notification icon -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@mipmap/ic_launcher" />
    </application>
</manifest>
```

#### **For iOS:**

1. In Firebase Console, add iOS app:
   - Bundle ID: from `ios/Runner.xcodeproj/project.pbxproj`
   - Download `GoogleService-Info.plist`
   - Add to `ios/Runner/` using Xcode

2. Update `ios/Podfile`:
```ruby
platform :ios, '13.0'

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  pod 'Firebase/Messaging'
end
```

3. Run:
```bash
cd ios
pod install
cd ..
```

4. Enable Push Notifications in Xcode:
   - Open `ios/Runner.xcworkspace`
   - Select Runner target → Signing & Capabilities
   - Click + Capability → Push Notifications
   - Click + Capability → Background Modes
   - Check "Remote notifications"

5. Update `ios/Runner/AppDelegate.swift`:
```swift
import UIKit
import Flutter
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### Step 4: Testing Push Notifications

#### **Test with Firebase Console:**

1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter:
   - Notification title: "Test Notification"
   - Notification text: "Testing FCM integration"
4. Click "Test on device"
5. Enter your FCM token (printed in console logs)
6. Send test message

#### **Test Programmatically:**

```dart
// In your app, get the FCM token
final notificationService = NotificationService();
final token = notificationService.fcmToken;
print('FCM Token: $token');

// Show a local notification
await notificationService.showLocalNotification(
  title: 'Test Notification',
  body: 'This is a test notification',
  data: {'type': 'test', 'message': 'Hello!'},
);
```

---

## 📱 Usage Examples

### Saved Locations

#### **Save a location:**

```dart
// From LocationSearchScreen, long-press a search result
// Or use the save button when viewing location details

// Programmatically:
await ref.read(savedLocationNotifierProvider.notifier).saveLocation(
  name: 'Mom\'s House',
  address: '123 Main St, Allapalli',
  latitude: 20.0123,
  longitude: 79.4567,
  type: SavedLocationType.favorite,
);
```

#### **Access saved locations:**

```dart
final savedLocations = ref.watch(savedLocationNotifierProvider);

final homeLocation = ref.read(savedLocationNotifierProvider.notifier).getHomeLocation();
final workLocation = ref.read(savedLocationNotifierProvider.notifier).getWorkLocation();
final favorites = ref.read(savedLocationNotifierProvider.notifier).getFavoriteLocations();
```

#### **Delete a location:**

```dart
await ref.read(savedLocationNotifierProvider.notifier).deleteLocation(locationId);
```

### Push Notifications

#### **Subscribe to topics:**

```dart
final notificationService = ref.read(notificationServiceProvider);

// Subscribe to ride updates for passenger
await notificationService.subscribeToTopic('passenger_${userId}');

// Subscribe to general announcements
await notificationService.subscribeToTopic('general_announcements');
```

#### **Handle notification taps:**

Notifications are automatically routed based on the `type` field in data:

- `booking_confirmed` → Booking details screen
- `ride_started` → Live tracking screen
- `ride_completed` → Ride history / rating screen
- `booking_cancelled` → Cancellation details
- `payment_due` → Payment screen
- `promo_offer` → Offers screen

#### **Listen to messages in real-time:**

```dart
final notificationService = ref.read(notificationServiceProvider);

notificationService.messageStream.listen((RemoteMessage message) {
  print('New message: ${message.notification?.title}');
  // Update UI, show in-app notification, etc.
});
```

---

## 🔔 Backend Integration

### Send FCM Notification from Backend

You'll need to update your backend to send FCM notifications:

```csharp
// Add NuGet package: FirebaseAdmin

using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;

public class NotificationService
{
    private readonly FirebaseMessaging _messaging;
    
    public NotificationService()
    {
        var credential = GoogleCredential.FromFile("path/to/serviceAccountKey.json");
        var app = FirebaseApp.Create(new AppOptions
        {
            Credential = credential
        });
        _messaging = FirebaseMessaging.GetMessaging(app);
    }
    
    public async Task SendBookingConfirmationAsync(string fcmToken, Booking booking)
    {
        var message = new Message
        {
            Token = fcmToken,
            Notification = new Notification
            {
                Title = "Booking Confirmed! 🎉",
                Body = $"Your ride on {booking.TravelDate:MMM dd} is confirmed. OTP: {booking.OTP}"
            },
            Data = new Dictionary<string, string>
            {
                { "type", "booking_confirmed" },
                { "bookingId", booking.Id.ToString() },
                { "otp", booking.OTP }
            },
            Android = new AndroidConfig
            {
                Priority = Priority.High,
                Notification = new AndroidNotification
                {
                    Icon = "ic_notification",
                    Color = "#FFD700",
                    Sound = "default"
                }
            },
            Apns = new ApnsConfig
            {
                Aps = new Aps
                {
                    Sound = "default",
                    Badge = 1
                }
            }
        };
        
        await _messaging.SendAsync(message);
    }
    
    public async Task SendRideStartedAsync(string fcmToken, Guid rideId, string bookingId)
    {
        var message = new Message
        {
            Token = fcmToken,
            Notification = new Notification
            {
                Title = "Your ride has started! 🚗",
                Body = "Track your ride in real-time"
            },
            Data = new Dictionary<string, string>
            {
                { "type", "ride_started" },
                { "rideId", rideId.ToString() },
                { "bookingId", bookingId }
            }
        };
        
        await _messaging.SendAsync(message);
    }
}
```

### API Endpoint to Save FCM Token

Add an endpoint to your backend:

```csharp
[HttpPost("fcm-token")]
[Authorize]
public async Task<IActionResult> UpdateFCMToken([FromBody] UpdateFCMTokenRequest request)
{
    var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    if (string.IsNullOrEmpty(userId))
        return Unauthorized();
    
    var user = await _context.Users.FindAsync(Guid.Parse(userId));
    if (user == null)
        return NotFound();
    
    user.FCMToken = request.Token;
    await _context.SaveChangesAsync();
    
    return Ok();
}

public class UpdateFCMTokenRequest
{
    public string Token { get; set; }
}
```

---

## 🧪 Testing Checklist

### Saved Locations:
- [ ] Save home location
- [ ] Save work location
- [ ] Save multiple favorite locations
- [ ] Edit saved location
- [ ] Delete saved location
- [ ] Select saved location from search screen
- [ ] Verify last used timestamp updates
- [ ] Test persistence after app restart

### Push Notifications:
- [ ] Request permission on first launch
- [ ] Receive foreground notifications
- [ ] Receive background notifications
- [ ] Receive notifications when app is terminated
- [ ] Tap notification to navigate to correct screen
- [ ] Local notification display works
- [ ] FCM token is sent to backend
- [ ] Subscribe/unsubscribe from topics

---

## 🐛 Troubleshooting

### Issue: "Firebase not initialized"
**Solution:** Make sure Firebase.initializeApp() completes before accessing any Firebase service.

### Issue: "No notification received on iOS"
**Solution:** 
1. Check Push Notifications capability is enabled in Xcode
2. Ensure APNs certificate is configured in Firebase Console
3. Test on a physical device (simulator doesn't support push notifications)

### Issue: "Saved locations not persisting"
**Solution:**
1. Run `flutter pub run build_runner build` to generate Hive adapter
2. Check that SavedLocationAdapter is registered in main.dart
3. Ensure Hive.initFlutter() completes before accessing saved locations

### Issue: "Permission denied on Android 13+"
**Solution:** Add `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` to AndroidManifest.xml

---

## 📚 Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Local Notifications Plugin](https://pub.dev/packages/flutter_local_notifications)
- [Hive Documentation](https://docs.hivedb.dev/)
- [Flutter Permission Handler](https://pub.dev/packages/permission_handler)

---

## 🎯 Next Steps

1. **Run `flutter pub get`** to install dependencies
2. **Generate Hive adapters** with build_runner
3. **Add Firebase configuration files** (google-services.json & GoogleService-Info.plist)
4. **Update backend** to send FCM notifications on ride events
5. **Test end-to-end** notification flow
6. **Add analytics** to track notification engagement

---

**Questions or issues?** Check the console logs for detailed error messages and troubleshooting hints.
