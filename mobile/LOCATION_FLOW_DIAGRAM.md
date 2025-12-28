# Location Detection & Service Area Flow - Quick Reference

## User Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         APP LAUNCH                               │
│                    (Splash Screen Shown)                         │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                   PASSENGER HOME SCREEN LOADS                    │
│                   initState() → _checkUserLocation()             │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│              REQUEST LOCATION PERMISSION                         │
│              locationService.getCurrentPosition()                │
└──────────┬────────────────┬────────────────┬─────────────────────┘
           │                │                │
           │                │                │
      GRANTED           DENIED         NOT AVAILABLE
           │                │                │
           ▼                ▼                ▼
    ┌──────────┐    ┌──────────────┐   ┌──────────────┐
    │ Get GPS  │    │ Show Warning │   │ Show Warning │
    │ Location │    │   Message    │   │   Message    │
    └────┬─────┘    └──────┬───────┘   └──────┬───────┘
         │                 │                   │
         │                 └──────┬────────────┘
         │                        │
         ▼                        ▼
    ┌──────────────────┐    ┌────────────────────────┐
    │ Validate Service │    │ User can manually enter│
    │      Area        │    │  pickup location       │
    │  (50km radius)   │    └────────────────────────┘
    └────┬─────────────┘
         │
         ├────────────────────────┬────────────────────────┐
         │                        │                        │
    IN SERVICE AREA          OUTSIDE SERVICE          EDGE OF SERVICE
         │                        │                        │
         ▼                        ▼                        ▼
┌─────────────────┐      ┌──────────────────┐    ┌─────────────────┐
│ Find Nearest    │      │ Get Current      │    │ Find Nearest    │
│ Predefined Loc  │      │ Address (Reverse │    │ Location Anyway │
│                 │      │ Geocoding)       │    │                 │
└────────┬────────┘      └────────┬─────────┘    └────────┬────────┘
         │                        │                        │
         ▼                        ▼                        │
┌─────────────────┐      ┌──────────────────┐            │
│ Auto-populate   │      │ Navigate to      │            │
│ Pickup Field    │      │ "Not Served"     │            │
│                 │      │ Screen           │            │
└────────┬────────┘      └────────┬─────────┘            │
         │                        │                       │
         ▼                        ▼                       │
┌─────────────────┐      ┌──────────────────┐           │
│ Show Success    │      │ Show:            │           │
│ Message         │      │ • Current Loc    │           │
│ "Pickup set to  │      │ • Office Info    │           │
│  [Location]"    │      │ • Call Button    │           │
└─────────────────┘      │ • WhatsApp Button│           │
                         │ • Back Button    │           │
                         └──────────────────┘           │
                                                         │
                         User can go back ──────────────┘
                         and manually explore app
```

## Code Flow

```
PassengerHomeScreen
    │
    ├─ initState()
    │   └─ WidgetsBinding.instance.addPostFrameCallback()
    │       └─ _checkUserLocation()
    │
    └─ _checkUserLocation()
        │
        ├─ 1. Get LocationService from provider
        │   └─ ref.read(locationServiceProvider)
        │
        ├─ 2. Request current position
        │   └─ locationService.getCurrentPosition()
        │       ├─ Check if location services enabled
        │       ├─ Check/Request permissions
        │       └─ Get GPS coordinates (lat, lng)
        │
        ├─ 3. Validate service area
        │   └─ locationService.isLocationInServiceArea(lat, lng)
        │       └─ Check distance to all predefined locations
        │           └─ _calculateDistance() [Haversine formula]
        │               └─ Return true if any within 50km
        │
        └─ 4. Handle result
            │
            ├─ IF inside service area:
            │   ├─ findNearestLocation(lat, lng)
            │   ├─ Set _selectedPickup = nearestLocation
            │   ├─ Set _pickupController.text = nearestLocation.name
            │   └─ Show success SnackBar
            │
            └─ IF outside service area:
                ├─ getAddressFromCoordinates(lat, lng)
                └─ Navigate to AreaNotServedScreen
                    └─ Display contact information
```

## Service Area Validation Logic

```
isLocationInServiceArea(userLat, userLng)
    │
    └─ For each predefined location:
        │
        ├─ Calculate distance using Haversine formula:
        │   
        │   distance = 2 * R * arcsin(√(a))
        │   
        │   where:
        │   a = sin²(Δlat/2) + cos(lat1) × cos(lat2) × sin²(Δlng/2)
        │   R = Earth radius (6371 km)
        │   Δlat = lat2 - lat1
        │   Δlng = lng2 - lng1
        │
        ├─ If distance ≤ 50km:
        │   └─ Return TRUE (user is in service area)
        │
        └─ If no location within 50km:
            └─ Return FALSE (user outside service area)
```

## Example Scenarios

### Scenario 1: User in Allapalli (Service HQ)
```
User Location: 19.4333°N, 79.9167°E (Allapalli center)
Nearest Location: Allapalli (distance: 0.5 km)
Result: ✅ IN SERVICE AREA
Action: Auto-fill pickup = "Allapalli"
Message: "Pickup location set to Allapalli" (green)
```

### Scenario 2: User in Nagpur (Outside service area)
```
User Location: 21.1458°N, 79.0882°E (Nagpur)
Nearest Location: Gadchiroli (distance: ~180 km)
Result: ❌ OUTSIDE SERVICE AREA
Action: Navigate to AreaNotServedScreen
Display: "Nagpur, Maharashtra" + Contact info
```

### Scenario 3: User near Chandrapur (Edge of service area)
```
User Location: 19.9500°N, 79.3000°E (Chandrapur)
Nearest Location: Chandrapur (distance: 3 km)
Result: ✅ IN SERVICE AREA
Action: Auto-fill pickup = "Chandrapur"
Message: "Pickup location set to Chandrapur" (green)
```

### Scenario 4: Permission Denied
```
User Action: Deny location permission
Result: ⚠️ PERMISSION DENIED
Action: Stay on home screen
Message: "Unable to get your location. You can manually enter pickup location." (orange)
User Experience: Can still use app by typing location
```

## Key Components

### LocationService Methods
```dart
┌─────────────────────────────────────────────────────┐
│ getCurrentPosition()                                │
│ → Returns: Position?                                │
│ → Purpose: Get user's GPS coordinates              │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ getAddressFromCoordinates(lat, lng)                 │
│ → Returns: String? (e.g., "Nagpur, Maharashtra")   │
│ → Purpose: Reverse geocoding                        │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ isLocationInServiceArea(lat, lng)                   │
│ → Returns: bool                                      │
│ → Purpose: Check if within 50km of any service loc │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ findNearestLocation(lat, lng)                       │
│ → Returns: LocationSuggestion?                      │
│ → Purpose: Find closest predefined location        │
└─────────────────────────────────────────────────────┘
```

## Service Coverage Map

```
         Maharashtra

    ┌────────────────────────┐
    │                        │
    │    Nagpur ❌           │
    │      ↓ 180km           │
    │                        │
    │   ╔════════════════╗   │
    │   ║  Gadchiroli    ║   │
    │   ║  District ✅   ║   │
    │   ║                ║   │
    │   ║  • Allapalli   ║   │
    │   ║  • Gadchiroli  ║   │
    │   ║  • Aheri       ║   │
    │   ║  • Etapalli    ║   │
    │   ║  + 9 more      ║   │
    │   ╚════════════════╝   │
    │                        │
    │   ╔════════════════╗   │
    │   ║  Chandrapur    ║   │
    │   ║  District ✅   ║   │
    │   ║                ║   │
    │   ║  • Chandrapur  ║   │
    │   ║  • Ballarpur   ║   │
    │   ║  • Bramhapuri  ║   │
    │   ║  • Warora      ║   │
    │   ║  + 7 more      ║   │
    │   ╚════════════════╝   │
    │                        │
    └────────────────────────┘

    Legend:
    ✅ = Service available (50km radius)
    ❌ = Outside service area
    ╔══╗ = Service district boundary
```

## Testing Checklist

```
Location Permission:
  ✅ First launch → Request permission
  ✅ Permission granted → Fetch location
  ✅ Permission denied → Show warning, allow manual input
  ✅ Permission denied forever → Graceful fallback

Service Area Detection:
  ✅ Inside 50km → Auto-populate + success message
  ✅ Outside 50km → Navigate to "Not Served" screen
  ✅ Exactly at boundary → Correct validation
  ✅ No predefined locations → Handle gracefully

UI/UX:
  ✅ Smooth transitions between screens
  ✅ Loading states during location fetch
  ✅ Clear error messages
  ✅ Success feedback
  ✅ Back navigation works

Edge Cases:
  ✅ Location services disabled
  ✅ GPS unavailable (indoors)
  ✅ Network unavailable (reverse geocoding)
  ✅ App in background during location fetch
  ✅ Multiple rapid launches
```

## Performance Metrics

```
Operation                    | Time      | Notes
─────────────────────────────|-----------|──────────────────────
Request Permission           | ~1-2s     | System dialog
Get GPS Location            | ~2-5s     | Varies by signal
Reverse Geocoding           | ~1-3s     | Network dependent
Service Area Validation     | <100ms    | Local calculation
Find Nearest Location       | <100ms    | ~50 iterations
Total (success case)        | ~4-10s    | User-friendly
```

## Configuration

```dart
// Editable parameters in location_service.dart

const maxDistanceKm = 50.0;  // Service radius
// Change this to expand/reduce coverage

const earthRadiusKm = 6371.0;  // Earth radius
// Fixed constant for calculations

// LocationAccuracy.high
// Can change to .medium or .low for faster results
// but less precise location
```
