# Allapalli Ride - Rural Taxi Booking App

A complete Flutter taxi booking application with animated UI/UX designed for rural and semi-urban Indian users. Features separate experiences for passengers and drivers with immersive animations and clean design system.

## 🎯 Features

### Passenger App
- **Animated Home Screen** - Map integration with pickup/dropoff search
- **Multiple Vehicle Types** - Auto, Bike, Car, Shared rides
- **Ride Booking** - Real-time ride matching and tracking
- **Ride History** - Timeline view of past rides
- **Payment Options** - Cash, UPI, Card, Wallet support
- **Ratings & Feedback** - Rate drivers after rides

### Driver App
- **Driver Dashboard** - Online/offline toggle, ride requests
- **Earnings Tracker** - Daily, weekly, monthly earnings with stats
- **Ride Management** - Accept, start, end rides
- **Performance Metrics** - Rating, acceptance rate, online hours
- **Payout History** - Track completed payouts

### Shared Features
- **Animated Splash Screen** - Logo transition animation
- **Onboarding Carousel** - Smooth page indicators and animations
- **Phone Authentication** - OTP-based login with validation
- **User Type Selection** - Choose between Passenger and Driver roles
- **Dark/Light Themes** - Complete theme support with system preference
- **Multi-language Support** - English, Hindi, Telugu, Marathi (framework ready)

## 🎨 Design System

### Theme Components
- **AppColors** - Comprehensive color palette for light/dark modes
- **TextStyles** - Typography system with display, heading, body, label styles
- **AppSpacing** - Consistent spacing and sizing system
- **AppTheme** - Complete Material 3 theme configuration

### Reusable Widgets
- **Buttons**: `PrimaryButton`, `SecondaryButton`, `RoundedIconButton`
- **Input Fields**: `CustomTextField`, `PasswordField`, `PhoneField`, `SearchField`
- **Loaders**: `AnimatedLoader`, `LoadingOverlay`, `ShimmerLoader`
- **Modals**: `CustomBottomSheet`, `SlideUpModal`, `CustomAlertDialog`
- **Cards**: `RideCard`, `DriverInfoCard`

## 📁 Project Structure

```
lib/
├── app/
│   ├── constants/
│   │   └── app_constants.dart       # App-wide constants
│   └── themes/
│       ├── app_colors.dart          # Color palette
│       ├── app_spacing.dart         # Spacing system
│       ├── app_theme.dart           # Theme configuration
│       └── text_styles.dart         # Typography
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       └── screens/
│   │           ├── splash_screen.dart
│   │           ├── onboarding_screen.dart
│   │           ├── login_screen.dart
│   │           ├── otp_verification_screen.dart
│   │           └── user_type_selection_screen.dart
│   ├── passenger/
│   │   └── presentation/
│   │       └── screens/
│   │           ├── passenger_home_screen.dart
│   │           └── ride_history_screen.dart
│   └── driver/
│       └── presentation/
│           └── screens/
│               ├── driver_dashboard_screen.dart
│               └── driver_earnings_screen.dart
├── shared/
│   └── widgets/
│       ├── buttons.dart             # Button components
│       ├── cards.dart               # Card components
│       ├── input_fields.dart        # Input components
│       ├── loaders.dart             # Loading components
│       └── modals.dart              # Modal components
└── main.dart                        # App entry point
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK >=3.3.2 <4.0.0
- Dart SDK >=3.3.2
- Android Studio / Xcode (for mobile development)
- VS Code with Flutter extension (recommended)

### Installation

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Run the app**
   ```bash
   # Run on default device
   flutter run
   
   # Run on specific device
   flutter run -d <device_id>
   
   # Run in release mode
   flutter run --release
   ```

3. **Build for production**
   ```bash
   # Android APK
   flutter build apk --release
   
   # Android App Bundle
   flutter build appbundle --release
   
   # iOS
   flutter build ios --release
   ```

### Available Devices
```bash
# List all connected devices
flutter devices

# Run on Android
flutter run -d android

# Run on iOS
flutter run -d ios

# Run on Web
flutter run -d chrome

# Run on macOS
flutter run -d macos
```

## 🎬 Animation Features

All screens include carefully crafted animations:
- **Duration**: <400ms for responsiveness
- **Types**: FadeIn, SlideY, SlideX, Scale, Shimmer
- **Libraries**: `flutter_animate`, `lottie`, `flutter_spinkit`

## 🗺️ Maps Integration

The app uses placeholder map views currently. To integrate real maps:

1. **Google Maps Setup**
   ```yaml
   # Uncomment in pubspec.yaml (already added)
   google_maps_flutter: ^2.6.1
   ```

2. **Add API Keys**
   - **Android**: Add to `android/app/src/main/AndroidManifest.xml`
     ```xml
     <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_API_KEY"/>
     ```
   
   - **iOS**: Add to `ios/Runner/AppDelegate.swift`
     ```swift
     GMSServices.provideAPIKey("YOUR_API_KEY")
     ```

3. **Replace Map Placeholders**
   - Update `PassengerHomeScreen` with `GoogleMap` widget
   - Update `DriverDashboardScreen` with `GoogleMap` widget

## 🔐 Authentication Flow

Current implementation uses phone number + OTP:
1. User enters phone number
2. OTP sent via SMS (backend integration needed)
3. OTP verification
4. User type selection (Passenger/Driver)
5. Navigate to respective dashboard

**TODO**: Integrate with backend authentication service

## 🎯 Backend Integration

The app is currently set up with UI/UX only. To connect to backend:

1. **Update Base URL** in `lib/app/constants/app_constants.dart`
   ```dart
   static const String baseUrl = 'YOUR_BACKEND_URL';
   ```

2. **Create API Services** (framework ready with Dio + Retrofit)
   - Add models in `lib/shared/models/`
   - Add repositories in feature folders
   - Implement API endpoints with Retrofit

3. **State Management** (Riverpod already set up)
   - Create providers for data management
   - Use `flutter_riverpod` for state updates

## 🌍 Localization (Ready)

Framework supports multiple languages. To add translations:

1. Add `flutter_localizations` to pubspec.yaml
2. Create `lib/l10n/` folder with ARB files
3. Generate translations
4. Update app to use localized strings

Supported languages defined in `AppConstants`:
- English (en)
- Hindi (hi)
- Telugu (te)
- Marathi (mr)

## 🎨 Customization

### Colors
Edit `lib/app/themes/app_colors.dart` to change:
- Brand colors (yellow/orange)
- Light/dark theme colors
- Status colors
- Map marker colors

### Typography
Edit `lib/app/themes/text_styles.dart` to adjust:
- Font sizes
- Font weights
- Line heights
- Letter spacing

### Spacing
Edit `lib/app/themes/app_spacing.dart` to modify:
- Padding values
- Border radius
- Icon sizes
- Button heights

## 📱 Platform-Specific Setup

### Android
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 34 (Android 14)
- Permissions needed: Location, Internet, Phone

### iOS
- Minimum iOS: 12.0
- Permissions needed: Location, Notifications
- Requires paid Apple Developer account for deployment

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

## 🐛 Known Issues & TODOs

### Current Limitations
- ✅ UI/UX implemented
- ⚠️ Backend integration needed
- ⚠️ Real map integration needed
- ⚠️ Payment gateway integration needed
- ⚠️ Real-time ride tracking (WebSocket/Firebase)
- ⚠️ Push notifications setup
- ⚠️ Analytics integration

### Next Steps
1. Set up backend API
2. Integrate Google Maps with real locations
3. Implement real-time ride tracking
4. Add payment gateway (Razorpay/Stripe)
5. Set up Firebase for notifications
6. Add crash reporting (Firebase Crashlytics)
7. Implement analytics (Firebase Analytics)
8. Add integration tests
9. Set up CI/CD pipeline
10. Prepare for production release

## 📦 Key Dependencies

- **flutter_riverpod**: State management
- **go_router**: Navigation (routes defined, ready to use)
- **flutter_animate**: Animations
- **lottie**: Animation assets
- **google_maps_flutter**: Map integration
- **geolocator**: Location services
- **dio**: HTTP client
- **retrofit**: API calls
- **hive**: Local storage
- **shared_preferences**: Simple storage
- **pin_code_fields**: OTP input
- **smooth_page_indicator**: Onboarding indicators
- **flutter_spinkit**: Loading animations
- **phosphor_flutter**: Icon library

## 🤝 Contributing

This is a starter project. To extend:
1. Add new screens in respective feature folders
2. Create reusable widgets in `lib/shared/widgets/`
3. Follow existing code patterns
4. Maintain consistent theming
5. Keep animations under 400ms
6. Test on both light and dark themes

## 📄 License

This project is part of a development portfolio. Update license as needed for production use.

## 🎯 Target Audience

- Rural and semi-urban Indian users
- Simple, intuitive interface
- Support for regional languages
- Optimized for low-end devices
- Works with 3G/4G networks

## 📞 Support

For issues or questions:
- Email: support@allapalliride.com (placeholder)
- Phone: +91-1234567890 (placeholder)

---

**Built with ❤️ using Flutter**

*Last Updated: November 8, 2025*
