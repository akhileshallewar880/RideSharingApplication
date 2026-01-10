# 🚀 Quick Test - Mock Location Updates

## Instant Test (Copy & Paste)

### Option 1: Test Widget in Your Screen

Add to `driver_home_screen.dart` or any screen:

```dart
import '../widgets/mock_location_test_widget.dart';

// In your build method:
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: SingleChildScrollView(
      child: Column(
        children: [
          // ... your existing widgets ...
          
          // Add this widget
          const MockLocationTestWidget(),
          
          // ... rest of widgets ...
        ],
      ),
    ),
  );
}
```

### Option 2: Quick Button Test

Add a floating action button to test:

```dart
import '../../../../core/services/location_tracking_service.dart';

// In your scaffold:
floatingActionButton: FloatingActionButton(
  onPressed: () async {
    final service = LocationTrackingService();
    service.mockService.enableMockMode();
    
    // Simulate movement
    for (final loc in ['pickup', 'stop1', 'stop2', 'dropoff']) {
      service.mockService.setMockLocationByName(loc);
      await Future.delayed(Duration(seconds: 5));
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Route complete!')),
    );
  },
  child: Icon(Icons.play_arrow),
  tooltip: 'Test Mock Location',
),
```

### Option 3: One-Line Commands (Debug Console)

While app is running, type in debug console or add to a button:

```dart
// Enable mock mode
LocationTrackingService().mockService.enableMockMode();

// Jump to dropoff
LocationTrackingService().mockService.setMockLocationByName('dropoff');

// Custom coordinates
LocationTrackingService().mockService.setMockLocation(
  latitude: 17.4500,
  longitude: 78.3875,
);
```

## 🎯 Expected Results

### After 3 seconds, you should see logs:
```
⏰ PERIODIC TIMER FIRED - fetching location...
📍 getCurrentLocation() called
🧪 Using mock position
⏰ Timer got position: 17.450000, 78.387500
🔄 Provider handling location update: 17.450000, 78.387500
✅ Provider state updated with new location
📡 Location broadcasted via socket
```

### UI should update with:
- New coordinates
- Updated distance/ETA
- Changed map marker position

## 🐛 Debug Button

In driver tracking screen, look for this button (debug builds only):

```
┌─────────────────────────────────────┐
│  ←  Ride 12345678         🐛 👥 🟢 │  ← Click the 🐛 bug icon
└─────────────────────────────────────┘
```

## ⚡ Fastest Test

1. Run app: `flutter run`
2. Navigate to driver tracking screen
3. Add this code anywhere clickable:

```dart
ElevatedButton(
  onPressed: () {
    LocationTrackingService()
      ..mockService.enableMockMode()
      ..mockService.setMockLocationByName('dropoff');
  },
  child: Text('Test Location'),
)
```

4. Click button
5. Wait 3 seconds
6. Check logs for "📍 GPS returned"

## 📍 Available Mock Locations

| Name | Location | Coordinates |
|------|----------|-------------|
| `pickup` | Asian Living, Gachibowli | 17.4243, 78.3463 |
| `stop1` | Wipro Circle | 17.4410, 78.3668 |
| `stop2` | Raidurg Metro | 17.4347, 78.3473 |
| `stop3` | Hitec City Metro | 17.4484, 78.3908 |
| `dropoff` | Durgam Cheruvu Metro | 17.4500, 78.3875 |
| `between-pickup-stop1` | Midpoint | 17.4327, 78.3566 |
| `between-stop1-stop2` | Midpoint | 17.4379, 78.3571 |
| `between-stop2-stop3` | Midpoint | 17.4416, 78.3691 |
| `between-stop3-dropoff` | Midpoint | 17.4492, 78.3892 |

## 🔥 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| No logs appearing | Check console, run in debug mode |
| "⚠️ Enable mock mode first" | Call `enableMockMode()` first |
| Old location showing | Wait 3 seconds for timer |
| UI not updating | Check `ref.watch(locationTrackingProvider)` |
| Permission denied | Not an issue with internal mock |

## ✅ Success Indicators

✅ See "🧪 Using mock position" in logs  
✅ See "⏰ Timer got position: <NEW coords>" every 3s  
✅ See "✅ Provider state updated" in logs  
✅ UI shows new coordinates  
✅ Map/timeline updates

## 🎬 Demo Scenario

```dart
// Complete test scenario
final service = LocationTrackingService();

print('Starting mock location test...');

service.mockService.enableMockMode();
print('✅ Mock mode enabled');

await Future.delayed(Duration(seconds: 2));
service.mockService.setMockLocationByName('pickup');
print('📍 At pickup');

await Future.delayed(Duration(seconds: 5));
service.mockService.setMockLocationByName('stop1');
print('📍 At stop 1');

await Future.delayed(Duration(seconds: 5));
service.mockService.setMockLocationByName('dropoff');
print('📍 At dropoff');

print('✅ Test complete!');
```

## 🆘 Still Not Working?

1. Open Location Debug Screen (🐛 button)
2. Click "Check Settings"
3. Click "Start Poll (3s)"
4. In separate window, run test code
5. Copy logs
6. Share with developer

---

**Files You Need:**
- ✅ `location_tracking_service.dart` - Already has mock support
- ✅ `mock_location_service.dart` - Already has predefined locations
- ✅ `mock_location_test_widget.dart` - NEW - Easy UI for testing
- ✅ `location_debug_screen.dart` - NEW - Advanced diagnostics

**No External Apps Needed!** Internal mock service works perfectly.
