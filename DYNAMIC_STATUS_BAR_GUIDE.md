# Dynamic Status Bar Implementation Guide

## Quick Reference

Apply dynamic status bar to any screen in 3 easy steps:

### Method 1: Using DynamicStatusBarMixin (Recommended)

```dart
// 1. Import the mixin
import 'package:allapalli_ride/core/utils/dynamic_status_bar.dart';

// 2. Add mixin to your State class
class _MyScreenState extends State<MyScreen> with DynamicStatusBarMixin {
  
  // 3. Set status bar color in build method
  @override
  Widget build(BuildContext context) {
    final myHeaderColor = Colors.blue; // Your header color
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateStatusBarWithColor(myHeaderColor);
    });
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: myHeaderColor,
        // ...
      ),
      body: // Your content
    );
  }
}
```

### Method 2: Using DynamicStatusBarWrapper

```dart
// 1. Import the wrapper
import 'package:allapalli_ride/core/utils/dynamic_status_bar.dart';

// 2. Wrap your entire screen
return DynamicStatusBarWrapper(
  statusBarColor: Colors.blue,
  child: Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.blue,
      // ...
    ),
    body: // Your content
  ),
);
```

---

## Screens to Update

### Already Implemented ✅
- ✅ `passenger_home_screen.dart` - Deep forest green (Dynamic)
- ✅ `ride_history_screen.dart` - White (Manual)
- ✅ `profile_screen.dart` - White (Manual)
- ✅ `ride_results_screen.dart` - White (Manual)
- ✅ `location_search_screen.dart` - White (Manual)
- ✅ `ride_details_screen.dart` - White (Manual)

### Passenger App Screens Needing Update 🔧

**Priority 1 - Main Flow:**
1. `booking_confirmation_screen.dart`
2. `ride_checkout_screen.dart`
3. `passenger_live_tracking_screen.dart`
4. `passenger_tracking_screen.dart`

**Priority 2 - Secondary:**
5. `booking_management_screen.dart`
6. `cancellation_confirmation_screen.dart`
7. `area_not_served_screen.dart`

### Driver App Screens 🔧
Review and apply to all driver screens:
- Driver home/dashboard
- Trip management screens
- Profile/settings screens
- Document upload screens
- Earnings screens

---

## Color Guidelines

### Passenger App
- **Home Screen:** Deep Forest Green `#1B5E20`
- **Profile/History/Details:** White `#FFFFFF`
- **Active Trip Tracking:** Deep Forest Green `#1B5E20`
- **Payment/Checkout:** White or Light background colors

### Driver App
- **Home Screen:** Match your driver theme color
- **Active Trip:** Match trip status (green for active, amber for scheduled)
- **Profile/Settings:** White

### General Rules
1. **Dark Headers (Green, Blue, etc.)** → Same dark color status bar
2. **White/Light Headers** → White status bar
3. **Gradient Headers** → Use the top color of gradient

---

## Example: Update booking_confirmation_screen.dart

### Before:
```dart
class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text('Booking Confirmed'),
      ),
      body: // Content
    );
  }
}
```

### After (Method 1 - Mixin):
```dart
import 'package:allapalli_ride/core/utils/dynamic_status_bar.dart';

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> 
    with DynamicStatusBarMixin {
  
  @override
  Widget build(BuildContext context) {
    final successGreen = Color(0xFF4CAF50);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateStatusBarWithColor(successGreen);
    });
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: successGreen,
        title: Text('Booking Confirmed'),
      ),
      body: // Content
    );
  }
}
```

### After (Method 2 - Wrapper):
```dart
import 'package:allapalli_ride/core/utils/dynamic_status_bar.dart';

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  @override
  Widget build(BuildContext context) {
    final successGreen = Color(0xFF4CAF50);
    
    return DynamicStatusBarWrapper(
      statusBarColor: successGreen,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: successGreen,
          title: Text('Booking Confirmed'),
        ),
        body: // Content
      ),
    );
  }
}
```

---

## Benefits

### Automatic Icon Brightness
The mixin/wrapper automatically calculates whether to use light or dark icons based on the background color brightness.

- **Dark backgrounds** → Light (white) icons
- **Light backgrounds** → Dark (black) icons

### Proper Cleanup
When using the mixin, status bar is automatically reset to default when the screen is disposed.

### Consistent User Experience
Status bar color always matches the header, creating a unified, polished look across the entire app.

---

## Testing Checklist

After applying dynamic status bar:

- [ ] Test on Android (various API levels)
- [ ] Test on iOS
- [ ] Verify icon visibility (light/dark icons)
- [ ] Check navigation transitions
- [ ] Test with light and dark themes
- [ ] Verify on devices with notch/cutout
- [ ] Check tablet/landscape mode

---

## Troubleshooting

### Icons Not Visible
**Problem:** Status bar icons are the same color as background  
**Solution:** Brightness calculation may need adjustment. Manually set icon brightness:

```dart
SystemChrome.setSystemUIOverlayStyle(
  SystemUiOverlayStyle(
    statusBarColor: yourColor,
    statusBarIconBrightness: Brightness.light, // or Brightness.dark
  ),
);
```

### Status Bar Not Changing
**Problem:** Status bar stays same color across screens  
**Solution:** Ensure you're calling the mixin method in build or using wrapper correctly.

### Flicker on Screen Change
**Problem:** Status bar color flickers during transition  
**Solution:** Use `addPostFrameCallback` to delay the color change until after build.

---

## Notes

1. **Consistency:** Try to use the same method (Mixin or Wrapper) throughout the app
2. **Performance:** Both methods are lightweight and won't impact performance
3. **Android Only:** Some status bar features are Android-specific
4. **iOS Safe Area:** Status bar on iOS respects safe area automatically

---

## Further Reading

- [Flutter SystemChrome Documentation](https://api.flutter.dev/flutter/services/SystemChrome-class.html)
- [Material Design Status Bar Guidelines](https://material.io/design/platform-guidance/android-bars.html)
- [iOS Status Bar Best Practices](https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/color/)

---

**Last Updated:** $(date +%Y-%m-%d)  
**Status:** Ready for implementation  
**Estimated Time:** 2-3 minutes per screen
