# Quick Start: Testing Intermediate Stops

## 5-Minute Setup

### Step 1: Add the Debug Panel to Your Tracking Screen

Open your driver tracking screen file and make these changes:

**File:** `mobile/lib/features/driver/presentation/screens/driver_tracking_screen.dart`

```dart
// Add this import
import '../../../../core/widgets/mock_location_debug_panel.dart';

// In your build method, wrap content in Stack and add the panel:
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        // Your existing GoogleMap widget
        GoogleMap(...),
        
        // Add this line:
        const MockLocationDebugPanel(),
      ],
    ),
  );
}
```

### Step 2: Configure Your Test Locations

Open `mobile/lib/core/services/mock_location_service.dart` and update the coordinates:

```dart
final Map<String, Map<String, double>> _predefinedLocations = {
  'pickup': {
    'lat': 19.0760,   // Replace with your actual pickup coordinates
    'lng': 72.8777,
  },
  'stop1': {
    'lat': 19.0896,   // First intermediate stop
    'lng': 72.8656,
  },
  'stop2': {
    'lat': 19.1136,   // Second intermediate stop
    'lng': 72.8697,
  },
  'dropoff': {
    'lat': 19.1197,   // Final destination
    'lng': 72.8464,
  },
};
```

**How to get coordinates:**
1. Open Google Maps
2. Right-click on your location
3. Click "What's here?"
4. Copy the coordinates

### Step 3: Run Your App

```bash
cd mobile
flutter run
```

### Step 4: Start Testing

1. **Open the tracking screen** (start a test ride)
2. **Tap the bug icon** 🐛 in the bottom-right corner
3. **Enable Mock Mode** (toggle the switch)
4. **Jump to locations:**
   - Tap "pickup" → You're at the pickup location
   - Tap "stop1" → You've reached the first intermediate stop
   - Tap "stop2" → You've reached the second stop
   - Tap "dropoff" → You've reached the destination

## That's It! 🎉

You can now test your intermediate stops without leaving your desk.

## Tips

- **Check the map:** Your position marker should move when you change locations
- **Check the console:** Look for 📍 emoji messages showing location updates
- **Backend sync:** Your mock locations are sent to the server just like real GPS data
- **Passenger app:** The passenger should see the driver moving on their map

## Troubleshooting

**Panel not showing?**
- Make sure you're running in debug mode (not release)
- Check that you added it to the correct screen

**Mock mode toggle not working?**
- Restart the app
- Check the console for any error messages

**Locations not updating?**
- Make sure mock mode is enabled (toggle should be green)
- Check that you've started tracking for the ride

## Next Steps

Once basic testing works:
1. Add your actual intermediate stop coordinates
2. Test the complete ride flow
3. Verify backend communication
4. Test with passenger app simultaneously

For more details, see [MOCK_LOCATION_TESTING_GUIDE.md](./MOCK_LOCATION_TESTING_GUIDE.md)
