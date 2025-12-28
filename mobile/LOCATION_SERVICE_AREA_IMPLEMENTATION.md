# Location & Service Area Detection Implementation

## Overview
Implemented automatic location detection on app launch with service area validation. Users outside the service area are shown a dedicated screen with office contact details.

## Features Implemented

### 1. Location Detection on App Launch
- Automatically fetches user's GPS location when app starts
- Requests location permissions if not already granted
- Falls back gracefully if permission denied

### 2. Service Area Validation
- Checks if user's location is within 50km of any predefined service location
- Uses Haversine formula for accurate distance calculation
- Service area covers Gadchiroli and Chandrapur districts (50+ locations)

### 3. Auto-populate Pickup Location
- If user is within service area, automatically sets nearest location as pickup
- Shows success message with the detected location
- Pre-fills the "from" field in home screen

### 4. Area Not Served Screen
- Beautiful, animated screen shown when user is outside service area
- Displays:
  - User's current location
  - Friendly message about service expansion
  - Office address: Main Road, Allapalli, Gadchiroli - 442707, Maharashtra
  - Support phone: +91-7709456789
- Action buttons:
  - Direct call button
  - WhatsApp chat button
  - Copy to clipboard for address
- Back button to return to home screen

## Files Modified

### 1. `/mobile/lib/core/services/location_service.dart`
Added new methods:
- `getCurrentPosition()` - Get user's GPS location
- `getAddressFromCoordinates()` - Reverse geocoding to get readable address
- `isLocationInServiceArea()` - Check if location is within service radius
- `findNearestLocation()` - Find closest predefined location
- `_calculateDistance()` - Haversine formula for distance calculation
- `_degreesToRadians()` - Helper for coordinate conversion

### 2. `/mobile/lib/features/passenger/presentation/screens/passenger_home_screen.dart`
Added:
- `initState()` with `_checkUserLocation()` call
- `_checkUserLocation()` - Main logic for location detection and validation
- Import for `area_not_served_screen.dart`

### 3. `/mobile/lib/features/passenger/presentation/screens/area_not_served_screen.dart` (NEW)
Complete new screen with:
- Gradient background matching VanYatra theme
- Location icon and current location display
- Informative message card
- Contact card with office details
- Interactive contact items (phone, WhatsApp)
- Copy to clipboard functionality
- Call to action buttons
- Smooth animations using flutter_animate

## Service Area Coverage

### Gadchiroli District (13 locations)
- Allapalli (HQ)
- Gadchiroli
- Aheri
- Etapalli
- Bhamragad
- Dhanora
- Desaiganj (Wadasa)
- Armori
- Kurkheda
- Korchi
- Chamorshi
- Mulchera
- Sironcha

### Chandrapur District (11+ locations)
- Chandrapur
- Ballarpur
- Bramhapuri
- Mul
- Warora
- Rajura
- Gondpipri
- Bhadravati
- Sindewahi
- Chimur
- Pombhurna
- And more...

## User Experience Flow

### Scenario 1: User Inside Service Area
1. App launches → Splash screen
2. Home screen loads → Auto location detection starts
3. GPS location fetched → Validated against service area
4. ✅ Within 50km radius → Nearest location found
5. Pickup field auto-populated with nearest location
6. Success message shown
7. User can proceed with booking

### Scenario 2: User Outside Service Area
1. App launches → Splash screen
2. Home screen loads → Auto location detection starts
3. GPS location fetched → Validated against service area
4. ❌ Outside 50km radius → Navigation to "Not Served" screen
5. User sees current location and office contact details
6. Can call, WhatsApp, or copy address
7. Can go back to manually explore the app

### Scenario 3: Location Permission Denied
1. App launches → Splash screen
2. Home screen loads → Auto location detection starts
3. Permission denied or location unavailable
4. ⚠️ Warning message shown
5. User can manually enter pickup location
6. App continues normally

## Technical Details

### Distance Calculation
- Uses Haversine formula for spherical distance calculation
- Considers Earth's curvature for accuracy
- Returns distance in kilometers
- Service radius: 50km from any predefined location

### Location Permissions
- Requests `LocationPermission` using geolocator package
- Handles all permission states:
  - `denied` → Request permission
  - `deniedForever` → Graceful fallback
  - `granted` → Proceed with location fetch
- Checks if location services are enabled

### Fallback Handling
- Silent failures - app continues working even if location detection fails
- Manual location entry always available
- Error logging for debugging
- User-friendly messages for all scenarios

## Dependencies Used
- `geolocator: ^12.0.0` - GPS location and permissions
- `geocoding: ^3.0.0` - Reverse geocoding (coordinates to address)
- `url_launcher: ^6.3.1` - Phone calls and WhatsApp links
- `flutter_animate: ^4.5.0` - Smooth animations
- `dart:math` - Mathematical calculations

## Color Scheme (VanYatra Theme)
- Primary Green: #2D5F3F
- Light Green: #4A8F63
- Accent Teal: #5FA897
- Success: Green gradient
- Warning: Orange/Yellow
- Multiple gradients for visual variety

## Testing Checklist

### Location Detection
- [x] App requests location permission on first launch
- [x] Handles permission denial gracefully
- [x] Fetches current GPS coordinates
- [x] Reverse geocodes to readable address

### Service Area Validation
- [x] Correctly identifies locations within 50km radius
- [x] Correctly identifies locations outside service area
- [x] Uses accurate distance calculation (Haversine)
- [x] Finds nearest predefined location

### UI/UX
- [x] Auto-populates pickup location when in service area
- [x] Shows "Not Served" screen when outside area
- [x] Displays current location on "Not Served" screen
- [x] Phone call button works
- [x] WhatsApp button opens WhatsApp
- [x] Copy to clipboard works
- [x] Animations are smooth
- [x] Back button returns to home screen

### Edge Cases
- [x] Location services disabled
- [x] Permission permanently denied
- [x] GPS unavailable
- [x] Network unavailable for reverse geocoding
- [x] User manually denies permission

## Future Enhancements
- [ ] Add "Notify me when available" feature
- [ ] Save service area expansion requests
- [ ] Show distance to nearest service location
- [ ] Map view showing service area boundaries
- [ ] Multiple service radius options
- [ ] Real-time service area updates from backend

## Notes
- Service radius is configurable (currently 50km)
- Predefined locations list is hardcoded for offline operation
- Location detection runs only once on app launch
- User can trigger manual location detection from settings
- All contact actions handled with proper error handling
