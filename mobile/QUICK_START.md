# 🚀 Quick Start Guide - Allapalli Ride

## Run the App (Fastest Way)

```bash
# 1. Install dependencies (already done)
flutter pub get

# 2. Check available devices
flutter devices

# 3. Run on your device
flutter run
```

## 📱 Screen Navigation Flow

### Current Implementation

```
SplashScreen (Auto-navigates after 3s)
    ↓
OnboardingScreen (Swipe through 3 pages)
    ↓
LoginScreen (Enter phone number)
    ↓
OtpVerificationScreen (Enter 6-digit OTP)
    ↓
UserTypeSelectionScreen (Choose Passenger or Driver)
    ↓
PassengerHomeScreen OR DriverDashboardScreen
```

### Available Routes

You can test individual screens by updating `main.dart`:

```dart
// Change this line in main.dart:
home: const SplashScreen(),

// To any of these:
home: const OnboardingScreen(),
home: const LoginScreen(),
home: const PassengerHomeScreen(),
home: const DriverDashboardScreen(),
home: const RideHistoryScreen(),
home: const DriverEarningsScreen(),
```

## 🎨 Test Features

### 1. Theme Switching
The app automatically follows system theme. To test:
- **iOS Simulator**: Settings → Developer → Dark Appearance
- **Android Emulator**: Settings → Display → Dark theme
- **Physical Device**: System dark mode toggle

### 2. Animations
Watch for animations on:
- ✅ Splash screen logo (scale + fade)
- ✅ Onboarding pages (slide + fade)
- ✅ Login screen fields (slide up + fade)
- ✅ OTP input (fade in with animation)
- ✅ Bottom sheets (slide up from bottom)
- ✅ Cards (fade + slide)
- ✅ Buttons (shimmer effect on primary buttons)

### 3. Interactive Elements
Try these interactions:
- **Home Screen**: Type in pickup/dropoff fields
- **Vehicle Selection**: Tap different vehicle type chips
- **Online Toggle**: Switch driver online/offline status
- **OTP Timer**: Watch countdown and resend button
- **User Type**: Select passenger or driver cards

## 🔍 Quick Testing Checklist

- [ ] App launches without errors
- [ ] Splash animation plays smoothly
- [ ] Can swipe through onboarding
- [ ] Can enter phone number (validates 10 digits)
- [ ] OTP screen appears with countdown
- [ ] Can select user type (passenger/driver)
- [ ] Passenger home shows map placeholder
- [ ] Driver dashboard shows stats
- [ ] All screens adapt to dark/light theme
- [ ] Bottom sheets slide up smoothly
- [ ] Cards display properly
- [ ] Buttons are responsive to touch

## 🐛 Common Issues & Fixes

### Issue: "Unable to find devices"
```bash
# For iOS Simulator
open -a Simulator

# For Android Emulator
# Open Android Studio → AVD Manager → Start emulator
```

### Issue: "Package not found"
```bash
flutter clean
flutter pub get
```

### Issue: "Gradle build failed" (Android)
```bash
cd android
./gradlew clean
cd ..
flutter run
```

### Issue: "CocoaPods not found" (iOS)
```bash
cd ios
pod install
cd ..
flutter run
```

## 📸 Screenshots to Verify

Check these screens look good:
1. **Splash**: Yellow/orange gradient with taxi icon
2. **Onboarding**: 3 cards with icons and smooth indicators
3. **Login**: Phone input with yellow button
4. **OTP**: 6 PIN boxes with timer
5. **User Type**: 2 large selection cards
6. **Passenger Home**: Map placeholder + bottom panel with search
7. **Driver Dashboard**: Map with online toggle + stats cards
8. **Ride History**: Timeline-style ride cards
9. **Earnings**: Gradient card with stats grid

## 🎯 Quick Customization

### Change Primary Color
```dart
// lib/app/themes/app_colors.dart
static const Color primaryYellow = Color(0xFFYOURCOLOR);
```

### Change App Name
```dart
// lib/app/constants/app_constants.dart
static const String appName = 'Your App Name';

// android/app/src/main/AndroidManifest.xml
android:label="Your App Name"

// ios/Runner/Info.plist
<key>CFBundleName</key>
<string>Your App Name</string>
```

### Add Your Logo
Replace the icon in splash/home screens:
```dart
// lib/features/auth/presentation/screens/splash_screen.dart
const Icon(Icons.local_taxi, ...) 
// Change to your logo widget
```

## 🚀 Next Steps After Testing

1. **Connect Backend**
   - Update `baseUrl` in `app_constants.dart`
   - Implement API services
   - Add authentication logic

2. **Add Real Maps**
   - Get Google Maps API key
   - Replace map placeholders
   - Implement location tracking

3. **Add Real Data**
   - Replace mock data with API calls
   - Implement state management with Riverpod
   - Add local storage with Hive

4. **Add Features**
   - Payment integration
   - Push notifications
   - Real-time tracking
   - Chat functionality

## 📚 Learning Resources

- **Flutter Docs**: https://docs.flutter.dev
- **Riverpod**: https://riverpod.dev
- **Flutter Animate**: https://pub.dev/packages/flutter_animate
- **Google Maps**: https://pub.dev/packages/google_maps_flutter

## ✨ Pro Tips

1. **Hot Reload**: Press `r` in terminal while app is running
2. **Hot Restart**: Press `R` to restart with new data
3. **Debug Paint**: Press `p` to see widget boundaries
4. **Performance**: Press `P` to show performance overlay
5. **Screenshot**: Press `s` to take screenshot

---

**Ready to code? Start with** `flutter run` **🎉**
