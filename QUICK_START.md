# 🚀 Quick Start Guide - Ride Tracking System

## ✅ What's Complete

### Backend (.NET 8)
- ✅ Running on http://localhost:5056
- ✅ SignalR Hub at ws://localhost:5056/tracking
- ✅ REST API at http://localhost:5056/api/v1/tracking
- ✅ Swagger UI at http://localhost:5056/swagger
- ✅ Database migration applied

### Mobile (Flutter)
- ✅ All 14 files created
- ⏳ Needs configuration + integration

---

## 🔧 Mobile Setup (Next Steps)

### 1. Update Server URL
**File**: `mobile/lib/core/config/app_constants.dart`

```dart
class AppConstants {
  // Replace with your computer's IP address
  static const String baseUrl = 'http://YOUR_IP_ADDRESS:5056/api/v1';
  
  static String get socketBaseUrl {
    final uri = Uri.parse(baseUrl);
    return 'http://${uri.host}:${uri.port}';
  }
}
```

**Find your IP**:
```bash
# macOS
ipconfig getifaddr en0

# Example output: 192.168.1.100
# Then use: http://192.168.1.100:5056/api/v1
```

### 2. Update SocketService Events
**File**: `mobile/lib/core/services/socket_service.dart`

Change all Socket.IO events to SignalR format:
- `socket.emit('join_ride', ...)` → `socket.invoke('JoinRide', ...)`
- `socket.on('location_update', ...)` → `socket.on('LocationUpdate', ...)`

See `INTEGRATION_CHECKLIST.md` for full list.

### 3. Add Navigation
**File**: `mobile/lib/features/driver/presentation/screens/active_trip_screen.dart`

After driver starts trip:
```dart
Navigator.pushNamed(context, '/driver-tracking', 
    arguments: {'rideId': rideId, 'ride': rideData});
```

### 4. Initialize Hive
**File**: `mobile/lib/main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocDir.path);
  Hive.registerAdapter(CachedRideAdapter());
  Hive.registerAdapter(CachedPassengerAdapter());
  Hive.registerAdapter(IntermediateStopDataAdapter());
  runApp(const MyApp());
}
```

### 5. Add Google Maps API Key
**Android**: `mobile/android/app/src/main/AndroidManifest.xml`
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

**iOS**: `mobile/ios/Runner/AppDelegate.swift`
```swift
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
```

---

## 🧪 Testing

### Test Backend SignalR Endpoint
```bash
curl http://localhost:5056/tracking
# Should return: Status 400 (requires WebSocket upgrade)
```

### View Swagger API Docs
Open browser: http://localhost:5056/swagger

### Test REST API
```bash
# Get location history (requires JWT token)
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:5056/api/v1/tracking/rides/RIDE_ID/latest
```

### Run Mobile App
```bash
cd mobile
flutter pub get
flutter run
```

---

## 📊 Architecture at a Glance

```
DRIVER MOBILE APP
    ↓ GPS updates every 30s
LocationTrackingService
    ↓ WebSocket (SignalR)
Backend TrackingHub (:5056/tracking)
    ↓ Broadcast
PASSENGER MOBILE APP(S)
    ↓ Map updates
Live driver location shown

OFFLINE MODE:
Driver Mobile → Hive Queue → Auto-sync when online
```

---

## 📁 Key Files Reference

### Mobile Files
- **Services**: `lib/core/services/location_tracking_service.dart`, `socket_service.dart`
- **Screens**: `lib/features/driver/presentation/screens/driver_tracking_screen.dart`
- **Screens**: `lib/features/passenger/presentation/screens/passenger_tracking_screen.dart`

### Backend Files
- **Hub**: `RideSharing.API/Hubs/TrackingHub.cs`
- **Service**: `RideSharing.API/Services/Implementation/LocationTrackingService.cs`
- **Controller**: `RideSharing.API/Controllers/LocationTrackingController.cs`

### Documentation
- **Mobile Guide**: `RIDE_TRACKING_IMPLEMENTATION.md`
- **Backend Guide**: `BACKEND_TRACKING_IMPLEMENTATION.md`
- **Integration Steps**: `INTEGRATION_CHECKLIST.md`
- **Summary**: `IMPLEMENTATION_SUMMARY.md`

---

## 🐛 Common Issues

### "SignalR connection failed"
- Check: Using correct IP (not localhost on real device)
- Check: Backend running (`curl http://YOUR_IP:5056`)
- Check: Firewall allows port 5056

### "Location not updating"
- Check: Location permissions granted
- Check: GPS enabled on device
- Check: `startTracking()` called

### "Map not showing"
- Check: Google Maps API key added
- Check: Maps SDK enabled in Google Cloud Console

---

## 📚 Full Documentation

For complete details, see:
- `IMPLEMENTATION_SUMMARY.md` - Full feature list
- `INTEGRATION_CHECKLIST.md` - Detailed setup steps
- `BACKEND_TRACKING_IMPLEMENTATION.md` - API documentation
- `RIDE_TRACKING_IMPLEMENTATION.md` - Mobile implementation

---

## 🎯 Expected Flow

1. Driver logs in → Creates/Accepts ride
2. Driver clicks "Start Trip" → Verifies passenger
3. **Auto-navigate to DriverTrackingScreen**
4. GPS starts tracking → Location updates every 30s
5. SignalR broadcasts to passengers
6. **Passenger sees live driver location + ETA**
7. Driver picks up passengers at stops
8. Driver collects payments (cash)
9. Driver completes trip

---

## ✅ Completion Status

| Component | Status |
|-----------|--------|
| Backend SignalR | ✅ Running |
| Backend REST API | ✅ Running |
| Database | ✅ Migrated |
| Mobile Services | ✅ Complete |
| Mobile UI | ✅ Complete |
| Documentation | ✅ Complete |
| **Integration** | ⏳ **Pending** |

---

**Backend Status**: ✅ Running on port 5056  
**Next Step**: Update mobile app configuration  
**Estimated Time**: 30 minutes for basic integration
