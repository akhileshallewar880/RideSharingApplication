# Mobile-Backend Integration Checklist

## ✅ Backend Complete
- [x] SignalR Hub implemented
- [x] Location Tracking Service created
- [x] REST API endpoints ready
- [x] Database migration applied
- [x] SignalR configured in Program.cs

## 🔄 Mobile Integration Steps

### Step 1: Update SocketService Event Names
**File**: `mobile/lib/core/services/socket_service.dart`

Currently using Socket.IO events - need to update for SignalR compatibility:

**Change From → To**:
```dart
// Connection
socket.emit('join_ride', ...) → socket.invoke('JoinRide', ...)
socket.emit('leave_ride', ...) → socket.invoke('LeaveRide', ...)

// Location Updates
socket.emit('location_update', ...) → socket.invoke('SendLocationUpdate', ...)

// Event Listeners
socket.on('location_update', ...) → socket.on('LocationUpdate', ...)
socket.on('trip_status', ...) → socket.on('RideMetrics', ...)
socket.on('passenger_update', ...) → socket.on('PassengerBoarded', ...)
socket.on('payment_collected', ...) → socket.on('PaymentCollected', ...)
```

**SignalR Connection String**:
```dart
// Update connect() method
final options = OptionBuilder()
    .setTransports(['websocket'])
    .setQuery({
      'access_token': token,  // JWT token for auth
    })
    .build();

socket = io('${AppConstants.socketBaseUrl}/tracking', options);
```

### Step 2: Update AppConstants Configuration
**File**: `mobile/lib/core/config/app_constants.dart`

```dart
class AppConstants {
  // Update with your actual server IP (not localhost!)
  static const String baseUrl = 'http://192.168.1.100:5000/api/v1';
  
  static String get socketBaseUrl {
    final uri = Uri.parse(baseUrl);
    return 'http://${uri.host}:${uri.port}';  
    // Returns: http://192.168.1.100:5000
  }
}
```

**Important**: Use your computer's local IP, NOT `localhost` or `127.0.0.1` (won't work on real devices)

### Step 3: Add Navigation After Trip Start
**File**: `mobile/lib/features/driver/presentation/screens/active_trip_screen.dart`

After driver clicks "Start Trip" and verifies passenger:

```dart
Future<void> _startTrip() async {
  // ... existing startTrip logic ...
  
  // After successful trip start:
  if (isDriver) {
    Navigator.pushNamed(
      context, 
      '/driver-tracking',
      arguments: {
        'rideId': widget.rideId,
        'ride': rideData,  // Pass full ride data
      },
    );
  } else {
    Navigator.pushNamed(
      context,
      '/passenger-tracking',
      arguments: {
        'rideId': widget.rideId,
        'ride': rideData,
      },
    );
  }
}
```

### Step 4: Register Routes in App Router
**File**: `mobile/lib/app/router/app_router.dart`

Add tracking screen routes:

```dart
static const driverTracking = '/driver-tracking';
static const passengerTracking = '/passenger-tracking';

static Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    // ... existing routes ...
    
    case driverTracking:
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (_) => DriverTrackingScreen(
          rideId: args['rideId'] as String,
          ride: args['ride'],
        ),
      );
      
    case passengerTracking:
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (_) => PassengerTrackingScreen(
          rideId: args['rideId'] as String,
          ride: args['ride'],
        ),
      );
    
    // ... rest of routes ...
  }
}
```

### Step 5: Initialize Hive (if not already done)
**File**: `mobile/lib/main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  final appDocDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocDir.path);
  
  // Register Hive adapters
  Hive.registerAdapter(CachedRideAdapter());
  Hive.registerAdapter(CachedPassengerAdapter());
  Hive.registerAdapter(IntermediateStopDataAdapter());
  
  runApp(const MyApp());
}
```

### Step 6: Request Location Permissions
**File**: `mobile/android/app/src/main/AndroidManifest.xml`

Verify these permissions exist:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

**File**: `mobile/ios/Runner/Info.plist`

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to track ride progress</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need background location to update ride status</string>
```

### Step 7: Update Google Maps API Key
**File**: `mobile/android/app/src/main/AndroidManifest.xml`

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

**File**: `mobile/ios/Runner/AppDelegate.swift`

```swift
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
```

---

## Testing Steps

### 1. Test Backend Connection
```bash
# Start backend server
cd server/ride_sharing_application/RideSharing.API
dotnet run

# Expected output:
# Now listening on: http://localhost:5000
```

### 2. Test SignalR Endpoint
```bash
# From mobile device/emulator, test connectivity:
curl http://YOUR_SERVER_IP:5000/tracking
```

### 3. Test Mobile App Flow
1. **Login as Driver**
2. **Create/Accept a Ride**
3. **Start Trip** (verify passenger)
4. **Observe Navigation** → Should open DriverTrackingScreen
5. **Check Location Updates** → Map should show driver marker + polyline
6. **Background App** → Location should continue updating every 30s
7. **Go Offline** → Locations queued in Hive
8. **Go Online** → Queued locations sync to backend

### 4. Test Passenger View
1. **Login as Passenger**
2. **Book a Ride** (with driver who started tracking)
3. **Should auto-open** PassengerTrackingScreen
4. **Observe Live Updates** → Driver location updates every 30s
5. **Check ETA** → Updates as driver moves
6. **Verify Stops** → Timeline shows pickup/intermediate/drop

---

## Common Issues & Solutions

### Issue: SignalR connection fails
**Check**:
- [ ] Backend is running: `curl http://YOUR_IP:5000`
- [ ] Firewall allows port 5000
- [ ] Using correct IP (NOT localhost on real device)
- [ ] JWT token is valid (check expiration)
- [ ] CORS origins include mobile IP

### Issue: Location not updating
**Check**:
- [ ] Location permissions granted in device settings
- [ ] GPS is enabled on device
- [ ] `LocationTrackingService.startTracking()` called
- [ ] Check Logcat/console for errors

### Issue: Map not showing
**Check**:
- [ ] Google Maps API key is valid
- [ ] API key has Maps SDK for Android/iOS enabled
- [ ] Billing enabled on Google Cloud project
- [ ] `google_maps_flutter` package installed

### Issue: Offline queue not syncing
**Check**:
- [ ] Hive initialized in `main.dart`
- [ ] Type adapters registered
- [ ] `SocketService.connect()` called when online
- [ ] `LocationQueue.syncQueuedLocations()` called

---

## Performance Tips

### Battery Optimization
```dart
// In LocationTrackingService
static const int _uiUpdateInterval = 30;      // 30 seconds for UI
static const int _storageInterval = 900;      // 15 minutes for storage

// Reduce frequency in battery saver mode:
final batteryLevel = await battery.batteryLevel;
if (batteryLevel < 20) {
  _uiUpdateInterval = 60;      // 1 minute
  _storageInterval = 1800;     // 30 minutes
}
```

### Network Optimization
```dart
// Batch location updates when offline
if (!isConnected) {
  _locationQueue.add(location);  // Queue for later
} else if (_locationQueue.isNotEmpty) {
  _socketService.sendBatchLocations(_locationQueue);  // Sync queued
  _locationQueue.clear();
}
```

### Memory Optimization
```dart
// Limit in-memory route polyline points
if (_routePoints.length > 500) {
  _routePoints.removeRange(0, 250);  // Keep last 250 points
}
```

---

## Next Steps After Integration

1. [ ] Test end-to-end flow (driver + passenger)
2. [ ] Monitor backend logs for SignalR connections
3. [ ] Check database for location entries
4. [ ] Test offline mode (airplane mode)
5. [ ] Test background location updates
6. [ ] Performance testing (battery drain, network usage)
7. [ ] Add error analytics (Sentry/Firebase Crashlytics)

---

## Production Checklist

- [ ] Replace localhost/IP with production domain
- [ ] Enable HTTPS (wss:// for SignalR)
- [ ] Configure SSL certificate
- [ ] Update CORS origins to production URLs
- [ ] Set up SignalR Redis backplane (if scaling)
- [ ] Enable location data archival (30 days)
- [ ] Add monitoring (Application Insights, New Relic)
- [ ] Configure CDN for static assets
- [ ] Test on various device models
- [ ] Submit for iOS/Android app review

---

**Status**: Backend ✅ Complete | Mobile Integration ⏳ Pending  
**Estimated Integration Time**: 2-3 hours  
**Last Updated**: December 19, 2024
