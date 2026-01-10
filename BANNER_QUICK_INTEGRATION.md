# 🎯 Quick Integration Guide - Home Screen Banners

## Copy-Paste Integration for Passenger Home Screen

Replace the commented banner section in `passenger_home_screen.dart` (around line 1878-1885) with:

### Step 1: Add Import (at the top of the file)

Add this import after the existing imports:

```dart
import 'package:allapalli_ride/widgets/local_banner_carousel.dart';
```

### Step 2: Replace Commented Banner Code

**Find this code** (around line 1878):
```dart
// Dynamic Banner Carousel (Offers) - Temporarily disabled to fix hit testing
// if (_banners.isNotEmpty)
//   Padding(
//     padding: const EdgeInsets.only(left: 16, right: 16, top: 24),
//     child: SizedBox(
//       height: 220,
//       child: DynamicBannerCarousel(banners: _banners),
//     ),
//   ),
```

**Replace with this:**
```dart
// Local Banner Carousel - Using assets (no API calls)
if (activeTrip.bookingNumber.isEmpty && upcomingRides.isEmpty)
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: LocalBannerCarousel(
      height: 180,
      autoPlayInterval: Duration(seconds: 5),
    ),
  ),
```

### Complete Context (Lines 1870-1900)

Here's how the complete section should look:

```dart
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Local Banner Carousel - Using assets (no API calls)
            if (activeTrip.bookingNumber.isEmpty && upcomingRides.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LocalBannerCarousel(
                  height: 180,
                  autoPlayInterval: Duration(seconds: 5),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Active Trip Card
            if (activeTrip.bookingNumber.isNotEmpty)
              _buildActiveTripCard(activeTrip, isDark),
              
            // Scheduled Ride Banner
            if (upcomingRides.isNotEmpty && activeTrip.bookingNumber.isEmpty)
              _buildScheduledRideBanner(upcomingRides.first, isDark),
            
            const SizedBox(height: 100), // Bottom padding
          ],
        ),
```

## 🎨 Logic Explanation

The banners will show **only when**:
- ✅ No active trip is in progress (`activeTrip.bookingNumber.isEmpty`)
- ✅ No upcoming scheduled rides (`upcomingRides.isEmpty`)

This keeps the UI clean and focused on active rides when they exist.

## 🚀 Test It

1. Save the file
2. **Hot restart** the app (Press `R` in terminal, NOT just `r`)
3. Login as a passenger
4. Banners should appear on the home screen
5. When you book a ride, banners automatically hide

## ✅ What You Get

- ✅ Beautiful banner carousel
- ✅ Auto-rotating every 5 seconds
- ✅ Smooth animations
- ✅ No API calls (100% local)
- ✅ Automatic show/hide based on ride status
- ✅ Works in dark/light mode

## 🎯 Optional Customizations

### Change Banner Text

Edit `lib/widgets/local_banner_carousel.dart` line 26:

```dart
final List<Map<String, String>> _localBanners = [
  {
    'image': 'assets/images/otp_banners/otp_banner_1.png',
    'title': 'Welcome to VanYatra! 🚗',  // ← Change this
    'subtitle': 'Your trusted rural ride booking platform',  // ← Change this
  },
  // Add more banners...
];
```

### Change Auto-play Speed

```dart
LocalBannerCarousel(
  height: 180,
  autoPlayInterval: Duration(seconds: 3), // ← Faster: 3 seconds
),
```

### Always Show Banners

Remove the conditional and just use:

```dart
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: LocalBannerCarousel(),
),
```

That's it! Your banners are ready to use! 🎉
