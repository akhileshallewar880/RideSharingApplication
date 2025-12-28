# Location Search & Autocomplete Feature

## Overview
This feature provides an autocomplete location search functionality for the pickup and dropoff location fields in the passenger home screen. When users start typing a city or location name, they will see relevant suggestions displayed in a dropdown.

## Components

### 1. LocationSuggestion Model
**Path:** `lib/features/passenger/domain/models/location_suggestion.dart`

Model representing a location with the following properties:
- `id`: Unique identifier
- `name`: Location name (e.g., "Allapalli")
- `state`: State name (e.g., "Maharashtra")
- `district`: District name (e.g., "Gadchiroli")
- `latitude`: Location latitude (optional)
- `longitude`: Location longitude (optional)
- `fullAddress`: Complete formatted address (e.g., "Allapalli, Maharashtra")

### 2. LocationService
**Path:** `lib/core/services/location_service.dart`

Service that handles location search with the following features:
- **API Integration**: Attempts to fetch locations from backend API endpoint `/locations/search`
- **Fallback Data**: Uses predefined local locations if API is unavailable
- **Smart Filtering**: Filters and ranks results based on query relevance
- **Coverage**: 43+ predefined locations covering:
  - Gadchiroli District (13 locations)
  - Chandrapur District (14 locations)
  - Nagpur District (7 locations)
  - Gondia District (5 locations)
  - Additional towns and villages

#### Search Algorithm
1. Exact match (highest priority)
2. Starts with query (second priority)
3. Contains query (third priority)
4. Returns top 10 results

### 3. LocationSearchField Widget
**Path:** `lib/features/passenger/presentation/widgets/location_search_field.dart`

A custom Flutter widget that provides autocomplete functionality:
- **Real-time Search**: Triggers search as user types (minimum 2 characters)
- **Dropdown Overlay**: Shows suggestions in a styled overlay below the input
- **Loading Indicator**: Displays loading state while searching
- **Clear Button**: Allows users to clear the input
- **Selection Callback**: Notifies parent when location is selected
- **Dark Mode Support**: Adapts to light/dark theme

#### Features:
- Debounced search (prevents excessive API calls)
- Overlay positioning using `CompositedTransformTarget`
- Smooth animations
- Keyboard-friendly
- Touch-friendly tap targets

### 4. LocationProvider
**Path:** `lib/core/providers/location_provider.dart`

Riverpod provider that creates and manages the LocationService instance.

## Usage

### In Passenger Home Screen
```dart
LocationSearchField(
  hint: 'Pickup location',
  controller: _pickupController,
  locationService: ref.read(locationServiceProvider),
  prefixIcon: Icons.trip_origin,
  onLocationSelected: (location) {
    setState(() {
      _selectedPickup = location;
    });
  },
)
```

## User Experience

1. **Start Typing**: User types "Alla" in pickup location
2. **Show Suggestions**: Dropdown appears showing:
   - Allapalli, Maharashtra (exact/starts with match - top result)
   - Ballarpur, Maharashtra (contains match)
   - Other relevant matches
3. **Select Location**: User taps on "Allapalli, Maharashtra"
4. **Auto-fill**: Field is filled with "Allapalli, Maharashtra"
5. **Callback**: Parent component receives LocationSuggestion object with full details

## Backend API (Optional)

If backend implements location search API, the service will use it:

**Endpoint:** `GET /api/v1/locations/search`
**Query Parameters:** 
- `query`: Search string
- `limit`: Max results (default: 10)

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "locations": [
      {
        "id": "1",
        "name": "Allapalli",
        "state": "Maharashtra",
        "district": "Gadchiroli",
        "latitude": 19.4333,
        "longitude": 79.9167,
        "fullAddress": "Allapalli, Maharashtra"
      }
    ]
  }
}
```

## Fallback Behavior

If the API is not available or returns an error:
- Service automatically falls back to predefined local locations
- No user-visible error (seamless fallback)
- Console log message for debugging

## Future Enhancements

1. **Google Places Integration**: For locations outside predefined list
2. **Recent Searches**: Cache and show recently searched locations
3. **Favorite Locations**: Save frequently used locations
4. **GPS Location**: Add "Current Location" option
5. **Map Integration**: Show location on map before selection
6. **Route Suggestions**: Suggest popular routes
7. **Multi-language Support**: Location names in local languages

## Testing

To test the feature:
1. Run the app
2. Navigate to passenger home screen
3. Tap on pickup location field
4. Type "Alla" - should see "Allapalli, Maharashtra"
5. Type "Chand" - should see "Chandrapur, Maharashtra"
6. Type "Nagpur" - should see "Nagpur, Maharashtra"
7. Select a location and verify field is filled
8. Repeat for dropoff location field

## Predefined Locations

The service includes 43 predefined locations covering major towns and cities in:
- **Gadchiroli District**: Allapalli, Gadchiroli, Aheri, Etapalli, Bhamragad, Dhanora, Desaiganj, Armori, Kurkheda, Korchi, Chamorshi, Mulchera, Sironcha
- **Chandrapur District**: Chandrapur, Ballarpur, Bramhapuri, Mul, Warora, Rajura, Gondpipri, Bhadravati, Sindewahi, Chimur, Pombhurna, Sawli, Korpana, Jivati, Nagbhir
- **Nagpur District**: Nagpur, Kamptee, Umred, Ramtek, Katol, Parseoni, Saoner
- **Gondia District**: Gondia, Tirora, Sadak Arjuni, Goregaon, Salekasa
- **Additional**: Palasgad, Jimalgatta, Kelapur

Each location includes coordinates for future map integration.
