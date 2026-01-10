# Admin Web App Location API Fix - January 11, 2026

## Issues Reported

User reported two critical errors in admin web app:
1. **Wrong API URL**: Admin web calling `http://192.168.88.14:5056` (local development) instead of production server
2. **Non-existent Endpoint**: Trying to access `/api/v1/googleplaces/autocomplete` which doesn't exist

Error logs:
```
Error fetching place suggestions: ClientException: XMLHttpRequest error., 
uri=http://192.168.88.14:5056/api/v1/googleplaces/autocomplete?input=aher&components=country%3Ain
GET http://192.168.88.14:5056/api/v1/googleplaces/autocomplete?input=aher net::ERR_ADDRESS_UNREACHABLE
```

## Root Causes

### 1. Wrong Environment Configuration
**File**: `admin_web/lib/core/config/environment_config.dart`

**Problem**: 
- Environment set to `AdminEnvironment.development`
- Development URL pointed to local server `http://192.168.88.14:5056`
- Production URL was incorrect (`https://api.vanyatra.com` doesn't exist)

**Impact**: All API calls were going to unreachable local IP address.

### 2. Non-Existent Google Places API
**File**: `admin_web/lib/core/services/google_places_service.dart`

**Problem**:
- Service trying to access `/api/v1/googleplaces/autocomplete` endpoint
- This endpoint doesn't exist in the backend API
- Backend has `/api/v1/locations/search` endpoint instead

**Impact**: Location search completely broken in admin web app.

## Solutions Implemented

### Fix 1: Update Environment Configuration

**File**: `admin_web/lib/core/config/environment_config.dart`

**Changes**:
```dart
// BEFORE
static const AdminEnvironment currentEnvironment = AdminEnvironment.development;
AdminEnvironment.production: 'https://api.vanyatra.com',

// AFTER
static const AdminEnvironment currentEnvironment = AdminEnvironment.production;
AdminEnvironment.production: 'http://57.159.31.172:8000',
```

**Result**: Admin web now points to actual production server.

### Fix 2: Update Google Places Service to Use Locations API

**File**: `admin_web/lib/core/services/google_places_service.dart`

**Changes**:

#### 1. Changed Base URL
```dart
// BEFORE
static String get baseUrl => '${AdminEnvironmentConfig.apiBaseUrl}/googleplaces';

// AFTER
static String get baseUrl => '${AdminEnvironmentConfig.apiBaseUrl}/locations';
```

#### 2. Updated getPlaceSuggestions() Method
```dart
// BEFORE - Called /googleplaces/autocomplete
final uri = Uri.parse('$baseUrl/autocomplete').replace(
  queryParameters: {
    'input': query,
    'components': 'country:in',
  },
);

// AFTER - Calls /locations/search
final uri = Uri.parse('$baseUrl/search').replace(
  queryParameters: {
    'query': query,
    'limit': '15',
  },
);
```

#### 3. Response Parsing Updated
```dart
// BEFORE - Expected Google Places format
if (json['success'] == true && json['data']['suggestions'] != null) {
  return suggestions.map((p) => PlaceAutocompleteResult.fromJson(p)).toList();
}

// AFTER - Parses locations API format
if (json['success'] == true && json['data']['locations'] != null) {
  final locations = json['data']['locations'] as List;
  return locations.map((loc) => PlaceAutocompleteResult(
    placeId: loc['id'] ?? '',
    description: loc['fullAddress'] ?? loc['name'] ?? '',
    mainText: loc['name'] ?? '',
    secondaryText: '${loc['district']}, ${loc['state']}',
  )).toList();
}
```

#### 4. Updated getPlaceDetails() Method
```dart
// BEFORE - Called /googleplaces/details/{placeId}
final uri = Uri.parse('$baseUrl/details/$placeId');

// AFTER - Calls /locations/{id}
final uri = Uri.parse('$baseUrl/$placeId');

// Converts location response to PlaceDetails format
return PlaceDetails(
  placeId: loc['id'] ?? '',
  name: loc['name'] ?? '',
  formattedAddress: loc['fullAddress'] ?? '',
  latitude: (loc['latitude'] as num?)?.toDouble() ?? 0.0,
  longitude: (loc['longitude'] as num?)?.toDouble() ?? 0.0,
  addressComponents: [
    AddressComponent(
      longName: loc['district'] ?? '',
      shortName: loc['district'] ?? '',
      types: ['locality'],
    ),
    AddressComponent(
      longName: loc['state'] ?? '',
      shortName: loc['state'] ?? '',
      types: ['administrative_area_level_1'],
    ),
  ],
);
```

## Files Modified

```
admin_web/lib/core/config/environment_config.dart
admin_web/lib/core/services/google_places_service.dart
```

## API Endpoints Now Used

### Location Search
- **Endpoint**: `GET /api/v1/locations/search?query={query}&limit=15`
- **Response Format**:
```json
{
  "success": true,
  "data": {
    "locations": [
      {
        "id": "uuid",
        "name": "Main Road, Allapalli",
        "state": "Maharashtra",
        "district": "Gadchiroli",
        "latitude": 19.65,
        "longitude": 79.8833,
        "fullAddress": "Main Road, Allapalli, Maharashtra"
      }
    ]
  }
}
```

### Location Details
- **Endpoint**: `GET /api/v1/locations/{id}`
- **Response Format**:
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "Main Road, Allapalli",
    "state": "Maharashtra",
    "district": "Gadchiroli",
    "latitude": 19.65,
    "longitude": 79.8833,
    "fullAddress": "Main Road, Allapalli, Maharashtra"
  }
}
```

## Deployment Process

### 1. Build Admin Web App
```bash
cd admin_web
flutter clean
flutter pub get
flutter build web --release --web-renderer html
```

### 2. Deploy to Server
```bash
# Copy to server temp directory
scp -r admin_web/build/web akhileshallewar880@57.159.31.172:/tmp/admin-web-new

# Move to production location with proper permissions
ssh akhileshallewar880@57.159.31.172 "
  sudo rm -rf /var/www/vanyatra-admin/* && 
  sudo cp -r /tmp/admin-web-new/* /var/www/vanyatra-admin/ && 
  sudo chown -R www-data:www-data /var/www/vanyatra-admin/ && 
  rm -rf /tmp/admin-web-new
"
```

## Testing Checklist

### ✅ Admin Web App
- [ ] Open admin web app in browser
- [ ] Navigate to Locations tab
- [ ] Try adding a new location
- [ ] Type in location search field (e.g., "Allapalli")
- [ ] Verify autocomplete suggestions appear
- [ ] Select a location from suggestions
- [ ] Verify location details populate correctly

### ✅ API Connectivity
- [ ] Check browser console - no `ERR_ADDRESS_UNREACHABLE` errors
- [ ] Verify API calls go to `http://57.159.31.172:8000`
- [ ] Confirm `/api/v1/locations/search` endpoint responds
- [ ] Confirm response parsing works correctly

## Important Notes

### Google Places API vs Locations API

**Admin web app does NOT use Google Places API**. Instead it uses:
- **Backend Locations API**: `/api/v1/locations/search`
- **Database**: Cities table with 25 Vidarbha region cities
- **No Google API Key Required**: All location data comes from our database

### Why "GooglePlacesService"?

The service is named `GooglePlacesService` for historical reasons (originally planned to use Google Places API), but it now uses the backend locations API. The name has been retained to avoid breaking changes in widgets that import this service.

### Environment Switching

To switch between environments (development/production), modify:
```dart
// admin_web/lib/core/config/environment_config.dart
static const AdminEnvironment currentEnvironment = AdminEnvironment.production;
```

Options:
- `AdminEnvironment.development` - Local server (192.168.88.14:5056)
- `AdminEnvironment.staging` - Staging server (if available)
- `AdminEnvironment.production` - Production server (57.159.31.172:8000)

## Related Issues Fixed Previously

### Backend Location API (Fixed Earlier Today)
1. Fixed `/api/v1/locations/popular` endpoint response format
2. Seeded 25 cities in database
3. Resolved DECIMAL→REAL data type mismatch
4. Updated mobile app to parse wrapped API responses

### Mobile App (Fixed Earlier Today)
1. Updated `LocationService` to handle wrapped API responses
2. Fixed popular locations parsing
3. Fixed search locations parsing

## Status

✅ **Admin Web App - Environment Fixed**  
✅ **Admin Web App - Google Places Service Updated**  
✅ **Admin Web App - Built for Production**  
✅ **Admin Web App - Deployed to Server**  
⏳ **Testing Required** - User should test location search in admin web

## Next Steps

1. **Clear Browser Cache**: Admin web users should hard-refresh (Ctrl+Shift+R or Cmd+Shift+R)
2. **Test Location Search**: Try adding a location in admin panel
3. **Verify Autocomplete**: Type "Alla" and check if "Allapalli" appears
4. **Check Console**: Ensure no network errors

---

**Date**: January 11, 2026  
**Server**: 57.159.31.172:8000  
**Admin Web URL**: http://57.159.31.172 (assuming Nginx configured)  
**Cities Database**: 25 active cities in Vidarbha region
