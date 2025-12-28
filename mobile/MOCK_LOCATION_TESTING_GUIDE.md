# Mock Location Testing Guide for Intermediate Stops

## Overview
This guide explains how to test intermediate stops in your taxi booking app without physically traveling to different locations. We've added a mock location system that allows you to simulate GPS positions.

## Setup

### 1. Mock Location Service
The `MockLocationService` has been added to simulate GPS locations for testing purposes.

**Location:** `mobile/lib/core/services/mock_location_service.dart`

### 2. Location Tracking Service Integration
The `LocationTrackingService` now supports mock locations automatically when mock mode is enabled.

**Location:** `mobile/lib/core/services/location_tracking_service.dart`

### 3. Debug Panel Widget
A floating debug panel widget is available to control mock locations from the UI.

**Location:** `mobile/lib/core/widgets/mock_location_debug_panel.dart`

## Usage Methods

### Method 1: Using the Debug Panel (Recommended for Quick Testing)

1. **Add the debug panel to your tracking screen:**
   
   ```dart
   import 'package:your_app/core/widgets/mock_location_debug_panel.dart';
   
   // In your tracking screen widget
   @override
   Widget build(BuildContext context) {
     return Stack(
       children: [
         // Your existing UI
         GoogleMap(...),
         
         // Add the debug panel (only shows in debug builds)
         const MockLocationDebugPanel(),
       ],
     );
   }
   ```

2. **Using the panel:**
   - Tap the bug icon 🐛 in the bottom-right corner
   - Toggle "Mock Mode" ON
   - Use quick location buttons (pickup, stop1, stop2, etc.)
   - Or enter custom coordinates manually

### Method 2: Programmatic Control

**In your code, add before starting a ride:**

```dart
import 'package:your_app/core/services/location_tracking_service.dart';

// Get the location tracking service
final locationService = LocationTrackingService();

// Enable mock mode
locationService.mockService.enableMockMode();

// Set a specific location
locationService.mockService.setMockLocation(
  latitude: 20.0100,
  longitude: 80.0100,
);

// Or use predefined locations
locationService.mockService.setMockLocationByName('stop1');
```

### Method 3: Flutter DevTools Console

While the app is running, open Flutter DevTools console and execute:

```dart
// Import the service (if not already available)
import 'package:your_app/core/services/mock_location_service.dart';

final mockService = MockLocationService();

// Enable and set location
mockService.enableMockMode();
mockService.setMockLocationByName('stop2');
```

## Setting Up Your Intermediate Stops

### Option 1: Update Predefined Locations

Edit the `_predefinedLocations` map in `mock_location_service.dart`:

```dart
final Map<String, Map<String, double>> _predefinedLocations = {
  'pickup': {
    'lat': 19.1234,  // Replace with actual coordinates
    'lng': 77.5678,
  },
  'stop1': {
    'lat': 19.2000,
    'lng': 77.6000,
  },
  'stop2': {
    'lat': 19.3000,
    'lng': 77.7000,
  },
  'dropoff': {
    'lat': 19.4000,
    'lng': 77.8000,
  },
};
```

### Option 2: Add Locations Dynamically

```dart
final mockService = MockLocationService();
mockService.enableMockMode();

// Add your intermediate stops
mockService.addLocation('marketplace', 19.1234, 77.5678);
mockService.addLocation('hospital', 19.2345, 77.6789);
mockService.addLocation('school', 19.3456, 77.7890);

// Then use them
mockService.setMockLocationByName('marketplace');
```

## Testing Workflow for Driver App

### Complete Test Scenario:

```dart
// 1. Enable mock mode when starting the ride
final locationService = LocationTrackingService();
locationService.mockService.enableMockMode();

// 2. Set initial position (pickup location)
locationService.mockService.setMockLocationByName('pickup');

// 3. Start tracking
await locationService.startTracking(rideId);

// 4. Simulate movement to intermediate stops
await Future.delayed(Duration(seconds: 5));
locationService.mockService.setMockLocationByName('stop1');

await Future.delayed(Duration(seconds: 5));
locationService.mockService.setMockLocationByName('stop2');

await Future.delayed(Duration(seconds: 5));
locationService.mockService.setMockLocationByName('dropoff');

// 5. Stop tracking when done
await locationService.stopTracking();
```

## Advanced Features

### Simulate Movement Animation

To simulate smooth movement between two points:

```dart
final mockService = MockLocationService();
mockService.enableMockMode();

// Animate from pickup to stop1
await mockService.simulateMovement(
  fromLat: 19.1234,
  fromLng: 77.5678,
  toLat: 19.2000,
  toLng: 77.6000,
  steps: 20,  // Number of position updates
  stepDuration: Duration(seconds: 1),  // Time between updates
);
```

### Get Available Locations

```dart
final locations = mockService.getAvailableLocations();
print('Available test locations: $locations');
```

## Finding Coordinates for Your Test Locations

### Method 1: Google Maps
1. Open Google Maps
2. Right-click on the location
3. Select "What's here?"
4. Copy the coordinates shown

### Method 2: Using Your Real Device
1. Disable mock mode temporarily
2. Use the app's location service to get current position
3. Log the coordinates when at your desired location:

```dart
final position = await locationService.getCurrentLocation();
print('Current location: ${position?.latitude}, ${position?.longitude}');
```

## Example Integration in Driver Tracking Screen

```dart
import 'package:flutter/material.dart';
import 'package:your_app/core/services/location_tracking_service.dart';
import 'package:your_app/core/widgets/mock_location_debug_panel.dart';

class DriverTrackingScreen extends StatefulWidget {
  // ... your existing code
}

class _DriverTrackingScreenState extends State<DriverTrackingScreen> {
  final LocationTrackingService _locationService = LocationTrackingService();
  
  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }
  
  Future<void> _initializeTracking() async {
    // For testing: Enable mock mode
    if (kDebugMode) {
      _locationService.mockService.enableMockMode();
      _locationService.mockService.setMockLocationByName('pickup');
    }
    
    // Start tracking
    await _locationService.startTracking(widget.rideId);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Your map and UI
          GoogleMap(
            // ... map configuration
          ),
          
          // Add mock location debug panel
          if (kDebugMode) const MockLocationDebugPanel(),
        ],
      ),
    );
  }
}
```

## Troubleshooting

### Mock locations not updating?
- Ensure mock mode is enabled: `mockService.isMockEnabled` should be `true`
- Check that you've called `startTracking()` after enabling mock mode
- Look for debug prints in the console (they start with 🧪 or 📍)

### Debug panel not showing?
- The panel only shows in debug builds by default
- Check the build condition in `mock_location_debug_panel.dart`

### Real GPS interfering with mock locations?
- Mock mode automatically overrides real GPS when enabled
- If issues persist, check location permissions (denying them will force mock-only mode)

## Best Practices

1. **Always disable mock mode in production:**
   ```dart
   if (kDebugMode) {
     locationService.mockService.enableMockMode();
   }
   ```

2. **Use descriptive location names:**
   Instead of 'loc1', 'loc2', use 'city_center', 'hospital_entrance', etc.

3. **Test the complete journey:**
   Don't just jump to locations; simulate the full route including intermediate stops

4. **Verify server communication:**
   Ensure your mock locations are being sent to the backend correctly

5. **Document your test coordinates:**
   Keep a record of which coordinates represent which real-world locations

## API Integration

The mock locations work seamlessly with your existing tracking system:
- Location updates are stored in the offline queue
- They're sent to the backend via WebSocket/SignalR
- The passenger app will see the driver's mock position on the map

## Disabling Mock Mode

When you're ready to test with real GPS:

```dart
locationService.mockService.disableMockMode();
```

Or simply remove/comment out the mock enabling code.

## Next Steps

1. Add this debug panel to your driver tracking screen
2. Update the predefined locations with your actual intermediate stop coordinates
3. Test the complete ride flow from pickup → stop1 → stop2 → ... → dropoff
4. Verify that each location change is reflected in both the driver and passenger apps

## Quick Testing Checklist

- [ ] Mock mode enabled
- [ ] Predefined locations configured with real coordinates
- [ ] Debug panel added to tracking screen
- [ ] Location updates visible on map
- [ ] Backend receiving location updates
- [ ] Passenger app showing driver movement
- [ ] Intermediate stops trigger correctly
- [ ] Mock mode disabled before production build
