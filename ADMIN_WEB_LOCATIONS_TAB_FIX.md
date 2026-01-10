# Admin Web Locations Tab Error Fix

## Issue
The admin web locations tab was throwing a runtime error when trying to load location data.

## Root Causes Identified

### 1. Incorrect API Base URL
**Problem**: The admin web environment config had the wrong IP address.
- **Old**: `http://192.168.88.10:5056`
- **New**: `http://192.168.88.14:5056`

**File**: `admin_web/lib/core/config/environment_config.dart`

### 2. Case Sensitivity in JSON Parsing
**Problem**: The AdminLocation model's `fromJson` method was not handling both camelCase and PascalCase field names from the backend API.

The .NET backend is configured to use camelCase JSON serialization:
```csharp
// Program.cs
options.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
```

However, the AdminLocation model was only looking for camelCase fields, and if there were any issues with the serialization, it would fail.

**File**: `admin_web/lib/models/admin_location_models.dart`

## Fixes Applied

### Fix 1: Update API Base URL
Updated the environment configuration to use the correct server IP address:

```dart
// admin_web/lib/core/config/environment_config.dart
static const Map<AdminEnvironment, String> _apiBaseUrls = {
  AdminEnvironment.development: 'http://192.168.88.14:5056', // Fixed IP
  AdminEnvironment.staging: 'https://staging-api.vanyatra.com',
  AdminEnvironment.production: 'https://api.vanyatra.com',
};
```

### Fix 2: Robust JSON Parsing
Updated the AdminLocation.fromJson method to handle both camelCase and PascalCase, with null safety:

```dart
factory AdminLocation.fromJson(Map<String, dynamic> json) {
  return AdminLocation(
    id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
    name: json['name'] ?? json['Name'] ?? '',
    state: json['state'] ?? json['State'] ?? '',
    district: json['district'] ?? json['District'] ?? '',
    subLocation: json['subLocation'] ?? json['SubLocation'],
    pincode: json['pincode'] ?? json['Pincode'],
    latitude: (json['latitude'] ?? json['Latitude'])?.toDouble(),
    longitude: (json['longitude'] ?? json['Longitude'])?.toDouble(),
    isActive: json['isActive'] ?? json['IsActive'] ?? false,
    createdAt: DateTimeParser.parse(json['createdAt'] ?? json['CreatedAt']),
    updatedAt: DateTimeParser.parse(json['updatedAt'] ?? json['UpdatedAt']),
  );
}
```

**Benefits**:
- Handles both camelCase (id, name) and PascalCase (Id, Name) field names
- Provides safe defaults for required fields (empty string for strings, false for booleans)
- Uses null-aware operators to prevent null reference errors
- Converts Guid to String automatically using `.toString()`
- Properly converts numeric values to double for latitude/longitude

## Backend API Structure

The admin locations endpoint returns data in this structure:

```json
{
  "success": true,
  "message": "Locations retrieved successfully",
  "data": {
    "locations": [
      {
        "id": "guid-string",
        "name": "Location Name",
        "state": "State",
        "district": "District",
        "subLocation": "Sub Location",
        "pincode": "123456",
        "latitude": 19.9167,
        "longitude": 79.3167,
        "isActive": true,
        "createdAt": "2026-01-03T10:00:00.0000000",
        "updatedAt": "2026-01-03T10:00:00.0000000"
      }
    ],
    "totalCount": 100,
    "page": 1,
    "pageSize": 50,
    "totalPages": 2
  },
  "error": null
}
```

## Testing

To verify the fix:

1. **Start the backend server** (should be running on `http://192.168.88.14:5056`)

2. **Run the admin web app**:
   ```bash
   cd admin_web
   flutter run -d chrome --web-port=8081
   ```

3. **Navigate to the Locations tab** in the admin dashboard

4. **Verify**:
   - Statistics load correctly (total locations, active, etc.)
   - Location list displays properly
   - Pagination works
   - Search functionality works
   - Add/Edit/Delete operations work

## Related Files

- `admin_web/lib/core/config/environment_config.dart` - Environment configuration
- `admin_web/lib/models/admin_location_models.dart` - Data models
- `admin_web/lib/services/location_service.dart` - API service
- `admin_web/lib/screens/locations_management_screen.dart` - UI screen
- `server/ride_sharing_application/RideSharing.API/Controllers/AdminLocationsController.cs` - Backend API
- `server/ride_sharing_application/RideSharing.API/Models/DTO/AdminLocationDto.cs` - Backend DTO

## Status

✅ **Fixed**: API base URL corrected
✅ **Fixed**: JSON parsing made robust with fallbacks
🔄 **Pending**: User testing to confirm locations tab works correctly

## Next Steps

1. Test the locations tab in the admin web app
2. Verify all CRUD operations work correctly
3. Check statistics display
4. Test pagination and search functionality
5. If any errors persist, check browser console for detailed error messages
